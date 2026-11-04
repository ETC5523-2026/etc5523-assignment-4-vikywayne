
#' Summarise traffic volumes
#'
#' Calculate total traffic volume and the number of records for selected
#' groups, such as monitoring sites, vehicle classes or months.
#'
#' @param data A traffic dataset containing the columns `date` and `volume`,
#'   along with the variables selected in `group_by`.
#' @param group_by Character vector of variables used to group the results.
#'   Supported variables are `date`, `month`, `site`, `heading`,
#'   `vehicle_class`, `speed_bin` and `classification_scheme`.
#'   Defaults to `c("site", "vehicle_class")`.
#' @param date_range Optional Date vector of length two giving the inclusive
#'   start and end dates for the analysis.
#'
#' @return A data frame containing the selected grouping variables,
#'   `total_volume` and `records`, ordered by the grouping variables.
#'
#' @examples
#' \dontrun{
#' data("traffic_counts", package = "vicfreight")
#' summarise_traffic(
#'   traffic_counts,
#'   group_by = c("site", "vehicle_class")
#' )
#' }
#'
#' @export
summarise_traffic <- function(
    data,
    group_by = c("site", "vehicle_class"),
    date_range = NULL
) {
  
  # Check input data
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.")
  }
  
  required_columns <- c("date", "volume")
  
  missing_required <- setdiff(
    required_columns,
    names(data)
  )
  
  if (length(missing_required) > 0) {
    stop(
      "Missing required columns: ",
      paste(missing_required, collapse = ", ")
    )
  }
  
  # Check grouping variables
  allowed_groups <- c(
    "date",
    "month",
    "site",
    "heading",
    "vehicle_class",
    "speed_bin",
    "classification_scheme"
  )
  
  if (
    !is.character(group_by) ||
    length(group_by) == 0 ||
    anyNA(group_by)
  ) {
    stop("`group_by` must be a non-empty character vector.")
  }
  
  if (anyDuplicated(group_by)) {
    stop("`group_by` cannot contain duplicate variables.")
  }
  
  invalid_groups <- setdiff(
    group_by,
    allowed_groups
  )
  
  if (length(invalid_groups) > 0) {
    stop(
      "Unsupported grouping variables: ",
      paste(invalid_groups, collapse = ", ")
    )
  }
  
  missing_groups <- setdiff(
    group_by,
    names(data)
  )
  
  if (length(missing_groups) > 0) {
    stop(
      "Grouping variables not found in data: ",
      paste(missing_groups, collapse = ", ")
    )
  }
  
  # Validate date range
  if (!is.null(date_range)) {
    
    if (
      !inherits(date_range, "Date") ||
      length(date_range) != 2 ||
      anyNA(date_range)
    ) {
      stop(
        "`date_range` must contain two valid Date values."
      )
    }
    
    if (date_range[1] > date_range[2]) {
      stop("The start date must not be after the end date.")
    }
    
    data <- data[
      data$date >= date_range[1] &
        data$date <= date_range[2],
      ,
      drop = FALSE
    ]
    
  }
  
  # Handle empty selections
  if (nrow(data) == 0) {
    stop(
      "No traffic records are available for the selected filters."
    )
  }
  
  # Check volume values
  if (!is.numeric(data$volume)) {
    stop("The `volume` column must be numeric.")
  }
  
  if (anyNA(data$volume)) {
    stop(
      "The `volume` column contains missing values. ",
      "Resolve them before summarising."
    )
  }
  
  # Calculate total volume for each group
  result <- stats::aggregate(
    data["volume"],
    by = data[group_by],
    FUN = sum
  )
  
  names(result)[
    names(result) == "volume"
  ] <- "total_volume"
  
  # Count the number of source records in each group
  record_counts <- stats::aggregate(
    rep(1L, nrow(data)),
    by = data[group_by],
    FUN = sum
  )
  
  names(record_counts)[
    names(record_counts) == "x"
  ] <- "records"
  
  # Combine totals and record counts
  result <- merge(
    result,
    record_counts,
    by = group_by,
    sort = TRUE
  )
  
  row.names(result) <- NULL
  
  result
}
