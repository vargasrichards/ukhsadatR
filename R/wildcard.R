# Wildcard / multi-value support for the UKHSA dashboard API
#
# Any of theme, sub_theme, topic, geography_type, geography and metric can be:
#   * a single exact value              e.g. "E-coli"
#   * a character vector of values      e.g. c("England", "Wales")
#   * "*" to mean every available value
#   * a glob pattern using * or ?       e.g. "NHS*London*", "*PercentResistant*"
#
# The hierarchy is walked level by level, following the `link` URLs the API
# returns, to build every matching combination down to the metric endpoint.

.api_base <- "https://api.ukhsa-dashboard.data.gov.uk/themes"

.hierarchy <- data.frame(
  arg    = c("theme", "sub_theme", "topic", "geography_type", "geography", "metric"),
  label  = c("Theme", "Sub-theme", "Topic", "Geography Type", "Geography", "Metric"),
  plural = c("themes", "sub-themes", "topics", "geography types", "geographies", "metrics"),
  child  = c("sub_themes", "topics", "geography_types", "geographies", "metrics", NA),
  stringsAsFactors = FALSE
)

# ---- Rate limiting -------------------------------------------------------
#
# Every request made by the package goes through .api_json(), which applies a
# shared token-bucket throttle (httr2::req_throttle) so that wildcard queries
# never fire requests faster than the configured rate. Rejections with
# HTTP 429 / 503 are retried with backoff, honouring any Retry-After header.
#
# The default is deliberately conservative. Change it per session with e.g.
#   options(ukhsadatR.requests_per_second = 0.5)

.rate_limit <- function() {
  rate <- getOption("ukhsadatR.requests_per_second", 1)
  if (!is.numeric(rate) || length(rate) != 1 || is.na(rate) || rate <= 0) {
    stop("option 'ukhsadatR.requests_per_second' must be a single positive number")
  }
  rate
}

# GET a URL and parse the JSON body.
.api_json <- function(url, query = list(), timeout = 30) {
  req <- httr2::request(url)
  if (length(query) > 0) req <- do.call(httr2::req_url_query, c(list(req), query))
  req |>
    httr2::req_user_agent("ukhsadatR (https://github.com/silverfoxdoc/ukhsadatR)") |>
    httr2::req_throttle(rate = .rate_limit(), realm = "ukhsadatR") |>
    httr2::req_retry(
      max_tries = 5,
      is_transient = function(resp) httr2::resp_status(resp) %in% c(429, 502, 503, 504),
      backoff = function(i) min(60, 2^i)
    ) |>
    httr2::req_timeout(timeout) |>
    httr2::req_perform() |>
    httr2::resp_body_string() |>
    jsonlite::fromJSON()
}

# ---- Catalogue cache -----------------------------------------------------
#
# Option lists (themes, topics, geographies, metrics, ...) change rarely, so
# they are cached for the R session. Repeating or refining a wildcard query
# then costs no extra catalogue requests. Data itself is never cached.

.cache <- new.env(parent = emptyenv())

.cached_options <- function(url) {
  if (!is.null(.cache[[url]])) return(.cache[[url]])
  res <- .api_json(url)
  if (length(res[["name"]]) > 0) assign(url, res, envir = .cache)
  res
}

#' Clear the Catalogue Cache
#'
#' The lists of available themes, topics, geographies and metrics are cached
#' for the R session to avoid repeating API requests. Call this to force them
#' to be fetched again.
#'
#' @return \code{NULL}, invisibly.
#' @export
clear_cache <- function() {
  rm(list = ls(.cache, all.names = TRUE), envir = .cache)
  invisible(NULL)
}

# Does a value contain glob wildcard characters?
.has_glob <- function(x) grepl("[*?]", x)

# Normalise an argument: NULL, NA and "" all mean "not supplied".
.clean_spec <- function(x) {
  if (is.null(x)) return(NULL)
  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(x)]
  if (length(x) == 0) NULL else unique(x)
}

# Return the subset of `options` matched by `spec` (exact values or globs),
# kept in the API's own order.
.match_options <- function(spec, options) {
  hit <- rep(FALSE, length(options))
  for (s in spec) {
    hit <- hit | if (.has_glob(s)) grepl(utils::glob2rx(s), options) else options == s
  }
  options[hit]
}

