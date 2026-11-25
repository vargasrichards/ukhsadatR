# Offline tests for the OpenPrescribing wrappers (R/openprescribing.R). The
# network layer .op_get() is mocked in helper-mock-openprescribing.R.

test_that("resolution names and aliases map to the API's org_type", {
  expect_equal(.op_resolution("icb")$api, "stp")
  expect_equal(.op_resolution("STP")$api, "stp")
  expect_equal(.op_resolution("Sub-ICB")$api, "ccg")
  expect_equal(.op_resolution("sicbl")$api, "ccg")
  expect_equal(.op_resolution("regional_team")$name, "region")
  expect_equal(.op_resolution("region")$api, "regional_team")
  expect_true(is.na(.op_resolution("england")$api))
  expect_error(.op_resolution("county"), "Unknown resolution")
  expect_error(.op_resolution(c("icb", "pcn")), "single string")
})

test_that("get_op_spending returns a tidy national series", {
  local_fake_op()
  df <- get_op_spending("0501")
  expect_s3_class(df, "data.frame")
  expect_named(df, c("date", "resolution", "org_id", "org_name", "code",
                     "code_label", "items", "quantity", "actual_cost"))
  expect_s3_class(df$date, "Date")
  expect_equal(nrow(df), length(op_months))
  expect_true(all(df$resolution == "england"))
  expect_true(all(is.na(df$org_id)))
  expect_true(all(df$org_name == "england"))
  expect_true(all(df$code == "0501"))
  expect_true(is.numeric(df$items))
  expect_false(is.unsorted(df$date))

  q <- op_calls("/spending_by_org/")[[1]]$query
  expect_equal(q$code, "0501")
  expect_null(q[["org_type"]])  # no org_type = England total
  expect_null(q[["org"]])
  expect_null(q[["date"]])
})

test_that("each resolution sends the matching org_type", {
  local_fake_op()
  for (r in c("region", "icb", "sicbl", "pcn")) {
    df <- get_op_spending("0501", resolution = r)
    expect_true(all(df$resolution == r))
    expect_gt(nrow(df), 0)
  }
  sent <- vapply(op_calls("/spending_by_org/"), function(x) x$query$org_type, character(1))
  expect_equal(sent, c("regional_team", "stp", "ccg", "pcn"))
})

test_that("org restricts the organisations and is sent comma-separated", {
  local_fake_op()
  df <- get_op_spending("0501", resolution = "icb", org = c("QKK", "QMF"))
  expect_setequal(df$org_id, c("QKK", "QMF"))
  expect_equal(op_calls("/spending_by_org/")[[1]]$query$org, "QKK,QMF")

  one <- get_op_spending("0501", resolution = "icb", org = "QKK")
  expect_equal(unique(one$org_id), "QKK")

  expect_error(get_op_spending("0501", org = "QKK"), "cannot be used")
})

test_that("several codes make separate requests and keep their labels", {
  local_fake_op()
  df <- get_op_spending(c(Penicillins = "050101", Macrolides = "050105"), resolution = "icb")
  expect_equal(length(op_calls("/spending_by_org/")), 2)
  expect_setequal(df$code_label, c("Penicillins", "Macrolides"))
  expect_setequal(df$code, c("050101", "050105"))
  # unnamed codes label themselves
  df2 <- get_op_spending(c("0501", "0502"))
  expect_setequal(df2$code_label, c("0501", "0502"))
})

test_that("combine = TRUE sums codes in one request", {
  local_fake_op()
  df <- get_op_spending(c(A = "050101", B = "050105"), combine = TRUE)
  expect_equal(length(op_calls("/spending_by_org/")), 1)
  expect_equal(op_calls("/spending_by_org/")[[1]]$query$code, "050101,050105")
  expect_equal(unique(df$code_label), "A + B")
})

test_that("code is validated", {
  local_fake_op()
  expect_error(get_op_spending(), "'code' is required")
  expect_error(get_op_spending(character()), "'code' is required")
  expect_error(get_op_spending(""), "empty")
  expect_error(get_op_spending("0501,0502"), "one code per element")
})

test_that("date, start and end filter months", {
  local_fake_op()
  # one month -> the API is asked for that date only
  one <- get_op_spending("0501", date = "2024-02-15")
  expect_equal(one$date, as.Date("2024-02-01"))
  expect_equal(op_calls("/spending_by_org/")[[1]]$query$date, "2024-02-01")

  # a range is filtered client-side from one request
  op_reset()
  rng <- get_op_spending("0501", start = "2024-02", end = "2024-03")
  expect_equal(rng$date, as.Date(c("2024-02-01", "2024-03-01")))
  expect_equal(length(op_calls("/spending_by_org/")), 1)

  # open-ended
  from <- get_op_spending("0501", start = as.Date("2024-03-20"))
  expect_equal(from$date, as.Date(c("2024-03-01", "2024-04-01")))
  upto <- get_op_spending("0501", end = "2024-01-31")
  expect_equal(upto$date, as.Date("2024-01-01"))

  expect_error(get_op_spending("0501", date = "2024-01-01", start = "2024-01-01"), "not both")
  expect_error(get_op_spending("0501", start = "2024-05", end = "2024-01"), "after")
  expect_error(get_op_spending("0501", date = "not a date"), "must be Date")
})

