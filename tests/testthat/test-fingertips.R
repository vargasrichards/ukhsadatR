# ---- classification -----------------------------------------------------

test_that("classification reproduces the original script's labels on real indicator names", {
  # Expected values were produced by the original scripts/fingertips_amr_download.R
  # on the real profile-101 catalogue.
  fx <- read.csv(test_path("fixtures", "indicator_classification.csv"),
                 stringsAsFactors = FALSE, na.strings = "")
  got <- classify_fingertips_indicators(fx$IndicatorName)
  for (col in c("is_rolling", "period_type", "theme", "organism", "specimen", "onset")) {
    expect_equal(got[[col]], fx[[col]], info = col)
  }
})

test_that("classification handles edge cases", {
  expect_equal(nrow(classify_fingertips_indicators(character())), 0)
  x <- classify_fingertips_indicators(c("something unrelated", NA))
  expect_equal(x$theme, c("other", "other"))
  expect_equal(x$period_type, c("unspecified", "unspecified"))
  expect_equal(x$is_rolling, c(FALSE, FALSE))
  expect_true(all(is.na(x$organism)))

  # rolling + month beats rolling + quarter; rolling quarterly is flagged as such
  y <- classify_fingertips_indicators(c(
    "rolling total by month", "rolling quarterly average"
  ))
  expect_equal(y$period_type, c(
    "12-month rolling, monthly steps", "rolling 4-quarter average, quarterly steps"
  ))
  # "tested" without "resistan" is testing; with "resistan" it is resistance
  z <- classify_fingertips_indicators(c("specimens tested", "resistance of tested specimens"))
  expect_equal(z$theme, c("testing", "resistance"))
})

# ---- period parsing -----------------------------------------------------

test_that("parse_fingertips_period handles every Fingertips label style", {
  res <- parse_fingertips_period(c(
    "2015 Q1", "2015 Q4", "Nov 2014", "Feb 2024", "Feb 2023",
    "2019/20", "2019/20 Q2", "2019/20 Q4", "2019", "not a period", NA
  ))
  d <- as.Date
  expect_equal(res$period_start, d(c(
    "2015-01-01", "2015-10-01", "2014-11-01", "2024-02-01", "2023-02-01",
    "2019-04-01", "2019-07-01", "2020-01-01", "2019-01-01", NA, NA
  )))
  expect_equal(res$period_end, d(c(
    "2015-03-31", "2015-12-31", "2014-11-30", "2024-02-29", "2023-02-28",
    "2020-03-31", "2019-09-30", "2020-03-31", "2019-12-31", NA, NA
  )))
  expect_s3_class(res$period_start, "Date")
})

test_that("parse_fingertips_period copes with zero-length input", {
  res <- parse_fingertips_period(character())
  expect_equal(nrow(res), 0)
  expect_s3_class(res$period_end, "Date")
})

# ---- catalogue ----------------------------------------------------------

test_that("fingertips_amr_indicators collapses domains and joins metadata", {
  local_fake_fingertips()
  cat_tbl <- fingertips_amr_indicators()
  expect_equal(cat_tbl$IndicatorID, 101:105)
  expect_equal(cat_tbl$Domains[1], "Overview | Resistance") # sorted, trimmed, collapsed
  expect_equal(cat_tbl$Definition[2], "definition of 102")
  expect_true(all(c("theme", "is_rolling", "period_type", "organism") %in% names(cat_tbl)))
})

test_that("fingertips_amr_indicators filters by theme and rolling", {
  local_fake_fingertips()
  expect_equal(fingertips_amr_indicators(themes = "resistance")$IndicatorID, 101:102)
  expect_equal(fingertips_amr_indicators(themes = c("cases", "prescribing"))$IndicatorID, 103:104)
  expect_equal(fingertips_amr_indicators(rolling = "exclude")$IndicatorID, c(102, 103, 105))
  expect_equal(fingertips_amr_indicators(rolling = "only")$IndicatorID, c(101, 104))
  expect_equal(
    fingertips_amr_indicators(themes = "resistance", rolling = "exclude")$IndicatorID, 102L
  )
})

test_that("invalid themes and rolling values are rejected", {
  local_fake_fingertips()
  expect_error(fingertips_amr_indicators(themes = "nope"), "Unknown theme")
  expect_error(fingertips_amr_indicators(rolling = "sometimes"), "should be one of")
  expect_error(download_fingertips_amr(themes = "nope"), "Unknown theme")
  expect_error(download_fingertips_amr(refresh = NA), "TRUE or FALSE")
  expect_error(download_fingertips_amr(max_tries = 0), "max_tries")
})

# ---- download -----------------------------------------------------------

quiet_dl <- function(...) download_fingertips_amr(..., pause = 0, retry_wait = 0, verbose = FALSE)

