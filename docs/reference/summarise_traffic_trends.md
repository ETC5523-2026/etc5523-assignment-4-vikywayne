# Summarise traffic trends over time

Aggregates traffic volume over daily or monthly periods, optionally by
monitoring site and vehicle class.

## Usage

``` r
summarise_traffic_trends(
  data,
  period = "daily",
  group_by = character(0),
  sites = NULL,
  vehicle_class = NULL
)
```

## Arguments

- data:

  A traffic data frame containing date and volume.

- period:

  Either "daily" or "monthly".

- group_by:

  Optional grouping columns, such as site and vehicle_class.

- sites:

  Optional vector of site IDs to include.

- vehicle_class:

  Optional vector of vehicle classes to include.

## Value

A data frame containing the time period, grouping columns and total
traffic volume.

## Examples

``` r
data("traffic_counts", package = "vicfreight")

example_data <- traffic_counts[
  traffic_counts$site %in% c(10001, 10002) &
    traffic_counts$date >= as.Date("2026-05-01") &
    traffic_counts$date <= as.Date("2026-05-07"),
]

summarise_traffic_trends(
  example_data,
  period = "monthly",
  group_by = "site"
)
#>   time_period  site total_volume
#> 1     2026-05 10001       180908
#> 2     2026-05 10002       152026
```
