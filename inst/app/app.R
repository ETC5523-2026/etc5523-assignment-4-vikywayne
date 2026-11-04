
# VicFreight - Shiny application

library(shiny)
library(ggplot2)

# Load datasets included in the installed package
app_data <- new.env()

utils::data(
  "traffic_counts",
  package = "vicfreight",
  envir = app_data
)

utils::data(
  "telemetry_sites",
  package = "vicfreight",
  envir = app_data
)

utils::data(
  "site_day_coverage",
  package = "vicfreight",
  envir = app_data
)

traffic_counts <- app_data$traffic_counts
telemetry_sites <- app_data$telemetry_sites
site_day_coverage <- app_data$site_day_coverage


# Use one consistent classification scheme for overview figures
traffic_4bin <- traffic_counts[
  traffic_counts$classification_scheme == "4-bin",
]

# Summary information
total_volume <- sum(traffic_4bin$volume, na.rm = TRUE)

number_sites <- length(unique(traffic_4bin$site))

complete_days <- sum(
  site_day_coverage$complete_day,
  na.rm = TRUE
)

date_range <- range(traffic_4bin$date, na.rm = TRUE)


# Calculate vehicle composition using the package function
vehicle_mix <- vicfreight::summarise_vehicle_mix(
  traffic_counts,
  group_by = "classification_scheme",
  classification_scheme = "4-bin"
)

# Site choices for the comparison dashboard
site_ids <- sort(unique(traffic_4bin$site))

site_labels <- vapply(site_ids, function(site_id) {
  
  description <- telemetry_sites$site_description[
    match(site_id, telemetry_sites$site)
  ]
  
  if (is.na(description)) {
    paste0("Site ", site_id, " (no reference description)")
  } else {
    paste0("Site ", site_id, " — ", description)
  }
  
}, character(1))

site_choices <- stats::setNames(
  as.character(site_ids),
  site_labels
)

site_display_names <- stats::setNames(
  site_labels,
  as.character(site_ids)
)

vehicle_classes <- sort(unique(traffic_4bin$vehicle_class))

vehicle_class_choices <- c(
  "All vehicle classes" = "all",
  stats::setNames(vehicle_classes, vehicle_classes)
)

# Order the 96 daily intervals by actual time, not alphabetically
time_to_minutes <- function(x) {
  parts <- strsplit(as.character(x), ":", fixed = TRUE)
  
  vapply(
    parts,
    function(part) {
      as.integer(part[1]) * 60L + as.integer(part[2])
    },
    integer(1)
  )
}

playback_times <- unique(as.character(traffic_4bin$time_bin))

playback_times <- playback_times[
  order(time_to_minutes(playback_times))
]

number_of_intervals <- length(playback_times)


