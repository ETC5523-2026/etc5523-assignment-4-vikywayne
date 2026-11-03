
# ============================================================
# VicFreight: Prepare package datasets
#
# Purpose:
# Prepare the May–October 2026 Victorian traffic-count data
# and monitoring-site reference information for the package.
#
# Outputs:
# - data/traffic_counts.rda
# - data/telemetry_sites.rda
# - data/site_day_coverage.rda
#
# Original source files are not modified.
# ============================================================


# 1. Setup ----------------------------------------------------

source_folder <- "data-raw/source"
output_folder <- "data"

# Create the package data folder if it does not exist
if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}

# Expected traffic columns
required_columns <- c(
  "date",
  "time_bin",
  "site",
  "heading",
  "vehicle_class",
  "speed_bin",
  "volume"
)

# Find daily traffic CSV files
traffic_files <- list.files(
  source_folder,
  pattern = "^TELEMETRYDATA_\\d{8}\\.csv$",
  recursive = TRUE,
  full.names = TRUE
)

if (length(traffic_files) == 0) {
  stop("No traffic CSV files found in data-raw/source.")
}

# Sort files chronologically using their filenames
file_dates <- as.Date(
  sub(
    "TELEMETRYDATA_(\\d{8})\\.csv",
    "\\1",
    basename(traffic_files)
  ),
  format = "%Y%m%d"
)

file_order <- order(file_dates)

traffic_files <- traffic_files[file_order]
file_dates <- file_dates[file_order]

message("Daily traffic files found: ", length(traffic_files))


# 2. Read and combine daily traffic files --------------------

traffic_list <- vector(
  "list",
  length(traffic_files)
)

for (i in seq_along(traffic_files)) {
  
  current_file <- traffic_files[i]
  
  traffic_day <- read.csv(
    current_file,
    stringsAsFactors = FALSE
  )
  
  # Check that all required columns are present
  missing_columns <- setdiff(
    required_columns,
    names(traffic_day)
  )
  
  if (length(missing_columns) > 0) {
    stop(
      "Missing required columns in ",
      basename(current_file),
      ": ",
      paste(missing_columns, collapse = ", ")
    )
  }
  
  # Retain the required traffic columns
  traffic_day <- traffic_day[
    ,
    required_columns,
    drop = FALSE
  ]
  
  # Standardise column types
  traffic_day$date <- as.Date(
    as.character(traffic_day$date),
    tryFormats = c(
      "%Y-%m-%d",
      "%d/%m/%Y",
      "%m/%d/%Y",
      "%Y/%m/%d"
    )
  )
  
  if (anyNA(traffic_day$date)) {
    stop(
      "Could not parse all dates in ",
      basename(current_file)
    )
  }
  
  traffic_day$time_bin <- as.character(
    traffic_day$time_bin
  )
  
  traffic_day$site <- as.character(
    traffic_day$site
  )
  
  traffic_day$heading <- as.character(
    traffic_day$heading
  )
  
  traffic_day$vehicle_class <- as.character(
    traffic_day$vehicle_class
  )
  
  traffic_day$speed_bin <- as.character(
    traffic_day$speed_bin
  )
  
  traffic_day$volume <- as.numeric(
    traffic_day$volume
  )
  
  # Add the source filename for traceability
  traffic_day$source_file <- basename(
    current_file
  )
  
  # Add the classification scheme
  traffic_day$classification_scheme <- ifelse(
    grepl("^4bin:", traffic_day$vehicle_class),
    "4-bin",
    ifelse(
      grepl("^12bin:", traffic_day$vehicle_class),
      "12-bin",
      "Other"
    )
  )
  
  # Add the month for temporal analysis
  traffic_day$month <- format(
    traffic_day$date,
    "%Y-%m"
  )
  
  traffic_list[[i]] <- traffic_day
  
  if (i %% 25 == 0 || i == length(traffic_files)) {
    message(
      "Processed ",
      i,
      " of ",
      length(traffic_files),
      " daily files."
    )
  }
}

# Combine all daily files into one dataset
traffic_counts <- do.call(
  rbind,
  traffic_list
)

row.names(traffic_counts) <- NULL

message(
  "Combined traffic records: ",
  format(nrow(traffic_counts), big.mark = ",")
)


# 3. Validate the combined traffic dataset -------------------

# Check the prepared dataset structure
str(traffic_counts)

# Check the date range
range(traffic_counts$date)

# Check the number of unique sites
length(unique(traffic_counts$site))

# Check the number of vehicle classes
length(unique(traffic_counts$vehicle_class))

# Check missing values in the main fields
colSums(
  is.na(
    traffic_counts[
      ,
      required_columns
    ]
  )
)

# Check whether volume contains negative values
if (any(traffic_counts$volume < 0, na.rm = TRUE)) {
  warning("Negative traffic volumes were found.")
}

# Check whether any volume values could not be converted
if (anyNA(traffic_counts$volume)) {
  warning(
    "Missing or non-numeric volume values were found."
  )
}


# 4. Read and prepare monitoring-site reference data ----------

sites <- read.csv(
  file.path(
    source_folder,
    "telemetry_sites.csv"
  ),
  stringsAsFactors = FALSE
)

# Check that the site identifier exists
if (!"site" %in% names(sites)) {
  stop(
    "The site reference file does not contain a 'site' column."
  )
}

# Standardise site identifiers
sites$site <- as.character(sites$site)

