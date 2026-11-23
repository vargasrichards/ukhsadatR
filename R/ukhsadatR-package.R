#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom httr2 request req_url_query req_timeout req_perform
#'   resp_body_string resp_status req_user_agent req_throttle req_retry
#' @importFrom jsonlite fromJSON
#' @importFrom utils URLencode
## usethis namespace: end
NULL

# data.table is used with its list-style `[` (by = ...) inside the package, so
# declare the package data.table-aware even though it is not attached.
.datatable.aware <- TRUE

# Column names used inside data.table expressions (silences R CMD check notes).
utils::globalVariables(c(
  "area_code", "timeperiod", "period_start", "period_end", "count", ".N"
))
