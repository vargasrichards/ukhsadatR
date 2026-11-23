test_that("default geography types follow the sub-theme", {
  expect_equal(unname(.default_geography_type("respiratory")), "UKHSA Region")
  expect_equal(unname(.default_geography_type(c("contact", "vector_borne"))), c("Nation", "Nation"))
})

test_that(".geography_types_for supports NULL, a scalar and a named override", {
  st <- c("respiratory", "contact")
  expect_equal(.geography_types_for(st, NULL),
               c(respiratory = "UKHSA Region", contact = "Nation"))
  expect_equal(.geography_types_for(st, "Nation"),
               c(respiratory = "Nation", contact = "Nation"))
  expect_equal(.geography_types_for(st, c(respiratory = "Nation")),
               c(respiratory = "Nation", contact = "Nation"))
  # a named override changes only the named sub-theme
  expect_equal(.geography_types_for(st, c(contact = "UKHSA Region")),
               c(respiratory = "UKHSA Region", contact = "UKHSA Region"))
  expect_equal(.geography_types_for(c("respiratory", "contact", "vector_borne"), c(respiratory = "Nation")),
               c(respiratory = "Nation", contact = "Nation", vector_borne = "Nation"))
  expect_equal(.geography_types_for(c("respiratory", "gastrointestinal"), c(respiratory = "Nation")),
               c(respiratory = "Nation", gastrointestinal = "UKHSA Region"))
  expect_error(.geography_types_for(st, c("a", "b")), "named vector")
  expect_error(.geography_types_for(st, c(nope = "Nation")), "not in 'sub_themes'")
})

test_that("get_subtheme_data returns one table per sub-theme, with the right geography", {
  local_fake_api(n_rows = 2)
  res <- get_subtheme_data(
    sub_themes = c("respiratory", "contact"), verbose = FALSE
  )
  expect_named(res, c("respiratory", "contact"))
  # respiratory has no UKHSA Region England; only East Midlands COVID-19 exists there
  expect_setequal(res$respiratory$geography_type, "UKHSA Region")
  expect_setequal(res$contact$geography_type, "Nation")
  expect_equal(unique(res$contact$sub_theme), "contact")
})

test_that("geography_type can be overridden per sub-theme", {
  local_fake_api(n_rows = 2)
  res <- get_subtheme_data(
    sub_themes = "respiratory", geography_type = "Nation", verbose = FALSE
  )
  expect_setequal(res$respiratory$geography_type, "Nation")
})

test_that("get_subtheme_data writes one file per sub-theme", {
  local_fake_api(n_rows = 3)
  dir <- withr::local_tempdir()
  res <- get_subtheme_data(
    sub_themes = c("contact", "vector_borne"), out_dir = dir, verbose = FALSE
  )
  expect_setequal(list.files(dir), c("contact.csv", "vector_borne.csv"))
  expect_equal(nrow(data.table::fread(file.path(dir, "contact.csv"))), nrow(res$contact))

  dir2 <- withr::local_tempdir()
  get_subtheme_data(sub_themes = "contact", out_dir = dir2, format = "rds", verbose = FALSE)
  expect_true(file.exists(file.path(dir2, "contact.rds")))
})

test_that("wildcard sub_themes are expanded against the API", {
  local_fake_api(n_rows = 1)
  res <- suppressMessages(
    get_subtheme_data(sub_themes = "*", topic = "*", verbose = FALSE,
                      geography_type = "Nation", max_datasets = 100)
  )
  # sub-themes with no Nation data (antimicrobial_resistance) come back NULL
  expect_true(all(c("respiratory", "contact", "vector_borne") %in% names(res)))
  expect_false(is.null(res$contact))
})

test_that("sub-themes that cannot be retrieved are skipped with a message", {
  local_fake_api(n_rows = 2)
  expect_message(
    expect_message(
      res <- get_subtheme_data(sub_themes = c("contact", "not_a_subtheme"), verbose = FALSE),
      "Skipping sub-theme 'not_a_subtheme'"
    ),
    "Invalid Sub-theme"
  )
  expect_null(res$not_a_subtheme)
  expect_false(is.null(res$contact))
})

test_that("get_subtheme_data validates its inputs", {
  expect_error(get_subtheme_data(theme = "*"), "single exact theme")
  expect_error(get_subtheme_data(theme = c("a", "b")), "single exact theme")
  expect_error(get_subtheme_data(sub_themes = c("", NA)), "no values")
  expect_error(get_subtheme_data(sub_themes = "contact", format = "xlsx"), "should be one of")
})

test_that("the default sub-theme list covers the ten infectious_disease sub-themes", {
  expect_length(.infectious_disease_subthemes, 10)
  expect_true(all(.nation_subthemes %in% .infectious_disease_subthemes))
})