# Check for duplicate site identifiers
if (anyDuplicated(sites$site)) {
  stop(
    "Duplicate site identifiers found in telemetry_sites.csv. ",
    "Resolve these before joining the reference data."
  )
}

# Keep the complete reference dataset separately
telemetry_sites <- sites

message(
  "Reference sites: ",
  nrow(telemetry_sites)
)


# 5. Add site reference information to traffic records --------

# Identify metadata columns that overlap with traffic columns
metadata_columns <- setdiff(
  names(telemetry_sites),
  "site"
)

overlapping_columns <- intersect(
  metadata_columns,
  names(traffic_counts)
)

# Prefix overlapping metadata column names
if (length(overlapping_columns) > 0) {
  
  names(telemetry_sites)[
    match(
      overlapping_columns,
      names(telemetry_sites)
    )
  ] <- paste0(
    "site_",
    overlapping_columns
  )
  
}

# Match each traffic record to its reference site
site_match <- match(
  traffic_counts$site,
  telemetry_sites$site
)

# Add reference information without dropping unmatched records
for (column in setdiff(names(telemetry_sites), "site")) {
  
  traffic_counts[[column]] <- telemetry_sites[[column]][site_match]
  
}

# Flag whether reference information was available
traffic_counts$site_metadata_match <- !is.na(
  site_match
)

# Report traffic sites without reference information
traffic_sites_without_reference <- setdiff(
  unique(traffic_counts$site),
  telemetry_sites$site
)

if (length(traffic_sites_without_reference) > 0) {
  
  warning(
    "Traffic observations exist for sites without reference ",
    "information: ",
    paste(
      traffic_sites_without_reference,
      collapse = ", "
    )
  )
  
}

# Report reference sites without traffic observations
reference_sites_without_traffic <- setdiff(
  telemetry_sites$site,
  unique(traffic_counts$site)
)

if (length(reference_sites_without_traffic) > 0) {
  
  message(
    "Reference sites without traffic observations: ",
    paste(
      reference_sites_without_traffic,
      collapse = ", "
    )
  )
  
}


# 6. Calculate site-day reporting coverage -------------------

# Count unique reporting intervals for each site and date
site_day_coverage <- aggregate(
  time_bin ~ date + site,
  data = traffic_counts,
  FUN = function(x) length(unique(x))
)

names(site_day_coverage)[
  names(site_day_coverage) == "time_bin"
] <- "intervals_reported"

# Add expected interval count for a complete day
site_day_coverage$expected_intervals <- 96L

# Flag complete and incomplete site-days
site_day_coverage$complete_day <- (
  site_day_coverage$intervals_reported == 96
)

# Add month
site_day_coverage$month <- format(
  site_day_coverage$date,
  "%Y-%m"
)

# Sort the coverage dataset
site_day_coverage <- site_day_coverage[
  order(
    site_day_coverage$date,
    site_day_coverage$site
  ),
]

row.names(site_day_coverage) <- NULL

# Summarise reporting coverage
message(
  "Complete site-days: ",
  sum(site_day_coverage$complete_day)
)

message(
  "Incomplete site-days: ",
  sum(!site_day_coverage$complete_day)
)


# 7. Inspect the incomplete October 23 data -------------------

oct23 <- traffic_counts[
  traffic_counts$date == as.Date("2026-10-23"),
]

if (nrow(oct23) > 0) {
  
  message(
    "October 23 records retained: ",
    nrow(oct23)
  )
  
  message(
    "October 23 sites: ",
    length(unique(oct23$site))
  )
  
  message(
    "October 23 intervals: ",
    length(unique(oct23$time_bin))
  )
  
  # The records are retained in traffic_counts.
  # Their incomplete reporting is reflected in site_day_coverage.
  
}


# 8. Final validation -----------------------------------------

# Check prepared dataset dimensions
dim(traffic_counts)

dim(telemetry_sites)

dim(site_day_coverage)

# Check classification record counts
table(
  traffic_counts$classification_scheme,
  useNA = "ifany"
)

# Check monthly record counts
monthly_record_counts <- aggregate(
  volume ~ month,
  data = traffic_counts,
  FUN = length
)

names(monthly_record_counts)[2] <- "records"

monthly_record_counts

# Check monthly site-day coverage
monthly_coverage <- aggregate(
  complete_day ~ month,
  data = site_day_coverage,
  FUN = function(x) {
    sum(x)
  }
)

names(monthly_coverage)[2] <- "complete_site_days"

monthly_coverage

# Check the site metadata match
table(
  traffic_counts$site_metadata_match
)


# 9. Save package datasets ------------------------------------

save(
  traffic_counts,
  file = file.path(
    output_folder,
    "traffic_counts.rda"
  ),
  compress = "xz"
)

save(
  telemetry_sites,
  file = file.path(
    output_folder,
    "telemetry_sites.rda"
  ),
  compress = "xz"
)

save(
  site_day_coverage,
  file = file.path(
    output_folder,
    "site_day_coverage.rda"
  ),
  compress = "xz"
)


# 10. Completion message --------------------------------------

message("")
message("Data preparation completed.")
message("Prepared datasets saved in: ", output_folder)
message("")
message("Files created:")
message("- traffic_counts.rda")
message("- telemetry_sites.rda")
message("- site_day_coverage.rda")

# ============================================================
# End of data preparation
# ============================================================
