# Get Combinations

Lists the theme / sub_theme / topic / geography_type / geography /
metric combinations that match a query, without downloading any data.
Use it to explore what is available, or to check how many datasets a
wildcard query in
[`get_data`](https://vargasrichards.github.io/ukamrdataR/reference/get_data.md)
would download.

## Usage

``` r
get_combinations(
  theme = "*",
  sub_theme = NULL,
  topic = NULL,
  geography_type = NULL,
  geography = NULL,
  metric = NULL,
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

- verbose:

  show progress messages.

## Value

               data.frame with one row per matching combination,
                       or \code{NULL} (invisibly) if the query could not be
                       resolved, in which case the available options are
                       shown as a message.

## Details

Each argument accepts a single value, a character vector of values,
`"*"` for every available value, or a glob pattern containing `*` or `?`
(for example `"NHS*London*"`).

Resolution stops at the last argument supplied, so
`get_combinations(theme = "*", sub_theme = "*")` lists every sub-theme
of every theme without looking further down the hierarchy.

## Examples

``` r
# \donttest{
# every topic in every sub-theme of infectious_disease
get_combinations(theme = "infectious_disease", sub_theme = "*", topic = "*")
#> Looking up topics for 10 combinations...
#>                 theme                     sub_theme
#> 1  infectious_disease      antimicrobial_resistance
#> 2  infectious_disease      antimicrobial_resistance
#> 3  infectious_disease      antimicrobial_resistance
#> 4  infectious_disease      antimicrobial_resistance
#> 5  infectious_disease      antimicrobial_resistance
#> 6  infectious_disease      antimicrobial_resistance
#> 7  infectious_disease                    bloodborne
#> 8  infectious_disease                    bloodborne
#> 9  infectious_disease                    bloodborne
#> 10 infectious_disease                    bloodborne
#> 11 infectious_disease         bloodstream_infection
#> 12 infectious_disease         bloodstream_infection
#> 13 infectious_disease         bloodstream_infection
#> 14 infectious_disease         bloodstream_infection
#> 15 infectious_disease         bloodstream_infection
#> 16 infectious_disease             childhood_illness
#> 17 infectious_disease                       contact
#> 18 infectious_disease                       contact
#> 19 infectious_disease                       contact
#> 20 infectious_disease              gastrointestinal
#> 21 infectious_disease              gastrointestinal
#> 22 infectious_disease invasive_bacterial_infections
#> 23 infectious_disease                   respiratory
#> 24 infectious_disease                   respiratory
#> 25 infectious_disease                   respiratory
#> 26 infectious_disease                   respiratory
#> 27 infectious_disease                   respiratory
#> 28 infectious_disease                   respiratory
#> 29 infectious_disease                   respiratory
#> 30 infectious_disease                   respiratory
#> 31 infectious_disease                   respiratory
#> 32 infectious_disease                   respiratory
#> 33 infectious_disease                   respiratory
#> 34 infectious_disease                   respiratory
#> 35 infectious_disease                   respiratory
#> 36 infectious_disease                   respiratory
#> 37 infectious_disease           vaccine_preventable
#> 38 infectious_disease                  vector_borne
#>                                topic
#> 1                             E-coli
#> 2                         E-faecalis
#> 3                          E-faecium
#> 4                       K-pneumoniae
#> 5                       P-aeruginosa
#> 6                       S-pneumoniae
#> 7                        Hepatitis-B
#> 8                        Hepatitis-C
#> 9                                HIV
#> 10                transfusion-safety
#> 11                            E-coli
#> 12                    Klebsiella-spp
#> 13                              MRSA
#> 14                              MSSA
#> 15            Pseudomonas-aeruginosa
#> 16                     Scarlet-fever
#> 17                              mpox
#> 18                     mpox-clade-1b
#> 19                     mpox-clade-2b
#> 20                       C-difficile
#> 21                         norovirus
#> 22                              iGAS
#> 23               acute-bronchiolitis
#> 24       acute-respiratory-infection
#> 25                        Adenovirus
#> 26                          COVID-19
#> 27                     COVID-19-like
#> 28                              hMPV
#> 29                         Influenza
#> 30                    influenza-like
#> 31 lower-respiratory-tract-infection
#> 32                        mycoplasma
#> 33                     Parainfluenza
#> 34                        Rhinovirus
#> 35                               RSV
#> 36 upper-respiratory-tract-infection
#> 37                           Measles
#> 38                              lyme

# every ICB and metric for E. coli resistance
get_combinations(
  theme = "infectious_disease",
  sub_theme = "antimicrobial_resistance",
  topic = "E-coli",
  geography_type = "Integrated Care Board",
  geography = "*",
  metric = "*PercentResistant*"
)
#> Looking up metrics for 48 combinations...
#>                  theme                sub_theme  topic        geography_type
#> 1   infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 2   infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 3   infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 4   infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 5   infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 6   infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 7   infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 8   infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 9   infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 10  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 11  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 12  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 13  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 14  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 15  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 16  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 17  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 18  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 19  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 20  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 21  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 22  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 23  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 24  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 25  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 26  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 27  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 28  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 29  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 30  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 31  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 32  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 33  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 34  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 35  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 36  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 37  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 38  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 39  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 40  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 41  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 42  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 43  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 44  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 45  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 46  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 47  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 48  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 49  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 50  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 51  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 52  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 53  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 54  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 55  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 56  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 57  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 58  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 59  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 60  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 61  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 62  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 63  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 64  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 65  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 66  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 67  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 68  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 69  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 70  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 71  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 72  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 73  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 74  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 75  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 76  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 77  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 78  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 79  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 80  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 81  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 82  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 83  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 84  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 85  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 86  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 87  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 88  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 89  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 90  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 91  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 92  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 93  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 94  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 95  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 96  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 97  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 98  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 99  infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 100 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 101 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 102 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 103 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 104 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 105 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 106 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 107 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 108 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 109 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 110 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 111 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 112 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 113 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 114 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 115 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 116 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 117 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 118 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 119 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 120 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 121 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 122 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 123 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 124 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 125 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 126 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 127 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 128 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 129 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 130 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 131 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 132 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 133 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 134 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 135 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 136 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 137 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 138 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 139 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 140 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 141 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 142 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 143 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 144 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 145 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 146 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 147 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 148 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 149 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 150 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 151 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 152 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 153 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 154 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 155 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 156 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 157 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 158 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 159 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 160 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 161 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 162 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 163 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 164 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 165 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 166 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 167 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 168 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 169 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 170 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 171 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 172 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 173 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 174 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 175 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 176 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 177 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 178 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 179 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 180 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 181 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 182 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 183 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 184 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 185 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 186 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 187 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 188 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 189 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 190 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 191 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 192 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 193 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 194 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 195 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 196 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 197 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 198 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 199 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 200 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 201 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 202 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 203 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 204 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 205 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 206 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 207 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 208 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 209 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 210 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 211 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 212 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 213 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 214 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 215 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 216 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 217 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 218 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 219 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 220 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 221 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 222 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 223 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 224 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 225 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 226 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 227 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#> 228 infectious_disease antimicrobial_resistance E-coli Integrated Care Board
#>                                                                         geography
#> 1   NHS Bath and North East Somerset, Swindon and Wiltshire Integrated Care Board
#> 2   NHS Bath and North East Somerset, Swindon and Wiltshire Integrated Care Board
#> 3   NHS Bath and North East Somerset, Swindon and Wiltshire Integrated Care Board
#> 4   NHS Bath and North East Somerset, Swindon and Wiltshire Integrated Care Board
#> 5   NHS Bath and North East Somerset, Swindon and Wiltshire Integrated Care Board
#> 6                 NHS Bedfordshire, Luton and Milton Keynes Integrated Care Board
#> 7                 NHS Bedfordshire, Luton and Milton Keynes Integrated Care Board
#> 8                 NHS Bedfordshire, Luton and Milton Keynes Integrated Care Board
#> 9                 NHS Bedfordshire, Luton and Milton Keynes Integrated Care Board
#> 10                              NHS Birmingham and Solihull Integrated Care Board
#> 11                              NHS Birmingham and Solihull Integrated Care Board
#> 12                              NHS Birmingham and Solihull Integrated Care Board
#> 13                              NHS Birmingham and Solihull Integrated Care Board
#> 14                              NHS Birmingham and Solihull Integrated Care Board
#> 15                                        NHS Black Country Integrated Care Board
#> 16                                        NHS Black Country Integrated Care Board
#> 17                                        NHS Black Country Integrated Care Board
#> 18                                        NHS Black Country Integrated Care Board
#> 19                                        NHS Black Country Integrated Care Board
#> 20    NHS Bristol, North Somerset and South Gloucestershire Integrated Care Board
#> 21    NHS Bristol, North Somerset and South Gloucestershire Integrated Care Board
#> 22    NHS Bristol, North Somerset and South Gloucestershire Integrated Care Board
#> 23    NHS Bristol, North Somerset and South Gloucestershire Integrated Care Board
#> 24    NHS Bristol, North Somerset and South Gloucestershire Integrated Care Board
#> 25      NHS Buckinghamshire, Oxfordshire and Berkshire West Integrated Care Board
#> 26      NHS Buckinghamshire, Oxfordshire and Berkshire West Integrated Care Board
#> 27      NHS Buckinghamshire, Oxfordshire and Berkshire West Integrated Care Board
#> 28      NHS Buckinghamshire, Oxfordshire and Berkshire West Integrated Care Board
#> 29                      NHS Cambridgeshire and Peterborough Integrated Care Board
#> 30                      NHS Cambridgeshire and Peterborough Integrated Care Board
#> 31                      NHS Cambridgeshire and Peterborough Integrated Care Board
#> 32                      NHS Cambridgeshire and Peterborough Integrated Care Board
#> 33                                         NHS Central East Integrated Care Board
#> 34                                         NHS Central East Integrated Care Board
#> 35                                         NHS Central East Integrated Care Board
#> 36                                         NHS Central East Integrated Care Board
#> 37                                         NHS Central East Integrated Care Board
#> 38                              NHS Cheshire and Merseyside Integrated Care Board
#> 39                              NHS Cheshire and Merseyside Integrated Care Board
#> 40                              NHS Cheshire and Merseyside Integrated Care Board
#> 41                              NHS Cheshire and Merseyside Integrated Care Board
#> 42                              NHS Cheshire and Merseyside Integrated Care Board
#> 43                     NHS Cornwall and the Isles of Scilly Integrated Care Board
#> 44                     NHS Cornwall and the Isles of Scilly Integrated Care Board
#> 45                     NHS Cornwall and the Isles of Scilly Integrated Care Board
#> 46                     NHS Cornwall and the Isles of Scilly Integrated Care Board
#> 47                     NHS Cornwall and the Isles of Scilly Integrated Care Board
#> 48                            NHS Coventry and Warwickshire Integrated Care Board
#> 49                            NHS Coventry and Warwickshire Integrated Care Board
#> 50                            NHS Coventry and Warwickshire Integrated Care Board
#> 51                            NHS Coventry and Warwickshire Integrated Care Board
#> 52                            NHS Coventry and Warwickshire Integrated Care Board
#> 53                                 NHS Derby and Derbyshire Integrated Care Board
#> 54                                 NHS Derby and Derbyshire Integrated Care Board
#> 55                                 NHS Derby and Derbyshire Integrated Care Board
#> 56                                 NHS Derby and Derbyshire Integrated Care Board
#> 57                                 NHS Derby and Derbyshire Integrated Care Board
#> 58                                                NHS Devon Integrated Care Board
#> 59                                                NHS Devon Integrated Care Board
#> 60                                                NHS Devon Integrated Care Board
#> 61                                                NHS Devon Integrated Care Board
#> 62                                                NHS Devon Integrated Care Board
#> 63                                               NHS Dorset Integrated Care Board
#> 64                                               NHS Dorset Integrated Care Board
#> 65                                               NHS Dorset Integrated Care Board
#> 66                                               NHS Dorset Integrated Care Board
#> 67                                               NHS Dorset Integrated Care Board
#> 68                                                NHS Essex Integrated Care Board
#> 69                                                NHS Essex Integrated Care Board
#> 70                                                NHS Essex Integrated Care Board
#> 71                                                NHS Essex Integrated Care Board
#> 72                                                NHS Essex Integrated Care Board
#> 73                                              NHS Frimley Integrated Care Board
#> 74                                              NHS Frimley Integrated Care Board
#> 75                                              NHS Frimley Integrated Care Board
#> 76                                              NHS Frimley Integrated Care Board
#> 77                                      NHS Gloucestershire Integrated Care Board
#> 78                                      NHS Gloucestershire Integrated Care Board
#> 79                                      NHS Gloucestershire Integrated Care Board
#> 80                                      NHS Gloucestershire Integrated Care Board
#> 81                                      NHS Gloucestershire Integrated Care Board
#> 82                                   NHS Greater Manchester Integrated Care Board
#> 83                                   NHS Greater Manchester Integrated Care Board
#> 84                                   NHS Greater Manchester Integrated Care Board
#> 85                                   NHS Greater Manchester Integrated Care Board
#> 86                                   NHS Greater Manchester Integrated Care Board
#> 87                          NHS Hampshire and Isle of Wight Integrated Care Board
#> 88                          NHS Hampshire and Isle of Wight Integrated Care Board
#> 89                          NHS Hampshire and Isle of Wight Integrated Care Board
#> 90                          NHS Hampshire and Isle of Wight Integrated Care Board
#> 91                          NHS Hampshire and Isle of Wight Integrated Care Board
#> 92                     NHS Herefordshire and Worcestershire Integrated Care Board
#> 93                     NHS Herefordshire and Worcestershire Integrated Care Board
#> 94                     NHS Herefordshire and Worcestershire Integrated Care Board
#> 95                     NHS Herefordshire and Worcestershire Integrated Care Board
#> 96                     NHS Herefordshire and Worcestershire Integrated Care Board
#> 97                         NHS Hertfordshire and West Essex Integrated Care Board
#> 98                         NHS Hertfordshire and West Essex Integrated Care Board
#> 99                         NHS Hertfordshire and West Essex Integrated Care Board
#> 100                        NHS Hertfordshire and West Essex Integrated Care Board
#> 101                          NHS Humber and North Yorkshire Integrated Care Board
#> 102                          NHS Humber and North Yorkshire Integrated Care Board
#> 103                          NHS Humber and North Yorkshire Integrated Care Board
#> 104                          NHS Humber and North Yorkshire Integrated Care Board
#> 105                          NHS Humber and North Yorkshire Integrated Care Board
#> 106                                     NHS Kent and Medway Integrated Care Board
#> 107                                     NHS Kent and Medway Integrated Care Board
#> 108                                     NHS Kent and Medway Integrated Care Board
#> 109                                     NHS Kent and Medway Integrated Care Board
#> 110                                     NHS Kent and Medway Integrated Care Board
#> 111                        NHS Lancashire and South Cumbria Integrated Care Board
#> 112                        NHS Lancashire and South Cumbria Integrated Care Board
#> 113                        NHS Lancashire and South Cumbria Integrated Care Board
#> 114                        NHS Lancashire and South Cumbria Integrated Care Board
#> 115                        NHS Lancashire and South Cumbria Integrated Care Board
#> 116               NHS Leicester, Leicestershire and Rutland Integrated Care Board
#> 117               NHS Leicester, Leicestershire and Rutland Integrated Care Board
#> 118               NHS Leicester, Leicestershire and Rutland Integrated Care Board
#> 119               NHS Leicester, Leicestershire and Rutland Integrated Care Board
#> 120               NHS Leicester, Leicestershire and Rutland Integrated Care Board
#> 121                                        NHS Lincolnshire Integrated Care Board
#> 122                                        NHS Lincolnshire Integrated Care Board
#> 123                                        NHS Lincolnshire Integrated Care Board
#> 124                                        NHS Lincolnshire Integrated Care Board
#> 125                                        NHS Lincolnshire Integrated Care Board
#> 126                                 NHS Mid and South Essex Integrated Care Board
#> 127                                 NHS Mid and South Essex Integrated Care Board
#> 128                                 NHS Mid and South Essex Integrated Care Board
#> 129                                 NHS Mid and South Essex Integrated Care Board
#> 130                                 NHS Norfolk and Suffolk Integrated Care Board
#> 131                                 NHS Norfolk and Suffolk Integrated Care Board
#> 132                                 NHS Norfolk and Suffolk Integrated Care Board
#> 133                                 NHS Norfolk and Suffolk Integrated Care Board
#> 134                                 NHS Norfolk and Suffolk Integrated Care Board
#> 135                                 NHS Norfolk and Waveney Integrated Care Board
#> 136                                 NHS Norfolk and Waveney Integrated Care Board
#> 137                                 NHS Norfolk and Waveney Integrated Care Board
#> 138                                 NHS Norfolk and Waveney Integrated Care Board
#> 139                                    NHS Northamptonshire Integrated Care Board
#> 140                                    NHS Northamptonshire Integrated Care Board
#> 141                                    NHS Northamptonshire Integrated Care Board
#> 142                                    NHS Northamptonshire Integrated Care Board
#> 143                                    NHS Northamptonshire Integrated Care Board
#> 144                                NHS North Central London Integrated Care Board
#> 145                                NHS North Central London Integrated Care Board
#> 146                                NHS North Central London Integrated Care Board
#> 147                                NHS North Central London Integrated Care Board
#> 148                        NHS North East and North Cumbria Integrated Care Board
#> 149                        NHS North East and North Cumbria Integrated Care Board
#> 150                        NHS North East and North Cumbria Integrated Care Board
#> 151                        NHS North East and North Cumbria Integrated Care Board
#> 152                        NHS North East and North Cumbria Integrated Care Board
#> 153                                   NHS North East London Integrated Care Board
#> 154                                   NHS North East London Integrated Care Board
#> 155                                   NHS North East London Integrated Care Board
#> 156                                   NHS North East London Integrated Care Board
#> 157                                   NHS North East London Integrated Care Board
#> 158                                   NHS North West London Integrated Care Board
#> 159                                   NHS North West London Integrated Care Board
#> 160                                   NHS North West London Integrated Care Board
#> 161                                   NHS North West London Integrated Care Board
#> 162                      NHS Nottingham and Nottinghamshire Integrated Care Board
#> 163                      NHS Nottingham and Nottinghamshire Integrated Care Board
#> 164                      NHS Nottingham and Nottinghamshire Integrated Care Board
#> 165                      NHS Nottingham and Nottinghamshire Integrated Care Board
#> 166                      NHS Nottingham and Nottinghamshire Integrated Care Board
#> 167                      NHS Shropshire, Telford and Wrekin Integrated Care Board
#> 168                      NHS Shropshire, Telford and Wrekin Integrated Care Board
#> 169                      NHS Shropshire, Telford and Wrekin Integrated Care Board
#> 170                      NHS Shropshire, Telford and Wrekin Integrated Care Board
#> 171                      NHS Shropshire, Telford and Wrekin Integrated Care Board
#> 172                                            NHS Somerset Integrated Care Board
#> 173                                            NHS Somerset Integrated Care Board
#> 174                                            NHS Somerset Integrated Care Board
#> 175                                            NHS Somerset Integrated Care Board
#> 176                                            NHS Somerset Integrated Care Board
#> 177                                   NHS South East London Integrated Care Board
#> 178                                   NHS South East London Integrated Care Board
#> 179                                   NHS South East London Integrated Care Board
#> 180                                   NHS South East London Integrated Care Board
#> 181                                   NHS South East London Integrated Care Board
#> 182                                   NHS South West London Integrated Care Board
#> 183                                   NHS South West London Integrated Care Board
#> 184                                   NHS South West London Integrated Care Board
#> 185                                   NHS South West London Integrated Care Board
#> 186                                   NHS South West London Integrated Care Board
#> 187                                     NHS South Yorkshire Integrated Care Board
#> 188                                     NHS South Yorkshire Integrated Care Board
#> 189                                     NHS South Yorkshire Integrated Care Board
#> 190                                     NHS South Yorkshire Integrated Care Board
#> 191                                     NHS South Yorkshire Integrated Care Board
#> 192                    NHS Staffordshire and Stoke-on-Trent Integrated Care Board
#> 193                    NHS Staffordshire and Stoke-on-Trent Integrated Care Board
#> 194                    NHS Staffordshire and Stoke-on-Trent Integrated Care Board
#> 195                    NHS Staffordshire and Stoke-on-Trent Integrated Care Board
#> 196                    NHS Staffordshire and Stoke-on-Trent Integrated Care Board
#> 197                        NHS Suffolk and North East Essex Integrated Care Board
#> 198                        NHS Suffolk and North East Essex Integrated Care Board
#> 199                        NHS Suffolk and North East Essex Integrated Care Board
#> 200                        NHS Suffolk and North East Essex Integrated Care Board
#> 201                                   NHS Surrey and Sussex Integrated Care Board
#> 202                                   NHS Surrey and Sussex Integrated Care Board
#> 203                                   NHS Surrey and Sussex Integrated Care Board
#> 204                                   NHS Surrey and Sussex Integrated Care Board
#> 205                                   NHS Surrey and Sussex Integrated Care Board
#> 206                                   NHS Surrey Heartlands Integrated Care Board
#> 207                                   NHS Surrey Heartlands Integrated Care Board
#> 208                                   NHS Surrey Heartlands Integrated Care Board
#> 209                                   NHS Surrey Heartlands Integrated Care Board
#> 210                                              NHS Sussex Integrated Care Board
#> 211                                              NHS Sussex Integrated Care Board
#> 212                                              NHS Sussex Integrated Care Board
#> 213                                              NHS Sussex Integrated Care Board
#> 214                                       NHS Thames Valley Integrated Care Board
#> 215                                       NHS Thames Valley Integrated Care Board
#> 216                                       NHS Thames Valley Integrated Care Board
#> 217                                       NHS Thames Valley Integrated Care Board
#> 218                                       NHS Thames Valley Integrated Care Board
#> 219                               NHS West and North London Integrated Care Board
#> 220                               NHS West and North London Integrated Care Board
#> 221                               NHS West and North London Integrated Care Board
#> 222                               NHS West and North London Integrated Care Board
#> 223                               NHS West and North London Integrated Care Board
#> 224                                      NHS West Yorkshire Integrated Care Board
#> 225                                      NHS West Yorkshire Integrated Care Board
#> 226                                      NHS West Yorkshire Integrated Care Board
#> 227                                      NHS West Yorkshire Integrated Care Board
#> 228                                      NHS West Yorkshire Integrated Care Board
#>                                                               metric
#> 1             e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 2   e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 3    e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 4           e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 5     e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 6             e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 7   e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 8    e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 9           e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 10            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 11  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 12   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 13          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 14    e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 15            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 16  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 17   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 18          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 19    e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 20            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 21  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 22   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 23          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 24    e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 25            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 26  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 27   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 28          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 29            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 30  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 31   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 32          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 33            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 34  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 35   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 36          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 37    e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 38            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 39  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 40   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 41          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 42    e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 43            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 44  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 45   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 46          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 47    e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 48            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 49  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 50   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 51          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 52    e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 53            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 54  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 55   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 56          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 57    e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 58            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 59  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 60   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 61          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 62    e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 63            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 64  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 65   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 66          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 67    e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 68            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 69  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 70   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 71          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 72    e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 73            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 74  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 75   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 76          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 77            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 78  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 79   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 80          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 81    e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 82            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 83  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 84   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 85          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 86    e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 87            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 88  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 89   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 90          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 91    e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 92            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 93  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 94   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 95          e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 96    e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 97            e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 98  e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 99   e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 100         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 101           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 102 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 103  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 104         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 105   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 106           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 107 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 108  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 109         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 110   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 111           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 112 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 113  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 114         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 115   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 116           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 117 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 118  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 119         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 120   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 121           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 122 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 123  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 124         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 125   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 126           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 127 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 128  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 129         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 130           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 131 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 132  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 133         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 134   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 135           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 136 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 137  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 138         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 139           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 140 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 141  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 142         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 143   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 144           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 145 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 146  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 147         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 148           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 149 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 150  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 151         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 152   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 153           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 154 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 155  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 156         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 157   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 158           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 159 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 160  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 161         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 162           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 163 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 164  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 165         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 166   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 167           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 168 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 169  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 170         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 171   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 172           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 173 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 174  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 175         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 176   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 177           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 178 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 179  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 180         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 181   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 182           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 183 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 184  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 185         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 186   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 187           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 188 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 189  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 190         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 191   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 192           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 193 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 194  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 195         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 196   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 197           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 198 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 199  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 200         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 201           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 202 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 203  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 204         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 205   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 206           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 207 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 208  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 209         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 210           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 211 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 212  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 213         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 214           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 215 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 216  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 217         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 218   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 219           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 220 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 221  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 222         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 223   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
#> 224           e-coli_testing_bacteraemiaPercentResistantRollingMonth
#> 225 e-coli_testing_bacteriuriaPercentResistantRollingMonthAcuteTrust
#> 226  e-coli_testing_bacteriuriaPercentResistantRollingMonthAllMedFac
#> 227         e-coli_testing_bacteriuriaPercentResistantRollingMonthGP
#> 228   e-coli_testing_bacteriuriaPercentResistantRollingMonthHospital
# }
```
