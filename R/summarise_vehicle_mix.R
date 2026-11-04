
#' Summarise vehicle composition
#'
#' Calculates total traffic volume and the percentage contribution
#' of each vehicle class within selected groups.
#'
#' @param data A traffic data frame containing volume and vehicle_class.
#' @param group_by Character vector of grouping columns.
#'   Supported columns are site, month, date, heading and
#'   classification_scheme.
#' @param classification_scheme Optional classification scheme to retain,
#'   such as "4-bin" or "12-bin".
#'
#' @return A data frame containing the grouping columns, vehicle class,
#'   total volume and percentage share of total volume.
#'
#' @examples
#' summarise_vehicle_mix(
#'   traffic_counts,
#'   group_by = c("site", "vehicle_class"),
#'   classification_scheme = "4-bin"
#' )
#'
#' @export
summarise_vehicle_mix <- function(
    data,
    group_by = "site",
    classification_scheme = NULL
) {
  
  # Check required columns
  required_columns <- c("volume", "vehicle_class")
  
  missing_columns <- setdiff(required_columns, names(data))
  
  if (length(missing_columns) > 0) {
    stop(
      "Missing required columns: ",
      paste(missing_columns, collapse = ", ")
    )
  }
  
  # Check grouping columns
  allowed_groups <- c(
    "site", "month", "date", "heading", "classification_scheme"
  )
  
  if (!all(group_by %in% allowed_groups)) {
    stop("One or more grouping columns are not supported.")
  }
  
  if (!all(group_by %in% names(data))) {
    stop("One or more grouping columns are missing from the data.")
  }
  
  # Optionally filter classification scheme
  if (!is.null(classification_scheme)) {
    
    if (!"classification_scheme" %in% names(data)) {
      stop("The data does not contain classification_scheme.")
    }
    
    data <- data[
      data$classification_scheme == classification_scheme &
        !is.na(data$classification_scheme),
    ]
  }
  
  if (nrow(data) == 0) {
    stop("No observations available after filtering.")
  }
  
  # Remove rows without a vehicle class or valid volume
  data <- data[
    !is.na(data$vehicle_class) &
      !is.na(data$volume),
  ]
  
  if (nrow(data) == 0) {
    stop("No valid vehicle observations available.")
  }
  
  # Calculate volume by group and vehicle class
  grouping_columns <- unique(c(group_by, "vehicle_class"))
  
  grouped_data <- aggregate(
    data["volume"],
    by = data[grouping_columns],
    FUN = sum
  )
  
  names(grouped_data)[names(grouped_data) == "volume"] <-
    "total_volume"
  
  # Calculate total volume within each group
  group_totals <- aggregate(
    grouped_data["total_volume"],
    by = grouped_data[group_by],
    FUN = sum
  )
  
  names(group_totals)[
    names(group_totals) == "total_volume"
  ] <- "group_total"
  
  # Calculate percentage contribution
  result <- merge(
    grouped_data,
    group_totals,
    by = group_by,
    all.x = TRUE,
    sort = FALSE
  )
  
  result$share_percent <-
    100 * result$total_volume / result$group_total
  
  result$group_total <- NULL
  
  rownames(result) <- NULL
  
  result
}
