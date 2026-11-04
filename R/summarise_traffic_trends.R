
#' Summarise traffic trends over time
#'
#' Aggregates traffic volume over daily or monthly periods,
#' optionally by monitoring site and vehicle class.
#'
#' @param data A traffic data frame containing date and volume.
#' @param period Either "daily" or "monthly".
#' @param group_by Optional grouping columns, such as site
#'   and vehicle_class.
#' @param sites Optional vector of site IDs to include.
#' @param vehicle_class Optional vector of vehicle classes to include.
#'
#' @return A data frame containing the time period, grouping columns
#'   and total traffic volume.
#'
#' @examples
#' data("traffic_counts", package = "vicfreight")
#'
#' example_data <- traffic_counts[
#'   traffic_counts$site %in% c(10001, 10002) &
#'     traffic_counts$date >= as.Date("2026-05-01") &
#'     traffic_counts$date <= as.Date("2026-05-07"),
#' ]
#'
#' summarise_traffic_trends(
#'   example_data,
#'   period = "monthly",
#'   group_by = "site"
#' )
#'
#' @export
summarise_traffic_trends <- function(
    data,
    period = "daily",
    group_by = character(0),
    sites = NULL,
    vehicle_class = NULL
) {
  
  required_columns <- c("date", "volume")
  
  missing_columns <- setdiff(required_columns, names(data))
  
  if (length(missing_columns) > 0) {
    stop(
      "Missing required columns: ",
      paste(missing_columns, collapse = ", ")
    )
  }
  
  if (!inherits(data$date, "Date")) {
    stop("The date column must be of Date class.")
  }
  
  if (!period %in% c("daily", "monthly")) {
    stop("period must be either 'daily' or 'monthly'.")
  }
  
  allowed_groups <- c(
    "site", "heading", "vehicle_class", "classification_scheme"
  )
  
  if (!all(group_by %in% allowed_groups)) {
    stop("One or more grouping columns are not supported.")
  }
  
  if (!all(group_by %in% names(data))) {
    stop("One or more grouping columns are missing from the data.")
  }
  
  if (!is.null(sites)) {
    if (!"site" %in% names(data)) {
      stop("The data does not contain a site column.")
    }
    
    data <- data[data$site %in% sites, ]
  }
  
  if (!is.null(vehicle_class)) {
    if (!"vehicle_class" %in% names(data)) {
      stop("The data does not contain a vehicle_class column.")
    }
    
    data <- data[data$vehicle_class %in% vehicle_class, ]
  }
  
  if (nrow(data) == 0) {
    stop("No observations found for the selected filters.")
  }
  
  if (period == "daily") {
    data$time_period <- data$date
  } else {
    data$time_period <- format(data$date, "%Y-%m")
  }
  
  grouping_columns <- unique(c("time_period", group_by))
  
  result <- stats::aggregate(
    data["volume"],
    by = data[grouping_columns],
    FUN = sum
  )
  
  names(result)[names(result) == "volume"] <- "total_volume"
  
  result <- result[do.call(
    order,
    result[grouping_columns]
  ), ]
  
  rownames(result) <- NULL
  
  result
}
