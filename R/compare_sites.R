
#' Compare traffic volumes across monitoring sites
#'
#' Summarises recorded traffic volume for selected monitoring sites,
#' with optional filtering by vehicle class and date range.
#'
#' @param data A traffic data frame containing site, date, volume
#'   and vehicle_class columns.
#' @param sites Optional vector of site IDs to compare.
#' @param vehicle_class Optional vector of vehicle classes to include.
#' @param start_date Optional starting date.
#' @param end_date Optional ending date.
#'
#' @return A data frame containing site, total volume and record count.
#'
#' @examples
#' compare_sites(
#'   traffic_counts,
#'   sites = c(10001, 10002)
#' )
#'
#' @export
compare_sites <- function(
    data,
    sites = NULL,
    vehicle_class = NULL,
    start_date = NULL,
    end_date = NULL
) {
  
  required_columns <- c(
    "site", "date", "volume", "vehicle_class"
  )
  
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
  
  if (!is.null(sites)) {
    data <- data[data$site %in% sites, ]
  }
  
  if (!is.null(vehicle_class)) {
    data <- data[data$vehicle_class %in% vehicle_class, ]
  }
  
  if (!is.null(start_date)) {
    data <- data[data$date >= as.Date(start_date), ]
  }
  
  if (!is.null(end_date)) {
    data <- data[data$date <= as.Date(end_date), ]
  }
  
  if (nrow(data) == 0) {
    stop("No observations found for the selected filters.")
  }
  
  result <- aggregate(
    cbind(total_volume = data$volume, records = 1),
    by = list(site = data$site),
    FUN = sum
  )
  
  result <- result[order(-result$total_volume), ]
  
  rownames(result) <- NULL
  
  result
}
