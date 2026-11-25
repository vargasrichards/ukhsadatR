# Retrieval of English GP prescribing data from the OpenPrescribing API
#
# OpenPrescribing (https://openprescribing.net, Bennett Institute for Applied
# Data Science, University of Oxford) re-publishes the NHS Business Services
# Authority "English Prescribing Dataset". Its keyless REST API
# (https://openprescribing.net/api/) returns monthly items, quantity and actual
# cost for any BNF code (chapter, section, paragraph, chemical, product or
# presentation), aggregated to England, NHS England region, ICB, Sub-ICB
# Location, Primary Care Network or individual practice, for the most recent
# five years.
#
# Endpoints wrapped here (all under /api/1.0/):
#   spending_by_org/  -> get_op_spending(), get_op_antibiotics()
#   org_details/      -> get_op_org_details()   (list size, ASTRO-PU, STAR-PU)
#   bnf_code/         -> search_op_bnf()
#   org_code/         -> search_op_org()
#   org_location/     -> get_op_boundaries()    (GeoJSON boundaries)
#
# Every request goes through the single internal function .op_get(), which
# is the only place that touches the network. The offline tests replace it
# with a mock.

.op_base <- "https://openprescribing.net/api/1.0"

# canonical resolution -> the `org_type` value the API understands. The API
# still uses the pre-2022 names internally: "ccg" is a Sub-ICB Location and
# "stp" is an ICB. `NA` means "no org_type" (an England-wide total).
.op_api_org_type <- c(
  england  = NA_character_,
  region   = "regional_team",
  icb      = "stp",
  sicbl    = "ccg",
  pcn      = "pcn",
  practice = "practice"
)

.op_resolution_aliases <- c(
  england = "england", national = "england", nation = "england", all = "england",
  region = "region", regional_team = "region", nhse_region = "region",
  icb = "icb", stp = "icb", integrated_care_board = "icb",
  sicbl = "sicbl", sub_icb = "sicbl", subicb = "sicbl", ccg = "sicbl",
  pcn = "pcn",
  practice = "practice", gp = "practice"
)

# ---- low-level HTTP -------------------------------------------------------

# Describe an HTTP error from OpenPrescribing in one readable message.
.op_stop_http <- function(status, body, path) {
  if (status == 403 && grepl("just a moment|cloudflare|challenge", body, ignore.case = TRUE)) {
    stop(
      "OpenPrescribing refused the request (HTTP 403, a bot-protection challenge), ",
      "so no data could be retrieved from ", path, ".\n",
      "This is applied by the service to some networks and clients (for example some ",
      "cloud or institutional IP ranges). Try again later or from another network, ",
      "and consider reducing the request rate with ",
      "options(ukhsadatR.requests_per_second = 0.5).",
      call. = FALSE
    )
  }
  detail <- tryCatch(jsonlite::fromJSON(body), error = function(e) NULL)
  msg <- if (is.character(detail) && length(detail) == 1) {
    detail
  } else if (is.list(detail) && !is.null(detail$detail)) {
    as.character(detail$detail)
  } else {
    substr(gsub("\\s+", " ", body), 1, 200)
  }
  stop(sprintf("OpenPrescribing API error (HTTP %d) for %s: %s", status, path, msg),
       call. = FALSE)
}

# GET <base><path>?<query>&format=json. Returns the parsed JSON (a data.frame
# for the usual array-of-objects responses), or the raw body when raw = TRUE
# (used for GeoJSON). Rate limited and retried like the UKHSA requests.
.op_get <- function(path, query = list(), timeout = 60, raw = FALSE) {
  query <- query[!vapply(query, is.null, logical(1))]
  query$format <- "json"
  req <- httr2::request(paste0(.op_base, path))
  req <- do.call(httr2::req_url_query, c(list(req), query))
  resp <- req |>
    httr2::req_user_agent("ukhsadatR (https://github.com/vargasrichards/ukamrdataR)") |>
    httr2::req_throttle(rate = .rate_limit(), realm = "ukhsadatR-openprescribing") |>
    httr2::req_retry(
      max_tries = 5,
      is_transient = function(resp) httr2::resp_status(resp) %in% c(429, 502, 503, 504),
      backoff = function(i) min(60, 2^i)
    ) |>
    httr2::req_timeout(timeout) |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_perform()

  status <- httr2::resp_status(resp)
  body <- httr2::resp_body_string(resp)
  if (status >= 400) .op_stop_http(status, body, path)
  if (raw) return(body)
  jsonlite::fromJSON(body)
}

