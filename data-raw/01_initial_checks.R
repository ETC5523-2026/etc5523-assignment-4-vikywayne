
# ============================================================
# VicFreight: Initial data inspection
#
# Purpose:
# Inspect the May–October 2026 Victorian traffic-count data
# before preparing the package dataset.
#
# This script examines:
# - Source-file availability and structure
# - Daily and monthly record counts
# - Vehicle classification schemes
# - Monitoring sites and reference information
# - Reporting interval coverage
# - Unusual or incomplete source files
#
# Original source files are not modified.
# ============================================================


# 1. Setup ----------------------------------------------------

# Define the source folder
source_folder <- "data-raw/source"

# Find all daily traffic CSV files
traffic_files <- list.files(
  source_folder,
  pattern = "^TELEMETRYDATA_\\d{8}\\.csv$",
  recursive = TRUE,
  full.names = TRUE
)

# Stop if no traffic files are found
if (length(traffic_files) == 0) {
  stop("No traffic CSV files found. Check the source folder.")
}

# Create the file inventory
file_inventory <- data.frame(
  file = basename(traffic_files),
  folder = basename(dirname(traffic_files)),
  file_path = traffic_files,
  stringsAsFactors = FALSE
)

# Extract dates from filenames
file_inventory$date <- as.Date(
  sub(
    "TELEMETRYDATA_(\\d{8})\\.csv",
    "\\1",
    file_inventory$file
  ),
  format = "%Y%m%d"
)

# Create month labels
file_inventory$month <- format(
  file_inventory$date,
  "%Y-%m"
)

# Sort the inventory by date
file_inventory <- file_inventory[
  order(file_inventory$date),
]

# IMPORTANT:
# Keep the file paths in the same order as the inventory.
traffic_files <- file_inventory$file_path

# Check the inventory
head(file_inventory)
tail(file_inventory)

# Total number of files
length(traffic_files)


# 2. Check monthly file and date availability ---------------

# Expected calendar dates from May to October 2026
expected_dates <- seq(
  as.Date("2026-05-01"),
  as.Date("2026-10-31"),
  by = "day"
)

# Available dates
available_dates <- sort(
  unique(file_inventory$date)
)

# Identify dates without a corresponding daily file
missing_dates <- setdiff(
  expected_dates,
  available_dates
)

missing_dates

# Count files available in each month
expected_months <- format(
  seq(
    as.Date("2026-05-01"),
    as.Date("2026-10-01"),
    by = "month"
  ),
  "%Y-%m"
)

monthly_file_counts <- data.frame(
  month = expected_months,
  files_available = as.integer(
    table(
      factor(
        file_inventory$month,
        levels = expected_months
      )
    )
  )
)

monthly_file_counts

# Available date range in each month
monthly_date_ranges <- do.call(
  rbind,
  lapply(
    split(file_inventory$date, file_inventory$month),
    function(x) {
      data.frame(
        month = format(min(x), "%Y-%m"),
        first_available_date = min(x),
        last_available_date = max(x)
      )
    }
  )
)

row.names(monthly_date_ranges) <- NULL

monthly_date_ranges


# 3. Check file sizes and daily row counts --------------------

file_stats <- data.frame(
  file = file_inventory$file,
  folder = file_inventory$folder,
  date = file_inventory$date,
  month = file_inventory$month,
  file_size_mb = round(
    file.info(traffic_files)$size / (1024^2),
    2
  ),
  rows = NA_integer_
)

# Count rows in each daily file
for (i in seq_along(traffic_files)) {
  
  traffic_day <- read.csv(
    traffic_files[i],
    stringsAsFactors = FALSE
  )
  
  file_stats$rows[i] <- nrow(traffic_day)
  
}

# Inspect the 15 smallest files
file_stats[
  order(file_stats$rows),
][1:min(15, nrow(file_stats)), ]

# Summary of file sizes
summary(file_stats$file_size_mb)

# Summary of daily row counts
summary(file_stats$rows)

# Summarise row counts by month
monthly_row_summary <- do.call(
  rbind,
  lapply(
    split(file_stats, file_stats$month),
    function(x) {
      data.frame(
        month = x$month[1],
        total_rows = sum(x$rows),
        average_rows = round(mean(x$rows)),
        minimum_rows = min(x$rows),
        maximum_rows = max(x$rows)
      )
    }
  )
)

row.names(monthly_row_summary) <- NULL

