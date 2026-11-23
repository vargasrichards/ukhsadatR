# ukamrdataR 
<!-- badges: start -->
[![R-CMD-check](https://github.com/vargasrichards/ukhsadatR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/vargasrichards/ukhsadatR/actions)

<!-- badges: end -->

This is a wrapper for the [UKHSA Data Dashboard](https://ukhsa-dashboard.data.gov.uk/) API, so that data can be easily imported into `R`.

Further detailed documentation on the UKHSA data dashboard API is available [here](https://ukhsa-dashboard.data.gov.uk/access-our-data).

This package is based upon the [`ukcovid19`](https://github.com/UKHSA-Internal/coronavirus-dashboard-api-R-sdk) package previously published by Public Health England but has been substantially rewritten and extended.

NB: This fork is specially adapted for AMR data. As well as the Data Dashboard API, it wraps the UKHSA [Fingertips](https://fingertips.phe.org.uk) "AMR local indicators" profile (antibiotic prescribing, resistance, bacteraemia / *C. difficile* case counts, stewardship) via the `fingertipsR` package. See [Fingertips AMR local indicators](#fingertips-amr-local-indicators).

## Installation

``` r
# install.packages("pak")
pak::pak("vargasrichards/ukhsadatR")
# or: remotes::install_github("vargasrichards/ukhsadatR")
```

The Fingertips functions additionally need [`fingertipsR`](https://github.com/ropensci/fingertipsR), which is not currently on CRAN:

``` r
pak::pak("ropensci/fingertipsR")
```

Every retrieval function is an ordinary R function with documented arguments, so another project can simply `library(ukhsadatR)` and call them; there are no command-line scripts to run. See `?get_data`, `?get_subtheme_data` and `?download_fingertips_amr`.

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

## Whole sub-themes

`get_subtheme_data()` runs `get_data()` once per sub-theme (all topics, geographies and metrics) and optionally saves one file per sub-theme. By default it fetches the ten sub-themes of `infectious_disease`, by UKHSA region (by nation for `contact` and `vector_borne`, which are only published nationally):

``` r
# everything, one CSV per sub-theme (a long download)
get_subtheme_data(out_dir = "ukhsa_data")

# just two sub-themes, in memory
x <- get_subtheme_data(sub_themes = c("respiratory", "gastrointestinal"))
names(x)

# override the geography type for one sub-theme
get_subtheme_data(sub_themes = c("respiratory", "contact"),
                  geography_type = c(respiratory = "Nation"))
```

## Fingertips AMR local indicators

`download_fingertips_amr()` retrieves every indicator in Fingertips profile 101 for **all** available area types (GP practice, Sub-ICB, ICB, trust, CCG, STP, region, England), un-aggregated and with numerator (`count`) and `denominator` columns. Each row is tagged with a `theme`, whether the series is rolling (`is_rolling`, `period_type`), organism / specimen / onset, and parsed `period_start` / `period_end` dates.

``` r
# Discrete (non-rolling) resistance series, in memory
res <- download_fingertips_amr(themes = "resistance", rolling = "exclude")

# Everything, cached and resumable on disk (re-run to retry failures)
amr <- download_fingertips_amr(out_dir = "data/fingertips_amr")

attr(amr, "download_log")      # status / rows / seconds per indicator
summarise_fingertips_coverage(amr)

# See what would be fetched without downloading any data
fingertips_amr_indicators(themes = c("prescribing", "resistance"))
```

Themes are `prescribing`, `resistance`, `testing`, `cases`, `stewardship`, `ipc` and `other`; `rolling` is `"include"`, `"exclude"` or `"only"`. Rolling series cannot be un-rolled without starting values, and "rolling quarterly average" series report the 4-quarter *average* count (rounded), so use `rolling = "exclude"` when you need discrete counts.

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
