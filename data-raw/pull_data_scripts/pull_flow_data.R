# If any of the queries do not work the code is set up to fail. This is on purpose
# because the queries aren't working we shouldn't be updating data.

### Pull Flow Data for each JPE tributary --------------------------------------

# Recent continuous flow data ---------------------------------------------------
# The full historical continuous (15-minute) record is pulled and cached separately in
# cache_flow_data.R because dataRetrieval::read_waterdata_continuous() only allows 3 years of
# data per request. Here we only pull the most recent two years (which fits within that limit),
# summarize to daily mean/min/max, and bind it with the cached historical record below.
recent_flow_start_date <- Sys.Date() - lubridate::years(2)
recent_flow_end_date <- Sys.Date()

# Pull the most recent continuous flow record for one gage and summarize to daily mean/min/max.
pull_recent_continuous_flow_stats <- function(gage_number, stream, site_group = NA_character_) {
  message(
    "Pulling continuous flow for USGS-", gage_number, ": ",
    recent_flow_start_date, " to ", recent_flow_end_date
  )

  continuous_query <- dataRetrieval::read_waterdata_continuous(
    monitoring_location_id = paste0("USGS-", gage_number),
    parameter_code = "00060",
    time = paste0(recent_flow_start_date, "/", recent_flow_end_date)
  )

  continuous_query |>
    dplyr::mutate(
      date = as.Date(time),
      value = ifelse(value < 0, NA_real_, value) # negative instantaneous readings are sensor noise
    ) |>
    dplyr::group_by(date) |>
    dplyr::summarise(
      mean = ifelse(all(is.na(value)), NA_real_, mean(value, na.rm = TRUE)),
      min = ifelse(all(is.na(value)), NA_real_, min(value, na.rm = TRUE)),
      max = ifelse(all(is.na(value)), NA_real_, max(value, na.rm = TRUE)),
      .groups = "drop"
    ) |>
    tidyr::pivot_longer(c(mean, min, max), names_to = "statistic", values_to = "value") |>
    dplyr::mutate(
      stream = stream,
      site_group = site_group,
      gage_agency = "USGS",
      gage_number = gage_number,
      parameter = "flow"
    )
}

## Battle Creek ----------------------------------------------------------------
### Flow Data Pull
#### Gage Agency (USGS, # 11376550)
battle_creek_daily_flows <- pull_recent_continuous_flow_stats(
  "11376550",
  stream = "battle creek",
  site_group = "battle creek"
)

## Butte Creek -----------------------------------------------------------------
### Flow Data Pull
#### Gage Agency (USGS, BCK)

# Grant Heneley at CDFW recommended using USGS instead of CDEC because CDEC will sometimes have weird datapoints
butte_creek_daily_flows <- pull_recent_continuous_flow_stats(
  "11390000",
  stream = "butte creek",
  site_group = "butte creek"
)

## Clear Creek -----------------------------------------------------------------
### Flow Data Pull
#### Gage Agency (CDEC, IGO)
clear_creek_daily_flows <- pull_recent_continuous_flow_stats(
  "11372000",
  stream = "clear creek",
  site_group = "clear creek"
)

## Deer Creek ------------------------------------------------------------------
### Flow Data Pull
#### Gage Agency (USGS, 11383500)
deer_creek_daily_flows <- pull_recent_continuous_flow_stats(
  "11383500",
  stream = "deer creek",
  site_group = "deer creek"
)

## Feather River ---------------------------------------------------------------
# Feather High Flow Channel

# Guidance from Kassie Henley (DWR)
# Do not use GRL because unreliable, especially at low flows
# Use ORF + TFB + TAO to represent HFC
# See data-raw/analysis/feather-flow-qc for more details

# Compared to other locations Feather River follows a different workflow
# USGS only includes data through ~2024 and does not have continuous data
# CDEC is usually only available starting ~2019
# This means we need to stitch these data sources together

