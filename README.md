# VICFREIGHT

**Exploring Victorian Freight-Related Road Activity**

VICFREIGHT is an R package for exploring Victorian road traffic activity, with an emphasis on heavy-vehicle movements, vehicle composition, traffic patterns across monitoring locations, and reporting completeness.

The package includes prepared traffic data, functions for summarising and comparing traffic activity, and an interactive Shiny dashboard.

## Intended users and purpose

VICFREIGHT is intended for people interested in investigating road traffic patterns across Victorian monitoring locations. It provides tools to explore traffic volumes, compare sites, examine vehicle composition and identify gaps in traffic reporting.

The dashboard brings these analyses together so users can investigate patterns across locations and time periods.

## Data

The package includes traffic monitoring data sourced from the Victorian Government's open data portal:

[Telemetry Traffic Counts and Classification](https://opendata.transport.vic.gov.au/dataset/telemetry-traffic-counts-and-classification)

The package includes a prepared snapshot of traffic monitoring data covering May to October 2026. The included datasets are fixed to this collection period and are not automatically refreshed when new observations become available from the original data source. The `data-raw` scripts document the preparation process used to generate the packaged datasets.

The data contains traffic counts aggregated into 15-minute intervals, with information about monitoring sites, vehicle classifications, headings and speed categories.

The package includes three prepared datasets:

- `traffic_counts`: Traffic observations, including date, time interval, monitoring site, vehicle classification, speed category and traffic volume.
- `telemetry_sites`: Monitoring site descriptions and geographic coordinates.
- `site_day_coverage`: Daily reporting coverage for each monitoring site, including the number of intervals reported and whether the day is complete.

Incomplete reporting days and observations without matching site metadata are retained so that data coverage can be examined rather than silently excluded.

## Installation

Install the package from GitHub using `devtools`:

```r
install.packages("devtools")

devtools::install_github(
  "ETC5523-2026/etc5523-assignment-4-vikywayne"
)
```

## Launching the dashboard

After installation, launch the interactive VICFREIGHT dashboard with:

```r
vicfreight::run_vicfreight()
```

The dashboard contains four sections:

1. **Overview** – Explore monitoring locations, traffic activity and vehicle composition.
2. **Site comparison** – Compare traffic volumes across selected monitoring sites and date ranges.
3. **Traffic trends** – Investigate daily or monthly traffic patterns across selected sites and vehicle classes.
4. **Reporting coverage** – Examine the completeness of traffic reporting and identify incomplete site-days.

The available controls allow users to filter the displayed results by monitoring site, date range, vehicle class and other relevant selections. The charts and tables update in response to these selections.

## Package functions

VICFREIGHT provides exported functions for analysing the included traffic data:

- `summarise_traffic()` – Summarise traffic observations using selected grouping variables and filters.
- `compare_sites()` – Compare traffic activity across selected monitoring sites.
- `summarise_vehicle_mix()` – Summarise the distribution and percentage composition of vehicle classes.
- `summarise_traffic_trends()` – Summarise traffic activity over daily or monthly periods.
- `run_vicfreight()` – Launch the interactive Shiny dashboard.

Function documentation is available through R help after installing the package. For example:

```r
?vicfreight::summarise_traffic
?vicfreight::compare_sites
?vicfreight::summarise_vehicle_mix
?vicfreight::summarise_traffic_trends
```

## Reproducibility

The `data-raw` directory contains scripts used to inspect, import and prepare the original traffic data and generate the datasets included in the package.

The dashboard uses the datasets bundled with the installed package and does not require users to supply the original CSV files when launching the application.

## Documentation

The package website and function reference documentation are available here:

**Package website:** To be added after the pkgdown site is published.

## Generative AI declaration

I used **ChatGPT (OpenAI)** as a supporting tool during the development, troubleshooting and documentation of VICFREIGHT. Its use primarily involved understanding R package development, resolving programming errors, troubleshooting the Shiny application, improving code formatting and organisation, and clarifying technical concepts.

AI assistance was used in the following areas:

- **Data preparation:** Discussing how to prepare the Victorian traffic-count data, handle different vehicle classification schemes, retain observations with unmatched site metadata and calculate reporting coverage.
- **R package development:** Understanding package structure, configuring dependencies, creating exported functions and documenting datasets.
- **Shiny application development:** Troubleshooting application errors, resolving CSS and formatting issues, improving interactive charts and maps, and understanding how application inputs affect displayed outputs.
- **Testing and debugging:** Investigating installation messages, resolving dependency issues, interpreting `devtools::check()` results and checking that the application and package functions behaved as expected.
- **Documentation and presentation:** Improving code readability, organising the README and clarifying explanations of the dashboard's controls, visualisations and outputs.

### Examples of AI-assisted questions

The following are representative examples based on discussions during this assignment. They have been paraphrased for clarity and are not verbatim transcripts of every interaction.

1. *"The traffic dataset contains both four-bin and twelve-bin vehicle classifications. How should these be handled when calculating vehicle composition so that traffic volumes are not double-counted?"*

2. *"Some traffic observations have no matching entry in the site metadata. Should these records be removed, or is there a way to retain them while identifying the missing metadata?"*

3. *"How can I calculate daily reporting completeness when each monitoring site is expected to report 96 fifteen-minute intervals, and how should incomplete days be represented?"*

4. *"My Shiny application is showing a parsing error after I changed the CSS. How can I identify the incorrect quotation marks or braces without replacing the entire application?"*

5. *"The Plotly chart is not rendering correctly. How can I convert the ggplot object and apply the layout and configuration without relying on an additional pipe operator?"*

6. *"How can I make the traffic trend chart show gaps where reporting periods are missing instead of connecting observations across those periods?"*

7. *"Why does the reporting coverage chart need a different approach to its y-axis limits when displaying proportions in a 100% stacked chart?"*

8. *"The package installs successfully, but `devtools::check()` reports a note about future file timestamps. How should I interpret this result alongside the other checks?"*

### Review and responsibility

AI-generated suggestions, explanations and code recommendations were reviewed and adapted during development. The package was tested through installation, function testing and `devtools::check()`, and the Shiny application was run to examine its behaviour and outputs.

ChatGPT was used as a supporting development and troubleshooting tool rather than as an independent source of data or analytical evidence. The final implementation, analytical decisions, interpretation of results and submitted work remain my responsibility.

## Author

**Annamalai Vikash Raam Manoj**

Master of Business Analytics  
Monash University