# ---- argument handling ----------------------------------------------------

.op_resolution <- function(resolution) {
  if (!is.character(resolution) || length(resolution) != 1 || is.na(resolution)) {
    stop("'resolution' must be a single string, one of: ",
         paste(names(.op_api_org_type), collapse = ", "), call. = FALSE)
  }
  key <- gsub("[ -]+", "_", tolower(trimws(resolution)))
  canon <- unname(.op_resolution_aliases[key])
  if (is.na(canon)) {
    stop(sprintf("Unknown resolution '%s'. Use one of: %s", resolution,
                 paste(names(.op_api_org_type), collapse = ", ")), call. = FALSE)
  }
  list(name = canon, api = unname(.op_api_org_type[canon]))
}

# `code` -> data.frame(code, label). Names of a named vector become labels.
.op_codes <- function(code) {
  if (is.null(code) || length(code) == 0) {
    stop("'code' is required: a BNF code or section number such as \"0501\" or \"5.1.1\". ",
         "Find codes with search_op_bnf() or op_antibiotic_classes().", call. = FALSE)
  }
  lab <- names(code)
  code <- trimws(as.character(code))
  if (anyNA(code) || any(!nzchar(code))) stop("'code' must not contain empty values", call. = FALSE)
  if (any(grepl(",", code, fixed = TRUE))) {
    stop("Give one code per element, not comma-separated strings. ",
         "Use combine = TRUE to sum several codes.", call. = FALSE)
  }
  if (is.null(lab)) lab <- code
  lab[is.na(lab) | !nzchar(lab)] <- code[is.na(lab) | !nzchar(lab)]
  data.frame(code = code, code_label = lab, stringsAsFactors = FALSE)
}

.op_org <- function(org, res) {
  if (is.null(org)) return(NULL)
  if (res$name == "england") {
    stop("'org' cannot be used with resolution = \"england\"; choose a finer resolution.",
         call. = FALSE)
  }
  org <- trimws(as.character(org))
  org <- org[!is.na(org) & nzchar(org)]
  if (length(org) == 0) NULL else org
}

.op_as_month <- function(x, arg) {
  if (inherits(x, "POSIXt")) x <- as.Date(x)
  if (is.character(x)) x <- ifelse(grepl("^\\d{4}-\\d{2}$", x), paste0(x, "-01"), x)
  d <- tryCatch(as.Date(x), error = function(e) as.Date(NA))
  if (anyNA(d)) {
    stop(sprintf("'%s' must be Date objects or \"YYYY-MM-DD\" / \"YYYY-MM\" strings", arg),
         call. = FALSE)
  }
  as.Date(format(d, "%Y-%m-01"))  # the API only holds first-of-month dates
}

# -> list(months = Date vector or NULL, from, to). `months` is only filled when
# an explicit set of months is implied (date, or start AND end).
.op_resolve_dates <- function(date, start, end) {
  if (!is.null(date) && (!is.null(start) || !is.null(end))) {
    stop("Use either 'date' or 'start'/'end', not both.", call. = FALSE)
  }
  if (!is.null(date)) {
    m <- sort(unique(.op_as_month(date, "date")))
    return(list(months = m, from = NULL, to = NULL))
  }
  from <- if (!is.null(start)) .op_as_month(start, "start")
  to   <- if (!is.null(end))   .op_as_month(end, "end")
  if (!is.null(from) && !is.null(to) && from > to) stop("'start' is after 'end'.", call. = FALSE)
  months <- if (!is.null(from) && !is.null(to)) seq(from, to, by = "month") else NULL
  list(months = months, from = from, to = to)
}

