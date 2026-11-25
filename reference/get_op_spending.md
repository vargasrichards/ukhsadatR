# Get prescribing totals from OpenPrescribing

Retrieves monthly prescribing *items*, *quantity* and *actual cost*
(GBP) for one or more BNF codes from the [OpenPrescribing
API](https://openprescribing.net/api/), aggregated to the spatial
resolution you choose. The data are NHS England primary-care (mainly GP)
prescriptions dispensed in the community, from the English Prescribing
Dataset; the API holds the most recent five years.

## Usage

``` r
get_op_spending(
  code,
  resolution = "england",
  org = NULL,
  date = NULL,
  start = NULL,
  end = NULL,
  combine = FALSE,
  add_list_size = FALSE,
  as_data_table = FALSE,
  verbose = TRUE
)
```

## Arguments

- code:

  character vector of BNF codes or section numbers (see Details).
  Optionally named to set labels.

- resolution:

  spatial resolution: one of `"england"` (default), `"region"`, `"icb"`,
  `"sicbl"`, `"pcn"`, `"practice"`.

- org:

  optional character vector of organisation codes to keep (for example
  ICB codes). For `resolution = "practice"` a Sub-ICB code expands to
  all of its practices. `NULL` (default) returns every organisation at
  that resolution. Find codes with
  [`search_op_org`](https://vargasrichards.github.io/ukamrdataR/reference/search_op_org.md).

- date:

  optional month(s) to return: Date objects or `"YYYY-MM-DD"` /
  `"YYYY-MM"` strings. Any day is rounded down to the first of its
  month.

- start, end:

  optional first and last month (inclusive) as for `date`; either may be
  given alone. Not combinable with `date`.

- combine:

  logical. If `TRUE`, all `code`s are summed in a single request (the
  API treats multiple codes as a union) and returned as one series.
  Beware double counting if the codes overlap.

- add_list_size:

  logical. If `TRUE`, also fetch
  [`get_op_org_details`](https://vargasrichards.github.io/ukamrdataR/reference/get_op_org_details.md)
  and add `total_list_size` and `items_per_1000` (items per 1,000
  registered patients).

- as_data_table:

  logical; return a `data.table`.

- verbose:

  logical; message the number of requests when it is large.

## Value

A data.frame with one row per month and organisation (and code):

- date:

  first day of the month (`Date`).

- resolution:

  the canonical resolution requested.

- org_id, org_name:

  organisation code and name (`NA` / "england" for national totals).

- code, code_label:

  the BNF code (or comma-joined codes if `combine`) and its label.

- items:

  number of prescription items.

- quantity:

  total quantity dispensed (units depend on the presentation, so only
  compare within the same product).

- actual_cost:

  actual cost in GBP.

Practice-level results add `parent_sicbl` and `setting` (the practice
setting code; 4 is a standard GP practice). With `add_list_size`,
columns `total_list_size` and `items_per_1000` are appended. Months with
no prescribing for an organisation are omitted by the API, not returned
as zero.

## Spatial resolutions

- `"england"`:

  one national series (the default).

- `"region"`:

  NHS England regions (the API's `regional_team`).

- `"icb"`:

  Integrated Care Boards (the API's `stp`).

- `"sicbl"`:

  Sub-ICB Locations (the API's `ccg`).

- `"pcn"`:

  Primary Care Networks.

- `"practice"`:

  individual GP practices.

`"stp"`, `"ccg"`, `"sub-icb"` and `"regional_team"` are accepted as
aliases. Organisations are those currently defined by OpenPrescribing:
practice prescribing is attributed to the organisation the practice
belongs to now, so a series does not follow past mergers or boundary
changes. Check that the `org_id` values match the boundary vintage you
plan to join them to.

## BNF codes

`code` is matched as a *prefix*, so `"0501"` covers all of BNF section
5.1 (antibacterial drugs) and `"0501013B0"` a single chemical. Section
numbers such as `"5.1"` or `"5.1.1"` are also accepted. If you supply
several codes they are fetched separately (one API request each) and
returned in long format with a `code` column, unless `combine = TRUE`.
Names on `code` become the `code_label` column. Find codes with
[`search_op_bnf`](https://vargasrichards.github.io/ukamrdataR/reference/search_op_bnf.md)
or
[`op_antibiotic_classes`](https://vargasrichards.github.io/ukamrdataR/reference/op_antibiotic_classes.md).

## Request volume

National and organisation-level queries need one request per code. The
API will not return all practices for all months in one call, so
`resolution = "practice"` without `org` needs `date` or both `start` and
`end` and sends one request per code per month. All requests are
throttled to `getOption("ukhsadatR.requests_per_second", 1)`.

## See also

[`get_op_antibiotics`](https://vargasrichards.github.io/ukamrdataR/reference/get_op_antibiotics.md),
[`get_op_org_details`](https://vargasrichards.github.io/ukamrdataR/reference/get_op_org_details.md),
[`get_op_boundaries`](https://vargasrichards.github.io/ukamrdataR/reference/get_op_boundaries.md)

## Examples

``` r
# \donttest{
# All antibacterials (BNF 5.1), England, monthly
get_op_spending("0501")
#> Error: OpenPrescribing refused the request (HTTP 403, a bot-protection challenge), so no data could be retrieved from /spending_by_org/.
#> This is applied by the service to some networks and clients (for example some cloud or institutional IP ranges). Try again later or from another network, and consider reducing the request rate with options(ukhsadatR.requests_per_second = 0.5).

# Penicillins and macrolides by ICB for 2024, with rates per 1,000 patients
get_op_spending(
  c(Penicillins = "050101", Macrolides = "050105"),
  resolution = "icb", start = "2024-01", end = "2024-12",
  add_list_size = TRUE
)
#> Error: OpenPrescribing refused the request (HTTP 403, a bot-protection challenge), so no data could be retrieved from /spending_by_org/.
#> This is applied by the service to some networks and clients (for example some cloud or institutional IP ranges). Try again later or from another network, and consider reducing the request rate with options(ukhsadatR.requests_per_second = 0.5).

# One chemical (amoxicillin) in every practice of one Sub-ICB, one month
sicbl <- search_op_org("devon", resolution = "sicbl")$code[1]
#> Error: OpenPrescribing refused the request (HTTP 403, a bot-protection challenge), so no data could be retrieved from /org_code/.
#> This is applied by the service to some networks and clients (for example some cloud or institutional IP ranges). Try again later or from another network, and consider reducing the request rate with options(ukhsadatR.requests_per_second = 0.5).
get_op_spending("0501013B0", resolution = "practice", org = sicbl,
                date = "2024-06")
#> Error: object 'sicbl' not found
# }
```
