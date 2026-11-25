# Search NHS organisations in OpenPrescribing

Finds the organisation codes to give to the `org` argument of
[`get_op_spending`](https://vargasrichards.github.io/ukamrdataR/reference/get_op_spending.md).

## Usage

``` r
search_op_org(q = NULL, resolution = NULL, exact = FALSE)
```

## Arguments

- q:

  character vector of search terms: the start of a code, or part of a
  name (practices also match on postcode). `NULL` lists every
  organisation of the given resolution.

- resolution:

  optional single resolution (`"region"`, `"icb"`, `"sicbl"`, `"pcn"`,
  `"practice"`) to search within. `NULL` searches Sub-ICB Locations and
  practices.

- exact:

  logical; require an exact code or name match.

## Value

A data.frame with at least `id`, `code`, `name` and `type`; practices
also have `postcode`, `setting`, `setting_name` and `ccg` (their Sub-ICB
code). Searching all practices (`q = NULL`) returns several thousand
rows.

## Examples

``` r
# \donttest{
search_op_org("london", resolution = "icb")
#> Error: OpenPrescribing refused the request (HTTP 403, a bot-protection challenge), so no data could be retrieved from /org_code/.
#> This is applied by the service to some networks and clients (for example some cloud or institutional IP ranges). Try again later or from another network, and consider reducing the request rate with options(ukhsadatR.requests_per_second = 0.5).
# }
```