.op_filter_dates <- function(df, win) {
  if (nrow(df) == 0) return(df)
  keep <- rep(TRUE, nrow(df))
  if (!is.null(win$months)) keep <- keep & df$date %in% win$months
  if (!is.null(win$from))   keep <- keep & df$date >= win$from
  if (!is.null(win$to))     keep <- keep & df$date <= win$to
  df[keep, , drop = FALSE]
}

# The API `org_type` for a resolution, or NULL (omit the parameter) for England.
.op_api_type <- function(res) if (is.na(res$api)) NULL else res$api

.op_as_df <- function(x) if (is.data.frame(x)) x else data.frame()

.op_finish <- function(df, as_data_table) {
  rownames(df) <- NULL
  if (isTRUE(as_data_table)) data.table::as.data.table(df) else df
}

# ---- spending -------------------------------------------------------------

.op_tidy_spending <- function(x, res, code, label) {
  x <- .op_as_df(x)
  n <- nrow(x)
  col <- function(nm, as, default) if (n > 0 && !is.null(x[[nm]])) as(x[[nm]]) else default
  out <- data.frame(
    date        = if (n > 0) as.Date(x$date) else as.Date(character()),
    resolution  = rep(res$name, n),
    org_id      = col("row_id", as.character, rep(NA_character_, n)),
    org_name    = col("row_name", as.character, rep(NA_character_, n)),
    code        = rep(code, n),
    code_label  = rep(label, n),
    items       = col("items", as.numeric, rep(NA_real_, n)),
    quantity    = col("quantity", as.numeric, rep(NA_real_, n)),
    actual_cost = col("actual_cost", as.numeric, rep(NA_real_, n)),
    stringsAsFactors = FALSE
  )
  if (res$name == "practice") {
    out$parent_sicbl <- col("ccg", as.character, rep(NA_character_, n))
    out$setting      <- col("setting", as.integer, rep(NA_integer_, n))
  }
  out
}

