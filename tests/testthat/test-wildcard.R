# Offline tests

test_that(".match_options handles '*', globs and exact values", {
  opts <- c("NHS North East London ICB", "NHS Kent ICB", "England")
  expect_equal(.match_options("*", opts), opts)
  expect_equal(.match_options("*London*", opts), "NHS North East London ICB")
  expect_equal(.match_options(c("England", "Narnia"), opts), "England")
  expect_equal(.match_options(c("England", "NHS*"), opts), opts)
  expect_length(.match_options("Narnia", opts), 0)
})

test_that(".clean_spec treats NULL, NA and empty strings as not supplied", {
  expect_null(.clean_spec(NULL))
  expect_null(.clean_spec(""))
  expect_null(.clean_spec(NA))
  expect_equal(.clean_spec(c("a", "", "a")), "a")
})

test_that("rate limit option is validated", {
  withr::local_options(ukhsadatR.requests_per_second = NULL)
  expect_equal(.rate_limit(), 1)
  withr::local_options(ukhsadatR.requests_per_second = 0.5)
  expect_equal(.rate_limit(), 0.5)
  withr::local_options(ukhsadatR.requests_per_second = -1)
  expect_error(.rate_limit(), "positive")
})

test_that("get_paginated_data rejects wildcards before any request", {
  expect_error(get_paginated_data(theme = "*"), "only supported in get_data")
  expect_error(get_paginated_data(theme = c("a", "b")), "only supported in get_data")
})