# Dashboard interface
ui <- navbarPage(
  
  title = div(
    class = "brand",
    span("VIC", class = "brand-highlight"),
    "FREIGHT",
    span(" / TRAFFIC INTELLIGENCE", class = "brand-subtitle")
  ),
  
  id = "main_nav",
  
  header = tags$head(
    
    
    tags$style(HTML("
  :root {
    --vf-bg: #0c1118;
    --vf-surface: #151e29;
    --vf-surface-raised: #1b2734;
    --vf-border: #2a3948;
    --vf-text: #edf1f5;
    --vf-muted: #9aa9b8;
    --vf-amber: #f2a93b;
    --vf-amber-light: #ffc66d;
    --vf-coral: #e77f78;
  }

  body {
    background: var(--vf-bg) !important;
    color: var(--vf-text) !important;
    font-family: 'Segoe UI', Arial, sans-serif;
  }

  .tab-content {
    background: var(--vf-bg);
  }

  .dashboard-container {
    max-width: 1600px;
    margin: 0 auto;
    padding: 30px 36px;
  }

  .navbar-default {
    background: #101720 !important;
    border: none !important;
    border-bottom: 1px solid var(--vf-border) !important;
    padding: 9px 24px;
  }

  .navbar-default .navbar-brand {
    color: var(--vf-text) !important;
    font-weight: 800;
    letter-spacing: 1.8px;
  }

  .navbar-default .navbar-nav > li > a {
    color: var(--vf-muted) !important;
    font-weight: 600;
  }

  .navbar-default .navbar-nav > .active > a,
  .navbar-default .navbar-nav > .active > a:hover,
  .navbar-default .navbar-nav > .active > a:focus {
    color: var(--vf-amber) !important;
    background: transparent !important;
    border-bottom: 2px solid var(--vf-amber);
  }

  .navbar-default .navbar-toggle {
    border-color: var(--vf-border);
  }

  .navbar-default .navbar-toggle .icon-bar {
    background: var(--vf-text);
  }

  .brand-highlight,
  .eyebrow,
  .vf-kicker,
  .vf-eyebrow {
    color: var(--vf-amber) !important;
  }

  .brand-subtitle {
    color: var(--vf-muted) !important;
  }

  .vf-hero {
    background:
      radial-gradient(circle at 85% 20%, rgba(242,169,59,.13), transparent 32%),
      linear-gradient(115deg, #1b2835, #111a24);
    border: 1px solid var(--vf-border);
    border-radius: 15px;
    padding: 34px 38px;
    margin-bottom: 25px;
  }

  .vf-hero h1,
  .vf-hero h2 {
    color: #ffffff;
    font-weight: 750;
    letter-spacing: -.6px;
  }

  .vf-hero p {
    color: var(--vf-muted);
    max-width: 850px;
    line-height: 1.7;
    font-size: 14px;
  }

  .vf-kicker,
  .vf-eyebrow {
    text-transform: uppercase;
    font-size: 10px;
    letter-spacing: 2.2px;
    font-weight: 800;
  }

  .metric-card,
  .content-panel,
  .vf-panel {
    background: var(--vf-surface) !important;
    border: 1px solid var(--vf-border) !important;
    border-radius: 12px !important;
    box-shadow: 0 8px 24px rgba(0,0,0,.12);
    color: var(--vf-text);
  }

  .metric-card {
    padding: 20px;
    min-height: 120px;
    margin-bottom: 20px;
  }

  .metric-label {
    color: var(--vf-muted) !important;
    font-size: 10px;
    letter-spacing: 1.2px;
    font-weight: 750;
    text-transform: uppercase;
  }

  .metric-value {
    color: var(--vf-amber-light) !important;
    font-size: 26px;
    font-weight: 750;
    margin-top: 12px;
  }

  .metric-note,
  .chart-note,
  .vf-muted {
    color: var(--vf-muted) !important;
  }

  .metric-note,
  .chart-note {
    font-size: 11px;
    margin-top: 8px;
  }

  .vf-muted {
    font-size: 12px;
    line-height: 1.65;
  }

  .section-heading {
    color: var(--vf-text) !important;
    font-size: 19px;
    font-weight: 700;
    margin: 28px 0 15px;
  }

  .vf-panel,
  .content-panel {
    padding: 22px;
    margin-bottom: 20px;
  }

  .vf-panel h3,
  .vf-panel h4,
  .content-panel h3,
  .content-panel h4 {
    color: var(--vf-text) !important;
    font-weight: 700;
    margin-top: 0;
  }

  .form-control,
  .selectize-control.single .selectize-input,
  .selectize-control.multi .selectize-input {
    background: #101923 !important;
    border: 1px solid #405365 !important;
    color: var(--vf-text) !important;
    border-radius: 7px !important;
    box-shadow: none !important;
  }

  .form-control:focus,
  .selectize-control .selectize-input.focus {
    border-color: var(--vf-amber) !important;
    box-shadow: 0 0 0 2px rgba(242,169,59,.15) !important;
  }

  .control-label {
    color: var(--vf-muted) !important;
    font-weight: 650;
  }

  .selectize-control.multi .selectize-input {
    padding: 8px !important;
    min-height: 44px;
  }

  .selectize-control.multi .selectize-input > div {
    background: #263b49 !important;
    color: var(--vf-text) !important;
    border: 1px solid #405365 !important;
    border-radius: 5px !important;
    padding: 5px 8px !important;
    margin: 3px !important;
  }

  .selectize-control.multi .selectize-input > div.active {
    background: #3b4650 !important;
    color: #ffffff !important;
  }

  .selectize-control.multi .selectize-input > div .remove {
    border-left: 1px solid #607080 !important;
    color: var(--vf-amber) !important;
  }

  .selectize-dropdown {
    background: var(--vf-surface) !important;
    border: 1px solid #405365 !important;
    color: var(--vf-text) !important;
  }

  .selectize-dropdown .option {
    color: var(--vf-text) !important;
    padding: 9px 12px !important;
  }

  .selectize-dropdown .option.active,
  .selectize-dropdown .option.selected {
    background: #263b49 !important;
    color: var(--vf-amber) !important;
  }

  .selectize-input input {
    color: #ffffff !important;
  }

  .daterangepicker,
  .datepicker,
  .datepicker-dropdown {
    background: var(--vf-surface) !important;
    border: 1px solid #405365 !important;
    border-radius: 10px !important;
    color: var(--vf-text) !important;
    box-shadow: 0 10px 30px rgba(0,0,0,.35) !important;
  }

  .daterangepicker td,
  .daterangepicker th,
  .datepicker td,
  .datepicker th {
    color: #dce6ee !important;
  }

  .daterangepicker td.available:hover,
  .datepicker table tr td.day:hover {
    background: #30495a !important;
    color: #ffffff !important;
  }

  .daterangepicker td.active,
  .daterangepicker td.active:hover,
  .datepicker table tr td.active,
  .datepicker table tr td.active:hover {
    background: var(--vf-amber) !important;
    color: #101923 !important;
  }

  .daterangepicker .calendar-table,
  .daterangepicker select,
  .daterangepicker select option {
    background: var(--vf-surface) !important;
    color: var(--vf-text) !important;
    border-color: #405365 !important;
  }

  .daterangepicker .drp-buttons {
    border-top: 1px solid var(--vf-border) !important;
  }

  .daterangepicker .applyBtn {
    background: var(--vf-amber) !important;
    border-color: var(--vf-amber) !important;
    color: #17130c !important;
  }

  .daterangepicker .cancelBtn {
    background: #263544 !important;
    border-color: #405365 !important;
    color: var(--vf-text) !important;
  }

  .input-group-addon {
    background: #203442 !important;
    border-color: #405365 !important;
    color: var(--vf-muted) !important;
  }

  .vf-playback {
    background: #111a24;
    border: 1px solid var(--vf-border);
    border-radius: 10px;
    padding: 17px 20px;
    margin-top: 15px;
  }

  .vf-time {
    color: var(--vf-amber-light);
    font-size: 23px;
    font-weight: 750;
    letter-spacing: .5px;
  }

  .vf-playback .btn-primary {
    background: var(--vf-amber) !important;
    border-color: var(--vf-amber) !important;
    color: #17130c !important;
    font-weight: 750;
  }

  .vf-playback .btn-default {
    background: #263544 !important;
    border-color: #405365 !important;
    color: var(--vf-text) !important;
  }

  .vf-playback .irs-bar,
  .vf-playback .irs-bar-edge,
  .vf-playback .irs-single {
    background: var(--vf-amber) !important;
    border-color: var(--vf-amber) !important;
  }

  .vf-playback .irs-handle {
    border-color: var(--vf-amber) !important;
  }

  .table {
    color: var(--vf-text) !important;
    background: var(--vf-surface) !important;
    margin-bottom: 0;
  }

  .table > thead > tr > th {
    color: var(--vf-amber) !important;
    background: #192936 !important;
    border-bottom: 1px solid var(--vf-border) !important;
  }

  .table > tbody > tr > td {
    color: var(--vf-text) !important;
    background: var(--vf-surface) !important;
    border-top: 1px solid var(--vf-border) !important;
  }

  .table-striped > tbody > tr:nth-of-type(odd) > td {
    background: #203442 !important;
    color: var(--vf-text) !important;
  }

  .footer {
    color: #718294 !important;
    font-size: 11px;
    border-top: 1px solid var(--vf-border) !important;
    padding: 18px 0;
    margin-top: 30px;
  }
")),
  ),
  
  
  # OVERVIEW
  tabPanel(
    "Overview",
    
    fluidPage(
      div(
        class = "dashboard-container",
        
        # Introduction
        div(
          class = "vf-hero",
          
          div(class = "vf-kicker",
              "VICTORIA  /  FREIGHT MONITORING INTELLIGENCE"),
          
          h1("Understanding freight movement across Victoria"),
          
          p(
            "An interactive exploration of recorded vehicle volumes, ",
            "vehicle classifications and reporting patterns across ",
            "Victoria's traffic monitoring network."
          ),
          
          p(
            class = "vf-muted",
            strong("Investigation question: "),
            "How do freight traffic volumes and vehicle composition ",
            "vary across monitoring locations and time?"
          ),
          
          p(
            class = "vf-muted",
            "Designed for transport analysts, planners and people ",
            "interested in understanding Victorian road freight activity."
          )
        ),
        
        # Network summary
        h3(class = "section-heading", "Network snapshot"),
        
        fluidRow(
          column(
            3,
            div(
              class = "metric-card",
              div(class = "metric-label", "Recorded vehicle volume"),
              div(class = "metric-value", textOutput("total_volume")),
              div(class = "metric-note", "4-bin classification")
            )
          ),
          
          column(
            3,
            div(
              class = "metric-card",
              div(class = "metric-label", "Monitoring sites"),
              div(class = "metric-value", textOutput("number_sites")),
              div(class = "metric-note", "Sites with traffic observations")
            )
          ),
          
          column(
            3,
            div(
              class = "metric-card",
              div(class = "metric-label", "Complete site-days"),
              div(class = "metric-value", textOutput("complete_days")),
              div(class = "metric-note", "96 intervals reported")
            )
          ),
          
          column(
            3,
            div(
              class = "metric-card",
              div(class = "metric-label", "Observation period"),
              div(class = "metric-value", textOutput("date_range")),
              div(class = "metric-note", "Available traffic data")
            )
          )
        ),
        
        # Main map and playback controls
        h3(class = "section-heading", "Explore traffic across the network"),
        
        fluidRow(
          column(
            9,
            
            div(
              class = "vf-panel",
              
              h4("Victorian traffic monitoring network"),
              
              p(
                class = "vf-muted",
                "Select a date and play through the day to explore ",
                "how recorded traffic volumes vary across monitoring sites."
              ),
              
              leaflet::leafletOutput(
                "network_map",
                height = "560px"
              ),
              
              div(
                class = "vf-muted",
                "Amber markers represent sites with traffic observations ",
                "for the selected interval. Larger markers indicate higher ",
                "recorded volume."
              )
            )
          ),
          
          column(
            3,
            
            div(
              class = "vf-panel",
              
              h4("Playback controls"),
              
              dateInput(
                "playback_date",
                "Observation date",
                value = min(traffic_4bin$date, na.rm = TRUE),
                min = min(traffic_4bin$date, na.rm = TRUE),
                max = max(traffic_4bin$date, na.rm = TRUE),
                format = "dd M yyyy"
              ),
              
              selectInput(
                "playback_class",
                "Vehicle classification",
                choices = vehicle_class_choices,
                selected = "all"
              ),
              
              div(
                class = "vf-playback",
                
                div(class = "vf-kicker", "CURRENT INTERVAL"),
                
                div(
                  class = "vf-time",
                  textOutput("playback_time", inline = TRUE)
                ),
                
                sliderInput(
                  "playback_step",
                  "15-minute interval",
                  min = 1,
                  max = number_of_intervals,
                  value = 1,
                  step = 1,
                  width = "100%"
                ),
                
                actionButton(
                  "play_button",
                  "Play playback",
                  class = "btn-primary",
                  width = "100%"
                ),
                
                br(),
                br(),
                
                actionButton(
                  "reset_playback",
                  "Reset to midnight",
                  class = "btn-default",
                  width = "100%"
                )
              ),
              
              br(),
              
              textOutput("playback_status"),
              
              hr(),
              
              h4("How to use this map"),
              
              p(
                class = "vf-muted",
                "1. Choose an observation date."
              ),
              
              p(
                class = "vf-muted",
                "2. Select all vehicle classes or one classification."
              ),
              
              p(
                class = "vf-muted",
                "3. Press Play or move the slider to inspect individual ",
                "15-minute intervals."
              ),
              
              p(
                class = "vf-muted",
                "4. Select a marker to inspect its recorded volume."
              )
            )
          )
        ),
        
        # Vehicle composition
        h3(class = "section-heading", "Vehicle composition"),
        
        div(
          class = "vf-panel",
          
          h4("Distribution of recorded vehicle classes"),
          
          p(
            class = "vf-muted",
            "The chart shows each vehicle class as a share of total ",
            "recorded volume across the available observation period."
          ),
          
          plotOutput(
            "vehicle_composition",
            height = "300px"
          ),
          
          p(
            class = "vf-muted",
            "Percentages are calculated from the 4-bin classification. ",
            "They describe the composition of recorded traffic, not ",
            "the proportion of all vehicles on Victorian roads."
          )
        ),
        
        # Data interpretation
        div(
          class = "vf-panel",
          
          h4("Understanding the data"),
          
          p(
            class = "vf-muted",
            "Traffic volumes are aggregated into 15-minute intervals ",
            "at monitoring locations. The playback shows changes in ",
            "recorded counts at these fixed sites; it does not track ",
            "individual vehicles or show their travel routes."
          ),
          
          p(
            class = "vf-muted",
            "A site with no marker activity for a selected interval ",
            "may have no matching observation. This should not be ",
            "interpreted automatically as zero traffic."
          ),
          
          p(
            class = "vf-muted",
            "The dataset includes monitoring reference locations that ",
            "may not have matching traffic observations. In addition, ",
            "some traffic observations do not have matching site metadata."
          ),
          
          p(
            class = "vf-muted",
            "Use the Site comparison, Traffic trends and Reporting ",
            "coverage sections to investigate longer-term differences ",
            "and reporting completeness."
          )
        ),
        
        div(
          class = "footer",
          "VICFREIGHT  |  Victorian freight traffic exploration  |  2026"
        )
      )
    )
  ),
  
  
  # SITE COMPARISON
  tabPanel(
    "Site comparison",
    
    fluidPage(
      div(
        class = "dashboard-container",
        
        # Page introduction
        div(
          class = "vf-hero",
          
          div(
            class = "vf-eyebrow",
            "LOCATION ANALYSIS / SITE-LEVEL COMPARISON"
          ),
          
          h2("Compare traffic across monitoring locations"),
          
          p(
            "Investigate how recorded vehicle volumes differ between ",
            "selected Victorian monitoring sites over a chosen period."
          ),
          
          p(
            strong("Investigation focus: "),
            "Which selected monitoring locations record the highest ",
            "traffic volumes, and how do those differences vary by ",
            "vehicle classification?"
          )
        ),
        
        # Main comparison section
        h3(
          class = "section-heading",
          "Explore monitoring locations"
        ),
        
        fluidRow(
          
          # Filters
          column(
            3,
            
            div(
              class = "vf-panel",
              
              h4("Comparison filters"),
              
              p(
                class = "vf-muted",
                "Choose the locations, observation period and ",
                "vehicle classification for your comparison."
              ),
              
              selectizeInput(
                "comparison_sites",
                "Monitoring sites",
                choices = site_choices,
                selected = as.character(site_ids[1:2]),
                multiple = TRUE,
                options = list(
                  plugins = list("remove_button"),
                  maxItems = 6,
                  placeholder = "Choose 2–6 monitoring sites"
                )
              ),
              
              dateRangeInput(
                "comparison_dates",
                "Observation period",
                start = min(traffic_4bin$date),
                end = max(traffic_4bin$date),
                min = min(traffic_4bin$date),
                max = max(traffic_4bin$date),
                format = "dd M yyyy"
              ),
              
              selectInput(
                "comparison_class",
                "Vehicle classification",
                choices = vehicle_class_choices,
                selected = "all"
              ),
              
              tags$hr(),
              
              h4("How to use this comparison"),
              
              p(
                class = "vf-muted",
                "1. Select at least two monitoring sites."
              ),
              
              p(
                class = "vf-muted",
                "2. Choose the dates you want to investigate."
              ),
              
              p(
                class = "vf-muted",
                "3. Select all vehicle classes or focus on one category."
              ),
              
              p(
                class = "vf-muted",
                "4. Compare the recorded totals in the chart and table."
              )
            )
          ),
          
          # Comparison chart
          column(
            9,
            
            div(
              class = "vf-panel",
              
              h4("Recorded traffic volume by monitoring site"),
              
              p(
                class = "vf-muted",
                "Sites are ranked by their total recorded vehicle ",
                "volume across the selected dates."
              ),
              
              plotOutput(
                "site_comparison_plot",
                height = "340px"
              ),
              
              p(
                class = "vf-muted",
                "Longer bars indicate higher recorded volumes. ",
                "The ranking reflects the selected period and ",
                "classification."
              )
            )
          )
        ),
        
        # Summary table
        h3(
          class = "section-heading",
          "Comparison results"
        ),
        
        div(
          class = "vf-panel",
          
          h4("Site-level summary"),
          
          p(
            class = "vf-muted",
            "Review the total recorded vehicle volume and number ",
            "of source records for each selected location."
          ),
          
          tableOutput("site_comparison_table"),
          
          tags$hr(),
          
          p(
            class = "vf-muted",
            "Interpretation note: total volumes are not adjusted ",
            "for incomplete reporting. Differences may reflect ",
            "both traffic activity and variation in data coverage. ",
            "Use the Reporting coverage section when assessing ",
            "whether sites have comparable reporting completeness."
          )
        ),
        
        div(
          class = "footer",
          "VICFREIGHT  |  Victorian freight traffic exploration  |  2026"
        )
      )
    )
  ),
  
  
  # TRAFFIC TRENDS
  tabPanel(
    "Traffic trends",
    
    fluidPage(
      div(
        class = "dashboard-container",
        
        h2("Traffic patterns over time"),
        
        p(
          "Explore how recorded traffic volumes change across ",
          "monitoring locations and vehicle classifications."
        ),
        
        fluidRow(
          
          # Trend filters
          column(
            3,
            
            div(
              class = "content-panel",
              
              h4("Trend filters"),
              
              selectizeInput(
                "trend_sites",
                "Select monitoring sites",
                choices = site_choices,
                selected = as.character(site_ids[1:2]),
                multiple = TRUE,
                options = list(
                  plugins = list("remove_button"),
                  maxItems = 5,
                  placeholder = "Choose up to five sites"
                )
              ),
              
              selectInput(
                "trend_period",
                "Time interval",
                choices = c(
                  "Daily" = "daily",
                  "Monthly" = "monthly"
                ),
                selected = "daily"
              ),
              
              dateRangeInput(
                "trend_dates",
                "Observation period",
                start = min(traffic_4bin$date),
                end = max(traffic_4bin$date),
                min = min(traffic_4bin$date),
                max = max(traffic_4bin$date),
                format = "dd M yyyy"
              ),
              
              selectInput(
                "trend_class",
                "Vehicle classification",
                choices = vehicle_class_choices,
                selected = "all"
              ),
              
              p(
                class = "chart-note",
                "Select one or more sites to explore their traffic patterns."
              )
            )
          ),
          
          # Trend chart
          column(
            9,
            
            div(
              class = "content-panel",
              
              h4("Recorded traffic volume over time"),
              
              plotly::plotlyOutput(
                "traffic_trend_plot",
                height = "430px"
              ),
              
              p(
                class = "chart-note",
                "Daily and monthly values represent recorded vehicle counts, ",
                "not estimates adjusted for missing observations."
              )
            )
          )
        ),
        
        # Summary table
        div(
          class = "content-panel",
          
          h4("Summary by monitoring site"),
          
          tableOutput("traffic_trend_table"),
          
          p(
            class = "chart-note",
            "Totals cover the selected dates and vehicle classification."
          )
        )
      )
    )
  ),
  
  
  
  # REPORTING COVERAGE
  tabPanel(
    "Reporting coverage",
    
    fluidPage(
      div(
        class = "dashboard-container",
        
        h2("Monitoring and reporting coverage"),
        
        p(
          "Assess the completeness of 15-minute traffic reporting ",
          "across monitoring locations and observation dates."
        ),
        
        fluidRow(
          
          # Coverage filters
          column(
            3,
            
            div(
              class = "content-panel",
              
              h4("Coverage filters"),
              
              selectizeInput(
                "coverage_sites",
                "Select monitoring sites",
                choices = site_choices,
                selected = as.character(site_ids[1:min(5, length(site_ids))]),
                multiple = TRUE,
                options = list(
                  plugins = list("remove_button"),
                  maxItems = 15,
                  placeholder = "Choose monitoring sites"
                )
              ),
              
              dateRangeInput(
                "coverage_dates",
                "Observation period",
                start = min(site_day_coverage$date, na.rm = TRUE),
                end = max(site_day_coverage$date, na.rm = TRUE),
                min = min(site_day_coverage$date, na.rm = TRUE),
                max = max(site_day_coverage$date, na.rm = TRUE),
                format = "dd M yyyy"
              ),
              
              p(
                class = "chart-note",
                "Select one or more sites and a date range to inspect reporting completeness."
              )
            )
          ),
          
          # Coverage summary and charts
          column(
            9,
            
            fluidRow(
              
              column(
                3,
                div(
                  class = "metric-card",
                  div(class = "metric-label", "Site-days assessed"),
                  div(
                    class = "metric-value",
                    textOutput("coverage_total_days")
                  ),
                  div(class = "metric-note", "Selected observations")
                )
              ),
              
              column(
                3,
                div(
                  class = "metric-card",
                  div(class = "metric-label", "Complete site-days"),
                  div(
                    class = "metric-value",
                    textOutput("coverage_complete_days")
                  ),
                  div(class = "metric-note", "96 intervals reported")
                )
              ),
              
              column(
                3,
                div(
                  class = "metric-card",
                  div(class = "metric-label", "Incomplete site-days"),
                  div(
                    class = "metric-value",
                    textOutput("coverage_incomplete_days")
                  ),
                  div(class = "metric-note", "Fewer than 96 intervals")
                )
              ),
              
              column(
                3,
                div(
                  class = "metric-card",
                  div(class = "metric-label", "Average intervals"),
                  div(
                    class = "metric-value",
                    textOutput("coverage_average_intervals")
                  ),
                  div(class = "metric-note", "Out of 96 expected")
                )
              )
            ),
            
            div(
              class = "content-panel",
              
              h4("Monthly reporting completeness"),
              
              plotOutput(
                "coverage_monthly_plot",
                height = "350px"
              ),
              
              p(
                class = "chart-note",
                "Each bar shows the proportion of selected site-days with complete ",
                "or incomplete reporting for that month. Monthly proportions are ",
                "based on available site-day records."
              )
            )
          )
        ),
        
        fluidRow(
          
          column(
            6,
            
            div(
              class = "content-panel",
              
              h4("Average reporting intervals by site"),
              
              plotOutput(
                "coverage_site_plot",
                height = "400px"
              ),
              
              p(
                class = "chart-note",
                "Sites with fewer average intervals have less complete reporting across the selected period."
              )
            )
          ),
          
          column(
            6,
            
            div(
              class = "content-panel",
              
              h4("Incomplete reporting days"),
              
              tableOutput("coverage_incomplete_table"),
              
              p(
                class = "chart-note",
                "Showing up to 25 incomplete site-days, ordered from the fewest ",
                "reported intervals to the most. These are the largest reporting gaps."
              )
            )
          )
        ),
        
        div(
          class = "content-panel",
          
          h4("Understanding reporting coverage"),
          
          p(
            "Each site-day is expected to contain 96 unique 15-minute ",
            "reporting intervals, representing a full 24-hour day."
          ),
          
          p(
            "A site-day with fewer than 96 reported intervals is classified ",
            "as incomplete. This indicates a reporting gap; it does not ",
            "necessarily mean that traffic volume was zero during the missing intervals."
          ),
          
          p(
            "The dashboard retains incomplete site-days in its analysis ",
            "rather than treating them as complete observations."
          )
        )
      )
    )
  )
  
)

# Server
server <- function(input, output, session) {
  
  output$total_volume <- renderText({
    format(round(total_volume), big.mark = ",")
  })
  
  output$number_sites <- renderText({
    format(number_sites, big.mark = ",")
  })
  
  output$complete_days <- renderText({
    format(complete_days, big.mark = ",")
  })
  
  output$date_range <- renderText({
    paste(
      format(date_range[1], "%b %Y"),
      "–",
      format(date_range[2], "%b %Y")
    )
  })
  
  
  
  # Vehicle composition chart
  output$vehicle_composition <- renderPlot({
    
    ggplot(
      vehicle_mix,
      aes(
        x = share_percent,
        y = reorder(vehicle_class, share_percent)
      )
    ) +
      
      geom_col(
        fill = "#f2a93b",
        width = 0.65
      ) +
      
      geom_text(
        aes(label = paste0(round(share_percent, 1), "%")),
        hjust = -0.2,
        colour = "white",
        size = 4
      ) +
      
      scale_x_continuous(
        limits = c(0, 115),
        breaks = seq(0, 100, by = 20),
        labels = function(x) paste0(x, "%")
      ) +
      
      scale_y_discrete(
        labels = function(x) {
          sub("^4bin: [0-9]+\\.", "", x)
        }
      ) +
      
      labs(
        title = "Traffic composition by vehicle class",
        x = "Share of recorded vehicle volume",
        y = NULL
      ) +
      
      theme_minimal() +
      
      theme(
        plot.background = element_rect(
          fill = "#192936",
          colour = NA
        ),
        
        panel.background = element_rect(
          fill = "#192936",
          colour = NA
        ),
        
        panel.grid.major.y = element_blank(),
        panel.grid.minor = element_blank(),
        
        panel.grid.major.x = element_line(
          colour = "#304353"
        ),
        
        axis.text.y = element_text(
          colour = "#dce6ee",
          size = 11
        ),
        
        axis.text.x = element_text(
          colour = "#dce6ee",
          size = 10
        ),
        
        axis.title.x = element_text(
          colour = "#91a5b6",
          size = 10
        ),
        
        plot.title = element_text(
          colour = "white",
          face = "bold",
          size = 14
        ),
        
        plot.margin = margin(
          t = 10,
          r = 25,
          b = 10,
          l = 10
        )
      )
    
  })
  
  
  
  # =========================================
  # TRAFFIC PLAYBACK
  # =========================================
  
  # Track whether playback is currently running
  playback_running <- reactiveVal(FALSE)
  
  # Prepare data for the selected date, class and interval
  playback_frame <- reactive({
    
    req(input$playback_date)
    req(input$playback_class)
    req(input$playback_step)
    
    selected_date <- as.Date(input$playback_date)
    
    selected_time <- playback_times[
      as.integer(input$playback_step)
    ]
    
    selected_data <- traffic_4bin[
      traffic_4bin$date == selected_date &
        as.character(traffic_4bin$time_bin) == selected_time,
    ]
    
    # Apply vehicle-class selection
    if (input$playback_class != "all") {
      
      selected_data <- selected_data[
        selected_data$vehicle_class == input$playback_class,
      ]
      
    }
    
    # Aggregate recorded volume at each monitoring site
    if (nrow(selected_data) > 0) {
      
      interval_summary <- aggregate(
        volume ~ site,
        data = selected_data,
        FUN = sum,
        na.rm = TRUE
      )
      
    } else {
      
      interval_summary <- data.frame(
        site = numeric(0),
        volume = numeric(0)
      )
      
    }
    
    # Retain reference sites even when no interval observation exists
    frame <- merge(
      telemetry_sites,
      interval_summary,
      by = "site",
      all.x = TRUE
    )
    
    frame
  })
  
  
  # Base map: render once, then update its markers using leafletProxy()
  output$network_map <- leaflet::renderLeaflet({
    
    leaflet::leaflet(
      options = leaflet::leafletOptions(
        zoomControl = TRUE,
        minZoom = 5,
        maxZoom = 16
      )
    ) |>
      
      leaflet::addTiles(
        urlTemplate = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
        attribution = paste(
          '&copy; <a href="https://www.openstreetmap.org/copyright">',
          'OpenStreetMap</a> contributors'
        )
      ) |>
      
      leaflet::setView(
        lng = 144.5,
        lat = -37.5,
        zoom = 6
      ) |>
      
      leaflet::addLegend(
        position = "bottomright",
        colors = c("#f2a93b", "#64748b"),
        labels = c(
          "Traffic observation",
          "No observation for interval"
        ),
        title = "Site reporting",
        opacity = 0.9
      )
    
  })
  
  
  # Update markers when the selected interval or filters change
  observeEvent(playback_frame(), {
    
    frame <- playback_frame()
    
    # Keep only locations with usable coordinates
    frame <- frame[
      !is.na(frame$longitude) &
        !is.na(frame$latitude) &
        is.finite(frame$longitude) &
        is.finite(frame$latitude),
    ]
    
    # Distinguish missing interval observations from recorded zero volume
    frame$marker_colour <- ifelse(
      is.na(frame$volume),
      "#64748b",
      "#f2a93b"
    )
    
    frame$marker_radius <- ifelse(
      is.na(frame$volume),
      4,
      pmin(
        18,
        5 + 2.3 * log10(frame$volume + 1)
      )
    )
    
    frame$popup_volume <- ifelse(
      is.na(frame$volume),
      "No observation for this interval",
      paste0(
        "Recorded volume: ",
        format(
          round(frame$volume),
          big.mark = ",",
          scientific = FALSE
        )
      )
    )
    
    frame$popup_site <- ifelse(
      is.na(frame$site_description) |
        frame$site_description == "",
      paste0("Site ", frame$site),
      frame$site_description
    )
    
    leaflet::leafletProxy("network_map", data = frame) |>
      leaflet::clearGroup("playback") |>
      
      leaflet::addCircleMarkers(
        lng = ~longitude,
        lat = ~latitude,
        
        radius = ~marker_radius,
        
        color = ~marker_colour,
        fillColor = ~marker_colour,
        
        fillOpacity = 0.85,
        weight = 1.2,
        opacity = 0.95,
        
        label = ~paste("Site", site),
        
        popup = ~paste0(
          "<strong>", popup_site, "</strong><br>",
          "Site ID: ", site, "<br>",
          popup_volume
        ),
        
        group = "playback"
      )
    
  }, ignoreInit = FALSE)
  
  
  # Display the selected interval as a clock time
  output$playback_time <- renderText({
    
    req(input$playback_step)
    
    playback_times[
      as.integer(input$playback_step)
    ]
    
  })
  
  
  # Explain the current playback state
  output$playback_status <- renderText({
    
    frame <- playback_frame()
    
    if (nrow(frame) == 0 || all(is.na(frame$volume))) {
      
      return(
        "No traffic observations are available for this date and interval."
      )
      
    }
    
    paste0(
      sum(!is.na(frame$volume)),
      " monitoring sites have observations for this interval."
    )
    
  })
  
  
  # Start and pause playback
  observeEvent(input$play_button, {
    
    new_state <- !isTRUE(playback_running())
    
    playback_running(new_state)
    
    updateActionButton(
      session,
      "play_button",
      label = if (new_state) "Pause playback" else "Resume playback"
    )
    
  })
  
  
  # Reset playback to midnight
  observeEvent(input$reset_playback, {
    
    playback_running(FALSE)
    
    updateActionButton(
      session,
      "play_button",
      label = "Play playback"
    )
    
    updateSliderInput(
      session,
      "playback_step",
      value = 1
    )
    
  })
  
  
  # Stop playback and reset when the date or class changes
  observeEvent(
    list(input$playback_date, input$playback_class),
    {
      
      playback_running(FALSE)
      
      updateActionButton(
        session,
        "play_button",
        label = "Play playback"
      )
      
      updateSliderInput(
        session,
        "playback_step",
        value = 1
      )
      
    },
    ignoreInit = TRUE
  )
  
  
  # Advance one 15-minute interval approximately every 700 milliseconds
  playback_timer <- reactiveTimer(700)
  
  observe({
    
    playback_timer()
    
    if (isTRUE(playback_running())) {
      
      current_step <- as.integer(input$playback_step)
      
      next_step <- current_step + 1L
      
      if (next_step > number_of_intervals) {
        next_step <- 1L
      }
      
      updateSliderInput(
        session,
        "playback_step",
        value = next_step
      )
      
    }
    
  })
  
  
  
  # Calculate site comparisons using the package function
  comparison_data <- reactive({
    
    req(input$comparison_sites)
    req(input$comparison_dates)
    
    validate(
      need(
        length(input$comparison_sites) >= 2,
        "Please select at least two monitoring sites."
      )
    )
    
    selected_class <- if (
      input$comparison_class == "all"
    ) {
      NULL
    } else {
      input$comparison_class
    }
    
    result <- tryCatch(
      
      vicfreight::compare_sites(
        data = traffic_4bin,
        sites = as.numeric(input$comparison_sites),
        vehicle_class = selected_class,
        start_date = input$comparison_dates[1],
        end_date = input$comparison_dates[2]
      ),
      
      error = function(e) {
        data.frame()
      }
    )
    
    validate(
      need(
        nrow(result) > 0,
        "No traffic observations were found for these selections."
      )
    )
    
    result$site_label <- unname(
      site_display_names[as.character(result$site)]
    )
    
    result$site_label[
      is.na(result$site_label)
    ] <- paste(
      "Site",
      result$site[
        is.na(result$site_label)
      ]
    )
    # Short labels for the chart; retain full descriptions for the table
    result$site_plot_label <- paste(
      "Site",
      result$site
    )
    
    result
  })
  
  
  # Site comparison chart
  output$site_comparison_plot <- renderPlot({
    
    comparison <- comparison_data()
    
    # Order sites from lowest to highest recorded volume
    comparison$site_plot_label <- factor(
      comparison$site_plot_label,
      levels = comparison$site_plot_label[
        order(comparison$total_volume)
      ]
    )
    
    # Compact axis labels for large volumes
    compact_volume <- function(x) {
      ifelse(
        x >= 1000000,
        paste0(round(x / 1000000, 1), "M"),
        ifelse(
          x >= 1000,
          paste0(round(x / 1000, 0), "K"),
          format(x, big.mark = ",", scientific = FALSE)
        )
      )
    }
    
    ggplot(
      comparison,
      aes(
        y = site_plot_label,
        x = total_volume
      )
    ) +
      
      # Horizontal ranking lines
      geom_segment(
        aes(
          x = 0,
          xend = total_volume,
          yend = site_plot_label
        ),
        colour = "#f2a93b",
        linewidth = 2.2,
        lineend = "round"
      ) +
      
      # Highlight the end of each ranking line
      geom_point(
        colour = "#ffc66d",
        size = 5,
        stroke = 1.2
      ) +
      
      # Exact recorded volume
      geom_text(
        aes(
          label = format(
            round(total_volume),
            big.mark = ",",
            scientific = FALSE
          )
        ),
        hjust = -0.2,
        colour = "#edf1f5",
        size = 3.8
      ) +
      
      scale_x_continuous(
        labels = compact_volume,
        expand = expansion(mult = c(0.02, 0.20))
      ) +
      
      labs(
        x = "Recorded vehicle volume",
        y = NULL
      ) +
      
      coord_cartesian(clip = "off") +
      
      theme_minimal() +
      
      theme(
        plot.background = element_rect(
          fill = "#151e29",
          colour = NA
        ),
        
        panel.background = element_rect(
          fill = "#151e29",
          colour = NA
        ),
        
        panel.grid.major.y = element_blank(),
        
        panel.grid.minor = element_blank(),
        
        panel.grid.major.x = element_line(
          colour = "#2a3948",
          linewidth = 0.5
        ),
        
        axis.text.y = element_text(
          colour = "#edf1f5",
          size = 11,
          face = "bold"
        ),
        
        axis.text.x = element_text(
          colour = "#9aa9b8",
          size = 9
        ),
        
        axis.title.x = element_text(
          colour = "#9aa9b8",
          size = 10,
          margin = margin(t = 12)
        ),
        
        axis.ticks = element_blank(),
        
        plot.margin = margin(
          t = 15,
          r = 35,
          b = 10,
          l = 10
        )
      )
    
  })
  
  
  
  # Site comparison results table
  output$site_comparison_table <- renderTable({
    
    comparison <- comparison_data()
    
    data.frame(
      Site = comparison$site_label,
      `Total vehicle volume` = format(
        comparison$total_volume,
        big.mark = ",",
        scientific = FALSE
      ),
      `Source records` = format(
        comparison$records,
        big.mark = ",",
        scientific = FALSE
      ),
      check.names = FALSE
    )
    
  },
  striped = TRUE,
  bordered = FALSE,
  spacing = "s"
  )
  
  # Prepare traffic data for the selected trend filters
  trend_data <- reactive({
    
    req(input$trend_sites)
    req(input$trend_dates)
    req(input$trend_period)
    
    selected_sites <- as.numeric(input$trend_sites)
    
    start_date <- as.Date(input$trend_dates[1])
    end_date <- as.Date(input$trend_dates[2])
    
    validate(
      need(
        length(selected_sites) >= 1,
        "Please select at least one monitoring site."
      ),
      need(
        !is.na(start_date) && !is.na(end_date) &&
          start_date <= end_date,
        "Please select a valid observation period."
      )
    )
    
    # Filter the observations
    selected_data <- traffic_4bin[
      traffic_4bin$site %in% selected_sites &
        traffic_4bin$date >= start_date &
        traffic_4bin$date <= end_date,
    ]
    
    # Apply the selected vehicle classification
    if (input$trend_class != "all") {
      
      selected_data <- selected_data[
        selected_data$vehicle_class == input$trend_class,
      ]
      
    }
    
    validate(
      need(
        nrow(selected_data) > 0,
        "No traffic observations were found for these selections."
      )
    )
    
    # Create daily or monthly reporting periods
    if (input$trend_period == "daily") {
      
      selected_data$period_date <- as.Date(
        selected_data$date
      )
      
    } else {
      
      selected_data$period_date <- as.Date(
        paste0(
          format(selected_data$date, "%Y-%m"),
          "-01"
        )
      )
      
    }
    
    # Aggregate recorded volume by period and site
    result <- aggregate(
      volume ~ period_date + site,
      data = selected_data,
      FUN = sum,
      na.rm = TRUE
    )
    
    # Add readable site names
    result$site_label <- unname(
      site_display_names[as.character(result$site)]
    )
    
    result$site_label[
      is.na(result$site_label)
    ] <- paste(
      "Site",
      result$site[
        is.na(result$site_label)
      ]
    )
    
    result
    
  })
  
  # Interactive traffic trends chart
  output$traffic_trend_plot <- plotly::renderPlotly({
    
    trends <- trend_data()
    
    validate(
      need(
        nrow(trends) > 0,
        "No traffic data is available for this selection."
      )
    )
    
    # Create short labels for the chart legend
    trends$site_plot_label <- paste("Site", trends$site)
    
    # Retain full site descriptions for hover details
    trends$hover_text <- paste0(
      "<b>", trends$site_label, "</b><br>",
      "Date: ", format(trends$period_date, "%d %b %Y"), "<br>",
      "Recorded volume: ",
      format(
        round(trends$volume),
        big.mark = ",",
        scientific = FALSE
      )
    )
    
    # Add missing periods so lines break where observations are absent
    if (input$trend_period == "daily") {
      
      all_periods <- seq.Date(
        from = as.Date(input$trend_dates[1]),
        to = as.Date(input$trend_dates[2]),
        by = "day"
      )
      
    } else {
      
      all_periods <- seq.Date(
        from = as.Date(format(
          as.Date(input$trend_dates[1]), "%Y-%m-01"
        )),
        to = as.Date(format(
          as.Date(input$trend_dates[2]), "%Y-%m-01"
        )),
        by = "month"
      )
      
    }
    
    period_grid <- expand.grid(
      period_date = all_periods,
      site = as.numeric(input$trend_sites)
    )
    
    plot_data <- merge(
      period_grid,
      trends,
      by = c("period_date", "site"),
      all.x = TRUE,
      sort = TRUE
    )
    
    plot_data$site_plot_label <- paste(
      "Site",
      plot_data$site
    )
    
    # Build the chart
    p <- ggplot(
      plot_data,
      aes(
        x = period_date,
        y = volume,
        colour = site_plot_label,
        group = site_plot_label,
        text = hover_text
      )
    ) +
      
      geom_line(
        linewidth = 1,
        na.rm = FALSE
      ) +
      
      geom_point(
        size = 2,
        na.rm = TRUE
      ) +
      
      scale_colour_manual(
        values = c(
          "#f2a93b",
          "#69a9e8",
          "#e77f78",
          "#b99add",
          "#91b9a0"
        )
      ) +
      
      scale_x_date(
        date_breaks = "1 month",
        date_labels = "%b %Y",
        expand = expansion(mult = c(0.02, 0.04))
      ) +
      
      scale_y_continuous(
        labels = function(x) {
          format(
            round(x),
            big.mark = ",",
            scientific = FALSE
          )
        },
        expand = expansion(mult = c(0, 0.10))
      ) +
      
      labs(
        x = "Observation period",
        y = "Recorded vehicle volume",
        colour = "Monitoring site"
      ) +
      
      theme_minimal() +
      
      theme(
        plot.background = element_rect(
          fill = "#192936",
          colour = NA
        ),
        
        panel.background = element_rect(
          fill = "#192936",
          colour = NA
        ),
        
        panel.grid.major = element_line(
          colour = "#304353"
        ),
        
        panel.grid.minor = element_blank(),
        
        axis.text = element_text(
          colour = "#dce6ee",
          size = 10
        ),
        
        axis.title = element_text(
          colour = "#91a5b6",
          size = 11
        ),
        
        legend.title = element_text(
          colour = "#dce6ee",
          face = "bold"
        ),
        
        legend.text = element_text(
          colour = "#dce6ee",
          size = 9
        ),
        
        legend.background = element_rect(
          fill = "#192936",
          colour = NA
        ),
        
        plot.margin = margin(15, 15, 15, 15)
      )
    
    interactive_plot <- plotly::ggplotly(
      p,
      tooltip = "text"
    )
    
    interactive_plot <- plotly::layout(
      interactive_plot,
      dragmode = "zoom",
      hoverlabel = list(
        bgcolor = "#203442",
        font = list(color = "#ffffff")
      ),
      legend = list(
        itemclick = "toggle",
        itemdoubleclick = "toggleothers"
      )
    )
    
    plotly::config(
      interactive_plot,
      displaylogo = FALSE,
      scrollZoom = TRUE
    )
    
  })
  
  # Summary of recorded traffic by selected site
  output$traffic_trend_table <- renderTable({
    
    trends <- trend_data()
    
    summary_data <- aggregate(
      volume ~ site_label,
      data = trends,
      FUN = sum,
      na.rm = TRUE
    )
    
    names(summary_data) <- c(
      "Monitoring site",
      "Total recorded vehicle volume"
    )
    
    summary_data$`Total recorded vehicle volume` <- format(
      summary_data$`Total recorded vehicle volume`,
      big.mark = ",",
      scientific = FALSE
    )
    
    summary_data
    
  },
  striped = TRUE,
  bordered = FALSE,
  spacing = "s"
  )
  
  
  # Prepare reporting coverage data for selected filters
  coverage_data <- reactive({
    
    req(input$coverage_sites)
    req(input$coverage_dates)
    
    start_date <- as.Date(input$coverage_dates[1])
    end_date <- as.Date(input$coverage_dates[2])
    
    validate(
      need(
        length(input$coverage_sites) >= 1,
        "Please select at least one monitoring site."
      ),
      
      need(
        !is.na(start_date) &&
          !is.na(end_date) &&
          start_date <= end_date,
        "Please select a valid observation period."
      )
    )
    
    result <- site_day_coverage[
      as.character(site_day_coverage$site) %in%
        input$coverage_sites &
        site_day_coverage$date >= start_date &
        site_day_coverage$date <= end_date,
    ]
    
    validate(
      need(
        nrow(result) > 0,
        "No reporting coverage records were found for these selections."
      )
    )
    
    result$site_label <- unname(
      site_display_names[as.character(result$site)]
    )
    
    result$site_label[
      is.na(result$site_label)
    ] <- paste(
      "Site",
      result$site[
        is.na(result$site_label)
      ]
    )
    
    result
  })
  
  
  # Coverage summary metrics
  output$coverage_total_days <- renderText({
    
    format(
      nrow(coverage_data()),
      big.mark = ","
    )
    
  })
  
  
  output$coverage_complete_days <- renderText({
    
    coverage <- coverage_data()
    
    format(
      sum(coverage$complete_day, na.rm = TRUE),
      big.mark = ","
    )
    
  })
  
  
  output$coverage_incomplete_days <- renderText({
    
    coverage <- coverage_data()
    
    format(
      sum(!coverage$complete_day, na.rm = TRUE),
      big.mark = ","
    )
    
  })
  
  
  output$coverage_average_intervals <- renderText({
    
    coverage <- coverage_data()
    
    paste0(
      round(mean(coverage$intervals_reported, na.rm = TRUE), 1),
      " / 96"
    )
    
  })
  
  
  # Monthly reporting completeness as proportions
  output$coverage_monthly_plot <- renderPlot({
    
    coverage <- coverage_data()
    
    coverage$month <- as.Date(
      format(coverage$date, "%Y-%m-01")
    )
    
    coverage$month_label <- format(coverage$month, "%b %Y")
    
    coverage$status <- ifelse(
      coverage$complete_day,
      "Complete",
      "Incomplete"
    )
    
    monthly_summary <- aggregate(
      site ~ month + month_label + status,
      data = coverage,
      FUN = length
    )
    
    names(monthly_summary)[4] <- "site_days"
    
    monthly_order <- unique(
      format(
        sort(unique(monthly_summary$month)),
        "%b %Y"
      )
    )
    
    monthly_summary$month_label <- factor(
      monthly_summary$month_label,
      levels = monthly_order
    )
    
    monthly_summary$status <- factor(
      monthly_summary$status,
      levels = c("Complete", "Incomplete")
    )
    
    ggplot(
      monthly_summary,
      aes(
        x = month_label,
        y = site_days,
        fill = status
      )
    ) +
      geom_col(
        position = "fill",
        width = 0.65
      ) +
      scale_fill_manual(
        values = c(
          "Complete" = "#f2a93b",
          "Incomplete" = "#e77f78"
        )
      ) +
      scale_x_discrete(
        drop = FALSE
      ) +
      
      scale_y_continuous(
        labels = function(x) {
          paste0(round(x * 100), "%")
        },
        expand = expansion(mult = c(0, 0.02))
      ) +
      
      coord_cartesian(
        ylim = c(0, 1)
      ) +
      
      labs(
        x = "Observation month",
        y = "Share of selected site-days",
        fill = "Reporting status"
      ) +
      
      theme_minimal() +
      
      theme(
        plot.background = element_rect(
          fill = "#151e29",
          colour = NA
        ),
        
        panel.background = element_rect(
          fill = "#151e29",
          colour = NA
        ),
        
        panel.grid.major = element_line(
          colour = "#2a3948"
        ),
        
        panel.grid.minor = element_blank(),
        
        axis.text = element_text(
          colour = "#dce6ee",
          size = 10
        ),
        
        axis.title = element_text(
          colour = "#9aa9b8",
          size = 10
        ),
        
        legend.title = element_text(
          colour = "#dce6ee",
          face = "bold"
        ),
        
        legend.text = element_text(
          colour = "#dce6ee",
          size = 10
        ),
        
        legend.background = element_rect(
          fill = "#151e29",
          colour = NA
        )
      )
    
  })
  
  # Average reporting intervals by monitoring site
  output$coverage_site_plot <- renderPlot({
    
    coverage <- coverage_data()
    
    site_summary <- aggregate(
      intervals_reported ~ site_label,
      data = coverage,
      FUN = mean
    )
    
    site_summary <- site_summary[
      order(site_summary$intervals_reported),
    ]
    
    # Show the 15 sites with the lowest average interval coverage
    site_summary <- head(site_summary, 15)
    
    ggplot(
      site_summary,
      aes(
        x = intervals_reported,
        y = reorder(site_label, intervals_reported)
      )
    ) +
      
      geom_col(
        fill = "#f2a93b",
        width = 0.65
      ) +
      
      geom_vline(
        xintercept = 96,
        colour = "#69a9e8",
        linetype = "dashed",
        linewidth = 0.8
      ) +
      
      geom_text(
        aes(
          label = round(intervals_reported, 1)
        ),
        hjust = -0.25,
        colour = "#edf1f5",
        size = 3.5
      ) +
      
      scale_x_continuous(
        limits = c(0, 110),
        breaks = seq(0, 100, by = 20)
      ) +
      
      labs(
        x = "Average reported intervals per day",
        y = NULL
      ) +
      
      theme_minimal() +
      
      theme(
        plot.background = element_rect(
          fill = "#151e29",
          colour = NA
        ),
        
        panel.background = element_rect(
          fill = "#151e29",
          colour = NA
        ),
        
        panel.grid.major.y = element_blank(),
        panel.grid.minor = element_blank(),
        
        panel.grid.major.x = element_line(
          colour = "#2a3948"
        ),
        
        axis.text = element_text(
          colour = "#dce6ee",
          size = 9
        ),
        
        axis.title = element_text(
          colour = "#9aa9b8",
          size = 10
        )
      )
    
  })
  
  
  # Table of incomplete site-days
  output$coverage_incomplete_table <- renderTable({
    
    coverage <- coverage_data()
    
    incomplete <- coverage[
      !coverage$complete_day,
    ]
    
    incomplete <- incomplete[
      order(
        incomplete$intervals_reported,
        incomplete$date
      ),
    ]
    
    if (nrow(incomplete) == 0) {
      
      return(
        data.frame(
          Message = "All selected site-days have complete reporting."
        )
      )
      
    }
    
    # Show the 25 site-days with the largest reporting gaps
    incomplete <- head(incomplete, 25)
    
    data.frame(
      Site = incomplete$site_label,
      
      Date = format(
        incomplete$date,
        "%d %b %Y"
      ),
      
      `Intervals reported` = format(
        round(incomplete$intervals_reported),
        big.mark = ",",
        scientific = FALSE
      ),
      
      `Intervals missing` = format(
        round(96 - incomplete$intervals_reported),
        big.mark = ",",
        scientific = FALSE
      ),
      
      check.names = FALSE
    )
    
  },
  striped = TRUE,
  bordered = FALSE,
  spacing = "s"
  )
  
  
}

# Launch application
shinyApp(ui = ui, server = server)