test_that("download_fingertips_amr returns a long, annotated table", {
  local_fake_fingertips()
  x <- quiet_dl()
  expect_s3_class(x, "data.frame")
  expect_equal(sort(unique(x$indicator_id)), 101:105)
  expect_equal(nrow(x), 5 * 2 * 2) # 5 indicators x 2 areas x 2 periods

  # renamed + numeric columns
  expect_true(all(c("indicator_id", "area_code", "area_name", "area_type", "timeperiod",
                    "value", "count", "denominator", "ci95_lower", "ci95_upper") %in% names(x)))
  expect_type(x$value, "double")
  # extra fingertipsR column is passed through
  expect_true("Sex" %in% names(x))

  # catalogue annotations
  r <- x[x$indicator_id == 102, ]
  expect_true(all(r$theme == "resistance"))
  expect_true(all(r$specimen == "urine"))
  expect_true(all(r$period_type == "quarter"))
  expect_false(any(r$is_rolling))
})

test_that("periods are parsed and 12-month rolling windows derived", {
  local_fake_fingertips()
  x <- quiet_dl()
  q <- x[x$indicator_id == 102 & x$timeperiod == "2024 Q2", ][1, ]
  expect_equal(q$period_start, as.Date("2024-04-01"))
  expect_equal(q$period_end, as.Date("2024-06-30"))
  expect_true(is.na(q$window_start))

  m <- x[x$indicator_id == 104 & x$timeperiod == "Feb 2024", ][1, ]
  expect_equal(m$period_end, as.Date("2024-02-29"))
  expect_equal(m$window_start, as.Date("2023-03-01")) # 12 months ending 29 Feb 2024
})

test_that("ICB names yield an ODS code and are trimmed", {
  local_fake_fingertips()
  x <- quiet_dl(themes = "resistance")
  icb <- x[x$area_type == "ICBs", ]
  expect_true(all(icb$area_name == "NHS Somewhere ICB - 02P"))
  expect_true(all(icb$area_org_code == "02P"))
  expect_true(all(is.na(x$area_org_code[x$area_type == "England"])))
})

test_that("themes and rolling arguments limit what is downloaded", {
  local_fake_fingertips()
  x <- quiet_dl(themes = "resistance", rolling = "exclude")
  expect_equal(unique(x$indicator_id), 102L)
  expect_equal(fake_state$ft_calls, 102L)
})

test_that("attributes carry the catalogue and download log", {
  local_fake_fingertips()
  x <- quiet_dl(themes = "cases")
  expect_equal(attr(x, "catalogue")$IndicatorID, 103L)
  log <- attr(x, "download_log")
  expect_equal(log$IndicatorID, 103L)
  expect_equal(log$status, "ok")
  expect_equal(log$rows, 4L)
})

test_that("as_data_table returns a data.table and keeps the attributes", {
  local_fake_fingertips()
  x <- quiet_dl(themes = "cases", as_data_table = TRUE)
  expect_s3_class(x, "data.table")
  expect_false(is.null(attr(x, "download_log")))
})

test_that("failed indicators are retried, then recorded, and the rest still returned", {
  calls <- new.env()
  calls$n <- 0L
  flaky <- function(indicator_id, profile_id) {
    if (indicator_id == 103L) {
      calls$n <- calls$n + 1L
      stop("API unavailable")
    }
    fake_ft_data(indicator_id, profile_id)
  }
  local_fake_fingertips(data = flaky)

  expect_warning(x <- quiet_dl(max_tries = 3), "Some indicators failed")
  expect_equal(calls$n, 3L)
  expect_false(103L %in% x$indicator_id)
  log <- attr(x, "download_log")
  expect_match(log$status[log$IndicatorID == 103], "^failed: API unavailable")
  expect_equal(sum(log$status == "ok"), 4)
})

test_that("a transient failure succeeds on a later attempt", {
  calls <- new.env()
  calls$n <- 0L
  flaky <- function(indicator_id, profile_id) {
    calls$n <- calls$n + 1L
    if (calls$n == 1L) stop("blip")
    fake_ft_data(indicator_id, profile_id)
  }
  local_fake_fingertips(data = flaky)
  x <- quiet_dl(themes = "cases")
  expect_equal(unique(x$indicator_id), 103L)
  expect_equal(calls$n, 2L)
})

test_that("if every download fails, a warning and an empty data.frame result", {
  local_fake_fingertips(data = function(indicator_id, profile_id) stop("down"))
  expect_warning(
    expect_warning(x <- quiet_dl(max_tries = 1), "Some indicators failed"),
    "No indicators could be downloaded"
  )
  expect_equal(nrow(x), 0)
})

test_that("an empty selection returns NULL with a message", {
  local_fake_fingertips()
  expect_message(
    x <- quiet_dl(themes = "ipc"),
    "No indicators match"
  )
  expect_null(x)
})

test_that("unparsed period labels warn but keep the rows", {
  odd <- function(indicator_id, profile_id) {
    d <- fake_ft_data(indicator_id, profile_id)
    d$Timeperiod[1] <- "Spring 2024"
    d
  }
  local_fake_fingertips(data = odd)
  expect_warning(x <- quiet_dl(themes = "cases"), "Unparsed Timeperiod labels.*Spring 2024")
  expect_equal(nrow(x), 4)
  expect_true(is.na(x$period_start[x$timeperiod == "Spring 2024"]))
})