# (1) Pull the most up to date data from CDEC here and summarize as daily mean, min, max, bind with the daily mean from USGS
# (2) Post processing step that involves adding together gages

# Pull a Feather River gage's USGS daily mean flow, optionally stitched together with a CDEC
# series. CDEC generally has a shorter period of record but better recent coverage, and can
# report min/max (not just mean) depending on the sensor's duration code.
build_feather_gage_flow <- function(usgs_id, gage_number,
                                     usgs_min_date = NULL,
                                     usgs_cutoff_date = NULL,
                                     cdec_station = NULL,
                                     cdec_dur_code = NULL,
                                     cdec_sensor_num = NULL,
                                     cdec_start_date = NULL) {
  usgs_daily_mean <- dataRetrieval::read_waterdata_daily(usgs_id, "00060") |>
    dplyr::select(time, value) |>
    dplyr::as_tibble() |>
    dplyr::rename(date = time) |>
    dplyr::mutate(
      date = as.Date(date),
      gage_agency = "USGS",
      gage_number = gage_number,
      statistic = "mean"
    ) |>
    dplyr::select(-geometry)

  if (!is.null(usgs_min_date)) usgs_daily_mean <- dplyr::filter(usgs_daily_mean, date >= usgs_min_date)
  if (!is.null(usgs_cutoff_date)) usgs_daily_mean <- dplyr::filter(usgs_daily_mean, date < usgs_cutoff_date)

  if (is.null(cdec_station)) {
    return(usgs_daily_mean |> dplyr::mutate(parameter = "flow") |> dplyr::filter(!is.na(date)))
  }

  cdec_daily_stats <- CDECRetrieve::cdec_query(
    station = cdec_station,
    dur_code = cdec_dur_code,
    sensor_num = cdec_sensor_num,
    start_date = cdec_start_date
  ) |>
    dplyr::select(-c(agency_cd, location_id, parameter_cd)) |>
    dplyr::rename(date = datetime, value = parameter_value) |>
    dplyr::mutate(gage_agency = "CDEC", gage_number = cdec_station, date = as.Date(date)) |>
    dplyr::group_by(date, gage_agency, gage_number) |>
    dplyr::summarise(
      mean = ifelse(all(is.na(value)), NA_real_, mean(value, na.rm = TRUE)),
      min = ifelse(all(is.na(value)), NA_real_, min(value, na.rm = TRUE)),
      max = ifelse(all(is.na(value)), NA_real_, max(value, na.rm = TRUE)),
      .groups = "drop"
    ) |>
    tidyr::pivot_longer(c(mean, min, max), names_to = "statistic", values_to = "value")

  dplyr::bind_rows(usgs_daily_mean, cdec_daily_stats) |>
    dplyr::mutate(parameter = "flow") |>
    dplyr::filter(!is.na(date))
}

### ORF ----------------------------
# As of 08/28/26 there is not a lag in the CDEC data.
feather_orf_usgs_cdec <- build_feather_gage_flow(
  "USGS-11406930", "USGS-11406930",
  usgs_cutoff_date = "2019-12-26",
  cdec_station = "ORF", cdec_dur_code = "E", cdec_sensor_num = "20",
  cdec_start_date = "2019-12-25" # earliest available as of 8/28/26
)

### TFB ----------------------
# As of 08/28/26 it appears that there is a lag in the CDEC data. Data posted through 8/22
feather_tfb_usgs_cdec <- build_feather_gage_flow(
  "USGS-11407000", "USGS-11407000",
  usgs_min_date = "1988-01-01", usgs_cutoff_date = "2021-08-30",
  cdec_station = "TFB", cdec_dur_code = "H", cdec_sensor_num = "20",
  cdec_start_date = "2021-08-30" # earliest the data is available
)

### TAO -------------------
# Only the daily mean is available on USGS and there is no CDEC series for this gage.
# This gage stops 2025-09-30
feather_tao_usgs <- build_feather_gage_flow(
  "USGS-11406920", "USGS-11406920",
  usgs_min_date = "1988-01-01"
)

