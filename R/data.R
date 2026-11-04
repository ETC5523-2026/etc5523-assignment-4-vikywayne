
#' Victorian freight traffic observations
#'
#' Traffic observations collected from Victorian road monitoring
#' locations between May and October 2026. Each row represents a
#' recorded vehicle count for a particular date, time interval,
#' monitoring site, vehicle class and speed bin.
#'
#' The dataset contains the original traffic fields together with
#' additional information from the site reference data, including
#' site descriptions, coordinates and metadata matching indicators.
#'
#' @format A data frame with 12,637,766 rows and 14 columns:
#' \describe{
#'   \item{date}{Date of the traffic observation.}
#'   \item{time_bin}{15-minute observation interval.}
#'   \item{site}{Monitoring site identifier.}
#'   \item{heading}{Direction of travel.}
#'   \item{vehicle_class}{Recorded vehicle classification.}
#'   \item{speed_bin}{Vehicle speed category.}
#'   \item{volume}{Number of vehicles recorded in the interval.}
#'   \item{source_file}{Original daily CSV filename.}
#'   \item{classification_scheme}{Vehicle classification scheme used.}
#'   \item{month}{Month of the observation.}
#'   \item{site_description}{Description of the monitoring location.}
#'   \item{latitude}{Latitude of the monitoring location.}
#'   \item{longitude}{Longitude of the monitoring location.}
#'   \item{site_metadata_match}{Whether matching site metadata was found.}
#' }
#' @source Victorian Department of Transport, Telemetry Traffic Counts
#'   and Classification dataset.
#' @seealso [telemetry_sites] for monitoring site reference information
#'   and [site_day_coverage] for daily reporting coverage.
"traffic_counts"


#' Victorian traffic monitoring site reference data
#'
#' Reference information for the monitoring locations used in the
#' traffic dataset. Contains site identifiers, location descriptions
#' and geographic coordinates.
#'
#' @format A data frame with 55 rows and 4 columns:
#' \describe{
#'   \item{site}{Monitoring site identifier.}
#'   \item{site_description}{Description of the monitoring location.}
#'   \item{latitude}{Latitude of the monitoring location.}
#'   \item{longitude}{Longitude of the monitoring location.}
#' }
#' @source Victorian Department of Transport, Telemetry Traffic Counts
#'   and Classification dataset.
#' @seealso [traffic_counts]
"telemetry_sites"


#' Daily traffic reporting coverage by monitoring site
#'
#' Summarises the number of reporting intervals recorded for each
#' monitoring site and date. A complete site-day contains all 96
#' expected 15-minute intervals.
#'
#' This dataset can be used to identify incomplete reporting periods
#' when interpreting traffic volumes.
#'
#' @format A data frame with 8,634 rows and 6 columns:
#' \describe{
#'   \item{date}{Date of the reporting period.}
#'   \item{site}{Monitoring site identifier.}
#'   \item{intervals_reported}{Number of intervals recorded.}
#'   \item{expected_intervals}{Expected number of intervals (96).}
#'   \item{complete_day}{Whether all expected intervals were reported.}
#'   \item{month}{Month of the reporting period.}
#' }
#' @seealso [traffic_counts] for the underlying traffic observations.
"site_day_coverage"
