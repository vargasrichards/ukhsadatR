#
# Retrieve every indicator in the UKHSA Fingertips "AMR local indicators"
# profile (ProfileID 101) with {fingertipsR}: antibiotic prescribing, antimicrobial
# resistance, bacteraemia / C. difficile case counts, stewardship and IPC. Data
# are fetched for ALL available area types (GP practice, Sub-ICB, ICB, trust,
# CCG, STP, region, England) and kept un-aggregated, with numerator (Count) and
# denominator columns, so discrete (non-rolling) series can be analysed directly.
#
# Usage (from the repo root):
#   Rscript scripts/fingertips_amr_download.R                    # everything
#   Rscript scripts/fingertips_amr_download.R --themes=resistance,cases
#   Rscript scripts/fingertips_amr_download.R --rolling=exclude  # drop rolling series
#   Rscript scripts/fingertips_amr_download.R --refresh          # ignore cache
#   Rscript scripts/fingertips_amr_download.R --out=data/fingertips_amr
#
# Options
#   --themes   comma list of: prescribing, resistance, testing, cases,
#              stewardship, ipc, other, all           (default: all)
#   --rolling  include | exclude | only               (default: include)
#   --out      output directory                       (default: data/fingertips_amr)
#   --refresh  re-download even if a cached file exists
#
# Outputs (in --out)
#   indicator_catalogue.csv   one row per indicator: theme, rolling flag, period type,
#                             organism/antibiotic tags, domains, full UKHSA metadata
#   raw/indicator_<ID>.rds    cached per-indicator download (resumable)
#   download_log.csv          status / rows / seconds per indicator
#   fingertips_amr_long.rds   all data stacked + parsed dates + catalogue columns
#   fingertips_amr_long.csv.gz  same, as compressed CSV
#
========================

## ---- 0. command-line options ------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
opt  <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit)) sub(paste0("^--", name, "="), "", hit[1]) else default
}
THEMES  <- strsplit(opt("themes", "all"), ",")[[1]]
ROLLING <- match.arg(opt("rolling", "include"), c("include", "exclude", "only"))
OUT_DIR <- opt("out", "data/fingertips_amr")
REFRESH <- "--refresh" %in% args
PROFILE_ID <- 101L                      # "AMR local indicators - produced by the UKHSA"
MAX_TRIES  <- 3L

if (!requireNamespace("fingertipsR", quietly = TRUE)) {
  pak::pak("ropensci/fingertipsR")
}
library(fingertipsR)
library(dplyr)
library(readr)


dir.create(file.path(OUT_DIR, "raw"), recursive = TRUE, showWarnings = FALSE)

## ---- 2. indicator catalogue --------------------------------------------------
# indicators() lists an indicator once per domain it appears in; collapse to one row.
ind <- indicators(ProfileID = PROFILE_ID) |>
  group_by(IndicatorID, IndicatorName) |>
  summarise(Domains = paste(sort(unique(trimws(DomainName))), collapse = " | "),
            .groups = "drop")

meta <- indicator_metadata(ProfileID = PROFILE_ID)
keep_meta <- intersect(
  c("IndicatorID", "Data source", "Definition", "Definition of numerator",
    "Definition of denominator", "Methodology", "Caveats", "Unit",
    "Value type", "Year type", "Date updated"),
  names(meta))
cat_tbl <- ind |> left_join(meta[, keep_meta], by = "IndicatorID")

# Classify from the indicator name (UKHSA names encode period type and measure).
nm <- tolower(cat_tbl$IndicatorName)
cat_tbl <- cat_tbl |>
  mutate(
    is_rolling = grepl("rolling", nm),
    # NB "rolling quarterly average" indicators report the AVERAGE QUARTERLY count over
    # the last 4 quarters (rounded to an integer), not a discrete quarterly count.
    period_type = case_when(
      grepl("rolling", nm) & grepl("month", nm)   ~ "12-month rolling, monthly steps",
      grepl("rolling", nm) & grepl("quarter", nm) ~ "rolling 4-quarter average, quarterly steps",
      grepl("financial year", nm)                 ~ "financial year",
      grepl("calendar year", nm)                  ~ "calendar year",
      grepl("quarter", nm)                        ~ "quarter",
      grepl("month", nm)                          ~ "month",
      grepl("\\byear\\b", nm)                     ~ "year (see definition)",
      TRUE                                        ~ "unspecified"),
    theme = case_when(
      grepl("prescrib|star-pu|antibiotic items|per 1,?000 .*(patients|population)", nm) ~ "prescribing",
      grepl("susceptib|tests? ?ing|tested", nm) & !grepl("resistan", nm)               ~ "testing",
      grepl("resistan", nm)                                                            ~ "resistance",
      grepl("bacteraemia|difficile|case counts|infection", nm)                         ~ "cases",
      grepl("stewardship|guardian|aware|access|watch|reserve", nm)                     ~ "stewardship",
      grepl("hand hygiene|screening|ipc|infection prevention", nm)                     ~ "ipc",
      TRUE                                                                             ~ "other"),
    organism = case_when(
      grepl("e\\. ?coli", nm)                 ~ "E. coli",
      grepl("klebsiella", nm)                 ~ "Klebsiella spp.",
      grepl("pseudomonas|aeruginosa", nm)     ~ "P. aeruginosa",
      grepl("neisseria|gonorrh", nm)          ~ "N. gonorrhoeae",
      grepl("mrsa", nm)                       ~ "MRSA",
      grepl("mssa", nm)                       ~ "MSSA",
      grepl("difficile", nm)                  ~ "C. difficile",
      grepl("enterococc|faecium", nm)         ~ "Enterococcus spp.",
      TRUE                                    ~ NA_character_),
    specimen = case_when(
      grepl("blood|bacteraemia", nm) ~ "blood",
      grepl("urine", nm)             ~ "urine",
      TRUE                           ~ NA_character_),
    onset = case_when(
      grepl("hospital-onset|hospital onset", nm)     ~ "hospital-onset",
      grepl("community-onset|community onset", nm)   ~ "community-onset",
      TRUE                                           ~ NA_character_)
  )

