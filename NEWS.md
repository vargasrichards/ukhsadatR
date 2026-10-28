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
