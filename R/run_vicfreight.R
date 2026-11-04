
#' Run the VICFREIGHT dashboard
#'
#' Launches the interactive Shiny application included with the
#' vicfreight package.
#'
#' @return Opens the VICFREIGHT Shiny application.
#' @export
#'
#' @examples
#' \dontrun{
#' run_vicfreight()
#' }
run_vicfreight <- function() {
  
  required_packages <- c(
    "shiny",
    "ggplot2",
    "leaflet",
    "plotly"
  )
  
  missing_packages <- required_packages[
    !vapply(
      required_packages,
      requireNamespace,
      logical(1),
      quietly = TRUE
    )
  ]
  
  if (length(missing_packages) > 0) {
    stop(
      "The VICFREIGHT dashboard requires these packages: ",
      paste(missing_packages, collapse = ", "),
      ". Please install them before launching the application.",
      call. = FALSE
    )
  }
  
  app_dir <- system.file(
    "app",
    package = "vicfreight"
  )
  
  if (!nzchar(app_dir) || !dir.exists(app_dir)) {
    stop(
      "The VICFREIGHT application files could not be found. ",
      "Please reinstall the vicfreight package.",
      call. = FALSE
    )
  }
  
  shiny::runApp(app_dir)
  
}
