# Compare traffic volumes across monitoring sites

Summarises recorded traffic volume for selected monitoring sites, with
optional filtering by vehicle class and date range.

## Usage

``` r
compare_sites(
  data,
  sites = NULL,
  vehicle_class = NULL,
  start_date = NULL,
  end_date = NULL
)
```

## Arguments

- data:

  A traffic data frame containing site, date, volume and vehicle_class
  columns.

- sites:

  Optional vector of site IDs to compare.

- vehicle_class:

  Optional vector of vehicle classes to include.

- start_date:

  Optional starting date.

- end_date:

  Optional ending date.

## Value

A data frame containing site, total volume and record count.

## Examples

``` r
data("traffic_counts", package = "vicfreight")

example_data <- traffic_counts[
  traffic_counts$site %in% c(10001, 10002) &
    traffic_counts$date >= as.Date("2026-05-01") &
    traffic_counts$date <= as.Date("2026-05-07"),
]

compare_sites(
  example_data,
  sites = c(10001, 10002)
)
#>    site total_volume records
#> 1 10001       180908   23043
#> 2 10002       152026   24263
```