# Combined HFC
feather_hfc <- feather_orf_usgs_cdec |>
  dplyr::select(date, statistic, parameter, orf = value) |>
  dplyr::full_join(
    feather_tfb_usgs_cdec |>
      dplyr::select(date, statistic, parameter, tfb = value)
  ) |>
  dplyr::full_join(
    feather_tao_usgs |>
      dplyr::select(date, statistic, parameter, tao = value)
  ) |>
  dplyr::mutate(value = orf + tfb + tao,
                date = as.Date(date),
                stream = "feather river",
                site_group = "upper feather hfc",
                gage_agency = "USGS/CDEC",
                gage_number = "11407000/TFB + 11406930/ORF + 11406920/TAO") |>
  dplyr::select(-c(tfb, orf, tao))

# Feather Low Flow Channel
# Guidance from Casey Campos (DWR): There is also side flow input from the hatchery that increases flow another ~100 cfs.
# There’s no publicly available single source to get the total flow downstream of the hatchery.
# You can use ORF + TFB to get the total LFC flow downstream of the hatchery.
feather_lfc <- feather_orf_usgs_cdec |>
  dplyr::select(date, statistic, parameter, orf = value) |>
  dplyr::full_join(
    feather_tfb_usgs_cdec |>
      dplyr::select(date, statistic, parameter, tfb = value)
  ) |>
  dplyr::mutate(
    date = as.Date(date),
    value = orf + tfb,
    stream = "feather river",
    site_group = "upper feather lfc",
    gage_agency = "USGS/CDEC",
    gage_number = "11407000/TFB + 11406930/ORF"
  ) |>
  dplyr::select(-c(tfb, orf))

#Lower Feather data
lower_feather_river_data_query <- CDECRetrieve::cdec_query(
  station = "FSB",
  dur_code = "H",
  sensor_num = "20",
  start_date = "2010-01-01"
)

lower_feather_river_daily_flows <- lower_feather_river_data_query |>
  dplyr::mutate(
    parameter_value = ifelse(
      parameter_value < 0,
      NA_real_,
      parameter_value
    )
  ) |>
  dplyr::group_by(date = as.Date(datetime)) |>
  dplyr::summarise(
    mean = ifelse(
      all(is.na(parameter_value)),
      NA,
      mean(parameter_value, na.rm = TRUE)
    ),
    max = ifelse(
      all(is.na(parameter_value)),
      NA,
      max(parameter_value, na.rm = TRUE)
    ),
    min = ifelse(
      all(is.na(parameter_value)),
      NA,
      min(parameter_value, na.rm = TRUE)
    )
  ) |>
  tidyr::pivot_longer(
    mean:min,
    names_to = "statistic",
    values_to = "value"
  ) |>
  dplyr::mutate(
    stream = "feather river",
    site_group = "lower feather river",
    gage_agency = "CDEC",
    gage_number = "FSB",
    parameter = "flow"
  )

## Mill Creek ------------------------------------------------------------------
### Flow Data Pull
#### Gage Agency (USGS, 11381500)
mill_creek_daily_flows <- pull_recent_continuous_flow_stats(
  "11381500",
  stream = "mill creek",
  site_group = "mill creek"
)

## Sacramento River ------------------------------------------------------------
### Flow Data Pull
#### Gage Agency (USGS, 11381500)
# site_group is added below when combining flow data, since this same gage represents both
# the tisdale and knights landing site groups
sac_river_daily_flows <- pull_recent_continuous_flow_stats(
  "11390500",
  stream = "sacramento river"
)

# Red Bluff --------------------------------------------------------------------
# but may be in the future

### Flow Data Pull
#### Gage Agency (USGS, 11377100)
rbdd_daily_flows <- pull_recent_continuous_flow_stats(
  "11377100",
  stream = "sacramento river",
  site_group = "red bluff diversion dam"
)

