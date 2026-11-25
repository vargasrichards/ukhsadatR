# Get Data

Downloads all pages of data for one or more metrics and combines them
into a single table.

## Usage

``` r
get_data(
  theme = NULL,
  sub_theme = NULL,
  topic = NULL,
  geography_type = NULL,
  geography = NULL,
  metric = NULL,
  save_to = NULL,
  as_data_table = FALSE,
  max_datasets = 500,
  verbose = TRUE
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

- save_to:

  optional file path. If supplied, the combined result is also written
  to disk: `.rds` files with
  [`saveRDS()`](https://rdrr.io/r/base/readRDS.html), anything else
  (e.g. `.csv`, `.csv.gz`) with
  [`data.table::fwrite()`](https://rdrr.io/pkg/data.table/man/fwrite.html).

- as_data_table:

  if `TRUE`, return a `data.table`; otherwise (the default) a
  `data.frame`.

- max_datasets:

  safety limit on the number of metric datasets a wildcard query may
  download. Raise it deliberately for very broad queries.

- verbose:

  show progress messages.

## Value

               data.frame (or data.table) containing the query
                       results.

## Details

Every query argument accepts:

- a single exact value, e.g. `"E-coli"`;

- a character vector of values, e.g. `c("England", "Wales")`;

- `"*"` to download every available value at that level;

- a glob pattern using `*` or `?`, e.g. `"NHS*London*"` or
  `"*PercentResistant*"`.

Wildcards can be used at any level, including `theme` and `sub_theme`.
Every matching combination is downloaded and the results are stacked
with
[`data.table::rbindlist()`](https://rdrr.io/pkg/data.table/man/rbindlist.html).
Each row keeps its own `theme`, `topic`, `geography`, `metric`, etc.
columns, so the combined table is self-describing.

Use
[`get_combinations`](https://vargasrichards.github.io/ukamrdataR/reference/get_combinations.md)
first to see how many datasets a wildcard query will download.

For further information on the UKHSA dashboard API please visit the [API
documentation](https://ukhsa-dashboard.data.gov.uk/access-our-data).

              If any argument is left \code{NULL} or is invalid,
                       the possible values for that argument are shown as a
                       message and \code{NULL} is returned invisibly.
                       Datasets that fail to download are skipped with a
                       message; the rest are still returned.

## Rate limiting

All requests are throttled to
`getOption("ukhsadatR.requests_per_second", 1)` and retried with backoff
on HTTP 429/503, so a wildcard query of N datasets takes at least N
seconds by default. Lists of available options are cached for the
session (see
[`clear_cache`](https://vargasrichards.github.io/ukamrdataR/reference/clear_cache.md)).
Please keep broad queries proportionate: preview them with
[`get_combinations`](https://vargasrichards.github.io/ukamrdataR/reference/get_combinations.md).

## Examples

``` r
# \donttest{
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

