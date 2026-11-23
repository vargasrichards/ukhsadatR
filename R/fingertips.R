# Retrieval of the UKHSA Fingertips "AMR local indicators" profile
#
# Fingertips (https://fingertips.phe.org.uk) is a separate UKHSA service from
# the Data Dashboard API wrapped by get_data(). This file wraps the
# {fingertipsR} client so that every indicator in profile 101 ("AMR local
# indicators - produced by the UKHSA": antibiotic prescribing, antimicrobial
# resistance, bacteraemia / C. difficile case counts, stewardship, IPC) can be
# retrieved with one function call, for all available area types (GP practice,
# Sub-ICB, ICB, trust, CCG, STP, region, England), kept un-aggregated and with
# numerator (Count) and denominator columns.
#
# {fingertipsR} is only needed here, so it is a suggested (not imported)
# package. All calls to it go through the three thin wrappers below, which
# also makes the download logic testable offline.

.fingertips_profile_id <- 101L

.fingertips_themes <- c(
  "prescribing", "resistance", "testing", "cases", "stewardship", "ipc", "other"
)

.fingertips_num_cols <- c(
  "Value", "Count", "Denominator", "LowerCI95.0limit", "UpperCI95.0limit",
  "LowerCI99.8limit", "UpperCI99.8limit"
)

# ---- fingertipsR wrappers ------------------------------------------------

