# Summarise the coverage of a Fingertips AMR download

One row per indicator and area type: how many areas and periods exist,
the first and last period, and the percentage of rows whose `count` is
missing (suppressed or never published).

## Usage

``` r
summarise_fingertips_coverage(x)
```

## Arguments

- x:

  the table returned by
  [`download_fingertips_amr`](https://vargasrichards.github.io/ukamrdataR/reference/download_fingertips_amr.md).

## Value

A data.frame with columns `indicator_id`, `indicator_name`, `theme`,
`period_type`, `is_rolling`, `area_type`, `n_areas`, `n_periods`,
`first_period`, `last_period`, `n_rows` and `pct_count_missing`.

## Examples

``` r
x <- data.frame(
  indicator_id = 1L, indicator_name = "demo", theme = "resistance",
  period_type = "quarter", is_rolling = FALSE, area_type = "ICBs",
  area_code = c("a", "b"), timeperiod = "2024 Q1", count = c(5, NA),
  period_start = as.Date("2024-01-01"), period_end = as.Date("2024-03-31")
)
summarise_fingertips_coverage(x)
#>   indicator_id indicator_name      theme period_type is_rolling area_type
#> 1            1           demo resistance     quarter      FALSE      ICBs
#>   n_areas n_periods first_period last_period n_rows pct_count_missing
#> 1       2         1   2024-01-01  2024-03-31      2                50
```
