# Sentinel for validation failure in UKHSA data functions
.validation_failed <- structure(list(), class = "api_validation_error")

#' Get Paginated Data
#'
#' Generates API query URL and retrieves paginated data.
#'
#' @param theme           the largest overall topical subgroup of data. For
#'                        example \code{infectious_disease}.
#'
#' @param sub_theme       a topical subgroup associated with the parent theme.
#'                        For example \code{respiratory}.
#'
#' @param topic           categorical subgroup associated with the selected
#'                        theme and sub_theme. For example, \code{COVID-19}.
#'
#' @param geography_type  the overarching area type for the intended geography.
#'                        For example \code{Nation}.
#'
#' @param geography       the selected area under the \code{geography_type}.
#'                        For example \code{England}.
#'
#' @param metric          the type of data being selected.
#'                        For example \code{COVID-19_testing_PCRcountByDay}.
#'
#' @param page_number     define which page of data to retrieve
#'
#' @param page_size       define number of results returned per page.
#'                        Maximum supported size is 365.
#'
#' @return                list containing the query structure and results
#'
#' @details               If any input argument is left NULL or invalid, a list
#'                        of possible values for that parameter is returned.
#'
#' @importFrom            httr2 request req_url_query req_timeout req_perform
#'                        resp_body_string resp_status
#' @importFrom            jsonlite fromJSON
#' @importFrom            utils URLencode
#'
#' @export
#'
#' @examples
#' get_paginated_data(
#'   theme = "infectious_disease",
#'   sub_theme = "respiratory",
#'   topic = "COVID-19",
#'   geography_type = "Nation",
#'   geography = "England",
#'   metric = "COVID-19_cases_casesByDay",
#'   page_number = 2,
#'   page_size = 6
#' )

get_paginated_data <- function(
  theme = NULL,
  sub_theme = NULL,
  topic = NULL,
  geography_type = NULL,
  geography = NULL,
  metric = NULL,
  page_number = 1,
  page_size = 365
) {
  multi <- vapply(
    list(theme, sub_theme, topic, geography_type, geography, metric),
    function(x) length(x) > 1 || (length(x) == 1 && grepl("[*?]", x)),
    logical(1)
  )
  if (any(multi)) {
    stop("Wildcards and multiple values are only supported in get_data(). ",
         "get_paginated_data() needs a single value for each argument.")
  }

  clean_argument <- function(x) if (is.null(x) || x == "") NULL else x

  list2env(
    lapply(
      list(
        theme = theme,
        sub_theme = sub_theme,
        topic = topic,
        geography_type = geography_type,
        geography = geography,
        metric = metric
      ),
      clean_argument
    ),
    envir = environment()
  )

  if (page_size > 365) {
    stop("Maximum allowed page_size is 365")
  }

  base <- "https://api.ukhsa-dashboard.data.gov.uk/themes"

  get_and_validate <- function(url, value, label) {
    result <- tryCatch({
      json_result <- .cached_options(url)

      options <- json_result[["name"]]

      if (is.null(options) || length(options) == 0) {
        stop(sprintf(
          "Unable to retrieve valid %s options from API. Please check the upstream API response or try again later.",
          label
        ))
      }

      if (is.null(value)) {
        stop(sprintf(
          "No '%s' entered. Available options:\n\n%s",
          label,
          paste(options, collapse = "\n")
        ))
      }

      if (!value %in% options) {
        stop(sprintf(
          "Invalid %s: '%s'. Available options:\n\n%s",
          label,
          value,
          paste(options, collapse = "\n")
        ))
      }

      return(value)
    }, error = function(e) {
      message(sprintf("! %s", conditionMessage(e)))
    })

    result
  }

  theme <- get_and_validate(base, theme, "Theme")
  if (is.null(theme)) return(.validation_failed)

  base <- paste(base, utils::URLencode(theme), "sub_themes", sep = "/")
  sub_theme <- get_and_validate(base, sub_theme, "Sub-theme")
  if (is.null(sub_theme)) return(.validation_failed)

  base <- paste(base, utils::URLencode(sub_theme), "topics", sep = "/")
  topic <- get_and_validate(base, topic, "Topic")
  if (is.null(topic)) return(.validation_failed)

  base <- paste(base, utils::URLencode(topic), "geography_types", sep = "/")
  geography_type <- get_and_validate(base, geography_type, "Geography Type")
  if (is.null(geography_type)) return(.validation_failed)

  base <- paste(base, utils::URLencode(geography_type), "geographies", sep = "/")
  geography <- get_and_validate(base, geography, "Geography")
  if (is.null(geography)) return(.validation_failed)

  base <- paste(base, utils::URLencode(geography), "metrics", sep = "/")
  metric <- get_and_validate(base, metric, "Metric")
  if (is.null(metric)) return(.validation_failed)

  url <- paste(base, utils::URLencode(metric), sep = "/")

  # Gracefully handle paginated data fetch
  result <- tryCatch({
    .api_json(url, query = list(page_size = page_size, page = page_number))
  }, error = function(e) {
    message("! Could not retrieve data from UKHSA API: ", conditionMessage(e))
  })

  result
}


