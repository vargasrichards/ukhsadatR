# A small in-memory stand-in for the UKHSA Data Dashboard API, so that the
# query-resolution, pagination and saving logic can be tested offline.
#
# The catalogue below mirrors the real hierarchy:
#   theme -> sub_theme -> topic -> geography_type -> geography -> metrics

fake_catalogue <- list(
  infectious_disease = list(
    respiratory = list(
      `COVID-19` = list(
        Nation = list(
          England = c("COVID-19_cases_casesByDay", "COVID-19_deaths_ONSByDay"),
          Wales   = "COVID-19_cases_casesByDay"
        ),
        `UKHSA Region` = list(
          `East Midlands` = "COVID-19_cases_casesByDay"
        )
      ),
      Influenza = list(
        Nation = list(England = "influenza_healthcare_hospitalAdmissionRateByWeek")
      )
    ),
    antimicrobial_resistance = list(
      `E-coli` = list(
        `UKHSA Region` = list(
          `East Midlands` = c("E-coli_PercentResistant_Amikacin", "E-coli_PercentResistant_Ceftazidime"),
          London          = c("E-coli_PercentResistant_Amikacin", "E-coli_PercentResistant_Ceftazidime")
        )
      )
    ),
    contact = list(
      Measles = list(Nation = list(England = "measles_cases_casesByWeek"))
    ),
    vector_borne = list(
      Dengue = list(Nation = list(England = "dengue_cases_casesByYear"))
    )
  ),
  non_infectious_disease = list(
    cardiovascular = list(
      Stroke = list(Nation = list(England = "stroke_cases_casesByYear"))
    )
  )
)

fake_state <- new.env(parent = emptyenv())

# Reset call log, failing endpoints and rows per metric.
fake_reset <- function(n_rows = 5L, fail = character()) {
  fake_state$urls <- character()
  fake_state$queries <- list()
  fake_state$n_rows <- n_rows
  fake_state$fail <- fail
  clear_cache()
}

fake_n_requests <- function(pattern = NULL) {
  u <- fake_state$urls
  if (is.null(pattern)) length(u) else sum(grepl(pattern, u))
}

# Stand-in for .api_json()
fake_api_json <- function(url, query = list(), timeout = 30) {
  fake_state$urls <- c(fake_state$urls, url)
  fake_state$queries <- c(fake_state$queries, list(query))

  if (any(vapply(fake_state$fail, function(f) grepl(f, url, fixed = TRUE), logical(1)))) {
    stop("HTTP 500 Internal Server Error")
  }

  base <- "https://api.ukhsa-dashboard.data.gov.uk/themes"
  rest <- sub(paste0("^", base, "/?"), "", url)
  parts <- if (nzchar(rest)) utils::URLdecode(strsplit(rest, "/")[[1]]) else character()
  k <- length(parts)

  # Walk the name segments (odd positions); even positions are level keywords.
  # A metric endpoint has 11 segments, a catalogue endpoint an even number.
  if (k %% 2 == 1 && k != 11) stop("HTTP 404 Not Found: ", url)
  node <- fake_catalogue
  for (j in seq_len(min(k, 10))[seq_len(min(k, 10)) %% 2 == 1]) {
    if (!is.list(node) || !(parts[j] %in% names(node))) stop("HTTP 404 Not Found: ", url)
    node <- node[[parts[j]]]
  }

  if (k == 11) { # metric endpoint: a paginated results payload
    if (!(parts[11] %in% node)) stop("HTTP 404 Not Found: ", url)
    return(fake_results(parts, query))
  }

  # catalogue endpoint: the options at this level, each with a link to itself
  opts <- if (is.list(node)) names(node) else node
  link_base <- paste(c(base, vapply(parts, utils::URLencode, character(1))), collapse = "/")
  data.frame(
    name = opts,
    link = paste(link_base, vapply(opts, utils::URLencode, character(1)), sep = "/"),
    stringsAsFactors = FALSE
  )
}

fake_results <- function(parts, query) {
  n <- fake_state$n_rows
  size <- query$page_size %||% 365
  page <- query$page %||% 1
  idx <- seq_len(n)
  lo <- (page - 1) * size + 1
  hi <- min(page * size, n)
  rows <- if (lo > n) integer() else idx[lo:hi]
  res <- data.frame(
    theme = rep(parts[1], length(rows)),
    sub_theme = rep(parts[3], length(rows)),
    topic = rep(parts[5], length(rows)),
    geography_type = rep(parts[7], length(rows)),
    geography = rep(parts[9], length(rows)),
    metric = rep(parts[11], length(rows)),
    date = format(as.Date("2024-01-01") + rows - 1),
    metric_value = rows * 1.5,
    stringsAsFactors = FALSE
  )
  list(
    count = n,
    `next` = if (hi < n) "more" else NULL,
    results = res
  )
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# Install the fake API for the duration of the calling test.
local_fake_api <- function(n_rows = 5L, fail = character(), .env = parent.frame()) {
  fake_reset(n_rows, fail)
  testthat::local_mocked_bindings(.api_json = fake_api_json, .env = .env)
  withr::defer(clear_cache(), envir = .env)
  invisible(NULL)
}
