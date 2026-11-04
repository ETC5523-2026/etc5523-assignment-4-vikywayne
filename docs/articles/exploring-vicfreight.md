# Exploring VICFREIGHT

## Introduction

VICFREIGHT is an R package for exploring Victorian road traffic
activity, with an emphasis on heavy-vehicle movements, vehicle
composition, traffic patterns across monitoring locations and reporting
completeness.

It is intended for users interested in investigating how traffic
activity varies across monitoring locations and time. The package
combines prepared traffic datasets, analytical functions and an
interactive Shiny dashboard.

This vignette introduces the included datasets, explains how to install
and launch the dashboard, and describes how to interpret its main
outputs.

## Installation

The package can be installed directly from its GitHub repository using
`devtools`.

``` r

install.packages("devtools")

devtools::install_github(
  "ETC5523-2026/etc5523-assignment-4-vikywayne"
)
```

Once installed, load the package:

``` r

library(vicfreight)
```

## Included datasets

VICFREIGHT includes three prepared datasets:

- `traffic_counts`: Traffic observations recorded at monitoring
  locations, including dates, fifteen-minute intervals, vehicle
  classifications, headings, speed categories and traffic volumes.
- `telemetry_sites`: Monitoring site descriptions and geographic
  coordinates.
- `site_day_coverage`: Reporting coverage for each monitoring site and
  date, including the number of intervals reported and whether the day
  is complete.

The datasets can be accessed after installing the package.

``` r

data("traffic_counts", package = "vicfreight")
data("telemetry_sites", package = "vicfreight")
data("site_day_coverage", package = "vicfreight")

head(traffic_counts)
head(telemetry_sites)
head(site_day_coverage)
```

The package includes a prepared snapshot of traffic monitoring data
covering May to October 2026. The included datasets are fixed to this
collection period and are not automatically refreshed when new
observations become available from the original data source. The
`data-raw` scripts document the preparation process used to generate the
packaged datasets.

The traffic observations are recorded in fifteen-minute intervals. A
complete reporting day is expected to contain 96 intervals for a
monitoring site.

Incomplete reporting days and traffic observations without matching site
metadata are retained in the prepared datasets. This allows users to
examine reporting coverage and recognise limitations in the available
site information.

## Launching the dashboard

The package includes an interactive Shiny dashboard. It can be launched
using the exported
[`run_vicfreight()`](https://etc5523-2026.github.io/etc5523-assignment-4-vikywayne/reference/run_vicfreight.md)
function.

``` r

vicfreight::run_vicfreight()
```

The dashboard uses the datasets included in the installed package. Users
do not need to download or provide the original CSV files to run the
application.

## Using the dashboard

The dashboard contains four main sections.

### Overview

The Overview section introduces the monitoring locations and provides a
geographical view of traffic activity. It also presents traffic summary
information and vehicle composition.

Users can explore the monitoring locations and use the playback controls
to examine how the displayed traffic activity changes over the selected
time sequence.

The map represents monitoring locations and their recorded activity. It
should not be interpreted as showing individual vehicle movements or
vehicle routes.

### Site comparison

The Site comparison section allows users to select monitoring locations,
a date range and a vehicle classification.

The displayed chart and summary table update according to these
selections. This helps users compare recorded traffic volumes across
selected sites and examine differences in activity over the chosen
period.

When interpreting comparisons, users should consider the reporting
coverage of the selected sites. A lower recorded volume may reflect
incomplete reporting as well as lower observed traffic activity.

### Traffic trends

The Traffic trends section allows users to examine traffic activity over
daily or monthly periods. Users can select monitoring locations, date
ranges and vehicle classifications.

The time-series chart helps identify changes and patterns in recorded
traffic volumes over time. The accompanying summary table provides the
corresponding aggregated values.

Daily trends can reveal shorter-term changes, while monthly summaries
provide a broader view of activity. Gaps in reporting should be
considered when interpreting apparent changes in the series.

### Reporting coverage

The Reporting coverage section examines the completeness of traffic
reporting across monitoring locations and dates.

It includes summaries of complete and incomplete site-days, reporting
coverage by month, average reported intervals by site and a table of
incomplete reporting days.

A complete site-day contains all 96 expected fifteen-minute intervals.
An incomplete site-day contains fewer than 96 reported intervals.

This section is important when interpreting the other dashboard outputs.
Traffic summaries are based on recorded observations, so incomplete
reporting may affect comparisons and apparent trends.

## Interpreting the outputs

The dashboard supports exploration of three related aspects of Victorian
traffic monitoring:

1.  **Traffic activity:** Recorded traffic volumes and how they vary
    across monitoring locations and time.
2.  **Vehicle composition:** The distribution of recorded vehicle
    classifications and the relative contribution of different vehicle
    groups.
3.  **Reporting coverage:** The completeness of the observations used to
    examine traffic activity.

These aspects should be considered together. For example, differences in
traffic volumes between two monitoring locations should not
automatically be interpreted as differences in actual traffic activity
without considering whether both locations have comparable reporting
coverage.

Similarly, an apparent change in a daily traffic trend should be
considered alongside any missing reporting intervals during the relevant
period.

## Analytical functions

In addition to the dashboard, VICFREIGHT provides exported functions for
working with the included traffic data:

- [`summarise_traffic()`](https://etc5523-2026.github.io/etc5523-assignment-4-vikywayne/reference/summarise_traffic.md)
  summarises traffic observations using selected grouping variables and
  filters.
- [`compare_sites()`](https://etc5523-2026.github.io/etc5523-assignment-4-vikywayne/reference/compare_sites.md)
  compares traffic activity across selected monitoring locations.
- [`summarise_vehicle_mix()`](https://etc5523-2026.github.io/etc5523-assignment-4-vikywayne/reference/summarise_vehicle_mix.md)
  summarises vehicle composition and percentage shares.
- [`summarise_traffic_trends()`](https://etc5523-2026.github.io/etc5523-assignment-4-vikywayne/reference/summarise_traffic_trends.md)
  summarises traffic activity over daily or monthly periods.

Detailed usage information for each function is available in the package
reference documentation.

## Limitations

The outputs describe recorded traffic observations rather than a
complete census of all road movements. Reporting gaps, incomplete
site-days and unmatched site metadata should be considered when
interpreting results.

The monitoring locations also represent specific points in the road
network. Their observations should not automatically be treated as
representative of all roads or traffic across Victoria.

The dashboard is intended to support exploratory investigation and
comparison, rather than establish causal explanations for observed
traffic patterns.

## Conclusion

VICFREIGHT brings together prepared Victorian traffic data, analytical
functions and an interactive dashboard to support the exploration of
freight-related road activity.

By examining traffic volumes, vehicle composition and reporting coverage
together, users can investigate patterns across monitoring locations
while recognising the limitations of the available observations.
