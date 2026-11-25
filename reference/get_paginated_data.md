# Get Paginated Data

Generates API query URL and retrieves paginated data.

## Usage

``` r
get_paginated_data(
  theme = NULL,
  sub_theme = NULL,
  topic = NULL,
  geography_type = NULL,
  geography = NULL,
  metric = NULL,
  page_number = 1,
  page_size = 365
)
```

## Arguments

- theme:

  the largest overall topical subgroup of data. For example
  `infectious_disease`.

- sub_theme:

  a topical subgroup associated with the parent theme. For example
  `respiratory`.

- topic:

  categorical subgroup associated with the selected theme and sub_theme.
  For example, `COVID-19`.

- geography_type:

  the overarching area type for the intended geography. For example
  `Nation`.

- geography:

  the selected area under the `geography_type`. For example `England`.

- metric:

  the type of data being selected. For example
  `COVID-19_testing_PCRcountByDay`.

- page_number:

  define which page of data to retrieve

- page_size:

  define number of results returned per page. Maximum supported size is
  365.

## Value

               list containing the query structure and results

## Details

              If any input argument is left NULL or invalid, a list
                       of possible values for that parameter is returned.

## Examples

``` r
get_paginated_data(
  theme = "infectious_disease",
  sub_theme = "respiratory",
  topic = "COVID-19",
  geography_type = "Nation",
  geography = "England",
  metric = "COVID-19_cases_casesByDay",
  page_number = 2,
  page_size = 6
)
#> $count
#> [1] 2485
#> 
#> $`next`
#> [1] "https://api.ukhsa-dashboard.data.gov.uk/themes/infectious_disease/sub_themes/respiratory/topics/COVID-19/geography_types/Nation/geographies/England/metrics/COVID-19_cases_casesByDay?page=3&page_size=6"
#> 
#> $previous
#> [1] "https://api.ukhsa-dashboard.data.gov.uk/themes/infectious_disease/sub_themes/respiratory/topics/COVID-19/geography_types/Nation/geographies/England/metrics/COVID-19_cases_casesByDay?page_size=6"
#> 
#> $results
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
#> 1     2       6 2020-02-05            1                     FALSE
#> 2     2       6 2020-02-06            0                     FALSE
#> 3     2       6 2020-02-07            0                     FALSE
#> 4     2       6 2020-02-08            3                     FALSE
#> 5     2       6 2020-02-09            1                     FALSE
#> 6     2       7 2020-02-10            1                     FALSE
#> 
```
