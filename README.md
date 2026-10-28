# ukhsadatR
<!-- badges: start -->
[![R-CMD-check](https://github.com/silverfoxdoc/ukhsadatR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/silverfoxdoc/ukhsadatR/actions)

<!-- badges: end -->

This is a wrapper for the [UKHSA Data Dashboard](https://ukhsa-dashboard.data.gov.uk/) API, so that data can be easily imported into `R`.

Further detailed documentation on the UKHSA data dashboard API is available [here](https://ukhsa-dashboard.data.gov.uk/access-our-data).

This package is based upon the [`ukcovid19`](https://github.com/UKHSA-Internal/coronavirus-dashboard-api-R-sdk) package previously published by Public Health England but has been substantially rewritten and extended.

## Installation

``` r
remotes::install_github("vargasrichards/ukhsadatR")
```

## Pagination

This API wrapper will bypass the pagination process and always download the full dataset for each metric requested.

## Wildcards

Any argument to `get_data()` can be `"*"` (every value), a glob pattern such as `"NHS*London*"`, or a vector of values. Every matching dataset is downloaded and stacked into one table, and can be saved at the same time:

``` r
ecoli <- get_data(
  theme = "infectious_disease",
  sub_theme = "antimicrobial_resistance",
  topic = "E-coli",
  geography_type = "Integrated Care Board",
  geography = "*",
  metric = "*PercentResistant*",
  as_data_table = TRUE,
  save_to = "ecoli_icb_resistance.csv"
)
```

Preview what a query will download, without downloading it, with `get_combinations()` (same arguments).

## Rate limiting

Requests are throttled to 1 per second by default and retried with backoff if the API returns 429 (too many requests). A wildcard query of N datasets therefore takes at least N seconds. Change the rate with `options(ukhsadatR.requests_per_second = 0.5)`. `get_data()` refuses queries matching more than `max_datasets` (default 500) datasets unless you raise the limit manually.

## Example

To obtain the daily reported cases of COVID-19, use the following:

``` r
get_data(
  theme = "infectious_disease",
  sub_theme = "respiratory",
  topic = "COVID-19",
  geography_type = "Nation",
  geography = "England",
  metric = "COVID-19_cases_casesByDay"
)
```

## Disclaimer

It is the user's responsibility to respect relevant rate limits for data retrieval, and all actions resulting from the use of this package are the user's responsibility.
