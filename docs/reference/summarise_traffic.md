# Summarise traffic volumes

Calculate total traffic volume and the number of records for selected
groups, such as monitoring sites, vehicle classes or months.

## Usage

``` r
summarise_traffic(
  data,
  group_by = c("site", "vehicle_class"),
  date_range = NULL
)
```

## Arguments

- data:

  A traffic dataset containing the columns `date` and `volume`, along
  with the variables selected in `group_by`.

- group_by:

  Character vector of variables used to group the results. Supported
  variables are `date`, `month`, `site`, `heading`, `vehicle_class`,
  `speed_bin` and `classification_scheme`. Defaults to
  `c("site", "vehicle_class")`.

- date_range:

  Optional Date vector of length two giving the inclusive start and end
  dates for the analysis.

## Value

A data frame containing the selected grouping variables, `total_volume`
and `records`, ordered by the grouping variables.

## Examples

``` r
if (FALSE) { # \dontrun{
data("traffic_counts", package = "vicfreight")
summarise_traffic(
  traffic_counts,
  group_by = c("site", "vehicle_class")
)
} # }
```