#' Get prescribing totals from OpenPrescribing
#'
#' Retrieves monthly prescribing \emph{items}, \emph{quantity} and
#' \emph{actual cost} (GBP) for one or more BNF codes from the
#' \href{https://openprescribing.net/api/}{OpenPrescribing API}, aggregated to
#' the spatial resolution you choose. The data are NHS England primary-care
#' (mainly GP) prescriptions dispensed in the community, from the English
#' Prescribing Dataset; the API holds the most recent five years.
#'
#' @section Spatial resolutions:
#' \describe{
#'   \item{\code{"england"}}{one national series (the default).}
#'   \item{\code{"region"}}{NHS England regions (the API's \code{regional_team}).}
#'   \item{\code{"icb"}}{Integrated Care Boards (the API's \code{stp}).}
#'   \item{\code{"sicbl"}}{Sub-ICB Locations (the API's \code{ccg}).}
#'   \item{\code{"pcn"}}{Primary Care Networks.}
#'   \item{\code{"practice"}}{individual GP practices.}
#' }
#' \code{"stp"}, \code{"ccg"}, \code{"sub-icb"} and \code{"regional_team"} are
#' accepted as aliases. Organisations are those currently defined by
#' OpenPrescribing: practice prescribing is attributed to the organisation the
#' practice belongs to now, so a series does not follow past mergers or
#' boundary changes. Check that the \code{org_id} values match the boundary
#' vintage you plan to join them to.
#'
#' @section BNF codes:
#' \code{code} is matched as a \emph{prefix}, so \code{"0501"} covers all of
#' BNF section 5.1 (antibacterial drugs) and \code{"0501013B0"} a single
#' chemical. Section numbers such as \code{"5.1"} or \code{"5.1.1"} are also
#' accepted. If you supply several codes they are fetched separately (one API
#' request each) and returned in long format with a \code{code} column, unless
#' \code{combine = TRUE}. Names on \code{code} become the \code{code_label}
#' column. Find codes with \code{\link{search_op_bnf}} or
#' \code{\link{op_antibiotic_classes}}.
#'
#' @section Request volume:
#' National and organisation-level queries need one request per code. The API
#' will not return all practices for all months in one call, so
#' \code{resolution = "practice"} without \code{org} needs \code{date} or both
#' \code{start} and \code{end} and sends one request per code per month. All
#' requests are throttled to
#' \code{getOption("ukhsadatR.requests_per_second", 1)}.
#'
#' @param code character vector of BNF codes or section numbers (see Details).
#'   Optionally named to set labels.
#' @param resolution spatial resolution: one of \code{"england"} (default),
#'   \code{"region"}, \code{"icb"}, \code{"sicbl"}, \code{"pcn"},
#'   \code{"practice"}.
#' @param org optional character vector of organisation codes to keep (for
#'   example ICB codes). For \code{resolution = "practice"} a Sub-ICB code
#'   expands to all of its practices. \code{NULL} (default) returns every
#'   organisation at that resolution. Find codes with
#'   \code{\link{search_op_org}}.
#' @param date optional month(s) to return: Date objects or
#'   \code{"YYYY-MM-DD"} / \code{"YYYY-MM"} strings. Any day is rounded down to
#'   the first of its month.
#' @param start,end optional first and last month (inclusive) as for
#'   \code{date}; either may be given alone. Not combinable with \code{date}.
#' @param combine logical. If \code{TRUE}, all \code{code}s are summed in a
#'   single request (the API treats multiple codes as a union) and returned
#'   as one series. Beware double counting if the codes overlap.
#' @param add_list_size logical. If \code{TRUE}, also fetch
#'   \code{\link{get_op_org_details}} and add \code{total_list_size} and
#'   \code{items_per_1000} (items per 1,000 registered patients).
#' @param as_data_table logical; return a \code{data.table}.
#' @param verbose logical; message the number of requests when it is large.
#'
#' @return A data.frame with one row per month and organisation (and code):
#' \describe{
#'   \item{date}{first day of the month (\code{Date}).}
#'   \item{resolution}{the canonical resolution requested.}
#'   \item{org_id, org_name}{organisation code and name (\code{NA} / "england"
#'     for national totals).}
#'   \item{code, code_label}{the BNF code (or comma-joined codes if
#'     \code{combine}) and its label.}
#'   \item{items}{number of prescription items.}
#'   \item{quantity}{total quantity dispensed (units depend on the
#'     presentation, so only compare within the same product).}
#'   \item{actual_cost}{actual cost in GBP.}
#' }
#' Practice-level results add \code{parent_sicbl} and \code{setting} (the
#' practice setting code; 4 is a standard GP practice). With
#' \code{add_list_size}, columns \code{total_list_size} and
#' \code{items_per_1000} are appended. Months with no prescribing for an
#' organisation are omitted by the API, not returned as zero.
#'
#' @seealso \code{\link{get_op_antibiotics}}, \code{\link{get_op_org_details}},
#'   \code{\link{get_op_boundaries}}
#'
#' @export
#'
#' @examples
#' \donttest{
#' # All antibacterials (BNF 5.1), England, monthly
#' get_op_spending("0501")
#'
#' # Penicillins and macrolides by ICB for 2024, with rates per 1,000 patients
#' get_op_spending(
#'   c(Penicillins = "050101", Macrolides = "050105"),
#'   resolution = "icb", start = "2024-01", end = "2024-12",
#'   add_list_size = TRUE
#' )
#'
#' # One chemical (amoxicillin) in every practice of one Sub-ICB, one month
#' sicbl <- search_op_org("devon", resolution = "sicbl")$code[1]
#' get_op_spending("0501013B0", resolution = "practice", org = sicbl,
#'                 date = "2024-06")
#' }
get_op_spending <- function(
  code,
  resolution = "england",
  org = NULL,
  date = NULL,
  start = NULL,
  end = NULL,
  combine = FALSE,
  add_list_size = FALSE,
  as_data_table = FALSE,
  verbose = TRUE
) {
  res <- .op_resolution(resolution)
  codes <- .op_codes(if (missing(code)) NULL else code)
  org <- .op_org(org, res)
  win <- .op_resolve_dates(date, start, end)

  if (isTRUE(combine) && nrow(codes) > 1) {
    codes <- data.frame(
      code = paste(codes$code, collapse = ","),
      code_label = paste(codes$code_label, collapse = " + "),
      stringsAsFactors = FALSE
    )
  }

  # The API refuses "all practices, all months" in one call: it needs an org
  # list or a single date, so loop over months in that case.
  per_month <- res$name == "practice" && is.null(org)
  if (per_month) {
    if (is.null(win$months)) {
      stop("resolution = \"practice\" without 'org' needs 'date', or both 'start' and 'end'. ",
           "Alternatively restrict 'org' to one or more practices or Sub-ICB codes.",
           call. = FALSE)
    }
    jobs <- expand.grid(i = seq_len(nrow(codes)), month = format(win$months),
                        KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  } else {
    one_month <- if (length(win$months) == 1) format(win$months) else NA_character_
    jobs <- data.frame(i = seq_len(nrow(codes)), month = one_month,
                       stringsAsFactors = FALSE)
  }

  if (isTRUE(verbose) && nrow(jobs) > 10) {
    message(sprintf(
      "Sending %d requests to OpenPrescribing (about %.0f minute(s) at %g request(s)/second).",
      nrow(jobs), ceiling(nrow(jobs) / .rate_limit() / 60), .rate_limit()
    ))
  }

  parts <- lapply(seq_len(nrow(jobs)), function(k) {
    ci <- jobs$i[k]
    raw <- .op_get("/spending_by_org/", list(
      code = codes$code[ci],
      org_type = .op_api_type(res),
      org = if (!is.null(org)) paste(org, collapse = ","),
      date = if (!is.na(jobs$month[k])) jobs$month[k]
    ))
    .op_tidy_spending(raw, res, codes$code[ci], codes$code_label[ci])
  })
  out <- do.call(rbind, parts)
  out <- .op_filter_dates(out, win)

  if (nrow(out) > 0) {
    out <- out[order(out$code_label, out$org_id, out$date), , drop = FALSE]
  }

  if (isTRUE(add_list_size)) {
    ls <- get_op_org_details(res$name, org = org, keys = "total_list_size",
                             date = date, start = start, end = end)
    key <- function(d) paste(d$date, ifelse(is.na(d$org_id), "", d$org_id))
    out$total_list_size <- ls$total_list_size[match(key(out), key(ls))]
    out$items_per_1000 <- ifelse(
      is.na(out$total_list_size) | out$total_list_size == 0,
      NA_real_, out$items / out$total_list_size * 1000
    )
  }
  .op_finish(out, as_data_table)
}

# ---- antibiotics ----------------------------------------------------------

#' BNF antibacterial drug classes (BNF section 5.1)
#'
#' The sub-sections of BNF chapter 5, section 1 ("Antibacterial drugs"), with
#' the BNF codes that \code{\link{get_op_spending}} accepts. Use it to pick
#' classes for \code{\link{get_op_antibiotics}}.
#'
#' The classes follow the BNF's own grouping, which is by drug class or
#' use rather than by AWaRe category, ATC group or the UKHSA/ESPAUR
#' definitions, and some classes straddle those (for example 5.1.7 and 5.1.13
#' mix agents). Section 5.1.9 (antituberculosis) and 5.1.10 (antileprotic) are
#' included for completeness but are normally excluded from community
#' antibiotic-stewardship analyses. BNF classification is revised over time;
#' confirm any code you rely on with \code{\link{search_op_bnf}}.
#'
#' @return A data.frame with columns \code{number} (BNF section number, e.g.
#'   \code{"5.1.1"}), \code{code} (BNF code prefix, e.g. \code{"050101"}) and
#'   \code{class}. The first row is the whole of section 5.1.
#' @export
#' @examples
#' op_antibiotic_classes()
op_antibiotic_classes <- function() {
  data.frame(
    number = c("5.1", paste0("5.1.", 1:13)),
    code = c("0501", sprintf("0501%02d", 1:13)),
    class = c(
      "All antibacterial drugs",
      "Penicillins",
      "Cephalosporins, carbapenems and other beta-lactams",
      "Tetracyclines",
      "Aminoglycosides",
      "Macrolides",
      "Clindamycin and lincomycin",
      "Some other antibiotics",
      "Sulfonamides and trimethoprim",
      "Antituberculosis drugs",
      "Antileprotic drugs",
      "Metronidazole, tinidazole and ornidazole",
      "Quinolones",
      "Urinary-tract infections"
    ),
    stringsAsFactors = FALSE
  )
}

#' Get antibiotic prescribing by BNF class from OpenPrescribing
#'
#' A convenience wrapper around \code{\link{get_op_spending}} that retrieves
#' one series per antibacterial class in BNF section 5.1 (see
#' \code{\link{op_antibiotic_classes}}) at the spatial resolution you choose.
#'
#' @param classes which classes to fetch: \code{NULL} (default) for all
#'   thirteen sub-sections 5.1.1-5.1.13, or a character vector of section
#'   numbers (\code{"5.1.5"}), BNF codes (\code{"050105"}) or class names
#'   (\code{"Macrolides"}, case-insensitive).
#' @param include_total logical. Also fetch all of section 5.1 as a further
#'   series (\code{code} \code{"0501"}). It overlaps the classes, so do not
#'   sum it with them.
#' @param ... passed to \code{\link{get_op_spending}}: \code{resolution},
#'   \code{org}, \code{date}, \code{start}, \code{end}, \code{add_list_size},
#'   \code{as_data_table}, \code{verbose}.
#'
#' @return As \code{\link{get_op_spending}}, with the class name in
#'   \code{code_label}. Costs one request per class (13 by default).
#'
#' @seealso \code{\link{op_antibiotic_classes}}
#' @export
#'
#' @examples
#' \donttest{
#' # Macrolide and tetracycline items per 1,000 patients, by ICB, since 2023
#' get_op_antibiotics(c("5.1.3", "Macrolides"), resolution = "icb",
#'                    start = "2023-01", add_list_size = TRUE)
#' }
get_op_antibiotics <- function(classes = NULL, include_total = FALSE, ...) {
  tab <- op_antibiotic_classes()
  sub <- tab[-1, , drop = FALSE]
  if (is.null(classes)) {
    sel <- sub
  } else {
    classes <- trimws(as.character(classes))
    hit <- vapply(classes, function(cl) {
      m <- which(sub$number == cl | sub$code == cl | tolower(sub$class) == tolower(cl))
      if (length(m) == 1) m else NA_integer_
    }, integer(1))
    if (anyNA(hit)) {
      stop("Unknown antibiotic class: ", paste(classes[is.na(hit)], collapse = ", "),
           ". See op_antibiotic_classes().", call. = FALSE)
    }
    sel <- sub[unique(hit), , drop = FALSE]
  }
  if (isTRUE(include_total)) sel <- rbind(tab[1, , drop = FALSE], sel)
  get_op_spending(code = stats::setNames(sel$code, sel$class), ...)
}

# ---- organisation details (denominators) -----------------------------------

#' Get list sizes and prescribing units from OpenPrescribing
#'
#' Monthly organisation statistics from the OpenPrescribing
#' \code{org_details} endpoint, mainly the registered patient list size used
#' as a denominator for prescribing rates. \code{\link{get_op_spending}}
#' can add these for you with \code{add_list_size = TRUE}.
#'
#' @param resolution,org,date,start,end,as_data_table as for
#'   \code{\link{get_op_spending}}. Without \code{org}, every organisation at
#'   the resolution is returned for the whole five-year window, which is a
#'   large download at \code{"practice"} level.
#' @param keys character vector of statistics to return: \code{"total_list_size"},
#'   \code{"astro_pu_items"}, \code{"astro_pu_cost"} or any
#'   \code{"star_pu.<name>"} key listed in the OpenPrescribing API
#'   documentation.
#'
#' @return A data.frame with columns \code{date}, \code{resolution},
#'   \code{org_id}, \code{org_name} and one column per requested key
#'   (STAR-PU keys appear as \code{star_pu.<name>}).
#' @export
#'
#' @examples
#' \donttest{
#' get_op_org_details("icb", keys = "total_list_size", start = "2024-01", end = "2024-03")
#' }
get_op_org_details <- function(
  resolution = "england",
  org = NULL,
  keys = "total_list_size",
  date = NULL,
  start = NULL,
  end = NULL,
  as_data_table = FALSE
) {
  res <- .op_resolution(resolution)
  org <- .op_org(org, res)
  win <- .op_resolve_dates(date, start, end)
  keys <- trimws(as.character(keys))
  keys <- keys[!is.na(keys) & nzchar(keys)]

  raw <- .op_get("/org_details/", list(
    org_type = .op_api_type(res),
    keys = if (length(keys) > 0) paste(keys, collapse = ","),
    org = if (!is.null(org)) paste(org, collapse = ",")
  ))
  x <- .op_as_df(raw)
  n <- nrow(x)
  if (n > 0) x <- jsonlite::flatten(x)  # star_pu is a nested object

  id <- if (n > 0 && !is.null(x$row_id)) as.character(x$row_id) else rep(NA_character_, n)
  nm <- if (n > 0 && !is.null(x$row_name)) as.character(x$row_name) else rep(NA_character_, n)
  if (res$name == "england") nm[] <- "england"
  out <- data.frame(
    date = if (n > 0) as.Date(x$date) else as.Date(character()),
    resolution = rep(res$name, n),
    org_id = id,
    org_name = nm,
    stringsAsFactors = FALSE
  )
  rest <- setdiff(names(x), c("date", "row_id", "row_name"))
  for (k in rest) out[[k]] <- x[[k]]
  for (k in setdiff(keys, names(out))) out[[k]] <- rep(NA_real_, nrow(out))

  out <- .op_filter_dates(out, win)
  .op_finish(out, as_data_table)
}

# ---- lookups --------------------------------------------------------------

#' Search BNF codes in OpenPrescribing
#'
#' Looks up BNF chapters, sections, paragraphs, chemicals, products and
#' presentations by name or code, to find the \code{code} to give to
#' \code{\link{get_op_spending}}.
#'
#' @param q character vector of search terms: part of a name (case
#'   insensitive, e.g. \code{"amoxicillin"}) or the start of a code
#'   (\code{"0501"}, \code{"5.1"}). Results for several terms are combined.
#' @param exact logical; if \code{TRUE} only exact code or name matches are
#'   returned.
#'
#' @return A data.frame with columns \code{type} (e.g. \code{"BNF section"},
#'   \code{"chemical"}, \code{"product"}, \code{"product format"}),
#'   \code{id} (the code or section number), \code{name} and, where the API
#'   supplies them, \code{section} and \code{is_generic}. Zero rows if nothing
#'   matches.
#' @export
#'
#' @examples
#' \donttest{
#' search_op_bnf("amoxicillin")
#' search_op_bnf("5.1.1")
#' }
search_op_bnf <- function(q, exact = FALSE) {
  if (missing(q) || length(q) == 0 || anyNA(q) || any(!nzchar(trimws(q)))) {
    stop("'q' must be one or more non-empty search terms.", call. = FALSE)
  }
  raw <- .op_get("/bnf_code/", list(
    q = paste(trimws(q), collapse = ","),
    exact = if (isTRUE(exact)) "true"
  ))
  x <- .op_as_df(raw)
  if (nrow(x) == 0) {
    return(data.frame(type = character(), id = character(), name = character(),
                      stringsAsFactors = FALSE))
  }
  rownames(x) <- NULL
  x
}

#' Search NHS organisations in OpenPrescribing
#'
#' Finds the organisation codes to give to the \code{org} argument of
#' \code{\link{get_op_spending}}.
#'
#' @param q character vector of search terms: the start of a code, or part of
#'   a name (practices also match on postcode). \code{NULL} lists every
#'   organisation of the given resolution.
#' @param resolution optional single resolution (\code{"region"},
#'   \code{"icb"}, \code{"sicbl"}, \code{"pcn"}, \code{"practice"}) to search
#'   within. \code{NULL} searches Sub-ICB Locations and practices.
#' @param exact logical; require an exact code or name match.
#'
#' @return A data.frame with at least \code{id}, \code{code}, \code{name} and
#'   \code{type}; practices also have \code{postcode}, \code{setting},
#'   \code{setting_name} and \code{ccg} (their Sub-ICB code). Searching all
#'   practices (\code{q = NULL}) returns several thousand rows.
#' @export
#'
#' @examples
#' \donttest{
#' search_op_org("london", resolution = "icb")
#' }
search_op_org <- function(q = NULL, resolution = NULL, exact = FALSE) {
  api <- NULL
  if (!is.null(resolution)) {
    res <- .op_resolution(resolution)
    if (res$name == "england") stop("England has no organisation codes to search.", call. = FALSE)
    api <- res$api
  }
  if (isTRUE(exact) && (is.null(q) || length(q) == 0)) {
    stop("'q' is required when exact = TRUE.", call. = FALSE)
  }
  raw <- .op_get("/org_code/", list(
    q = if (!is.null(q) && length(q) > 0) paste(trimws(q), collapse = ","),
    org_type = api,
    exact = if (isTRUE(exact)) "true"
  ))
  x <- .op_as_df(raw)
  if (nrow(x) == 0) {
    return(data.frame(id = character(), code = character(), name = character(),
                      type = character(), stringsAsFactors = FALSE))
  }
  rownames(x) <- NULL
  x
}

#' Get organisation boundaries from OpenPrescribing
#'
#' Downloads the geographic boundaries (or centroids / locations) that
#' OpenPrescribing holds for organisations, ready to join to
#' \code{\link{get_op_spending}} results by \code{org_id == code} for
#' mapping.
#'
#' @details Region, ICB and PCN boundaries are unions of the underlying
#'   Sub-ICB (or practice) boundaries, so they are consistent with the
#'   OpenPrescribing organisation hierarchy but may differ slightly from the
#'   ONS generalised boundaries. Practices are returned as points.
#'
#' @param resolution one of \code{"region"}, \code{"icb"}, \code{"sicbl"},
#'   \code{"pcn"}, \code{"practice"}.
#' @param org optional character vector of organisation codes to keep.
#' @param centroids logical; return centroids instead of polygons (only
#'   honoured for Sub-ICB Locations).
#' @param as \code{"sf"} (default; needs the \pkg{sf} package) or
#'   \code{"geojson"} for the raw GeoJSON text.
#'
#' @return An \code{sf} object in EPSG:4326 (WGS 84) with columns \code{name},
#'   \code{code} and a geometry column, or the GeoJSON string.
#' @export
#'
#' @examples
#' \donttest{
#' icb <- get_op_boundaries("icb")
#' plot(sf::st_geometry(icb))
#' }
get_op_boundaries <- function(resolution = "icb", org = NULL, centroids = FALSE,
                              as = c("sf", "geojson")) {
  as <- match.arg(as)
  res <- .op_resolution(resolution)
  if (res$name == "england") {
    stop("There is no boundary for England as a single organisation; choose a finer resolution.",
         call. = FALSE)
  }
  org <- .op_org(org, res)
  if (as == "sf" && !requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required for as = \"sf\". Install it, or use as = \"geojson\".",
         call. = FALSE)
  }
  body <- .op_get("/org_location/", list(
    org_type = res$api,
    q = if (!is.null(org)) paste(org, collapse = ","),
    centroids = if (isTRUE(centroids)) "true"
  ), raw = TRUE)
  if (as == "geojson") return(body)
  sf::st_read(body, quiet = TRUE)
}