test_that("all-practice queries are made one month at a time", {
  local_fake_op()
  expect_error(get_op_spending("0501", resolution = "practice"), "needs 'date'")
  expect_error(get_op_spending("0501", resolution = "practice", start = "2024-01"), "needs 'date'")

  df <- get_op_spending(c("0501", "0502"), resolution = "practice",
                        start = "2024-01", end = "2024-02", verbose = FALSE)
  expect_equal(length(op_calls("/spending_by_org/")), 4)  # 2 codes x 2 months
  expect_true(all(c("parent_sicbl", "setting") %in% names(df)))
  expect_setequal(df$date, as.Date(c("2024-01-01", "2024-02-01")))
  expect_equal(nrow(df), 2 * 2 * 3)  # codes x months x practices
})

test_that("practice queries with org make a single request", {
  local_fake_op()
  df <- get_op_spending("0501", resolution = "practice", org = "36L")  # a Sub-ICB code
  expect_equal(length(op_calls("/spending_by_org/")), 1)
  expect_setequal(df$org_id, c("A81001", "A81002"))
  expect_true(all(df$parent_sicbl == "36L"))
})

test_that("add_list_size adds the denominator and a rate", {
  local_fake_op()
  df <- get_op_spending("0501", resolution = "icb", add_list_size = TRUE)
  expect_true(all(c("total_list_size", "items_per_1000") %in% names(df)))
  expect_equal(df$items_per_1000, df$items / df$total_list_size * 1000)
  # QKK is org 1, QMF is org 2 in the mock; 2024-02 is month 2
  row <- df[df$org_id == "QMF" & df$date == as.Date("2024-02-01"), ]
  expect_equal(row$total_list_size, op_list_size(2, 2))
  expect_equal(length(op_calls("/org_details/")), 1)

  nat <- get_op_spending("0501", add_list_size = TRUE)  # joins on date only
  expect_false(anyNA(nat$total_list_size))
  expect_equal(nat$total_list_size, op_list_size(1, seq_len(nrow(nat))))
})

test_that("an empty response gives a zero-row data.frame with the usual columns", {
  local_fake_op(empty = TRUE)
  df <- get_op_spending("9999", resolution = "icb")
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 0)
  expect_true(all(c("date", "org_id", "items", "actual_cost") %in% names(df)))
  expect_s3_class(df$date, "Date")

  df2 <- get_op_spending("9999", resolution = "icb", add_list_size = TRUE)
  expect_equal(nrow(df2), 0)
  expect_true("items_per_1000" %in% names(df2))
})

test_that("as_data_table returns a data.table", {
  local_fake_op()
  expect_s3_class(get_op_spending("0501", as_data_table = TRUE), "data.table")
  expect_s3_class(get_op_org_details(as_data_table = TRUE), "data.table")
})

test_that("op_antibiotic_classes lists BNF 5.1 and its sub-sections", {
  tab <- op_antibiotic_classes()
  expect_equal(nrow(tab), 14)
  expect_equal(tab$code[1], "0501")
  expect_equal(tab$number[1:3], c("5.1", "5.1.1", "5.1.2"))
  expect_equal(tab$code[tab$number == "5.1.5"], "050105")
  expect_equal(tab$class[tab$number == "5.1.5"], "Macrolides")
  expect_false(anyDuplicated(tab$code) > 0)
})

test_that("get_op_antibiotics fetches one series per class", {
  local_fake_op()
  all <- get_op_antibiotics(resolution = "icb", verbose = FALSE)
  expect_equal(length(op_calls("/spending_by_org/")), 13)
  expect_equal(length(unique(all$code_label)), 13)

  op_reset()
  some <- get_op_antibiotics(c("5.1.5", "penicillins", "050103"))
  expect_equal(length(op_calls("/spending_by_org/")), 3)
  expect_setequal(some$code_label, c("Macrolides", "Penicillins", "Tetracyclines"))

  op_reset()
  tot <- get_op_antibiotics("Macrolides", include_total = TRUE)
  expect_setequal(tot$code, c("0501", "050105"))

  expect_error(get_op_antibiotics("5.9.9"), "Unknown antibiotic class")
})

