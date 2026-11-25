# Parse Fingertips period labels into dates

Fingertips labels time periods as text: `"2015 Q1"` (calendar quarter),
`"Nov 2014"` (month), `"2019/20"` (financial year, April to March),
`"2019/20 Q2"` (financial-year quarter) and `"2019"` (calendar year).
This converts them to the first and last day of the period the label
describes.

## Usage

``` r
parse_fingertips_period(label)
```

## Arguments

- label:

  character vector of Fingertips period labels.

## Value

A data.frame with columns `period_start` and `period_end` (class
`Date`); `NA` for unrecognised labels.

## Details

For indicators that are 12-month rolling series the value covers the
twelve months *ending* at `period_end`; for other rolling series the
window length is not stated by the API, so check the indicator
definition.

## Examples

``` r
parse_fingertips_period(c("2015 Q1", "Nov 2014", "2019/20", "2019/20 Q2", "2019"))
#>   period_start period_end
#> 1   2015-01-01 2015-03-31
#> 2   2014-11-01 2014-11-30
#> 3   2019-04-01 2020-03-31
#> 4   2019-07-01 2019-09-30
#> 5   2019-01-01 2019-12-31
```
