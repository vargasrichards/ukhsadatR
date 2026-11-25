# A small in-memory stand-in for the OpenPrescribing API so that request
# construction, parsing and tidying can be tested offline. It replaces the
# internal .op_get(), mimicking the JSON shapes the real endpoints return
# (checked against the OpenPrescribing source, api/views_*.py):
#
#   spending_by_org -> items, quantity, actual_cost, date, row_id, row_name
#                      (+ ccg, setting for practices)
#   org_details     -> date, row_id, row_name, <keys>, nested star_pu
#   bnf_code        -> type, id, name, ...
#   org_code        -> id, code, name, type, ...
#   org_location    -> GeoJSON text

op_state <- new.env(parent = emptyenv())

op_months <- c("2024-01-01", "2024-02-01", "2024-03-01", "2024-04-01")

# org universe per API org_type
op_orgs <- list(
  england       = data.frame(row_id = NA_character_, row_name = "england", stringsAsFactors = FALSE),
  regional_team = data.frame(row_id = c("Y56", "Y58"), row_name = c("LONDON", "SOUTH WEST"), stringsAsFactors = FALSE),
  stp           = data.frame(row_id = c("QKK", "QMF"), row_name = c("SOUTH EAST LONDON", "NORTH EAST LONDON"), stringsAsFactors = FALSE),
  ccg           = data.frame(row_id = c("36L", "72Q", "91Q"), row_name = c("SICBL A", "SICBL B", "SICBL C"), stringsAsFactors = FALSE),
  pcn           = data.frame(row_id = c("U10001", "U10002"), row_name = c("PCN 1", "PCN 2"), stringsAsFactors = FALSE),
  practice      = data.frame(row_id = c("A81001", "A81002", "B82003"), row_name = c("PRACTICE 1", "PRACTICE 2", "PRACTICE 3"),
                             ccg = c("36L", "36L", "72Q"), setting = 4L, stringsAsFactors = FALSE)
)

op_reset <- function(empty = FALSE) {
  op_state$calls <- list()
  op_state$empty <- empty
}

op_calls <- function(path = NULL) {
  cl <- op_state$calls
  if (is.null(path)) cl else Filter(function(x) identical(x$path, path), cl)
}

op_list_size <- function(org_index, month_index) 1000 * org_index + 10 * month_index

fake_op_get <- function(path, query = list(), timeout = 60, raw = FALSE) {
  query <- query[!vapply(query, is.null, logical(1))]
  op_state$calls <- c(op_state$calls, list(list(path = path, query = query, raw = raw)))

  org_type <- query[["org_type"]] %||% "england"
  split_csv <- function(x) if (is.null(x)) NULL else strsplit(x, ",")[[1]]

  if (path == "/spending_by_org/") {
    if (op_state$empty) return(list())
    orgs <- op_orgs[[org_type]]
    ids <- split_csv(query[["org"]])
    if (!is.null(ids)) {
      if (org_type == "practice") {
        orgs <- orgs[orgs$row_id %in% ids | orgs$ccg %in% ids, , drop = FALSE]
      } else {
        orgs <- orgs[orgs$row_id %in% ids, , drop = FALSE]
      }
    }
    if (org_type == "practice" && is.null(query[["date"]]) && is.null(ids)) {
      stop("OpenPrescribing API error (HTTP 400) for /spending_by_org/: you must supply either a list of practice IDs or a date")
    }
    months <- if (is.null(query[["date"]])) op_months else intersect(op_months, query[["date"]])
    if (length(months) == 0 || nrow(orgs) == 0) return(list())
    rows <- expand.grid(o = seq_len(nrow(orgs)), m = seq_along(months), KEEP.OUT.ATTRS = FALSE)
    codes_len <- sum(nchar(strsplit(query[["code"]], ",")[[1]]))  # makes the value depend on the code
    out <- data.frame(
      items = codes_len * 10 + rows$o * 100 + rows$m,
      quantity = codes_len * 100 + rows$o,
      actual_cost = round((codes_len * 10 + rows$o * 100 + rows$m) * 1.25, 2),
      date = months[rows$m],
      row_id = orgs$row_id[rows$o],
      row_name = orgs$row_name[rows$o],
      stringsAsFactors = FALSE
    )
    if (org_type == "practice") {
      out$ccg <- orgs$ccg[rows$o]
      out$setting <- orgs$setting[rows$o]
    }
    return(out)
  }

  if (path == "/org_details/") {
    orgs <- op_orgs[[org_type]]
    ids <- split_csv(query[["org"]])
    if (!is.null(ids) && org_type != "england") orgs <- orgs[orgs$row_id %in% ids, , drop = FALSE]
    rows <- expand.grid(o = seq_len(nrow(orgs)), m = seq_along(op_months), KEEP.OUT.ATTRS = FALSE)
    out <- data.frame(date = op_months[rows$m], stringsAsFactors = FALSE)
    if (org_type != "england") {
      out$row_id <- orgs$row_id[rows$o]
      out$row_name <- orgs$row_name[rows$o]
    }
    keys <- split_csv(query[["keys"]])
    if (is.null(keys) || "total_list_size" %in% keys) {
      out$total_list_size <- op_list_size(rows$o, rows$m)
    }
    if (any(grepl("^star_pu\\.", keys))) {
      out$star_pu <- data.frame(oral_antibacterials_item = rows$o * 0.5 + rows$m)  # nested like the real JSON
    }
    return(out)
  }

  if (path == "/bnf_code/") {
    return(data.frame(
      type = c("BNF section", "chemical"),
      id = c("5.1.1", "0501013B0"),
      name = c("Penicillins", "Amoxicillin"),
      stringsAsFactors = FALSE
    ))
  }

  if (path == "/org_code/") {
    return(data.frame(
      id = c("QKK", "QMF"), code = c("QKK", "QMF"),
      name = c("SOUTH EAST LONDON", "NORTH EAST LONDON"),
      type = "stp", stringsAsFactors = FALSE
    ))
  }

  if (path == "/org_location/") {
    return(paste0(
      '{"type":"FeatureCollection","features":[',
      '{"type":"Feature","properties":{"name":"A","code":"QKK"},',
      '"geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}},',
      '{"type":"Feature","properties":{"name":"B","code":"QMF"},',
      '"geometry":{"type":"Polygon","coordinates":[[[1,0],[2,0],[2,1],[1,1],[1,0]]]}}]}'
    ))
  }

  stop("fake_op_get: unexpected path ", path)
}

# Install the fake OpenPrescribing API for the duration of the calling test.
local_fake_op <- function(empty = FALSE, .env = parent.frame()) {
  op_reset(empty)
  testthat::local_mocked_bindings(.op_get = fake_op_get, .env = .env)
  invisible(NULL)
}
