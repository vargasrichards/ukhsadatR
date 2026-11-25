# Search BNF codes in OpenPrescribing

Looks up BNF chapters, sections, paragraphs, chemicals, products and
presentations by name or code, to find the `code` to give to
[`get_op_spending`](https://vargasrichards.github.io/ukamrdataR/reference/get_op_spending.md).

## Usage

``` r
search_op_bnf(q, exact = FALSE)
```

## Arguments

- q:

  character vector of search terms: part of a name (case insensitive,
  e.g. `"amoxicillin"`) or the start of a code (`"0501"`, `"5.1"`).
  Results for several terms are combined.

- exact:

  logical; if `TRUE` only exact code or name matches are returned.

## Value

A data.frame with columns `type` (e.g. `"BNF section"`, `"chemical"`,
`"product"`, `"product format"`), `id` (the code or section number),
`name` and, where the API supplies them, `section` and `is_generic`.
Zero rows if nothing matches.

## Examples

``` r
# \donttest{
search_op_bnf("amoxicillin")
#> Error: OpenPrescribing refused the request (HTTP 403, a bot-protection challenge), so no data could be retrieved from /bnf_code/.
#> This is applied by the service to some networks and clients (for example some cloud or institutional IP ranges). Try again later or from another network, and consider reducing the request rate with options(ukhsadatR.requests_per_second = 0.5).
search_op_bnf("5.1.1")
#> Error: OpenPrescribing refused the request (HTTP 403, a bot-protection challenge), so no data could be retrieved from /bnf_code/.
#> This is applied by the service to some networks and clients (for example some cloud or institutional IP ranges). Try again later or from another network, and consider reducing the request rate with options(ukhsadatR.requests_per_second = 0.5).
# }
```