want <- cat_tbl |>
  filter("all" %in% THEMES | theme %in% THEMES) |>
  filter(ROLLING == "include" | (ROLLING == "exclude" & !is_rolling) | (ROLLING == "only" & is_rolling))

write_csv(cat_tbl, file.path(OUT_DIR, "indicator_catalogue.csv"))
message(sprintf("Profile %d: %d indicators in catalogue; %d selected (themes=%s, rolling=%s).",
                PROFILE_ID, nrow(cat_tbl), nrow(want), paste(THEMES, collapse = ","), ROLLING))
print(count(want, theme, is_rolling))

## ---- 3. download (cached, resumable, with retries) ----------------------------
fetch_one <- function(id) {
  f <- file.path(OUT_DIR, "raw", sprintf("indicator_%d.rds", id))
  if (!REFRESH && file.exists(f)) return(list(status = "cached", secs = 0, n = NA_integer_, file = f))
  t0 <- Sys.time()
  for (k in seq_len(MAX_TRIES)) {
    res <- tryCatch({
      utils::capture.output(                    # fingertips_data() prints a progress bar
        out <- suppressMessages(
          fingertips_data(IndicatorID = id, AreaTypeID = "All", ProfileID = PROFILE_ID)))
      out
    }, error = function(e) e)
    if (!inherits(res, "error")) {
      saveRDS(res, f)
      return(list(status = "ok", secs = as.numeric(difftime(Sys.time(), t0, units = "secs")),
                  n = nrow(res), file = f))
    }
    Sys.sleep(5 * k)
  }
  list(status = paste("failed:", conditionMessage(res)), secs = NA_real_, n = 0L, file = NA_character_)
}

log_rows <- vector("list", nrow(want))
for (i in seq_len(nrow(want))) {
  id <- want$IndicatorID[i]
  r  <- fetch_one(id)
  log_rows[[i]] <- tibble(IndicatorID = id, status = r$status, rows = r$n, seconds = round(r$secs, 1))
  message(sprintf("[%3d/%3d] %d  %-8s %s", i, nrow(want), id, substr(r$status, 1, 8),
                  substr(want$IndicatorName[i], 1, 70)))
  Sys.sleep(0.5)                                    # be polite to the API
}
dl_log <- bind_rows(log_rows)
write_csv(dl_log, file.path(OUT_DIR, "download_log.csv"))
if (any(grepl("^failed", dl_log$status))) warning("Some indicators failed - see download_log.csv; re-run to retry (cache is kept).")

## ---- 4. period parsing -------------------------------------------------------
# Fingertips labels: "2015 Q1" (calendar quarter), "Nov 2014" (month), "2019/20"
# (financial year), "2019/20 Q2" (financial-year quarter), "2019" (calendar year).
# period_start / period_end describe the period LABEL. For indicators named
# "12-month rolling ..." the value covers the 12 months ending at period_end, so
# window_start (first day of that 12-month window) is also given; for other rolling
# series ("rolling quarterly") the window length is not stated in the API - check the
# indicator's definition in indicator_catalogue.csv before relying on window_start.
add_months <- function(d, k) { lt <- as.POSIXlt(d); lt$mon <- lt$mon + k; as.Date(lt) }
month_end  <- function(first_of_month) add_months(first_of_month, 1) - 1
first_day  <- function(y, m) as.Date(sprintf("%04d-%02d-01", as.integer(y), as.integer(m)))

