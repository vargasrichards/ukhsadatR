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