## Yuba River ------------------------------------------------------------------
### Flow Data Pull
#### Gage Agency (USGS, 11421000)
yuba_river_daily_flows <- pull_recent_continuous_flow_stats(
  "11421000",
  stream = "yuba river",
  site_group = "yuba river"
)

# Define the required object names
required_objects <- c(
  "battle_creek_daily_flows",
  "butte_creek_daily_flows",
  "clear_creek_daily_flows",
  "deer_creek_daily_flows",
  "feather_hfc",
  "feather_lfc",
  "lower_feather_river_daily_flows",
  "mill_creek_daily_flows",
  "sac_river_daily_flows",
  "rbdd_daily_flows",
  "yuba_river_daily_flows"
)

# Check if all objects exist
if (!all(sapply(required_objects, exists))) {
  stop(
    "One or more of the flow queries do not exist in the environment."
  )
}

# If all objects exist, continue with the rest of the code
print("All required objects exist. Proceeding...")

# Combine all flow data from different streams
# Created a site group variable so that the hfc and lfc will bind with the correct sites
# so need to bind feather to the site lookup separately
recent_flow_daily <- data.table::rbindlist(
  list(
    battle_creek_daily_flows,
    butte_creek_daily_flows,
    clear_creek_daily_flows,
    deer_creek_daily_flows,
    mill_creek_daily_flows,
    sac_river_daily_flows |> dplyr::mutate(site_group = "tisdale"),
    sac_river_daily_flows |>
      dplyr::mutate(site_group = "knights landing"),
    rbdd_daily_flows,
    yuba_river_daily_flows,
    feather_hfc, # sum of TFB, ORF, TAO
    feather_lfc, # sum of TFB and ORF
    lower_feather_river_daily_flows
  ),
  use.names = TRUE,
  fill = TRUE
) |>
  dplyr::filter(lubridate::year(date) > 1990)

# Bind the freshly pulled continuous data (most recent two years) with the full historical
# record cached by cache_flow_data.R. The two windows can overlap as time passes since the
# cache is a static snapshot, so duplicates are removed here, keeping the freshly pulled value.
flow_data_cached <- readRDS("data-raw/pull_data_scripts/cached_data/flow_data_cached.rds")

flow_daily <- dplyr::bind_rows(recent_flow_daily, flow_data_cached) |>
  dplyr::distinct(date, stream, site_group, parameter, statistic, .keep_all = TRUE)

# Check to make sure there are no duplicates because the reshaping with result in values of 0 and 1 if duplicates exist which is a major issue.
find_duplicates <- flow_daily |>
  group_by(date, stream, site_group, parameter, statistic) |>
  tally() |>
  filter(n > 1)

if (nrow(find_duplicates) > 0) {
  stop(
    "Duplicates exist in the flow_daily table. Resolve these duplicates before proceeding."
  )
}

data.table::setDT(flow_daily)

# Reshape the data to 'wider' format (like pivot_wider)
reshaped_flow <- data.table::dcast(
  flow_daily,
  ... ~ statistic,
  value.var = "value"
)


# Group by week and year, and perform the summarization
updated_flow_data <- reshaped_flow[,
                                            .(
                                              max = max(max, na.rm = TRUE),
                                              mean = mean(mean, na.rm = TRUE),
                                              min = min(min, na.rm = TRUE)
                                            ),
                                            by = .(
                                              week = lubridate::week(date),
                                              year = lubridate::year(date),
                                              stream,
                                              gage_number,
                                              gage_agency,
                                              site_group,
                                              parameter
                                            )
]

# Display the final result
print(head(updated_flow_data))

flow_data <- updated_flow_data |>
  dplyr::filter(!is.na(week), year >= 1990) |>
  dplyr::mutate(
    max = ifelse(max == "-Inf", NA, max),
    min = ifelse(min == "Inf", NA, min)
  ) |>
  tidyr::pivot_longer(
    max:min,
    names_to = "statistic",
    values_to = "value"
  ) |>
  glimpse()


#Save package
usethis::use_data(flow_data, overwrite = TRUE)
