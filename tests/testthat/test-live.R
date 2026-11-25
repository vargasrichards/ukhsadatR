# Smoke tests against the real UKHSA API. They are opt-in because they depend
# on the network and on the upstream service being up:
#
#   Sys.setenv(UKHSADATR_LIVE_TESTS = "true"); devtools::test()

skip_unless_live <- function() {
  testthat::skip_on_cran()
  testthat::skip_if_not(
    identical(Sys.getenv("UKHSADATR_LIVE_TESTS"), "true"),
    "set UKHSADATR_LIVE_TESTS=true to run live API tests"
  )
  testthat::skip_if_offline("api.ukhsa-dashboard.data.gov.uk")
}

test_that("live: get_data returns a data.frame for a valid query", {
  skip_unless_live()
  clear_cache()
  df <- get_data(
    theme = "infectious_disease", sub_theme = "respiratory", topic = "COVID-19",
    geography_type = "Nation", geography = "England",
    metric = "COVID-19_cases_casesByDay", verbose = FALSE
  )
  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 0)
})

test_that("live: invalid theme fails gracefully", {
  skip_unless_live()
  clear_cache()
  expect_message(
    result <- get_paginated_data(theme = "NOT_A_THEME"),
    regexp = "Invalid Theme.*Available options"
  )
  expect_true(inherits(result, "api_validation_error"))
})

# ---- OpenPrescribing --------------------------------------------------------
# Same opt-in switch. These hit https://openprescribing.net/api/1.0/ and will
# fail if the service is down or challenges the client (HTTP 403).

skip_unless_live_op <- function() {
  testthat::skip_on_cran()
  testthat::skip_if_not(
    identical(Sys.getenv("UKHSADATR_LIVE_TESTS"), "true"),
    "set UKHSADATR_LIVE_TESTS=true to run live API tests"
  )
  testthat::skip_if_offline("openprescribing.net")
}

test_that("live: national antibacterial prescribing", {
  skip_unless_live_op()
  df <- get_op_spending("0501")
  expect_s3_class(df, "data.frame")
  expect_gt(nrow(df), 12)
  expect_s3_class(df$date, "Date")
  expect_true(all(df$items > 0))
})

test_that("live: ICB resolution, a named class, and list-size rates", {
  skip_unless_live_op()
  end <- format(Sys.Date() - 120, "%Y-%m")
  start <- format(Sys.Date() - 240, "%Y-%m")
  df <- get_op_spending(c(Macrolides = "050105"), resolution = "icb",
                        start = start, end = end, add_list_size = TRUE)
  expect_gt(length(unique(df$org_id)), 30)  # ~36 ICBs
  expect_true(all(df$items_per_1000 > 0, na.rm = TRUE))
  expect_equal(unique(df$code_label), "Macrolides")
})

test_that("live: lookups", {
  skip_unless_live_op()
  b <- search_op_bnf("amoxicillin")
  expect_gt(nrow(b), 0)
  expect_true(all(c("type", "id", "name") %in% names(b)))
  o <- search_op_org("london", resolution = "icb")
  expect_gt(nrow(o), 0)
})

test_that("live: invalid input returns a readable error", {
  skip_unless_live_op()
  expect_error(get_op_spending("0501", resolution = "practice", date = "2001-01-01"),
               "HTTP 4")
})