# Walk the API hierarchy and return a data.frame with one row per matching
# combination: columns for each level resolved plus `url` (the endpoint for
# the next level down, or the data endpoint once metric is resolved).
# Returns NULL (after messaging the available options) when a level cannot be
# resolved, mirroring the behaviour of get_paginated_data().
.resolve_combinations <- function(spec, depth = nrow(.hierarchy), verbose = TRUE,
                                  max_datasets = Inf) {
  frontier <- data.frame(url = .api_base, stringsAsFactors = FALSE)

  for (i in seq_len(depth)) {
    lvl <- .hierarchy[i, ]
    s <- .clean_spec(spec[[lvl$arg]])

    if (verbose && nrow(frontier) > 1 && !is.null(s)) {
      message(sprintf("Looking up %s for %d combinations...", lvl$plural, nrow(frontier)))
    }

    new_rows <- list()
    all_options <- character()
    matched <- character()

    for (r in seq_len(nrow(frontier))) {
      url <- frontier$url[r]
      opts <- tryCatch(.cached_options(url), error = function(e) {
        message(sprintf("! Could not retrieve %s options from %s: %s",
                        lvl$label, url, conditionMessage(e)))
        NULL
      })
      if (is.null(opts) || length(opts[["name"]]) == 0) next

      all_options <- union(all_options, opts[["name"]])
      if (is.null(s)) next

      keep <- .match_options(s, opts[["name"]])
      if (length(keep) == 0) next
      matched <- union(matched, keep)

      idx <- match(keep, opts[["name"]])
      links <- if (!is.null(opts[["link"]])) {
        opts[["link"]][idx]
      } else {
        paste(url, utils::URLencode(keep), sep = "/")
      }

      rows <- frontier[rep(r, length(keep)), , drop = FALSE]
      rows[[lvl$arg]] <- keep
      rows$url <- if (is.na(lvl$child)) links else paste(links, lvl$child, sep = "/")
      new_rows[[length(new_rows) + 1]] <- rows
    }

    if (length(all_options) == 0) {
      message(sprintf(
        "! Unable to retrieve valid %s options from API. Please check the upstream API response or try again later.",
        lvl$label
      ))
      return(NULL)
    }

    if (is.null(s)) {
      message(sprintf(
        "! No '%s' entered. Use \"*\" for all. Available options:\n\n%s",
        lvl$label, paste(all_options, collapse = "\n")
      ))
      return(NULL)
    }

    if (length(new_rows) == 0) {
      message(sprintf(
        "! Invalid %s: '%s'. Available options:\n\n%s",
        lvl$label, paste(s, collapse = "', '"), paste(all_options, collapse = "\n")
      ))
      return(NULL)
    }

    # Exact values that matched nowhere are skipped, but say so.
    missing <- s[!.has_glob(s) & !s %in% matched]
    if (length(missing) > 0) {
      message(sprintf("! %s not found and skipped: %s",
                      lvl$label, paste(missing, collapse = ", ")))
    }

    frontier <- do.call(rbind, new_rows)
    rownames(frontier) <- NULL

    # Every remaining branch yields at least one dataset, so stop walking the
    # catalogue as soon as the limit is exceeded rather than at the end.
    if (nrow(frontier) > max_datasets) {
      message(sprintf(
        "! This query matches %s%s datasets, which exceeds max_datasets = %s.\nNarrow the query, preview it with get_combinations(), or raise max_datasets.",
        if (i < depth) "at least " else "",
        format(nrow(frontier), big.mark = ","), format(max_datasets, big.mark = ",")
      ))
      return(NULL)
    }
  }

  frontier[, c(.hierarchy$arg[seq_len(depth)], "url"), drop = FALSE]
}

# Download every page of a single metric endpoint.
# Returns a data.table (possibly empty), or NULL if a request failed.
.fetch_all_pages <- function(url, page_size = 365) {
  pages <- list()
  page <- 1

  repeat {
    resp <- tryCatch(
      .api_json(url, query = list(page_size = page_size, page = page)),
      error = function(e) {
        message("! Could not retrieve data from UKHSA API: ", conditionMessage(e))
        NULL
      }
    )
    if (is.null(resp)) return(NULL)

    res <- resp[["results"]]
    if (is.null(res) || NROW(res) == 0) break
    pages[[length(pages) + 1]] <- data.table::as.data.table(res)

    if (is.null(resp[["next"]])) break
    page <- page + 1
  }

  if (length(pages) == 0) return(data.table::data.table())
  data.table::rbindlist(pages, use.names = TRUE, fill = TRUE)
}

# Save a result to disk: .rds via saveRDS(), anything else (csv, tsv, csv.gz)
# via data.table::fwrite().
.save_data <- function(x, path, verbose = TRUE) {
  dir <- dirname(path)
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)

  if (grepl("\\.rds$", path, ignore.case = TRUE)) {
    saveRDS(x, path)
  } else {
    data.table::fwrite(x, path)
  }

  if (verbose) {
    message(sprintf("Saved %s rows to %s", format(nrow(x), big.mark = ","), path))
  }
  invisible(path)
}


#' Get Combinations
#'
#' Lists the theme / sub_theme / topic / geography_type / geography / metric
#' combinations that match a query, without downloading any data. Use it to
#' explore what is available, or to check how many datasets a wildcard query
#' in \code{\link{get_data}} would download.
#'
#' Each argument accepts a single value, a character vector of values,
#' \code{"*"} for every available value, or a glob pattern containing
#' \code{*} or \code{?} (for example \code{"NHS*London*"}).
#'
#' Resolution stops at the last argument supplied, so
#' \code{get_combinations(theme = "*", sub_theme = "*")} lists every
#' sub-theme of every theme without looking further down the hierarchy.
#'
#' @inheritParams get_data
#'
#' @return                data.frame with one row per matching combination,
#'                        or \code{NULL} (invisibly) if the query could not be
#'                        resolved, in which case the available options are
#'                        shown as a message.
#'
#' @export
#'
#' @examples
#' \donttest{
#' # every topic in every sub-theme of infectious_disease
#' get_combinations(theme = "infectious_disease", sub_theme = "*", topic = "*")
#'
#' # every ICB and metric for E. coli resistance
#' get_combinations(
#'   theme = "infectious_disease",
#'   sub_theme = "antimicrobial_resistance",
#'   topic = "E-coli",
#'   geography_type = "Integrated Care Board",
#'   geography = "*",
#'   metric = "*PercentResistant*"
#' )
#' }

get_combinations <- function(
  theme = "*",
  sub_theme = NULL,
  topic = NULL,
  geography_type = NULL,
  geography = NULL,
  metric = NULL,
  verbose = TRUE
) {
  spec <- list(
    theme = theme,
    sub_theme = sub_theme,
    topic = topic,
    geography_type = geography_type,
    geography = geography,
    metric = metric
  )
  supplied <- which(!vapply(spec, function(x) is.null(.clean_spec(x)), logical(1)))
  depth <- if (length(supplied) == 0) 1 else max(supplied)

  combos <- .resolve_combinations(spec, depth = depth, verbose = verbose)
  if (is.null(combos)) return(invisible(NULL))
  combos$url <- NULL
  combos
}
