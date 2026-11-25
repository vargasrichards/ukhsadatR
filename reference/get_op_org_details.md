# Get list sizes and prescribing units from OpenPrescribing

Monthly organisation statistics from the OpenPrescribing `org_details`
endpoint, mainly the registered patient list size used as a denominator
for prescribing rates.
[`get_op_spending`](https://vargasrichards.github.io/ukamrdataR/reference/get_op_spending.md)
can add these for you with `add_list_size = TRUE`.

## Usage

``` r
get_op_org_details(
  resolution = "england",
  org = NULL,
  keys = "total_list_size",
  date = NULL,
  start = NULL,
  end = NULL,
  as_data_table = FALSE
)
```

## Arguments

- resolution, org, date, start, end, as_data_table:

  as for
  [`get_op_spending`](https://vargasrichards.github.io/ukamrdataR/reference/get_op_spending.md).
  Without `org`, every organisation at the resolution is returned for
  the whole five-year window, which is a large download at `"practice"`
  level.

- keys:

  character vector of statistics to return: `"total_list_size"`,
  `"astro_pu_items"`, `"astro_pu_cost"` or any `"star_pu.<name>"` key
  listed in the OpenPrescribing API documentation.

## Value

A data.frame with columns `date`, `resolution`, `org_id`, `org_name` and
one column per requested key (STAR-PU keys appear as `star_pu.<name>`).

## Examples

``` r
# \donttest{
get_op_org_details("icb", keys = "total_list_size", start = "2024-01", end = "2024-03")
#> Error: OpenPrescribing refused the request (HTTP 403, a bot-protection challenge), so no data could be retrieved from /org_details/.
#> This is applied by the service to some networks and clients (for example some cloud or institutional IP ranges). Try again later or from another network, and consider reducing the request rate with options(ukhsadatR.requests_per_second = 0.5).
# }
```
