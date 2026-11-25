# Get organisation boundaries from OpenPrescribing

Downloads the geographic boundaries (or centroids / locations) that
OpenPrescribing holds for organisations, ready to join to
[`get_op_spending`](https://vargasrichards.github.io/ukamrdataR/reference/get_op_spending.md)
results by `org_id == code` for mapping.

## Usage

``` r
get_op_boundaries(
  resolution = "icb",
  org = NULL,
  centroids = FALSE,
  as = c("sf", "geojson")
)
```

## Arguments

- resolution:

  one of `"region"`, `"icb"`, `"sicbl"`, `"pcn"`, `"practice"`.

- org:

  optional character vector of organisation codes to keep.

- centroids:

  logical; return centroids instead of polygons (only honoured for
  Sub-ICB Locations).

- as:

  `"sf"` (default; needs the sf package) or `"geojson"` for the raw
  GeoJSON text.

## Value

An `sf` object in EPSG:4326 (WGS 84) with columns `name`, `code` and a
geometry column, or the GeoJSON string.

## Details

Region, ICB and PCN boundaries are unions of the underlying Sub-ICB (or
practice) boundaries, so they are consistent with the OpenPrescribing
organisation hierarchy but may differ slightly from the ONS generalised
boundaries. Practices are returned as points.

## Examples

``` r
# \donttest{
icb <- get_op_boundaries("icb")
#> Error: OpenPrescribing refused the request (HTTP 403, a bot-protection challenge), so no data could be retrieved from /org_location/.
#> This is applied by the service to some networks and clients (for example some cloud or institutional IP ranges). Try again later or from another network, and consider reducing the request rate with options(ukhsadatR.requests_per_second = 0.5).
plot(sf::st_geometry(icb))
#> Error: object 'icb' not found
# }
```
