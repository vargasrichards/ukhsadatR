# BNF antibacterial drug classes (BNF section 5.1)

The sub-sections of BNF chapter 5, section 1 ("Antibacterial drugs"),
with the BNF codes that
[`get_op_spending`](https://vargasrichards.github.io/ukamrdataR/reference/get_op_spending.md)
accepts. Use it to pick classes for
[`get_op_antibiotics`](https://vargasrichards.github.io/ukamrdataR/reference/get_op_antibiotics.md).

## Usage

``` r
op_antibiotic_classes()
```

## Value

A data.frame with columns `number` (BNF section number, e.g. `"5.1.1"`),
`code` (BNF code prefix, e.g. `"050101"`) and `class`. The first row is
the whole of section 5.1.

## Details

The classes follow the BNF's own grouping, which is by drug class or use
rather than by AWaRe category, ATC group or the UKHSA/ESPAUR
definitions, and some classes straddle those (for example 5.1.7 and
5.1.13 mix agents). Section 5.1.9 (antituberculosis) and 5.1.10
(antileprotic) are included for completeness but are normally excluded
from community antibiotic-stewardship analyses. BNF classification is
revised over time; confirm any code you rely on with
[`search_op_bnf`](https://vargasrichards.github.io/ukamrdataR/reference/search_op_bnf.md).

## Examples

``` r
op_antibiotic_classes()
#>    number   code                                              class
#> 1     5.1   0501                            All antibacterial drugs
#> 2   5.1.1 050101                                        Penicillins
#> 3   5.1.2 050102 Cephalosporins, carbapenems and other beta-lactams
#> 4   5.1.3 050103                                      Tetracyclines
#> 5   5.1.4 050104                                    Aminoglycosides
#> 6   5.1.5 050105                                         Macrolides
#> 7   5.1.6 050106                         Clindamycin and lincomycin
#> 8   5.1.7 050107                             Some other antibiotics
#> 9   5.1.8 050108                      Sulfonamides and trimethoprim
#> 10  5.1.9 050109                             Antituberculosis drugs
#> 11 5.1.10 050110                                 Antileprotic drugs
#> 12 5.1.11 050111           Metronidazole, tinidazole and ornidazole
#> 13 5.1.12 050112                                         Quinolones
#> 14 5.1.13 050113                           Urinary-tract infections
```