# ---- files, cache, resume -----------------------------------------------

test_that("out_dir receives the documented files", {
  local_fake_fingertips()
  dir <- file.path(withr::local_tempdir(), "ft")
  x <- quiet_dl(out_dir = dir)
  expect_setequal(
    list.files(dir),
    c("indicator_catalogue.csv", "download_log.csv", "fingertips_amr_long.rds",
      "fingertips_amr_long.csv.gz", "indicator_coverage.csv", "raw")
  )
  expect_length(list.files(file.path(dir, "raw")), 5)
  expect_equal(nrow(data.table::fread(file.path(dir, "indicator_catalogue.csv"))), 5)
  expect_equal(nrow(utils::read.csv(gzfile(file.path(dir, "fingertips_amr_long.csv.gz")))), nrow(x))
  back <- readRDS(file.path(dir, "fingertips_amr_long.rds"))
  expect_equal(back$value, x$value)
})

test_that("without out_dir nothing is written to the working directory", {
  local_fake_fingertips()
  wd <- withr::local_tempdir()
  withr::local_dir(wd)
  quiet_dl()
  expect_length(list.files(wd, recursive = TRUE, all.files = TRUE), 0)
})

test_that("the catalogue file always lists all themes, whatever was selected", {
  local_fake_fingertips()
  dir <- withr::local_tempdir()
  quiet_dl(themes = "cases", out_dir = dir)
  expect_equal(nrow(data.table::fread(file.path(dir, "indicator_catalogue.csv"))), 5)
  expect_equal(length(list.files(file.path(dir, "raw"))), 1)
})

test_that("cached indicators are not downloaded again unless refresh = TRUE", {
  local_fake_fingertips()
  dir <- withr::local_tempdir()
  quiet_dl(out_dir = dir)
  expect_length(fake_state$ft_calls, 5)

  x <- quiet_dl(out_dir = dir)
  expect_length(fake_state$ft_calls, 5) # no new calls
  expect_true(all(attr(x, "download_log")$status == "cached"))
  expect_equal(nrow(x), 20)

  quiet_dl(out_dir = dir, refresh = TRUE)
  expect_length(fake_state$ft_calls, 10)
})

test_that("a run resumes after a partial failure", {
  fail_103 <- TRUE
  data <- function(indicator_id, profile_id) {
    if (fail_103 && indicator_id == 103L) stop("down")
    fake_ft_data(indicator_id, profile_id)
  }
  local_fake_fingertips(data = data)
  dir <- withr::local_tempdir()
  suppressWarnings(quiet_dl(out_dir = dir, max_tries = 1))
  expect_length(list.files(file.path(dir, "raw")), 4)

  fail_103 <- FALSE
  fake_state$ft_calls <- integer()
  x <- quiet_dl(out_dir = dir, max_tries = 1)
  expect_equal(fake_state$ft_calls, 103L) # only the missing one
  expect_equal(sort(unique(x$indicator_id)), 101:105)
})

# ---- coverage -----------------------------------------------------------

test_that("summarise_fingertips_coverage counts areas, periods and missing counts", {
  local_fake_fingertips()
  x <- quiet_dl()
  cov <- summarise_fingertips_coverage(x)
  expect_equal(nrow(cov), 10) # 5 indicators x 2 area types
  r <- cov[cov$indicator_id == 102 & cov$area_type == "England", ]
  expect_equal(r$n_areas, 1)
  expect_equal(r$n_periods, 2)
  expect_equal(r$n_rows, 2)
  expect_equal(r$first_period, as.Date("2024-01-01"))
  expect_equal(r$last_period, as.Date("2024-06-30"))
  expect_true(all(cov$pct_count_missing >= 0 & cov$pct_count_missing <= 100))
})

test_that("summarise_fingertips_coverage handles all-NA dates and bad input", {
  x <- data.frame(
    indicator_id = 1L, indicator_name = "a", theme = "other", period_type = "unspecified",
    is_rolling = FALSE, area_type = "England", area_code = "E", timeperiod = "weird",
    count = NA_real_, period_start = as.Date(NA), period_end = as.Date(NA)
  )
  cov <- summarise_fingertips_coverage(x)
  expect_true(is.na(cov$first_period))
  expect_equal(cov$pct_count_missing, 100)
  expect_error(summarise_fingertips_coverage(data.frame(a = 1)), "missing column")
})

# ---- fingertipsR availability ------------------------------------------

test_that("a clear error is raised when fingertipsR is not installed", {
  skip_if(requireNamespace("fingertipsR", quietly = TRUE), "fingertipsR is installed")
  expect_error(download_fingertips_amr(verbose = FALSE), "pak::pak")
  expect_error(fingertips_amr_indicators(), "fingertipsR")
})
