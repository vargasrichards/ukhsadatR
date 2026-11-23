# Argument validation in get_paginated_data(), tested against the offline fake API.

test_that("graceful failure and messaging on missing theme", {
  local_fake_api()
  expect_message(
    result <- get_paginated_data(theme = NULL),
    regexp = "No 'Theme' entered. Available options",
    ignore.case = TRUE
  )
  expect_true(inherits(result, "api_validation_error"))
})

test_that("graceful failure on invalid theme", {
  local_fake_api()
  expect_message(
    result <- get_paginated_data(theme = "NOT_A_THEME"),
    regexp = "Invalid Theme.*Available options",
    ignore.case = TRUE
  )
  expect_true(inherits(result, "api_validation_error"))
})

test_that("graceful failure on missing sub_theme", {
  local_fake_api()
  expect_message(
    result <- get_paginated_data(theme = "infectious_disease", sub_theme = NULL),
    regexp = "No 'Sub-theme' entered.*Available options",
    ignore.case = TRUE
  )
  expect_true(inherits(result, "api_validation_error"))
})

test_that("graceful failure on invalid sub_theme", {
  local_fake_api()
  expect_message(
    result <- get_paginated_data(theme = "infectious_disease", sub_theme = "NOT_A_SUB_THEME"),
    regexp = "Invalid Sub-theme.*Available options",
    ignore.case = TRUE
  )
  expect_true(inherits(result, "api_validation_error"))
})

test_that("graceful failure on missing topic", {
  local_fake_api()
  expect_message(
    result <- get_paginated_data(theme = "infectious_disease", sub_theme = "respiratory", topic = NULL),
    regexp = "No 'Topic' entered.*Available options",
    ignore.case = TRUE
  )
  expect_true(inherits(result, "api_validation_error"))
})

test_that("graceful failure on invalid topic", {
  local_fake_api()
  expect_message(
    result <- get_paginated_data(theme = "infectious_disease", sub_theme = "respiratory", topic = "NOT_A_TOPIC"),
    regexp = "Invalid Topic.*Available options",
    ignore.case = TRUE
  )
  expect_true(inherits(result, "api_validation_error"))
})

test_that("graceful failure on missing geography_type", {
  local_fake_api()
  expect_message(
    result <- get_paginated_data(theme = "infectious_disease", sub_theme = "respiratory", topic = "COVID-19", geography_type = NULL),
    regexp = "No 'Geography Type' entered.*Available options",
    ignore.case = TRUE
  )
  expect_true(inherits(result, "api_validation_error"))
})

test_that("graceful failure on invalid geography_type", {
  local_fake_api()
  expect_message(
    result <- get_paginated_data(theme = "infectious_disease", sub_theme = "respiratory", topic = "COVID-19", geography_type = "NOT_A_GEOGRAPHY_TYPE"),
    regexp = "Invalid Geography Type.*Available options",
    ignore.case = TRUE
  )
  expect_true(inherits(result, "api_validation_error"))
})

test_that("graceful failure on missing geography", {
  local_fake_api()
  expect_message(
    result <- get_paginated_data(theme = "infectious_disease", sub_theme = "respiratory", topic = "COVID-19", geography_type = "Nation", geography = NULL),
    regexp = "No 'Geography' entered.*Available options",
    ignore.case = TRUE
  )
  expect_true(inherits(result, "api_validation_error"))
})

test_that("graceful failure on invalid geography", {
  local_fake_api()
  expect_message(
    result <- get_paginated_data(theme = "infectious_disease", sub_theme = "respiratory", topic = "COVID-19", geography_type = "Nation", geography = "NOT_A_GEOGRAPHY"),
    regexp = "Invalid Geography.*Available options",
    ignore.case = TRUE
  )
  expect_true(inherits(result, "api_validation_error"))
})

test_that("graceful failure on missing metric", {
  local_fake_api()
  expect_message(
    result <- get_paginated_data(theme = "infectious_disease", sub_theme = "respiratory", topic = "COVID-19", geography_type = "Nation", geography = "England", metric = NULL),
    regexp = "No 'Metric' entered.*Available options",
    ignore.case = TRUE
  )
  expect_true(inherits(result, "api_validation_error"))
})

test_that("graceful failure on invalid metric", {
  local_fake_api()
  expect_message(
    result <- get_paginated_data(theme = "infectious_disease", sub_theme = "respiratory", topic = "COVID-19", geography_type = "Nation", geography = "England", metric = "NOT_A_METRIC"),
    regexp = "Invalid Metric.*Available options",
    ignore.case = TRUE
  )
  expect_true(inherits(result, "api_validation_error"))
})

test_that("get_paginated_data errors on page_size > 365", {
  local_fake_api()
  expect_error(
    get_paginated_data(
      theme = "infectious_disease", sub_theme = "respiratory", topic = "COVID-19",
      geography_type = "Nation", geography = "England",
      metric = "COVID-19_cases_casesByDay", page_size = 366
    ),
    regexp = "Maximum allowed page_size is 365",
    ignore.case = TRUE
  )
})

test_that("get_paginated_data accepts page_size = 365", {
  local_fake_api()
  expect_silent(
    get_paginated_data(
      theme = "infectious_disease", sub_theme = "respiratory", topic = "COVID-19",
      geography_type = "Nation", geography = "England",
      metric = "COVID-19_cases_casesByDay", page_size = 365
    )
  )
})

test_that("an unreachable API gives a message, not an error", {
  local_fake_api(fail = "themes")
  expect_message(
    result <- get_paginated_data(theme = "infectious_disease"),
    "HTTP 500"
  )
  expect_true(inherits(result, "api_validation_error"))
})
