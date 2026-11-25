# Introduction to ukhsadatR

## Introduction

The `ukhsadatR` package provides easy access to UK Health Security
Agency (UKHSA) data via their API.

## Example

Below demonstrates how to retrieve daily reported COVID-19 cases at the
national level for England:

``` r

library(ukhsadatR)

get_data(
  theme = "infectious_disease",
  sub_theme = "respiratory",
  topic = "COVID-19",
  geography_type = "Nation",
  geography = "England",
  metric = "COVID-19_cases_casesByDay"
) |>
  head()
#>                theme   sub_theme    topic geography_type geography
#> 1 infectious_disease respiratory COVID-19         Nation   England
#> 2 infectious_disease respiratory COVID-19         Nation   England
#> 3 infectious_disease respiratory COVID-19         Nation   England
#> 4 infectious_disease respiratory COVID-19         Nation   England
#> 5 infectious_disease respiratory COVID-19         Nation   England
#> 6 infectious_disease respiratory COVID-19         Nation   England
#>   geography_code                    metric metric_group stratum sex age year
#> 1      E92000001 COVID-19_cases_casesByDay        cases default all all 2020
#> 2      E92000001 COVID-19_cases_casesByDay        cases default all all 2020
#> 3      E92000001 COVID-19_cases_casesByDay        cases default all all 2020
#> 4      E92000001 COVID-19_cases_casesByDay        cases default all all 2020
#> 5      E92000001 COVID-19_cases_casesByDay        cases default all all 2020
#> 6      E92000001 COVID-19_cases_casesByDay        cases default all all 2020
#>   month epiweek       date metric_value in_reporting_delay_period
#> 1     1       5 2020-01-30            1                     FALSE
#> 2     1       5 2020-01-31            0                     FALSE
#> 3     2       5 2020-02-01            0                     FALSE
#> 4     2       5 2020-02-02            1                     FALSE
#> 5     2       6 2020-02-03           18                     FALSE
#> 6     2       6 2020-02-04            0                     FALSE
```

## Wildcard example

For exploratory data analysis, you may wish to download more than one
single combination.

It is good practice to preview the combinations first:

``` r

get_combinations(
 theme = "infectious_disease",
   sub_theme = "antimicrobial_resistance",
   topic = "E-coli", geography_type = "Nation", geography = "*", metric = "*"
 )
#>                 theme                sub_theme  topic geography_type geography
#> 1  infectious_disease antimicrobial_resistance E-coli         Nation   England
#> 2  infectious_disease antimicrobial_resistance E-coli         Nation   England
#> 3  infectious_disease antimicrobial_resistance E-coli         Nation   England
#> 4  infectious_disease antimicrobial_resistance E-coli         Nation   England
#> 5  infectious_disease antimicrobial_resistance E-coli         Nation   England
#> 6  infectious_disease antimicrobial_resistance E-coli         Nation   England
#> 7  infectious_disease antimicrobial_resistance E-coli         Nation   England
#> 8  infectious_disease antimicrobial_resistance E-coli         Nation   England
#> 9  infectious_disease antimicrobial_resistance E-coli         Nation   England
#> 10 infectious_disease antimicrobial_resistance E-coli         Nation   England
#> 11 infectious_disease antimicrobial_resistance E-coli         Nation   England
#> 12 infectious_disease antimicrobial_resistance E-coli         Nation   England
#> 13 infectious_disease antimicrobial_resistance E-coli         Nation   England
#> 14 infectious_disease antimicrobial_resistance E-coli         Nation   England
#> 15 infectious_disease antimicrobial_resistance E-coli         Nation   England
#>                                                              metric
#> 1                e-coli_testing_bacteraemiaNumberTestedRollingMonth
#> 2            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 3               e-coli_testing_bacteraemiaPercentTestedRollingMonth
#> 4      e-coli_testing_bacteriuriaNumberTestedRollingMonthAcuteTrust
#> 5       e-coli_testing_bacteriuriaNumberTestedRollingMonthAllMedFac
#> 6              e-coli_testing_bacteriuriaNumberTestedRollingMonthGP
#> 7        e-coli_testing_bacteriuriaNumberTestedRollingMonthHospital
#> 8  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 9   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 10         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 11   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 12    e-coli_testing_bacteriuriaPercentTestedRollingMonthAcuteTrust
#> 13     e-coli_testing_bacteriuriaPercentTestedRollingMonthAllMedFac
#> 14            e-coli_testing_bacteriuriaPercentTestedRollingMonthGP
#> 15      e-coli_testing_bacteriuriaPercentTestedRollingMonthHospital
```

## Whole sub-themes

[`get_subtheme_data()`](https://vargasrichards.github.io/ukamrdataR/reference/get_subtheme_data.md)
downloads every sub-theme of a theme in one call and can save one file
per sub-theme. This is a large download, so it is not run here:

``` r

get_subtheme_data(
  sub_themes = c("respiratory", "gastrointestinal"),
  out_dir = "ukhsa_data"
)
```

## Fingertips AMR local indicators

The package also wraps the UKHSA Fingertips “AMR local indicators”
profile through the suggested `fingertipsR` package
(`pak::pak("ropensci/fingertipsR")`). Preview the indicators, then
download them:

``` r

fingertips_amr_indicators(themes = "resistance", rolling = "exclude")

res <- download_fingertips_amr(themes = "resistance", rolling = "exclude")
summarise_fingertips_coverage(res)
```

Pass `out_dir` to cache every indicator on disk so an interrupted
download can be resumed by running the same call again.
