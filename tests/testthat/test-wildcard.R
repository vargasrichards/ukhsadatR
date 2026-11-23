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

test_that("get_combinations lists every matching combination", {
  local_fake_api()
  res <- get_combinations(
    theme = "infectious_disease", sub_theme = "respiratory",
    topic = "COVID-19", geography_type = "*", geography = "*", metric = "*",
    verbose = FALSE
  )
  expect_s3_class(res, "data.frame")
  expect_named(res, c("theme", "sub_theme", "topic", "geography_type", "geography", "metric"))
  # Nation: England x2 metrics + Wales x1; UKHSA Region: East Midlands x1
  expect_equal(nrow(res), 4)
  expect_setequal(res$geography, c("England", "Wales", "East Midlands"))
  expect_false("url" %in% names(res))
})

test_that("get_combinations stops at the last supplied level", {
  local_fake_api()
  res <- get_combinations(theme = "*", sub_theme = "*", verbose = FALSE)
  expect_named(res, c("theme", "sub_theme"))
  expect_true(all(c("respiratory", "contact", "cardiovascular") %in% res$sub_theme))
  # no request below the sub-theme level was made
  expect_equal(fake_n_requests("/topics"), 0)
})

test_that("glob patterns match across a level", {
  local_fake_api()
  res <- get_combinations(
    theme = "infectious_disease", sub_theme = "antimicrobial_resistance",
    topic = "E-coli", geography_type = "UKHSA Region", geography = "*",
    metric = "*Ceftaz*", verbose = FALSE
  )
  expect_equal(nrow(res), 2)
  expect_true(all(res$metric == "E-coli_PercentResistant_Ceftazidime"))
})

test_that("vectors of exact values are combined, unknown ones skipped with a message", {
  local_fake_api()
  expect_message(
    res <- get_combinations(
      theme = "infectious_disease", sub_theme = "respiratory", topic = "COVID-19",
      geography_type = "Nation", geography = c("England", "Narnia"),
      metric = "COVID-19_cases_casesByDay", verbose = FALSE
    ),
    "Geography not found and skipped: Narnia"
  )
  expect_equal(res$geography, "England")
})

test_that("missing and invalid arguments return NULL with the available options", {
  local_fake_api()
  expect_message(
    res <- get_combinations(theme = "infectious_disease", sub_theme = "nope", verbose = FALSE),
    "Invalid Sub-theme.*respiratory"
  )
  expect_null(res)
  expect_message(
    res <- get_combinations(theme = "infectious_disease", sub_theme = "respiratory", topic = ""),
    "No 'Topic' entered"
  )
  expect_null(res)
})

test_that("catalogue lookups are cached for the session and clear_cache resets them", {
  local_fake_api()
  args <- list(theme = "infectious_disease", sub_theme = "respiratory", verbose = FALSE)
  do.call(get_combinations, args)
  n1 <- fake_n_requests()
  do.call(get_combinations, args)
  expect_equal(fake_n_requests(), n1)

  expect_null(clear_cache())
  do.call(get_combinations, args)
  expect_equal(fake_n_requests(), 2 * n1)
})

test_that("catalogue failures are reported rather than thrown", {
  local_fake_api(fail = "themes")
  expect_message(
    res <- get_combinations(theme = "*", verbose = FALSE),
    "Could not retrieve Theme options"
  )
  expect_null(res)
})
