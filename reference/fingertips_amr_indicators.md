# List the indicators in the Fingertips AMR profile

Returns the catalogue of indicators in the UKHSA Fingertips "AMR local
indicators" profile (profile 101), one row per indicator, with the full
UKHSA metadata and the classification from
[`classify_fingertips_indicators`](https://vargasrichards.github.io/ukamrdataR/reference/classify_fingertips_indicators.md).
No indicator data are downloaded, so this is the quick way to see what
[`download_fingertips_amr`](https://vargasrichards.github.io/ukamrdataR/reference/download_fingertips_amr.md)
would fetch.

## Usage

``` r
fingertips_amr_indicators(
  themes = "all",
  rolling = c("include", "exclude", "only"),
  profile_id = .fingertips_profile_id
)
```

## Arguments

- themes:

  character vector of themes to keep: any of `"prescribing"`,
  `"resistance"`, `"testing"`, `"cases"`, `"stewardship"`, `"ipc"`,
  `"other"`, or `"all"` (the default).

- rolling:

  `"include"` (default) keeps every indicator, `"exclude"` drops rolling
  series, `"only"` keeps only rolling series.

- profile_id:

  Fingertips profile ID. The default, 101, is "AMR local indicators -
  produced by the UKHSA".

## Value

A data.frame with one row per indicator.

## Details

Requires the fingertipsR package, which is not currently on CRAN:
`pak::pak("ropensci/fingertipsR")`.

## Examples

``` r
# \donttest{
if (requireNamespace("fingertipsR", quietly = TRUE)) {
  cat_tbl <- fingertips_amr_indicators(themes = "resistance", rolling = "exclude")
  head(cat_tbl[, c("IndicatorID", "IndicatorName", "period_type")])
}
#>   IndicatorID
#> 1       92519
#> 2       92521
#>                                                                                                  IndicatorName
#> 1   Percentage of community E. coli urine specimens resistant to trimethoprim; by ICB sub-location and quarter
#> 2 Percentage of community E. coli urine specimens resistant to nitrofurantoin; by ICB sub-location and quarter
#>   period_type
#> 1     quarter
#> 2     quarter
# }
```