#' Get Data
#'
#' Downloads all pages of data for one or more metrics and combines them into
#' a single table.
#'
#' Every query argument accepts:
#' \itemize{
#'   \item a single exact value, e.g. \code{"E-coli"};
#'   \item a character vector of values, e.g. \code{c("England", "Wales")};
#'   \item \code{"*"} to download every available value at that level;
#'   \item a glob pattern using \code{*} or \code{?}, e.g. \code{"NHS*London*"}
#'         or \code{"*PercentResistant*"}.
#' }
#' Wildcards can be used at any level, including \code{theme} and
#' \code{sub_theme}. Every matching combination is downloaded and the results
#' are stacked with \code{data.table::rbindlist()}. Each row keeps its own
#' \code{theme}, \code{topic}, \code{geography}, \code{metric}, etc. columns,
#' so the combined table is self-describing.
#'
#' Use \code{\link{get_combinations}} first to see how many datasets a
#' wildcard query will download.
#'
#' For further information on the UKHSA dashboard API please visit
#' the \href{https://ukhsa-dashboard.data.gov.uk/access-our-data}{API documentation}.
#'
#' @param theme           the largest overall topical subgroup of data. For
#'                        example \code{infectious_disease}.
#'
#' @param sub_theme       a topical subgroup associated with the parent theme.
#'                        For example \code{respiratory}.
#'
#' @param topic           categorical subgroup associated with the selected
#'                        theme and sub_theme. For example, \code{COVID-19}.
#'
#' @param geography_type  the overarching area type for the intended geography.
#'                        For example \code{Nation}.
#'
#' @param geography       the selected area under the \code{geography_type}.
#'                        For example \code{England}.
#'
#' @param metric          the type of data being selected.
#'                        For example \code{COVID-19_testing_PCRcountByDay}.
#'
#' @param save_to         optional file path. If supplied, the combined result
#'                        is also written to disk: \code{.rds} files with
#'                        \code{saveRDS()}, anything else (e.g. \code{.csv},
#'                        \code{.csv.gz}) with \code{data.table::fwrite()}.
#'
#' @param as_data_table   if \code{TRUE}, return a \code{data.table};
#'                        otherwise (the default) a \code{data.frame}.
#'
#' @param max_datasets    safety limit on the number of metric datasets a
#'                        wildcard query may download. Raise it deliberately
#'                        for very broad queries.
#'
#' @param verbose         show progress messages.
#'
#' @section Rate limiting:
#' All requests are throttled to \code{getOption("ukhsadatR.requests_per_second", 1)}
#' and retried with backoff on HTTP 429/503, so a wildcard query of N datasets
#' takes at least N seconds by default. Lists of available options are
#' cached for the session (see \code{\link{clear_cache}}). Please keep broad
#' queries proportionate: preview them with \code{\link{get_combinations}}.
#'
#' @return                data.frame (or data.table) containing the query
#'                        results.
#'
#' @details               If any argument is left \code{NULL} or is invalid,
#'                        the possible values for that argument are shown as a
#'                        message and \code{NULL} is returned invisibly.
#'                        Datasets that fail to download are skipped with a
#'                        message; the rest are still returned.
#'
#' @export
#'
#' @examples
#' \donttest{
#' get_data(
#'   theme = "infectious_disease",
#'   sub_theme = "respiratory",
#'   topic = "COVID-19",
#'   geography_type = "Nation",
#'   geography = "England",
#'   metric = "COVID-19_cases_casesByDay"
#' ) |>
#'   head()
#'
#' # all ICBs, all E. coli resistance metrics, saved as CSV
#' ecoli <- get_data(
#'   theme = "infectious_disease",
#'   sub_theme = "antimicrobial_resistance",
#'   topic = "E-coli",
#'   geography_type = "Integrated Care Board",
#'   geography = "*",
#'   metric = "*PercentResistant*",
#'   save_to = file.path(tempdir(), "ecoli_icb.csv")
#' )
#' }

get_data <- function(
  theme = NULL,
  sub_theme = NULL,
  topic = NULL,
  geography_type = NULL,
  geography = NULL,
  metric = NULL,
  save_to = NULL,
  as_data_table = FALSE,
  max_datasets = 500,
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

  combos <- .resolve_combinations(spec, verbose = verbose, max_datasets = max_datasets)
  if (is.null(combos)) return(invisible(NULL))

  n <- nrow(combos)
  if (verbose && n > 1) {
    mins <- n / .rate_limit() / 60
    message(sprintf(
      "Downloading %s datasets (at least %s requests; ~%s min at %s request(s)/sec)...",
      format(n, big.mark = ","), format(n, big.mark = ","),
      format(ceiling(mins)), format(.rate_limit())
    ))
  }

  results <- vector("list", n)
  failed <- 0L
  for (i in seq_len(n)) {
    if (verbose && n > 1) {
      message(sprintf("[%d/%d] %s | %s | %s",
                      i, n, combos$topic[i], combos$geography[i], combos$metric[i]))
    }
    results[[i]] <- .fetch_all_pages(combos$url[i])
    if (is.null(results[[i]])) failed <- failed + 1L
  }

  if (failed > 0) {
    message(sprintf("! %d of %d datasets could not be downloaded and were skipped.", failed, n))
  }

  out <- data.table::rbindlist(results, use.names = TRUE, fill = TRUE)

  if (nrow(out) == 0) {
    warning("No results were returned by the API.")
    return(data.frame())
  }

  if (!as_data_table) data.table::setDF(out)
  if (!is.null(save_to)) .save_data(out, save_to, verbose = verbose)

  out
}