monthly_row_summary


# 4. Check file structure and column consistency -------------

# Read column names without loading the full files
file_columns <- lapply(
  traffic_files,
  function(file) {
    names(
      read.csv(
        file,
        nrows = 0
      )
    )
  }
)

# Use the first file as the reference
reference_columns <- file_columns[[1]]

# Check whether all files have the same columns
same_columns <- vapply(
  file_columns,
  function(x) {
    identical(x, reference_columns)
  },
  logical(1)
)

table(same_columns)

# Display files with different column structures
file_inventory[!same_columns, ]

# Inspect the first daily file
first_file <- read.csv(
  traffic_files[1],
  stringsAsFactors = FALSE
)

# Column names
names(first_file)

# Data types
str(first_file)

# First few records
head(first_file)


# 5. Inspect the site reference file -------------------------

sites <- read.csv(
  file.path(source_folder, "telemetry_sites.csv"),
  stringsAsFactors = FALSE
)

# Inspect its dimensions and column names
dim(sites)

names(sites)

head(sites)

# Check required site identifier
if (!"site" %in% names(sites)) {
  stop("The site reference file does not contain a 'site' column.")
}

# Number of unique reference sites
length(unique(sites$site))


# 6. Inspect categories and reporting coverage ---------------

# Initialise objects for collecting summary information.
# The full six-month dataset is not retained in memory.

all_vehicle_classes <- character()
all_sites <- character()
all_headings <- character()
all_speed_bins <- character()
all_time_bins <- character()

site_classification <- data.frame(
  site = character(),
  classification_scheme = character()
)

monthly_site_classification <- data.frame(
  month = character(),
  site = character(),
  classification_scheme = character()
)

other_records_by_month <- data.frame(
  month = character(),
  other_record_count = integer()
)

site_day_coverage <- data.frame(
  date = as.Date(character()),
  month = character(),
  site = character(),
  intervals_reported = integer()
)

site_month_presence <- data.frame(
  month = character(),
  site = character()
)

monthly_classification_counts <- data.frame(
  month = character(),
  classification_scheme = character(),
  records = integer()
)

# Read and inspect one daily file at a time
for (i in seq_along(traffic_files)) {
  
  traffic_day <- read.csv(
    traffic_files[i],
    stringsAsFactors = FALSE
  )
  
  current_month <- file_inventory$month[i]
  current_date <- file_inventory$date[i]
  
  # Collect unique vehicle classes
  all_vehicle_classes <- union(
    all_vehicle_classes,
    unique(traffic_day$vehicle_class)
  )
  
  # Collect unique monitoring sites
  all_sites <- union(
    all_sites,
    as.character(unique(traffic_day$site))
  )
  
  # Collect unique headings
  all_headings <- union(
    all_headings,
    unique(traffic_day$heading)
  )
  
  # Collect unique speed categories
  all_speed_bins <- union(
    all_speed_bins,
    unique(traffic_day$speed_bin)
  )
  
  # Collect unique time intervals
  all_time_bins <- union(
    all_time_bins,
    unique(traffic_day$time_bin)
  )
  
  # Identify the classification scheme
  traffic_day$classification_scheme <- ifelse(
    grepl("^4bin:", traffic_day$vehicle_class),
    "4-bin",
    ifelse(
      grepl("^12bin:", traffic_day$vehicle_class),
      "12-bin",
      "Other"
    )
  )
  
  # Count records by classification scheme
  classification_counts <- as.data.frame(
    table(traffic_day$classification_scheme)
  )
  
  names(classification_counts) <- c(
    "classification_scheme",
    "records"
  )
  
  classification_counts$month <- current_month
  
  monthly_classification_counts <- rbind(
    monthly_classification_counts,
    classification_counts[
      ,
      c("month", "classification_scheme", "records")
    ]
  )
  
  # Count records classified as Other
  other_records_by_month <- rbind(
    other_records_by_month,
    data.frame(
      month = current_month,
      other_record_count = sum(
        traffic_day$classification_scheme == "Other"
      )
    )
  )
  
  # Collect site and classification combinations.
  # Other is excluded because it is not a classification scheme.
  current_site_classification <- unique(
    traffic_day[
      traffic_day$classification_scheme != "Other",
      c("site", "classification_scheme")
    ]
  )
  
  current_site_classification$site <- as.character(
    current_site_classification$site
  )
  
  # Store overall site classification combinations
  site_classification <- rbind(
    site_classification,
    current_site_classification
  )
  
  # Store site classification combinations by month
  current_monthly_site_classification <- current_site_classification
  
  current_monthly_site_classification$month <- current_month
  
  monthly_site_classification <- rbind(
    monthly_site_classification,
    current_monthly_site_classification[
      ,
      c("month", "site", "classification_scheme")
    ]
  )
  
  # Record which sites appear in each month
  site_month_presence <- rbind(
    site_month_presence,
    data.frame(
      month = current_month,
      site = as.character(unique(traffic_day$site))
    )
  )
  
  # Count unique time intervals reported by each site
  current_coverage <- aggregate(
    time_bin ~ site,
    data = traffic_day,
    FUN = function(x) length(unique(x))
  )
  
  names(current_coverage)[2] <- "intervals_reported"
  
  current_coverage$date <- current_date
  current_coverage$month <- current_month
  current_coverage$site <- as.character(current_coverage$site)
  
  site_day_coverage <- rbind(
    site_day_coverage,
    current_coverage[
      ,
      c("date", "month", "site", "intervals_reported")
    ]
  )
  
}

