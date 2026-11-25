# ukhsadatR (development version)

* New OpenPrescribing support (<https://openprescribing.net/api/>, English GP prescribing, last five years):
  * `get_op_spending()` returns monthly items, quantity and actual cost for any BNF code(s) at England, region, ICB, Sub-ICB Location, PCN or practice resolution, with `date` / `start` / `end` filtering, long-format output for several named codes, `combine`, and `add_list_size` for items per 1,000 patients.
  * `get_op_antibiotics()` and `op_antibiotic_classes()` fetch the BNF 5.1 antibacterial sub-classes.
  * `get_op_org_details()` returns list sizes, ASTRO-PU and STAR-PU; `search_op_bnf()` and `search_op_org()` look up codes; `get_op_boundaries()` returns organisation boundaries as `sf` (`sf` is a suggested package).
  * Requests use the existing rate limit and retry settings. Offline tests mock the API; opt-in live tests are in `test-live.R`.

# ukhsadatR 1.0.0

# ukhsadatR 0.3.0

* The retrieval scripts in `scripts/` are now documented, exported functions with ordinary arguments instead of command-line flags, so they can be used from any project after installing the package.
* New `get_subtheme_data()` (from `scripts/retrieve_all.R`) downloads every sub-theme of a theme (default: the ten `infectious_disease` sub-themes), optionally saving one file per sub-theme.
* New `download_fingertips_amr()` (from `scripts/fingertips_amr_download.R`) downloads the Fingertips "AMR local indicators" profile for all area types, with per-indicator caching and resumption when `out_dir` is given. Command-line options map to arguments: `--themes` to `themes`, `--rolling` to `rolling`, `--out` to `out_dir` and `--refresh` to `refresh`. Unlike the script it keeps everything in memory when `out_dir` is `NULL` and no longer needs `dplyr` or `readr`.
* New helpers `fingertips_amr_indicators()`, `classify_fingertips_indicators()`, `parse_fingertips_period()` and `summarise_fingertips_coverage()`.
* `fingertipsR` (not on CRAN) is a suggested package, installed with `pak::pak("ropensci/fingertipsR")`.
* Fixed `get_data()` failing with "subscript out of bounds" when one of several datasets could not be downloaded; the failed dataset is now skipped as documented.
* Offline test suite: the API is mocked, so tests no longer need network access. The live tests are opt-in (`UKHSADATR_LIVE_TESTS=true`).

# ukhsadatR 0.2.0

* `get_data()` now supports wildcards: any argument can be `"*"` (all values), a glob pattern such as `"NHS*London*"`, or a character vector of values. All matching datasets are downloaded and combined with `data.table::rbindlist()`.
* New `save_to` argument in `get_data()` writes the combined result to `.csv` / `.csv.gz` (via `data.table::fwrite()`) or `.rds`.
* New `as_data_table` argument returns a `data.table` instead of a `data.frame`.
* New `max_datasets` safety limit for broad wildcard queries.
* New `get_combinations()` lists the datasets a query matches without downloading them.
* All requests are now rate limited (default 1 request/second, set with `options(ukhsadatR.requests_per_second = ...)`) and retried with exponential backoff on HTTP 429/502/503/504, honouring `Retry-After`.
* Catalogue lookups (available themes, topics, geographies, metrics) are cached for the session; `clear_cache()` resets them.

# ukhsadatR 0.1.1

* updated errors/warnings to fail gracefully as messages, given the dependancy on external API URL.


# ukhsadatR 0.1.0

* Initial CRAN submission.
