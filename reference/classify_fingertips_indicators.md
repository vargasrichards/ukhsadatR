# Classify Fingertips indicators from their names

UKHSA indicator names encode the period type and the measure (for
example "12-month rolling" or "financial year"), and the metadata
`Frequency` field is mostly missing, so the names are parsed instead.
This is the classification that
[`download_fingertips_amr`](https://vargasrichards.github.io/ukamrdataR/reference/download_fingertips_amr.md)
attaches to every row it returns.

## Usage

``` r
classify_fingertips_indicators(indicator_name)
```

## Arguments

- indicator_name:

  character vector of Fingertips indicator names.

## Value

A data.frame with one row per name and columns:

- is_rolling:

  logical; the name mentions a rolling window.

- period_type:

  one of `"12-month rolling, monthly steps"`,
  `"rolling 4-quarter average, quarterly steps"`, `"financial year"`,
  `"calendar year"`, `"quarter"`, `"month"`, `"year (see definition)"`,
  `"unspecified"`.

- theme:

  one of `"prescribing"`, `"resistance"`, `"testing"`, `"cases"`,
  `"stewardship"`, `"ipc"`, `"other"`.

- organism:

  e.g. `"E. coli"`, or `NA`.

- specimen:

  `"blood"`, `"urine"` or `NA`.

- onset:

  `"hospital-onset"`, `"community-onset"` or `NA`.

## Details

Note that "rolling quarterly average" indicators report the *average
quarterly* count over the last four quarters (rounded to an integer),
not a discrete quarterly count.

## Examples

``` r
classify_fingertips_indicators(c(
  "E. coli bacteraemia: 12-month rolling count",
  "Escherichia coli urine resistance to trimethoprim: quarterly"
))
#>   is_rolling                     period_type      theme organism specimen onset
#> 1       TRUE 12-month rolling, monthly steps      cases  E. coli    blood  <NA>
#> 2      FALSE                         quarter resistance     <NA>    urine  <NA>
```