# Remove duplicate site and classification combinations
site_classification <- unique(site_classification)

# Remove duplicate monthly site and classification combinations
monthly_site_classification <- unique(monthly_site_classification)

# Aggregate Other records into monthly totals
other_records_by_month <- aggregate(
  other_record_count ~ month,
  data = other_records_by_month,
  FUN = sum
)

other_records_by_month <- other_records_by_month[
  order(other_records_by_month$month),
]

row.names(other_records_by_month) <- NULL

# Remove duplicate site-classification combinations
site_classification <- unique(site_classification)

# Remove duplicate site-month combinations
site_month_presence <- unique(site_month_presence)

# Sort collected categories
all_vehicle_classes <- sort(all_vehicle_classes)
all_sites <- sort(all_sites)
all_headings <- sort(all_headings)
all_speed_bins <- sort(all_speed_bins)
all_time_bins <- sort(all_time_bins)


# 7. Inspect vehicle classifications -------------------------

# List all unique vehicle classes
all_vehicle_classes

length(all_vehicle_classes)

# Total records by classification scheme
classification_totals <- aggregate(
  records ~ classification_scheme,
  data = monthly_classification_counts,
  FUN = sum
)

classification_totals

# Classification counts by month
classification_by_month <- xtabs(
  records ~ month + classification_scheme,
  data = monthly_classification_counts
)

classification_by_month

# Records classified as Other by month
other_records_by_month


# 8. Check classification schemes by site --------------------

# Display the classification scheme used by each site
site_classification <- site_classification[
  order(site_classification$site),
]

site_classification

# Count sites using each classification scheme
table(site_classification$classification_scheme)

# Check whether any site uses multiple schemes
scheme_count_by_site <- aggregate(
  classification_scheme ~ site,
  data = site_classification,
  FUN = function(x) length(unique(x))
)

sites_using_multiple_schemes <- scheme_count_by_site[
  scheme_count_by_site$classification_scheme > 1,
]

sites_using_multiple_schemes

# Count distinct sites by classification scheme in each month
monthly_site_classification_counts <- aggregate(
  site ~ month + classification_scheme,
  data = monthly_site_classification,
  FUN = function(x) length(unique(x))
)

names(monthly_site_classification_counts)[3] <- "sites"

monthly_site_classification_counts


# Note:
# site_classification records the schemes observed across all months.
# monthly_site_classification records the schemes used by each site
# in each individual month.
# classification_by_month contains record counts, not site counts.


# 9. Inspect sites, headings, speed bins and time intervals ----

# Unique monitoring sites
length(all_sites)

all_sites

# Unique heading categories
length(all_headings)

all_headings

# Unique speed categories
length(all_speed_bins)

all_speed_bins

# Unique time intervals
length(all_time_bins)

all_time_bins


# 10. Check site coverage across months ----------------------

# Number of sites represented in each month
monthly_site_counts <- aggregate(
  site ~ month,
  data = site_month_presence,
  FUN = function(x) length(unique(x))
)

names(monthly_site_counts)[2] <- "sites_reporting"

monthly_site_counts

# Create a month-by-site presence table
site_presence_table <- xtabs(
  ~ month + site,
  data = site_month_presence
)

# Convert to presence/absence values
site_presence_table <- (site_presence_table > 0) * 1