test_that("get_op_org_details tidies list sizes and flattens STAR-PU", {
  local_fake_op()
  df <- get_op_org_details("icb", keys = c("total_list_size", "star_pu.oral_antibacterials_item"))
  expect_true(all(c("date", "resolution", "org_id", "org_name", "total_list_size",
                    "star_pu.oral_antibacterials_item") %in% names(df)))
  expect_equal(nrow(df), 2 * length(op_months))
  expect_equal(op_calls("/org_details/")[[1]]$query$keys,
               "total_list_size,star_pu.oral_antibacterials_item")
  expect_equal(op_calls("/org_details/")[[1]]$query$org_type, "stp")

  nat <- get_op_org_details()
  expect_true(all(nat$org_name == "england"))
  expect_true(all(is.na(nat$org_id)))

  rng <- get_op_org_details("icb", org = "QKK", start = "2024-03")
  expect_equal(unique(rng$org_id), "QKK")
  expect_equal(rng$date, as.Date(c("2024-03-01", "2024-04-01")))
})

test_that("search_op_bnf passes terms and only sends exact when TRUE", {
  local_fake_op()
  out <- search_op_bnf(c("amoxicillin", "5.1.1"))
  expect_equal(op_calls("/bnf_code/")[[1]]$query$q, "amoxicillin,5.1.1")
  expect_null(op_calls("/bnf_code/")[[1]]$query[["exact"]])  # the API treats any value as exact
  expect_true(all(c("type", "id", "name") %in% names(out)))

  search_op_bnf("0501", exact = TRUE)
  expect_equal(op_calls("/bnf_code/")[[2]]$query$exact, "true")
  expect_error(search_op_bnf(""), "non-empty")
})

test_that("search_op_org maps the resolution to the API org_type", {
  local_fake_op()
  out <- search_op_org("london", resolution = "icb")
  q <- op_calls("/org_code/")[[1]]$query
  expect_equal(q$org_type, "stp")
  expect_equal(q$q, "london")
  expect_null(q[["exact"]])
  expect_true(all(c("id", "code", "name", "type") %in% names(out)))
  expect_error(search_op_org("x", resolution = "england"), "no organisation codes")
  expect_error(search_op_org(exact = TRUE), "required")
})

test_that("get_op_boundaries returns sf or GeoJSON", {
  local_fake_op()
  txt <- get_op_boundaries("icb", as = "geojson")
  expect_type(txt, "character")
  expect_true(op_calls("/org_location/")[[1]]$raw)
  expect_equal(op_calls("/org_location/")[[1]]$query$org_type, "stp")

  skip_if_not_installed("sf")
  g <- get_op_boundaries("icb", org = "QKK")
  expect_s3_class(g, "sf")
  expect_true(all(c("name", "code") %in% names(g)))
  expect_equal(op_calls("/org_location/")[[2]]$query$q, "QKK")

  expect_error(get_op_boundaries("england"), "no boundary")
})

# ---- real .op_get() against stubbed HTTP responses ---------------------------

test_that(".op_get parses JSON, builds the URL and reports API errors", {
  withr::local_options(ukhsadatR.requests_per_second = 1000)

  seen <- NULL
  httr2::local_mocked_responses(function(req) {
    seen <<- req$url
    httr2::response_json(body = list(list(items = 1, date = "2024-01-01")))
  })
  x <- .op_get("/spending_by_org/", list(code = "0501", org_type = "stp", org = NULL))
  expect_s3_class(x, "data.frame")
  expect_match(seen, "^https://openprescribing.net/api/1.0/spending_by_org/\\?")
  expect_match(seen, "code=0501")
  expect_match(seen, "org_type=stp")
  expect_match(seen, "format=json")
  expect_false(grepl("org=", seen, fixed = TRUE))

  httr2::local_mocked_responses(function(req) {
    httr2::response(status_code = 400, headers = list(`Content-Type` = "application/json"),
                    body = charToRaw('"Error: unrecognised org_type parameter"'))
  })
  expect_error(.op_get("/spending_by_org/", list(org_type = "zzz")),
               "HTTP 400.*unrecognised org_type")

  httr2::local_mocked_responses(function(req) {
    httr2::response(status_code = 400, headers = list(`Content-Type` = "application/json"),
                    body = charToRaw('{"detail":"Date is outside the 5 years of data available"}'))
  })
  expect_error(.op_get("/spending_by_org/", list(date = "2001-01-01")),
               "outside the 5 years")

  httr2::local_mocked_responses(function(req) {
    httr2::response(status_code = 403, headers = list(`Content-Type` = "text/html"),
                    body = charToRaw("<html><title>Just a moment...</title></html>"))
  })
  expect_error(.op_get("/bnf_code/", list(q = "x")), "bot-protection challenge")
})
