# Victorian freight traffic observations

Traffic observations collected from Victorian road monitoring locations
between May and October 2026. Each row represents a recorded vehicle
count for a particular date, time interval, monitoring site, vehicle
class and speed bin.

## Usage

``` r
data(traffic_counts)
```

## Format

A data frame with 12,637,766 rows and 14 columns:

- date:

  Date of the traffic observation.

- time_bin:

  15-minute observation interval.

- site:

  Monitoring site identifier.

- heading:

  Direction of travel.

- vehicle_class:

  Recorded vehicle classification.

- speed_bin:

  Vehicle speed category.

- volume:

  Number of vehicles recorded in the interval.

- source_file:

  Original daily CSV filename.

- classification_scheme:

  Vehicle classification scheme used.

- month:

  Month of the observation.

- site_description:

  Description of the monitoring location.

- latitude:

  Latitude of the monitoring location.

- longitude:

  Longitude of the monitoring location.

- site_metadata_match:

  Whether matching site metadata was found.

## Source

Victorian Department of Transport, Telemetry Traffic Counts and
Classification dataset.

## Details

The dataset contains the original traffic fields together with
additional information from the site reference data, including site
descriptions, coordinates and metadata matching indicators.

## See also

[telemetry_sites](https://etc5523-2026.github.io/etc5523-assignment-4-vikywayne/reference/telemetry_sites.md)
for monitoring site reference information and
[site_day_coverage](https://etc5523-2026.github.io/etc5523-assignment-4-vikywayne/reference/site_day_coverage.md)
for daily reporting coverage.
