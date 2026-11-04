# Summarise vehicle composition

Calculates total traffic volume and the percentage contribution of each
vehicle class within selected groups.

## Usage

``` r
summarise_vehicle_mix(data, group_by = "site", classification_scheme = NULL)
```

## Arguments

- data:

  A traffic data frame containing volume and vehicle_class.

- group_by:

  Character vector of grouping columns. Supported columns are site,
  month, date, heading and classification_scheme.

- classification_scheme:

  Optional classification scheme to retain, such as "4-bin" or "12-bin".

## Value

A data frame containing the grouping columns, vehicle class, total
volume and percentage share of total volume.

## Examples

``` r
data("traffic_counts", package = "vicfreight")

example_data <- traffic_counts[
  traffic_counts$site %in% c(10001, 10002) &
    traffic_counts$date >= as.Date("2026-05-01") &
    traffic_counts$date <= as.Date("2026-05-07"),
]

summarise_vehicle_mix(
  example_data,
  group_by = "site",
  classification_scheme = "4-bin"
)
#>    site        vehicle_class total_volume share_percent
#> 1 10001        4bin: 1.Short       128182     70.912028
#> 2 10001        4bin: 2.Rigid        13839      7.655923
#> 3 10001  4bin: 3.Articulated        19156     10.597360
#> 4 10001 4bin: 4.Bdouble/HPFV        19585     10.834689
#> 5 10002        4bin: 1.Short        89544     58.931462
#> 6 10002        4bin: 2.Rigid        33728     22.197360
#> 7 10002  4bin: 3.Articulated        12513      8.235162
#> 8 10002 4bin: 4.Bdouble/HPFV        16161     10.636015
```
