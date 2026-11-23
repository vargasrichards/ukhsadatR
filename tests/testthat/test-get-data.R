test_that("get_data downloads and stacks every matching dataset", {
  local_fake_api(n_rows = 4)
  df <- get_data(
    theme = "infectious_disease", sub_theme = "respiratory", topic = "COVID-19",
    geography_type = "Nation", geography = "*", metric = "*", verbose = FALSE
  )
  expect_s3_class(df, "data.frame")
  expect_false(inherits(df, "data.table"))
  expect_equal(nrow(df), 3 * 4) # three datasets
  expect_setequal(df$geography, c("England", "Wales"))
  expect_setequal(df$metric, c("COVID-19_cases_casesByDay", "COVID-19_deaths_ONSByDay"))
  expect_true(all(c("theme", "topic", "metric", "metric_value") %in% names(df)))
})

test_that("get_data follows pagination until the last page", {
  local_fake_api(n_rows = 800) # page size 365 -> 3 pages
  df <- get_data(
    theme = "infectious_disease", sub_theme = "respiratory", topic = "COVID-19",
    geography_type = "Nation", geography = "England",
    metric = "COVID-19_cases_casesByDay", verbose = FALSE
  )
  expect_equal(nrow(df), 800)
  expect_equal(fake_n_requests("/metrics/COVID-19_cases_casesByDay$"), 3)
  pages <- vapply(
    fake_state$queries[grepl("/metrics/COVID", fake_state$urls)],
    function(q) q$page, numeric(1)
  )
  expect_equal(pages, 1:3)
})

test_that("as_data_table returns a data.table", {
  local_fake_api()
  dt <- get_data(
    theme = "infectious_disease", sub_theme = "contact", topic = "*",
    geography_type = "Nation", geography = "*", metric = "*",
    as_data_table = TRUE, verbose = FALSE
  )
  expect_s3_class(dt, "data.table")
})

test_that("save_to writes csv, csv.gz and rds files that round-trip", {
  local_fake_api(n_rows = 3)
  dir <- withr::local_tempdir()
  args <- list(
    theme = "infectious_disease", sub_theme = "contact", topic = "Measles",
    geography_type = "Nation", geography = "England",
    metric = "measles_cases_casesByWeek", verbose = FALSE
  )

  df <- do.call(get_data, c(args, save_to = file.path(dir, "nested", "a.csv")))
  expect_equal(nrow(data.table::fread(file.path(dir, "nested", "a.csv"))), 3)

  do.call(get_data, c(args, save_to = file.path(dir, "b.csv.gz")))
  expect_equal(nrow(utils::read.csv(gzfile(file.path(dir, "b.csv.gz")))), 3)

  do.call(get_data, c(args, save_to = file.path(dir, "c.rds")))
  expect_equal(readRDS(file.path(dir, "c.rds")), df)
})

test_that("verbose = FALSE is silent, verbose = TRUE reports saving", {
  local_fake_api(n_rows = 2)
  dir <- withr::local_tempdir()
  args <- list(
    theme = "infectious_disease", sub_theme = "contact", topic = "Measles",
    geography_type = "Nation", geography = "England",
    metric = "measles_cases_casesByWeek"
  )
  expect_silent(do.call(get_data, c(args, verbose = FALSE)))
  expect_message(
    do.call(get_data, c(args, save_to = file.path(dir, "x.csv"), verbose = TRUE)),
    "Saved 2 rows"
  )
})

test_that("datasets that fail to download are skipped, the rest returned", {
  local_fake_api(n_rows = 2, fail = "COVID-19_deaths_ONSByDay")
  expect_message(
    expect_message(
      df <- get_data(
        theme = "infectious_disease", sub_theme = "respiratory", topic = "COVID-19",
        geography_type = "Nation", geography = "England", metric = "*", verbose = FALSE
      ),
      "1 of 2 datasets could not be downloaded"
    ),
    "Could not retrieve data from UKHSA API"
  )
  expect_equal(unique(df$metric), "COVID-19_cases_casesByDay")
})

test_that("an empty result warns and returns an empty data.frame", {
  local_fake_api(n_rows = 0)
  expect_warning(
    df <- get_data(
      theme = "infectious_disease", sub_theme = "contact", topic = "Measles",
      geography_type = "Nation", geography = "England",
      metric = "measles_cases_casesByWeek", verbose = FALSE
    ),
    "No results"
  )
  expect_equal(nrow(df), 0)
})

test_that("max_datasets stops over-broad queries before any data is downloaded", {
  local_fake_api()
  expect_message(
    res <- get_data(
      theme = "infectious_disease", sub_theme = "*", topic = "*",
      geography_type = "*", geography = "*", metric = "*",
      max_datasets = 3, verbose = FALSE
    ),
    "exceeds max_datasets"
  )
  expect_null(res)
  expect_equal(fake_n_requests("/metrics/"), 0)
})

test_that("get_data returns NULL with available options when an argument is missing", {
  local_fake_api()
  expect_message(
    res <- get_data(theme = "infectious_disease", verbose = FALSE),
    "No 'Sub-theme' entered"
  )
  expect_null(res)
})

test_that("get_paginated_data returns one page of the API response", {
  local_fake_api(n_rows = 10)
  res <- get_paginated_data(
    theme = "infectious_disease", sub_theme = "respiratory", topic = "COVID-19",
    geography_type = "Nation", geography = "England",
    metric = "COVID-19_cases_casesByDay", page_number = 2, page_size = 4
  )
  expect_equal(nrow(res$results), 4)
  expect_equal(fake_state$queries[[length(fake_state$queries)]],
               list(page_size = 4, page = 2))
})