.require_fingertipsR <- function() {
  if (!requireNamespace("fingertipsR", quietly = TRUE)) {
    stop(
      "Package 'fingertipsR' is required for the Fingertips functions but is not installed.\n",
      "It is not currently on CRAN; install it with:\n",
      "  pak::pak(\"ropensci/fingertipsR\")",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

.ft_indicators <- function(profile_id) {
  .require_fingertipsR()
  fingertipsR::indicators(ProfileID = profile_id)
}

.ft_metadata <- function(profile_id) {
  .require_fingertipsR()
  fingertipsR::indicator_metadata(ProfileID = profile_id)
}

.ft_data <- function(indicator_id, profile_id) {
  .require_fingertipsR()
  # fingertips_data() prints a progress bar; swallow it.
  utils::capture.output(
    out <- suppressMessages(
      fingertipsR::fingertips_data(
        IndicatorID = indicator_id, AreaTypeID = "All", ProfileID = profile_id
      )
    )
  )
  out
}

# ---- indicator classification --------------------------------------------

# First-match-wins labelling (like dplyr::case_when): `rules` is a named list
# of logical vectors, the names being the labels, in priority order.
.first_match <- function(rules, n, default = NA_character_) {
  out <- rep(default, n)
  done <- rep(FALSE, n)
  for (label in names(rules)) {
    hit <- !done & rules[[label]]
    out[hit] <- label
    done <- done | hit
  }
  out
}

#' Classify Fingertips indicators from their names
#'
#' UKHSA indicator names encode the period type and the measure (for example
#' "12-month rolling" or "financial year"), and the metadata \code{Frequency}
#' field is mostly missing, so the names are parsed instead. This is the
#' classification that \code{\link{download_fingertips_amr}} attaches to every
#' row it returns.
#'
#' Note that "rolling quarterly average" indicators report the \emph{average
#' quarterly} count over the last four quarters (rounded to an integer), not a
#' discrete quarterly count.
#'
#' @param indicator_name character vector of Fingertips indicator names.
#'
#' @return A data.frame with one row per name and columns:
#' \describe{
#'   \item{is_rolling}{logical; the name mentions a rolling window.}
#'   \item{period_type}{one of \code{"12-month rolling, monthly steps"},
#'     \code{"rolling 4-quarter average, quarterly steps"},
#'     \code{"financial year"}, \code{"calendar year"}, \code{"quarter"},
#'     \code{"month"}, \code{"year (see definition)"}, \code{"unspecified"}.}
#'   \item{theme}{one of \code{"prescribing"}, \code{"resistance"},
#'     \code{"testing"}, \code{"cases"}, \code{"stewardship"}, \code{"ipc"},
#'     \code{"other"}.}
#'   \item{organism}{e.g. \code{"E. coli"}, or \code{NA}.}
#'   \item{specimen}{\code{"blood"}, \code{"urine"} or \code{NA}.}
#'   \item{onset}{\code{"hospital-onset"}, \code{"community-onset"} or
#'     \code{NA}.}
#' }
#'
#' @export
#'
#' @examples
#' classify_fingertips_indicators(c(
#'   "E. coli bacteraemia: 12-month rolling count",
#'   "Escherichia coli urine resistance to trimethoprim: quarterly"
#' ))
classify_fingertips_indicators <- function(indicator_name) {
  nm <- tolower(as.character(indicator_name))
  n <- length(nm)
  g <- function(pattern) grepl(pattern, nm)

  rolling <- g("rolling")

  period_type <- .first_match(list(
    "12-month rolling, monthly steps"            = rolling & g("month"),
    "rolling 4-quarter average, quarterly steps" = rolling & g("quarter"),
    "financial year"                             = g("financial year"),
    "calendar year"                              = g("calendar year"),
    "quarter"                                    = g("quarter"),
    "month"                                      = g("month"),
    "year (see definition)"                      = g("\\byear\\b")
  ), n, default = "unspecified")

  theme <- .first_match(list(
    prescribing = g("prescrib|star-pu|antibiotic items|per 1,?000 .*(patients|population)"),
    testing     = g("susceptib|tests? ?ing|tested") & !g("resistan"),
    resistance  = g("resistan"),
    cases       = g("bacteraemia|difficile|case counts|infection"),
    stewardship = g("stewardship|guardian|aware|access|watch|reserve"),
    ipc         = g("hand hygiene|screening|ipc|infection prevention")
  ), n, default = "other")

  organism <- .first_match(list(
    "E. coli"           = g("e\\. ?coli"),
    "Klebsiella spp."   = g("klebsiella"),
    "P. aeruginosa"     = g("pseudomonas|aeruginosa"),
    "N. gonorrhoeae"    = g("neisseria|gonorrh"),
    "MRSA"              = g("mrsa"),
    "MSSA"              = g("mssa"),
    "C. difficile"      = g("difficile"),
    "Enterococcus spp." = g("enterococc|faecium")
  ), n)

  specimen <- .first_match(list(
    blood = g("blood|bacteraemia"),
    urine = g("urine")
  ), n)

  onset <- .first_match(list(
    "hospital-onset"  = g("hospital-onset|hospital onset"),
    "community-onset" = g("community-onset|community onset")
  ), n)

  data.frame(
    is_rolling = rolling, period_type = period_type, theme = theme,
    organism = organism, specimen = specimen, onset = onset,
    stringsAsFactors = FALSE
  )
}

# ---- period parsing ------------------------------------------------------

.add_months <- function(d, k) {
  lt <- as.POSIXlt(d)
  lt$mon <- lt$mon + k
  as.Date(lt)
}
.month_end <- function(first_of_month) .add_months(first_of_month, 1) - 1
.first_day <- function(y, m) as.Date(sprintf("%04d-%02d-01", as.integer(y), as.integer(m)))

#' Parse Fingertips period labels into dates
#'
#' Fingertips labels time periods as text: \code{"2015 Q1"} (calendar
#' quarter), \code{"Nov 2014"} (month), \code{"2019/20"} (financial year,
#' April to March), \code{"2019/20 Q2"} (financial-year quarter) and
#' \code{"2019"} (calendar year). This converts them to the first and last day
#' of the period the label describes.
#'
#' For indicators that are 12-month rolling series the value covers the twelve
#' months \emph{ending} at \code{period_end}; for other rolling series the
#' window length is not stated by the API, so check the indicator definition.
#'
#' @param label character vector of Fingertips period labels.
#'
#' @return A data.frame with columns \code{period_start} and
#'   \code{period_end} (class \code{Date}); \code{NA} for unrecognised labels.
#'
#' @export
#'
#' @examples
#' parse_fingertips_period(c("2015 Q1", "Nov 2014", "2019/20", "2019/20 Q2", "2019"))
parse_fingertips_period <- function(label) {
  label <- as.character(label)
  n <- length(label)
  start <- as.Date(rep(NA_character_, n))
  end <- start

  i <- grepl("^\\d{4} Q[1-4]$", label) # calendar quarter
  if (any(i)) {
    y <- as.integer(substr(label[i], 1, 4))
    q <- as.integer(substr(label[i], 7, 7))
    s <- .first_day(y, 3 * (q - 1) + 1)
    start[i] <- s
    end[i] <- .month_end(.add_months(s, 2))
  }
  i <- grepl("^\\d{4}/\\d{2} Q[1-4]$", label) # financial-year quarter (Apr-Mar)
  if (any(i)) {
    y <- as.integer(substr(label[i], 1, 4))
    q <- as.integer(substr(label[i], 10, 10))
    s <- .add_months(.first_day(y, 4), 3 * (q - 1))
    start[i] <- s
    end[i] <- .month_end(.add_months(s, 2))
  }
  i <- grepl("^[A-Za-z]{3} \\d{4}$", label) # month
  if (any(i)) {
    m <- match(substr(label[i], 1, 3), month.abb)
    y <- as.integer(substr(label[i], 5, 8))
    s <- .first_day(y, m)
    start[i] <- s
    end[i] <- .month_end(s)
  }
  i <- grepl("^\\d{4}/\\d{2}$", label) # financial year
  if (any(i)) {
    y <- as.integer(substr(label[i], 1, 4))
    start[i] <- .first_day(y, 4)
    end[i] <- .month_end(.first_day(y + 1, 3))
  }
  i <- grepl("^\\d{4}$", label) # calendar year
  if (any(i)) {
    y <- as.integer(label[i])
    start[i] <- .first_day(y, 1)
    end[i] <- .month_end(.first_day(y, 12))
  }

  data.frame(period_start = start, period_end = end)
}

# ---- catalogue -----------------------------------------------------------

.check_themes <- function(themes) {
  themes <- as.character(themes)
  bad <- setdiff(themes, c("all", .fingertips_themes))
  if (length(bad) > 0) {
    stop(
      "Unknown theme(s): ", paste(bad, collapse = ", "), ". Valid themes are: ",
      paste(c("all", .fingertips_themes), collapse = ", "), ".",
      call. = FALSE
    )
  }
  themes
}

.check_scalar_flag <- function(x, name) {
  if (!is.logical(x) || length(x) != 1 || is.na(x)) {
    stop("'", name, "' must be TRUE or FALSE", call. = FALSE)
  }
}

# Full (unfiltered) catalogue: one row per indicator.
.fingertips_catalogue <- function(profile_id) {
  ind <- as.data.frame(.ft_indicators(profile_id), stringsAsFactors = FALSE)
  if (nrow(ind) == 0) {
    stop("Fingertips returned no indicators for profile ", profile_id, call. = FALSE)
  }

  # indicators() lists an indicator once per domain it appears in; collapse.
  key <- unique(ind[, c("IndicatorID", "IndicatorName"), drop = FALSE])
  key <- key[order(key$IndicatorID, key$IndicatorName), , drop = FALSE]
  key$Domains <- vapply(seq_len(nrow(key)), function(i) {
    d <- ind$DomainName[ind$IndicatorID == key$IndicatorID[i] &
                          ind$IndicatorName == key$IndicatorName[i]]
    paste(sort(unique(trimws(d))), collapse = " | ")
  }, character(1))
  rownames(key) <- NULL

  meta <- as.data.frame(.ft_metadata(profile_id), stringsAsFactors = FALSE)
  keep_meta <- intersect(
    c("Data source", "Definition", "Definition of numerator",
      "Definition of denominator", "Methodology", "Caveats", "Unit",
      "Value type", "Year type", "Date updated"),
    names(meta)
  )
  idx <- match(key$IndicatorID, meta$IndicatorID)
  for (col in keep_meta) key[[col]] <- meta[[col]][idx]

  cbind(key, classify_fingertips_indicators(key$IndicatorName))
}

.select_indicators <- function(cat_tbl, themes, rolling) {
  keep <- ("all" %in% themes | cat_tbl$theme %in% themes) &
    (rolling == "include" |
       (rolling == "exclude" & !cat_tbl$is_rolling) |
       (rolling == "only" & cat_tbl$is_rolling))
  cat_tbl[keep, , drop = FALSE]
}

#' List the indicators in the Fingertips AMR profile
#'
#' Returns the catalogue of indicators in the UKHSA Fingertips "AMR local
#' indicators" profile (profile 101), one row per indicator, with the full
#' UKHSA metadata and the classification from
#' \code{\link{classify_fingertips_indicators}}. No indicator data are
#' downloaded, so this is the quick way to see what
#' \code{\link{download_fingertips_amr}} would fetch.
#'
#' Requires the \pkg{fingertipsR} package, which is not currently on CRAN:
#' \code{remotes::install_github("ropensci/fingertipsR")}.
#'
#' @param themes character vector of themes to keep: any of
#'   \code{"prescribing"}, \code{"resistance"}, \code{"testing"},
#'   \code{"cases"}, \code{"stewardship"}, \code{"ipc"}, \code{"other"}, or
#'   \code{"all"} (the default).
#' @param rolling \code{"include"} (default) keeps every indicator,
#'   \code{"exclude"} drops rolling series, \code{"only"} keeps only rolling
#'   series.
#' @param profile_id Fingertips profile ID. The default, 101, is "AMR local
#'   indicators - produced by the UKHSA".
#'
#' @return A data.frame with one row per indicator.
#'
#' @export
#'
#' @examples
#' \donttest{
#' if (requireNamespace("fingertipsR", quietly = TRUE)) {
#'   cat_tbl <- fingertips_amr_indicators(themes = "resistance", rolling = "exclude")
#'   head(cat_tbl[, c("IndicatorID", "IndicatorName", "period_type")])
#' }
#' }
fingertips_amr_indicators <- function(themes = "all",
                                      rolling = c("include", "exclude", "only"),
                                      profile_id = .fingertips_profile_id) {
  themes <- .check_themes(themes)
  rolling <- match.arg(rolling)
  out <- .select_indicators(.fingertips_catalogue(profile_id), themes, rolling)
  rownames(out) <- NULL
  out
}

# ---- download ------------------------------------------------------------

# Download one indicator, using/refreshing the cache in `raw_dir` if given.
.fetch_indicator <- function(id, profile_id, raw_dir, refresh, max_tries, retry_wait) {
  f <- if (is.null(raw_dir)) NULL else file.path(raw_dir, sprintf("indicator_%s.rds", id))
  if (!refresh && !is.null(f) && file.exists(f)) {
    return(list(status = "cached", secs = 0, n = NA_integer_, data = readRDS(f)))
  }

  t0 <- Sys.time()
  res <- NULL
  for (k in seq_len(max_tries)) {
    res <- tryCatch(.ft_data(id, profile_id), error = function(e) e)
    if (!inherits(res, "error")) {
      if (!is.null(f)) saveRDS(res, f)
      return(list(
        status = "ok",
        secs = as.numeric(difftime(Sys.time(), t0, units = "secs")),
        n = nrow(res), data = res
      ))
    }
    if (k < max_tries) Sys.sleep(retry_wait * k)
  }
  list(status = paste("failed:", conditionMessage(res)), secs = NA_real_, n = 0L, data = NULL)
}

#' Download the Fingertips AMR local indicators
#'
#' Retrieves every indicator in the UKHSA Fingertips "AMR local indicators"
#' profile (profile 101) with \pkg{fingertipsR}: antibiotic prescribing,
#' antimicrobial resistance, bacteraemia / \emph{C. difficile} case counts,
#' susceptibility testing, stewardship and infection prevention and control.
#' Data are fetched for \emph{all} available area types (GP practice, Sub-ICB,
#' ICB, trust, CCG, STP, region, England) and are kept un-aggregated, with
#' numerator (\code{count}) and \code{denominator} columns, so discrete
#' (non-rolling) series can be analysed directly. \code{count} and
#' \code{denominator} are \code{NA} where UKHSA disclosure control suppresses
#' small numbers.
#'
#' Every indicator is first classified by name (see
#' \code{\link{classify_fingertips_indicators}}), and the time-period labels
#' are parsed to dates (see \code{\link{parse_fingertips_period}}). The result
#' is one long table with columns:
#' \code{indicator_id}, \code{indicator_name}, \code{area_code},
#' \code{area_name}, \code{area_type}, \code{parent_code}, \code{parent_name},
#' \code{timeperiod}, \code{value}, \code{count}, \code{denominator},
#' \code{ci95_lower}, \code{ci95_upper}, the parsed \code{period_start},
#' \code{period_end} and (for 12-month rolling series) \code{window_start},
#' the classification columns \code{theme}, \code{organism}, \code{specimen},
#' \code{onset}, \code{is_rolling}, \code{period_type}, \code{Domains}, and
#' \code{area_org_code}: the NHS organisation (ODS) code parsed from the end of
#' Sub-ICB / ICB names (for GPs and trusts \code{area_code} already is the ODS
#' code). Verify \code{area_org_code} against your own lookup before joining on
#' it. Any further columns returned by \pkg{fingertipsR} are kept unchanged.
#'
#' Downloads are slow (one API call sequence per indicator) and are
#' therefore \strong{cached and resumable} when \code{out_dir} is given: each
#' indicator is stored in \code{<out_dir>/raw/indicator_<ID>.rds} and skipped
#' on the next call unless \code{refresh = TRUE}. If a call is interrupted or
#' some indicators fail, simply run it again.
#'
#' @section Files written when \code{out_dir} is supplied:
#' \describe{
#'   \item{\code{indicator_catalogue.csv}}{one row per indicator in the
#'     profile (all themes, regardless of \code{themes}): theme, rolling flag,
#'     period type, organism / specimen tags, domains and UKHSA metadata.}
#'   \item{\code{raw/indicator_<ID>.rds}}{cached per-indicator download.}
#'   \item{\code{download_log.csv}}{status, rows and seconds per indicator.}
#'   \item{\code{fingertips_amr_long.rds}, \code{fingertips_amr_long.csv.gz}}{
#'     the combined table, as returned.}
#'   \item{\code{indicator_coverage.csv}}{from
#'     \code{\link{summarise_fingertips_coverage}}.}
#' }
#' With the default \code{out_dir = NULL} nothing is written to disk and
#' nothing is cached between calls.
#'
#' @param themes character vector of themes to download: any of
#'   \code{"prescribing"}, \code{"resistance"}, \code{"testing"},
#'   \code{"cases"}, \code{"stewardship"}, \code{"ipc"}, \code{"other"}, or
#'   \code{"all"} (the default).
#' @param rolling \code{"include"} (default) downloads rolling and discrete
#'   series, \code{"exclude"} drops rolling series, \code{"only"} keeps only
#'   rolling series.
#' @param out_dir optional output directory (created if needed). See the
#'   section on files written. \code{NULL} (default) keeps everything in
#'   memory.
#' @param refresh if \code{TRUE}, re-download indicators even if a cached
#'   file exists in \code{out_dir}.
#' @param profile_id Fingertips profile ID; the default, 101, is "AMR local
#'   indicators - produced by the UKHSA".
#' @param max_tries number of attempts per indicator before it is recorded as
#'   failed.
#' @param retry_wait seconds to wait after a failed attempt, multiplied by the
#'   attempt number.
#' @param pause seconds to wait between indicators, to be polite to the API.
#' @param as_data_table if \code{TRUE}, return a \code{data.table} rather than
#'   a \code{data.frame}.
#' @param verbose show progress messages.
#'
#' @return The combined long table (a \code{data.frame}, or \code{data.table}
#'   if \code{as_data_table = TRUE}), with two attributes:
#'   \code{attr(x, "catalogue")} (the selected indicators) and
#'   \code{attr(x, "download_log")} (status, rows and seconds per indicator).
#'   Attributes are dropped by subsetting, so keep a reference to the full
#'   object, or read the files from \code{out_dir}. \code{NULL} (invisibly)
#'   is returned if no indicator matches the selection; an empty data.frame,
#'   with a warning, if every download failed.
#'
#' @seealso \code{\link{fingertips_amr_indicators}} to preview the selection;
#'   \code{\link{get_data}} for the (separate) UKHSA Data Dashboard API.
#'
#' @export
#'
#' @examples
#' \donttest{
#' if (requireNamespace("fingertipsR", quietly = TRUE)) {
#'   # discrete (non-rolling) resistance series only, kept in memory
#'   res <- download_fingertips_amr(themes = "resistance", rolling = "exclude")
#'   head(res)
#'
#'   # everything, cached and resumable on disk
#'   download_fingertips_amr(out_dir = file.path(tempdir(), "fingertips_amr"))
#' }
#' }
download_fingertips_amr <- function(themes = "all",
                                    rolling = c("include", "exclude", "only"),
                                    out_dir = NULL,
                                    refresh = FALSE,
                                    profile_id = .fingertips_profile_id,
                                    max_tries = 3L,
                                    retry_wait = 5,
                                    pause = 0.5,
                                    as_data_table = FALSE,
                                    verbose = TRUE) {
  themes <- .check_themes(themes)
  rolling <- match.arg(rolling)
  .check_scalar_flag(refresh, "refresh")
  .check_scalar_flag(as_data_table, "as_data_table")
  .check_scalar_flag(verbose, "verbose")
  if (!is.numeric(max_tries) || length(max_tries) != 1 || max_tries < 1) {
    stop("'max_tries' must be a single number >= 1", call. = FALSE)
  }

  raw_dir <- NULL
  if (!is.null(out_dir)) {
    raw_dir <- file.path(out_dir, "raw")
    dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # -- catalogue ---------------------------------------------------------
  cat_tbl <- .fingertips_catalogue(profile_id)
  want <- .select_indicators(cat_tbl, themes, rolling)
  rownames(want) <- NULL
  if (!is.null(out_dir)) {
    data.table::fwrite(cat_tbl, file.path(out_dir, "indicator_catalogue.csv"))
  }
  if (verbose) {
    message(sprintf(
      "Profile %s: %d indicators in catalogue; %d selected (themes=%s, rolling=%s).",
      profile_id, nrow(cat_tbl), nrow(want), paste(themes, collapse = ","), rolling
    ))
  }
  if (nrow(want) == 0) {
    message("! No indicators match the selected themes / rolling filter.")
    return(invisible(NULL))
  }

  # -- download ----------------------------------------------------------
  dl <- vector("list", nrow(want))
  log_rows <- vector("list", nrow(want))
  for (i in seq_len(nrow(want))) {
    id <- want$IndicatorID[i]
    r <- .fetch_indicator(id, profile_id, raw_dir, refresh, max_tries, retry_wait)
    dl[[i]] <- r$data
    log_rows[[i]] <- data.frame(
      IndicatorID = id, status = r$status, rows = r$n,
      seconds = round(r$secs, 1), stringsAsFactors = FALSE
    )
    if (verbose) {
      message(sprintf("[%3d/%3d] %s  %-8s %s", i, nrow(want), id,
                      substr(r$status, 1, 8), substr(want$IndicatorName[i], 1, 70)))
    }
    if (pause > 0 && i < nrow(want) && r$status != "cached") Sys.sleep(pause)
  }
  dl_log <- do.call(rbind, log_rows)
  if (!is.null(out_dir)) data.table::fwrite(dl_log, file.path(out_dir, "download_log.csv"))
  if (any(grepl("^failed", dl_log$status))) {
    warning("Some indicators failed - see attr(x, \"download_log\"); re-run to retry",
            if (!is.null(out_dir)) " (the cache is kept)" else "", ".", call. = FALSE)
  }

  ok <- !vapply(dl, is.null, logical(1))
  if (!any(ok)) {
    warning("No indicators could be downloaded.", call. = FALSE)
    return(data.frame())
  }

  # -- stack, parse periods, annotate -------------------------------------
  long <- .assemble_fingertips_long(dl[ok], want)
  attr(long, "catalogue") <- want
  attr(long, "download_log") <- dl_log

  if (!is.null(out_dir)) {
    .save_data(long, file.path(out_dir, "fingertips_amr_long.rds"), verbose = FALSE)
    .save_data(long, file.path(out_dir, "fingertips_amr_long.csv.gz"), verbose = FALSE)
    data.table::fwrite(summarise_fingertips_coverage(long),
                       file.path(out_dir, "indicator_coverage.csv"))
    if (verbose) message("Files written to ", out_dir)
  }
  if (verbose) {
    message(sprintf("Retrieved %s rows, %d indicators.",
                    format(nrow(long), big.mark = ","),
                    length(unique(long$indicator_id))))
  }

  if (as_data_table) {
    cat_attr <- attr(long, "catalogue")
    log_attr <- attr(long, "download_log")
    long <- data.table::as.data.table(long)
    attr(long, "catalogue") <- cat_attr
    attr(long, "download_log") <- log_attr
  }
  long
}

# Stack per-indicator downloads into the documented long table.
.assemble_fingertips_long <- function(dl, want) {
  all_dat <- data.table::rbindlist(
    lapply(dl, function(d) {
      d <- as.data.frame(d, stringsAsFactors = FALSE)
      for (col in intersect(.fingertips_num_cols, names(d))) d[[col]] <- as.numeric(d[[col]])
      d
    }),
    use.names = TRUE, fill = TRUE
  )
  all_dat <- as.data.frame(all_dat, stringsAsFactors = FALSE)

  # period labels -> dates (parsed once per distinct label)
  labs <- unique(all_dat$Timeperiod)
  parsed <- parse_fingertips_period(labs)
  unparsed <- labs[is.na(parsed$period_start)]
  if (length(unparsed) > 0) {
    warning("Unparsed Timeperiod labels (dates left NA): ",
            paste(utils::head(unparsed, 10), collapse = "; "), call. = FALSE)
  }
  m <- match(all_dat$Timeperiod, labs)
  all_dat$period_start <- parsed$period_start[m]
  all_dat$period_end <- parsed$period_end[m]

  # catalogue columns
  cat_cols <- c("theme", "organism", "specimen", "onset", "is_rolling", "period_type", "Domains")
  mi <- match(all_dat$IndicatorID, want$IndicatorID)
  for (col in cat_cols) all_dat[[col]] <- want[[col]][mi]

  all_dat$window_start <- as.Date(NA)
  roll12 <- grepl("^12-month rolling", all_dat$period_type) & !is.na(all_dat$period_end)
  if (any(roll12)) {
    all_dat$window_start[roll12] <- .add_months(all_dat$period_end[roll12] + 1, -12)
  }

  renames <- c(
    IndicatorID = "indicator_id", IndicatorName = "indicator_name",
    AreaCode = "area_code", AreaName = "area_name", AreaType = "area_type",
    ParentCode = "parent_code", ParentName = "parent_name",
    Timeperiod = "timeperiod", Value = "value", Count = "count",
    Denominator = "denominator",
    `LowerCI95.0limit` = "ci95_lower", `UpperCI95.0limit` = "ci95_upper"
  )
  hit <- match(names(renames), names(all_dat))
  names(all_dat)[hit[!is.na(hit)]] <- renames[!is.na(hit)]

  # Sub-ICB / ICB names carry the NHS organisation (ODS) code at the end
  # ("... ICB - 02P ", with trailing whitespace).
  all_dat$area_name <- trimws(all_dat$area_name)
  all_dat$area_org_code <- NA_character_
  has_code <- all_dat$area_type %in% c("ICB sub-locations", "ICBs") &
    grepl(" - [A-Z0-9]{3,6}$", all_dat$area_name)
  all_dat$area_org_code[has_code] <-
    sub("^.* - ([A-Z0-9]{3,6})$", "\\1", all_dat$area_name[has_code])

  all_dat
}

# ---- coverage summary ----------------------------------------------------

.min_date <- function(x) if (all(is.na(x))) as.Date(NA) else min(x, na.rm = TRUE)
.max_date <- function(x) if (all(is.na(x))) as.Date(NA) else max(x, na.rm = TRUE)

#' Summarise the coverage of a Fingertips AMR download
#'
#' One row per indicator and area type: how many areas and periods exist, the
#' first and last period, and the percentage of rows whose \code{count} is
#' missing (suppressed or never published).
#'
#' @param x the table returned by \code{\link{download_fingertips_amr}}.
#'
#' @return A data.frame with columns \code{indicator_id},
#'   \code{indicator_name}, \code{theme}, \code{period_type},
#'   \code{is_rolling}, \code{area_type}, \code{n_areas}, \code{n_periods},
#'   \code{first_period}, \code{last_period}, \code{n_rows} and
#'   \code{pct_count_missing}.
#'
#' @export
#'
#' @examples
#' x <- data.frame(
#'   indicator_id = 1L, indicator_name = "demo", theme = "resistance",
#'   period_type = "quarter", is_rolling = FALSE, area_type = "ICBs",
#'   area_code = c("a", "b"), timeperiod = "2024 Q1", count = c(5, NA),
#'   period_start = as.Date("2024-01-01"), period_end = as.Date("2024-03-31")
#' )
#' summarise_fingertips_coverage(x)
summarise_fingertips_coverage <- function(x) {
  need <- c("indicator_id", "indicator_name", "theme", "period_type", "is_rolling",
            "area_type", "area_code", "timeperiod", "period_start", "period_end", "count")
  miss <- setdiff(need, names(x))
  if (length(miss) > 0) {
    stop("'x' is missing column(s): ", paste(miss, collapse = ", "),
         ". Was it produced by download_fingertips_amr()?", call. = FALSE)
  }
  dt <- data.table::as.data.table(x)
  out <- dt[, list(
    n_areas = data.table::uniqueN(area_code),
    n_periods = data.table::uniqueN(timeperiod),
    first_period = .min_date(period_start),
    last_period = .max_date(period_end),
    n_rows = .N,
    pct_count_missing = round(100 * mean(is.na(count)), 1)
  ), by = c("indicator_id", "indicator_name", "theme", "period_type",
            "is_rolling", "area_type")]
  out <- as.data.frame(out)
  out[order(out$indicator_id, out$area_type), , drop = FALSE]
}