site_presence_table

# Sites present in all six months
sites_in_all_months <- colnames(site_presence_table)[
  colSums(site_presence_table) == nrow(site_presence_table)
]

sites_in_all_months

# Sites present in only some months
sites_not_in_all_months <- colnames(site_presence_table)[
  colSums(site_presence_table) < nrow(site_presence_table)
]

sites_not_in_all_months


# 11. Check daily reporting interval coverage ---------------

# Summary of intervals reported per site-day
summary(site_day_coverage$intervals_reported)

# Identify site-days with fewer than 96 intervals
# A complete 24-hour day contains 96 fifteen-minute intervals.
incomplete_site_days <- site_day_coverage[
  site_day_coverage$intervals_reported < 96,
]

# Number of site-days with fewer than 96 intervals
nrow(incomplete_site_days)

# Inspect the 20 site-days with the fewest intervals
incomplete_site_days <- incomplete_site_days[
  order(incomplete_site_days$intervals_reported),
]

head(incomplete_site_days, 20)

# Summarise reporting coverage by month
monthly_interval_summary <- do.call(
  rbind,
  lapply(
    split(site_day_coverage, site_day_coverage$month),
    function(x) {
      data.frame(
        month = x$month[1],
        site_days = nrow(x),
        average_intervals = round(
          mean(x$intervals_reported),
          2
        ),
        median_intervals = median(x$intervals_reported),
        minimum_intervals = min(x$intervals_reported),
        maximum_intervals = max(x$intervals_reported)
      )
    }
  )
)

row.names(monthly_interval_summary) <- NULL

monthly_interval_summary

# Average number of intervals reported per site
site_coverage_summary <- aggregate(
  intervals_reported ~ site,
  data = site_day_coverage,
  FUN = mean
)

names(site_coverage_summary)[2] <- "mean_intervals_per_day"

site_coverage_summary <- site_coverage_summary[
  order(site_coverage_summary$mean_intervals_per_day),
]

head(site_coverage_summary, 15)


# 12. Investigate the October 23 source file ------------------

oct23_date <- as.Date("2026-10-23")

oct23_index <- which(
  file_inventory$date == oct23_date
)

if (length(oct23_index) == 1) {
  
  oct23 <- read.csv(
    traffic_files[oct23_index],
    stringsAsFactors = FALSE
  )
  
  # Number of records
  nrow(oct23)
  
  # Sites represented
  sort(unique(oct23$site))
  
  # Number of time intervals
  length(unique(oct23$time_bin))
  
  # Records by site
  table(oct23$site)
  
  # Time intervals recorded
  sort(unique(oct23$time_bin))
  
  # Inspect the records
  oct23
  
} else {
  
  message("No single October 23 source file was found.")
  
}


# 13. Investigate site 1224 -----------------------------------

# Check whether site 1224 appears in traffic observations
site_1224_records <- site_day_coverage[
  site_day_coverage$site == "1224",
]

site_1224_records

# Check whether site 1224 appears in the reference file
sites[
  as.character(sites$site) == "1224",
]


# 14. Compare traffic sites with the site reference -----------

# Convert site identifiers to character for comparison
traffic_sites <- sort(
  unique(as.character(all_sites))
)

reference_sites <- sort(
  unique(as.character(sites$site))
)

# Traffic sites without reference information
traffic_sites_without_reference <- setdiff(
  traffic_sites,
  reference_sites
)

traffic_sites_without_reference

# Reference sites without traffic observations
reference_sites_without_traffic <- setdiff(
  reference_sites,
  traffic_sites
)

reference_sites_without_traffic

# Compare the total number of unique sites
length(traffic_sites)

length(reference_sites)


# 15. Summary of initial inspection --------------------------

# File availability
monthly_file_counts

missing_dates

monthly_date_ranges

# Daily record counts
monthly_row_summary

# Vehicle classification counts
classification_totals

classification_by_month

other_records_by_month

# Classification schemes by site
table(site_classification$classification_scheme)

sites_using_multiple_schemes

# Site coverage
monthly_site_counts

sites_in_all_months

sites_not_in_all_months

# Reporting interval coverage
monthly_interval_summary

summary(site_day_coverage$intervals_reported)

# October 23
if (exists("oct23")) {
  nrow(oct23)
}

# Site reference mismatches
traffic_sites_without_reference

reference_sites_without_traffic


# ============================================================
# End of initial data inspection
# ============================================================