# all ICBs, all E. coli resistance metrics, saved as CSV
ecoli <- get_data(
  theme = "infectious_disease",
  sub_theme = "antimicrobial_resistance",
  topic = "E-coli",
  geography_type = "Integrated Care Board",
  geography = "*",
  metric = "*PercentResistant*",
  save_to = file.path(tempdir(), "ecoli_icb.csv")
)
#> Looking up metrics for 48 combinations...
#> Downloading 228 datasets (at least 228 requests; ~4 min at 1 request(s)/sec)...
#> [1/228] E-coli | NHS Bath and North East Somerset, Swindon and Wiltshire Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [2/228] E-coli | NHS Bath and North East Somerset, Swindon and Wiltshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [3/228] E-coli | NHS Bath and North East Somerset, Swindon and Wiltshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [4/228] E-coli | NHS Bath and North East Somerset, Swindon and Wiltshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [5/228] E-coli | NHS Bath and North East Somerset, Swindon and Wiltshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [6/228] E-coli | NHS Bedfordshire, Luton and Milton Keynes Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [7/228] E-coli | NHS Bedfordshire, Luton and Milton Keynes Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [8/228] E-coli | NHS Bedfordshire, Luton and Milton Keynes Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [9/228] E-coli | NHS Bedfordshire, Luton and Milton Keynes Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [10/228] E-coli | NHS Birmingham and Solihull Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [11/228] E-coli | NHS Birmingham and Solihull Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [12/228] E-coli | NHS Birmingham and Solihull Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [13/228] E-coli | NHS Birmingham and Solihull Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [14/228] E-coli | NHS Birmingham and Solihull Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [15/228] E-coli | NHS Black Country Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [16/228] E-coli | NHS Black Country Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [17/228] E-coli | NHS Black Country Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [18/228] E-coli | NHS Black Country Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [19/228] E-coli | NHS Black Country Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [20/228] E-coli | NHS Bristol, North Somerset and South Gloucestershire Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [21/228] E-coli | NHS Bristol, North Somerset and South Gloucestershire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [22/228] E-coli | NHS Bristol, North Somerset and South Gloucestershire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [23/228] E-coli | NHS Bristol, North Somerset and South Gloucestershire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [24/228] E-coli | NHS Bristol, North Somerset and South Gloucestershire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [25/228] E-coli | NHS Buckinghamshire, Oxfordshire and Berkshire West Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [26/228] E-coli | NHS Buckinghamshire, Oxfordshire and Berkshire West Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [27/228] E-coli | NHS Buckinghamshire, Oxfordshire and Berkshire West Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [28/228] E-coli | NHS Buckinghamshire, Oxfordshire and Berkshire West Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [29/228] E-coli | NHS Cambridgeshire and Peterborough Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [30/228] E-coli | NHS Cambridgeshire and Peterborough Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [31/228] E-coli | NHS Cambridgeshire and Peterborough Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [32/228] E-coli | NHS Cambridgeshire and Peterborough Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [33/228] E-coli | NHS Central East Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [34/228] E-coli | NHS Central East Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [35/228] E-coli | NHS Central East Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [36/228] E-coli | NHS Central East Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [37/228] E-coli | NHS Central East Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [38/228] E-coli | NHS Cheshire and Merseyside Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [39/228] E-coli | NHS Cheshire and Merseyside Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [40/228] E-coli | NHS Cheshire and Merseyside Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [41/228] E-coli | NHS Cheshire and Merseyside Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [42/228] E-coli | NHS Cheshire and Merseyside Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [43/228] E-coli | NHS Cornwall and the Isles of Scilly Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [44/228] E-coli | NHS Cornwall and the Isles of Scilly Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [45/228] E-coli | NHS Cornwall and the Isles of Scilly Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [46/228] E-coli | NHS Cornwall and the Isles of Scilly Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [47/228] E-coli | NHS Cornwall and the Isles of Scilly Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [48/228] E-coli | NHS Coventry and Warwickshire Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [49/228] E-coli | NHS Coventry and Warwickshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [50/228] E-coli | NHS Coventry and Warwickshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [51/228] E-coli | NHS Coventry and Warwickshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [52/228] E-coli | NHS Coventry and Warwickshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [53/228] E-coli | NHS Derby and Derbyshire Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [54/228] E-coli | NHS Derby and Derbyshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [55/228] E-coli | NHS Derby and Derbyshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [56/228] E-coli | NHS Derby and Derbyshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [57/228] E-coli | NHS Derby and Derbyshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [58/228] E-coli | NHS Devon Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [59/228] E-coli | NHS Devon Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [60/228] E-coli | NHS Devon Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [61/228] E-coli | NHS Devon Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [62/228] E-coli | NHS Devon Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [63/228] E-coli | NHS Dorset Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [64/228] E-coli | NHS Dorset Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [65/228] E-coli | NHS Dorset Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [66/228] E-coli | NHS Dorset Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [67/228] E-coli | NHS Dorset Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [68/228] E-coli | NHS Essex Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [69/228] E-coli | NHS Essex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [70/228] E-coli | NHS Essex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [71/228] E-coli | NHS Essex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [72/228] E-coli | NHS Essex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [73/228] E-coli | NHS Frimley Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [74/228] E-coli | NHS Frimley Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [75/228] E-coli | NHS Frimley Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [76/228] E-coli | NHS Frimley Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [77/228] E-coli | NHS Gloucestershire Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [78/228] E-coli | NHS Gloucestershire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [79/228] E-coli | NHS Gloucestershire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [80/228] E-coli | NHS Gloucestershire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [81/228] E-coli | NHS Gloucestershire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [82/228] E-coli | NHS Greater Manchester Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [83/228] E-coli | NHS Greater Manchester Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [84/228] E-coli | NHS Greater Manchester Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [85/228] E-coli | NHS Greater Manchester Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [86/228] E-coli | NHS Greater Manchester Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [87/228] E-coli | NHS Hampshire and Isle of Wight Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [88/228] E-coli | NHS Hampshire and Isle of Wight Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [89/228] E-coli | NHS Hampshire and Isle of Wight Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [90/228] E-coli | NHS Hampshire and Isle of Wight Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [91/228] E-coli | NHS Hampshire and Isle of Wight Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [92/228] E-coli | NHS Herefordshire and Worcestershire Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [93/228] E-coli | NHS Herefordshire and Worcestershire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [94/228] E-coli | NHS Herefordshire and Worcestershire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [95/228] E-coli | NHS Herefordshire and Worcestershire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [96/228] E-coli | NHS Herefordshire and Worcestershire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [97/228] E-coli | NHS Hertfordshire and West Essex Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [98/228] E-coli | NHS Hertfordshire and West Essex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [99/228] E-coli | NHS Hertfordshire and West Essex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [100/228] E-coli | NHS Hertfordshire and West Essex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [101/228] E-coli | NHS Humber and North Yorkshire Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [102/228] E-coli | NHS Humber and North Yorkshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [103/228] E-coli | NHS Humber and North Yorkshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [104/228] E-coli | NHS Humber and North Yorkshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [105/228] E-coli | NHS Humber and North Yorkshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [106/228] E-coli | NHS Kent and Medway Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [107/228] E-coli | NHS Kent and Medway Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [108/228] E-coli | NHS Kent and Medway Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [109/228] E-coli | NHS Kent and Medway Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [110/228] E-coli | NHS Kent and Medway Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [111/228] E-coli | NHS Lancashire and South Cumbria Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [112/228] E-coli | NHS Lancashire and South Cumbria Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [113/228] E-coli | NHS Lancashire and South Cumbria Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [114/228] E-coli | NHS Lancashire and South Cumbria Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [115/228] E-coli | NHS Lancashire and South Cumbria Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [116/228] E-coli | NHS Leicester, Leicestershire and Rutland Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [117/228] E-coli | NHS Leicester, Leicestershire and Rutland Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [118/228] E-coli | NHS Leicester, Leicestershire and Rutland Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [119/228] E-coli | NHS Leicester, Leicestershire and Rutland Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [120/228] E-coli | NHS Leicester, Leicestershire and Rutland Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [121/228] E-coli | NHS Lincolnshire Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [122/228] E-coli | NHS Lincolnshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [123/228] E-coli | NHS Lincolnshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [124/228] E-coli | NHS Lincolnshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [125/228] E-coli | NHS Lincolnshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [126/228] E-coli | NHS Mid and South Essex Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [127/228] E-coli | NHS Mid and South Essex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [128/228] E-coli | NHS Mid and South Essex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [129/228] E-coli | NHS Mid and South Essex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [130/228] E-coli | NHS Norfolk and Suffolk Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [131/228] E-coli | NHS Norfolk and Suffolk Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [132/228] E-coli | NHS Norfolk and Suffolk Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [133/228] E-coli | NHS Norfolk and Suffolk Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [134/228] E-coli | NHS Norfolk and Suffolk Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [135/228] E-coli | NHS Norfolk and Waveney Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [136/228] E-coli | NHS Norfolk and Waveney Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [137/228] E-coli | NHS Norfolk and Waveney Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [138/228] E-coli | NHS Norfolk and Waveney Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [139/228] E-coli | NHS Northamptonshire Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [140/228] E-coli | NHS Northamptonshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [141/228] E-coli | NHS Northamptonshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [142/228] E-coli | NHS Northamptonshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [143/228] E-coli | NHS Northamptonshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [144/228] E-coli | NHS North Central London Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [145/228] E-coli | NHS North Central London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [146/228] E-coli | NHS North Central London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [147/228] E-coli | NHS North Central London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [148/228] E-coli | NHS North East and North Cumbria Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [149/228] E-coli | NHS North East and North Cumbria Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [150/228] E-coli | NHS North East and North Cumbria Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [151/228] E-coli | NHS North East and North Cumbria Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [152/228] E-coli | NHS North East and North Cumbria Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [153/228] E-coli | NHS North East London Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [154/228] E-coli | NHS North East London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [155/228] E-coli | NHS North East London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [156/228] E-coli | NHS North East London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [157/228] E-coli | NHS North East London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [158/228] E-coli | NHS North West London Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [159/228] E-coli | NHS North West London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [160/228] E-coli | NHS North West London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [161/228] E-coli | NHS North West London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [162/228] E-coli | NHS Nottingham and Nottinghamshire Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [163/228] E-coli | NHS Nottingham and Nottinghamshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [164/228] E-coli | NHS Nottingham and Nottinghamshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [165/228] E-coli | NHS Nottingham and Nottinghamshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [166/228] E-coli | NHS Nottingham and Nottinghamshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [167/228] E-coli | NHS Shropshire, Telford and Wrekin Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [168/228] E-coli | NHS Shropshire, Telford and Wrekin Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [169/228] E-coli | NHS Shropshire, Telford and Wrekin Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [170/228] E-coli | NHS Shropshire, Telford and Wrekin Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [171/228] E-coli | NHS Shropshire, Telford and Wrekin Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [172/228] E-coli | NHS Somerset Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [173/228] E-coli | NHS Somerset Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [174/228] E-coli | NHS Somerset Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [175/228] E-coli | NHS Somerset Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [176/228] E-coli | NHS Somerset Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [177/228] E-coli | NHS South East London Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [178/228] E-coli | NHS South East London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [179/228] E-coli | NHS South East London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [180/228] E-coli | NHS South East London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [181/228] E-coli | NHS South East London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [182/228] E-coli | NHS South West London Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [183/228] E-coli | NHS South West London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [184/228] E-coli | NHS South West London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [185/228] E-coli | NHS South West London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [186/228] E-coli | NHS South West London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [187/228] E-coli | NHS South Yorkshire Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [188/228] E-coli | NHS South Yorkshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [189/228] E-coli | NHS South Yorkshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [190/228] E-coli | NHS South Yorkshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [191/228] E-coli | NHS South Yorkshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [192/228] E-coli | NHS Staffordshire and Stoke-on-Trent Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [193/228] E-coli | NHS Staffordshire and Stoke-on-Trent Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [194/228] E-coli | NHS Staffordshire and Stoke-on-Trent Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [195/228] E-coli | NHS Staffordshire and Stoke-on-Trent Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [196/228] E-coli | NHS Staffordshire and Stoke-on-Trent Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [197/228] E-coli | NHS Suffolk and North East Essex Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [198/228] E-coli | NHS Suffolk and North East Essex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [199/228] E-coli | NHS Suffolk and North East Essex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [200/228] E-coli | NHS Suffolk and North East Essex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [201/228] E-coli | NHS Surrey and Sussex Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [202/228] E-coli | NHS Surrey and Sussex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [203/228] E-coli | NHS Surrey and Sussex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [204/228] E-coli | NHS Surrey and Sussex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [205/228] E-coli | NHS Surrey and Sussex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [206/228] E-coli | NHS Surrey Heartlands Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [207/228] E-coli | NHS Surrey Heartlands Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [208/228] E-coli | NHS Surrey Heartlands Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [209/228] E-coli | NHS Surrey Heartlands Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [210/228] E-coli | NHS Sussex Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [211/228] E-coli | NHS Sussex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [212/228] E-coli | NHS Sussex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [213/228] E-coli | NHS Sussex Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [214/228] E-coli | NHS Thames Valley Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [215/228] E-coli | NHS Thames Valley Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [216/228] E-coli | NHS Thames Valley Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [217/228] E-coli | NHS Thames Valley Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [218/228] E-coli | NHS Thames Valley Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [219/228] E-coli | NHS West and North London Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [220/228] E-coli | NHS West and North London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [221/228] E-coli | NHS West and North London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [222/228] E-coli | NHS West and North London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [223/228] E-coli | NHS West and North London Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> [224/228] E-coli | NHS West Yorkshire Integrated Care Board | e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> [225/228] E-coli | NHS West Yorkshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> [226/228] E-coli | NHS West Yorkshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> [227/228] E-coli | NHS West Yorkshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> [228/228] E-coli | NHS West Yorkshire Integrated Care Board | e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> Saved 49,898 rows to /tmp/Rtmp00t3oZ/ecoli_icb.csv
# }
```
