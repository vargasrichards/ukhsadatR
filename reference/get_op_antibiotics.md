# Get antibiotic prescribing by BNF class from OpenPrescribing

A convenience wrapper around
[`get_op_spending`](https://vargasrichards.github.io/ukamrdataR/reference/get_op_spending.md)
that retrieves one series per antibacterial class in BNF section 5.1
(see
[`op_antibiotic_classes`](https://vargasrichards.github.io/ukamrdataR/reference/op_antibiotic_classes.md))
at the spatial resolution you choose.

## Usage

``` r
get_op_antibiotics(classes = NULL, include_total = FALSE, ...)
```

## Arguments

- classes:

  which classes to fetch: `NULL` (default) for all thirteen sub-sections
  5.1.1-5.1.13, or a character vector of section numbers (`"5.1.5"`),
  BNF codes (`"050105"`) or class names (`"Macrolides"`,
  case-insensitive).

- include_total:

  logical. Also fetch all of section 5.1 as a further series (`code`
  `"0501"`). It overlaps the classes, so do not sum it with them.

- ...:

  passed to
  [`get_op_spending`](https://vargasrichards.github.io/ukamrdataR/reference/get_op_spending.md):
  `resolution`, `org`, `date`, `start`, `end`, `add_list_size`,
  `as_data_table`, `verbose`.

## Value

As
[`get_op_spending`](https://vargasrichards.github.io/ukamrdataR/reference/get_op_spending.md),
with the class name in `code_label`. Costs one request per class (13 by
default).

## See also

[`op_antibiotic_classes`](https://vargasrichards.github.io/ukamrdataR/reference/op_antibiotic_classes.md)

## Examples

``` r
# \donttest{
# Macrolide and tetracycline items per 1,000 patients, by ICB, since 2023
get_op_antibiotics(c("5.1.3", "Macrolides"), resolution = "icb",
                   start = "2023-01", add_list_size = TRUE)
#> Error: OpenPrescribing refused the request (HTTP 403, a bot-protection challenge), so no data could be retrieved from /spending_by_org/.
#> This is applied by the service to some networks and clients (for example some cloud or institutional IP ranges). Try again later or from another network, and consider reducing the request rate with options(ukhsadatR.requests_per_second = 0.5).
# }
```
