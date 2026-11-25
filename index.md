# ukamrdataR

Documentation: <https://vargasrichards.github.io/ukamrdataR/>. The R
package is named `ukhsadatR`: use
[`library(ukhsadatR)`](https://github.com/vargasrichards/ukamrdataR)
after installing.

This is a wrapper for the [UKHSA Data
Dashboard](https://ukhsa-dashboard.data.gov.uk/) API, so that data can
be easily imported into `R`.

Further detailed documentation on the UKHSA data dashboard API is
available [here](https://ukhsa-dashboard.data.gov.uk/access-our-data).

This package is based upon the
[`ukcovid19`](https://github.com/UKHSA-Internal/coronavirus-dashboard-api-R-sdk)
package previously published by Public Health England but has been
substantially rewritten and extended.

NB: This fork is specially adapted for AMR data. As well as the Data
Dashboard API, it wraps the UKHSA
[Fingertips](https://fingertips.phe.org.uk) “AMR local indicators”
profile (antibiotic prescribing, resistance, bacteraemia / *C.
difficile* case counts, stewardship) via the `fingertipsR` package. See
[Fingertips AMR local indicators](#fingertips-amr-local-indicators).

## Installation

``` r

# install.packages("pak")
pak::pak("vargasrichards/ukamrdataR")
# or: remotes::install_github("vargasrichards/ukamrdataR")
```

The Fingertips functions additionally need
[`fingertipsR`](https://github.com/ropensci/fingertipsR), which is not
currently on CRAN:

``` r

pak::pak("ropensci/fingertipsR")
```

Every retrieval function is an ordinary R function with documented
arguments, so another project can simply
[`library(ukhsadatR)`](https://github.com/vargasrichards/ukamrdataR) and
call them; there are no command-line scripts to run. See
[`?get_data`](https://vargasrichards.github.io/ukamrdataR/reference/get_data.md),
[`?get_subtheme_data`](https://vargasrichards.github.io/ukamrdataR/reference/get_subtheme_data.md)
and
[`?download_fingertips_amr`](https://vargasrichards.github.io/ukamrdataR/reference/download_fingertips_amr.md).

## Pagination

This API wrapper will bypass the pagination process and always download
the full dataset for each metric requested.

## Wildcards

Any argument to
[`get_data()`](https://vargasrichards.github.io/ukamrdataR/reference/get_data.md)
can be `"*"` (every value), a glob pattern such as `"NHS*London*"`, or a
vector of values. Every matching dataset is downloaded and stacked into
one table, and can be saved at the same time:

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

Preview what a query will download, without downloading it, with
[`get_combinations()`](https://vargasrichards.github.io/ukamrdataR/reference/get_combinations.md)
(same arguments).

## Rate limiting

Requests are throttled to 1 per second by default and retried with
backoff if the API returns 429 (too many requests). A wildcard query of
N datasets therefore takes at least N seconds. Change the rate with
`options(ukhsadatR.requests_per_second = 0.5)`.
[`get_data()`](https://vargasrichards.github.io/ukamrdataR/reference/get_data.md)
refuses queries matching more than `max_datasets` (default 500) datasets
unless you raise the limit manually.

## Whole sub-themes

[`get_subtheme_data()`](https://vargasrichards.github.io/ukamrdataR/reference/get_subtheme_data.md)
runs
[`get_data()`](https://vargasrichards.github.io/ukamrdataR/reference/get_data.md)
once per sub-theme (all topics, geographies and metrics) and optionally
saves one file per sub-theme. By default it fetches the ten sub-themes
of `infectious_disease`, by UKHSA region (by nation for `contact` and
`vector_borne`, which are only published nationally):

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

[`download_fingertips_amr()`](https://vargasrichards.github.io/ukamrdataR/reference/download_fingertips_amr.md)
retrieves every indicator in Fingertips profile 101 for **all**
available area types (GP practice, Sub-ICB, ICB, trust, CCG, STP,
region, England), un-aggregated and with numerator (`count`) and
`denominator` columns. Each row is tagged with a `theme`, whether the
series is rolling (`is_rolling`, `period_type`), organism / specimen /
onset, and parsed `period_start` / `period_end` dates.

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

Themes are `prescribing`, `resistance`, `testing`, `cases`,
`stewardship`, `ipc` and `other`; `rolling` is `"include"`, `"exclude"`
or `"only"`. Rolling series cannot be un-rolled without starting values,
and “rolling quarterly average” series report the 4-quarter *average*
count (rounded), so use `rolling = "exclude"` when you need discrete
counts.

## OpenPrescribing (English GP prescribing)

The [OpenPrescribing API](https://openprescribing.net/api/) (Bennett
Institute, University of Oxford; keyless) serves monthly **items,
quantity and actual cost** for any BNF code from the NHS Business
Services Authority prescribing dataset, for the last five years.
[`get_op_spending()`](https://vargasrichards.github.io/ukamrdataR/reference/get_op_spending.md)
retrieves it at the spatial resolution you choose: `"england"`,
`"region"`, `"icb"`, `"sicbl"` (Sub-ICB Location), `"pcn"` or
`"practice"`.

``` r

# Antibacterials (BNF 5.1), England, monthly
get_op_spending("0501")

# Named classes by ICB for 2024, with items per 1,000 registered patients
get_op_spending(
  c(Penicillins = "050101", Macrolides = "050105"),
  resolution = "icb", start = "2024-01", end = "2024-12",
  add_list_size = TRUE
)

# Every BNF 5.1 sub-class (13 requests) at region level
get_op_antibiotics(resolution = "region", start = "2023-01")

# Find BNF and organisation codes, and get boundaries for mapping
search_op_bnf("amoxicillin")
search_op_org("london", resolution = "icb")
icb <- get_op_boundaries("icb")          # sf object (needs the 'sf' package)
```

`code` is matched as a BNF prefix (`"0501"` = all antibacterials;
section numbers such as `"5.1.1"` also work). Several codes are fetched
separately and returned in long format with a `code_label` column unless
`combine = TRUE`.
[`get_op_org_details()`](https://vargasrichards.github.io/ukamrdataR/reference/get_op_org_details.md)
returns the list-size denominators directly. Organisations are those
OpenPrescribing currently defines, so a series does not follow past ICB
/ Sub-ICB mergers; check that `org_id` matches your boundary vintage.
All requests share the package’s rate limit (see above).

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

It is the user’s responsibility to respect relevant rate limits for data
retrieval, and all actions resulting from the use of this package are
the user’s responsibility.
