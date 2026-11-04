# Daily traffic reporting coverage by monitoring site

Summarises the number of reporting intervals recorded for each
monitoring site and date. A complete site-day contains all 96 expected
15-minute intervals.

## Usage

``` r
data(site_day_coverage)
```

## Format

A data frame with 8,634 rows and 6 columns:

- date:

  Date of the reporting period.

- site:

  Monitoring site identifier.

- intervals_reported:

  Number of intervals recorded.

- expected_intervals:

  Expected number of intervals (96).

- complete_day:

  Whether all expected intervals were reported.

- month:

  Month of the reporting period.

## Details

This dataset can be used to identify incomplete reporting periods when
interpreting traffic volumes.

## See also

[traffic_counts](https://etc5523-2026.github.io/etc5523-assignment-4-vikywayne/reference/traffic_counts.md)
for the underlying traffic observations.