parse_period <- function(label) {
  n <- length(label)
  start <- as.Date(rep(NA_character_, n)); end <- start
  i <- grepl("^\\d{4} Q[1-4]$", label)                       # calendar quarter
  if (any(i)) {
    y <- as.integer(substr(label[i], 1, 4)); q <- as.integer(substr(label[i], 7, 7))
    s <- first_day(y, 3 * (q - 1) + 1); start[i] <- s; end[i] <- month_end(add_months(s, 2)) }
  i <- grepl("^\\d{4}/\\d{2} Q[1-4]$", label)                # financial-year quarter (Apr-Mar)
  if (any(i)) {
    y <- as.integer(substr(label[i], 1, 4)); q <- as.integer(substr(label[i], 10, 10))
    s <- add_months(first_day(y, 4), 3 * (q - 1)); start[i] <- s; end[i] <- month_end(add_months(s, 2)) }
  i <- grepl("^[A-Za-z]{3} \\d{4}$", label)                  # month
  if (any(i)) {
    m <- match(substr(label[i], 1, 3), month.abb); y <- as.integer(substr(label[i], 5, 8))
    s <- first_day(y, m); start[i] <- s; end[i] <- month_end(s) }
  i <- grepl("^\\d{4}/\\d{2}$", label)                       # financial year
  if (any(i)) {
    y <- as.integer(substr(label[i], 1, 4)); start[i] <- first_day(y, 4); end[i] <- month_end(first_day(y + 1, 3)) }
  i <- grepl("^\\d{4}$", label)                              # calendar year
  if (any(i)) {
    y <- as.integer(label[i]); start[i] <- first_day(y, 1); end[i] <- month_end(first_day(y, 12)) }
  tibble(period_start = start, period_end = end)
}

## ---- 5. stack, annotate, save ------------------------------------------------
files <- dl_log$IndicatorID[dl_log$status %in% c("ok", "cached")]
num_cols <- c("Value", "Count", "Denominator", "LowerCI95.0limit", "UpperCI95.0limit",
              "LowerCI99.8limit", "UpperCI99.8limit")
all_dat <- bind_rows(lapply(files, function(id) {
  readRDS(file.path(OUT_DIR, "raw", sprintf("indicator_%d.rds", id))) |>
    mutate(across(any_of(num_cols), as.numeric))
}))

labs <- distinct(all_dat, Timeperiod)
labs <- bind_cols(labs, parse_period(labs$Timeperiod))
unparsed <- labs$Timeperiod[is.na(labs$period_start)]
if (length(unparsed)) warning("Unparsed Timeperiod labels (dates left NA): ",
                              paste(utils::head(unparsed, 10), collapse = "; "))

long <- all_dat |>
  left_join(labs, by = "Timeperiod") |>
  left_join(select(cat_tbl, IndicatorID, theme, organism, specimen, onset,
                   is_rolling, period_type, Domains), by = "IndicatorID") |>
  mutate(window_start = if_else(grepl("^12-month rolling", period_type) & !is.na(period_end),
                                add_months(period_end + 1, -12), as.Date(NA))) |>
  rename(indicator_id = IndicatorID, indicator_name = IndicatorName,
         area_code = AreaCode, area_name = AreaName, area_type = AreaType,
         parent_code = ParentCode, parent_name = ParentName,
         timeperiod = Timeperiod, value = Value, count = Count, denominator = Denominator,
         ci95_lower = `LowerCI95.0limit`, ci95_upper = `UpperCI95.0limit`) |>
  # Sub-ICB / ICB names carry the NHS organisation (ODS) code at the end ("... ICB - 02P ",
  # with trailing whitespace); expose it as a join key for other NHS datasets (verify
  # against your lookup before joining). For GPs and trusts, area_code is already the ODS code.
  mutate(area_name = trimws(area_name),
         area_org_code = if_else(area_type %in% c("ICB sub-locations", "ICBs") &
                                   grepl(" - [A-Z0-9]{3,6}$", area_name),
                                 sub("^.* - ([A-Z0-9]{3,6})$", "\\1", area_name), NA_character_))

saveRDS(long, file.path(OUT_DIR, "fingertips_amr_long.rds"))
write_csv(long, file.path(OUT_DIR, "fingertips_amr_long.csv.gz"))

## ---- 6. summary --------------------------------------------------------------
message("\nSaved ", nrow(long), " rows, ", n_distinct(long$indicator_id), " indicators -> ", OUT_DIR)
print(long |>
        group_by(theme, is_rolling, area_type) |>
        summarise(indicators = n_distinct(indicator_id), areas = n_distinct(area_code),
                  first = min(period_start, na.rm = TRUE), last = max(period_end, na.rm = TRUE),
                  has_count = mean(!is.na(count)), .groups = "drop"),
      n = 100, width = Inf)

# One row per indicator x area type: what exists, how fine, and whether counts survive.
coverage <- long |>
  group_by(indicator_id, indicator_name, theme, period_type, is_rolling, area_type) |>
  summarise(n_areas = n_distinct(area_code), n_periods = n_distinct(timeperiod),
            first_period = min(period_start, na.rm = TRUE), last_period = max(period_end, na.rm = TRUE),
            n_rows = n(), pct_count_missing = round(100 * mean(is.na(count)), 1), .groups = "drop")
write_csv(coverage, file.path(OUT_DIR, "indicator_coverage.csv"))
message("Wrote indicator_coverage.csv (", nrow(coverage), " indicator x area-type rows)")
