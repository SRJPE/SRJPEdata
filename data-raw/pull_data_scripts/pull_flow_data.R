# If any of the queries do not work the code is set up to fail. This is on purpose
# because the queries aren't working we shouldn't be updating data.

### Pull Flow Data for each JPE tributary --------------------------------------

## Battle Creek ----------------------------------------------------------------
### Flow Data Pull
#### Gage Agency (USGS, # 11376550)

# Pull data
battle_creek_data_query <- dataRetrieval::read_waterdata_daily(
  "USGS-11376550",
  "00060"
)
battle_creek_daily_flows <- battle_creek_data_query |> # rename to match new naming structure
  dplyr::select(time, value) |> 
  dplyr::as_tibble() |>
  dplyr::rename(date = time) |>
  dplyr::mutate(
    stream = "battle creek", # add additional columns for stream, gage info, and parameter
    site_group = "battle creek",
    gage_agency = "USGS",
    gage_number = "11376550",
    parameter = "flow",
    statistic = "mean"
  ) |> 
  dplyr::select(-geometry)

## Butte Creek -----------------------------------------------------------------
### Flow Data Pull
#### Gage Agency (USGS, BCK)

# Grant Heneley at CDFW recommended using USGS instead of CDEC because CDEC will sometimes have weird datapoints
# Pull data
butte_creek_data_query <- dataRetrieval::read_waterdata_daily("USGS-11390000", "00060")
butte_creek_daily_flows <- butte_creek_data_query %>%
  dplyr::select(time, value) %>%
  dplyr::as_tibble() %>%
  dplyr::rename(date = time) |>
  dplyr::mutate(
    value = ifelse(value < 0, NA_real_, value),
    stream = "butte creek",
    site_group = "butte creek",
    gage_agency = "USGS",
    gage_number = "11390000",
    parameter = "flow",
    statistic = "mean"
  ) |> 
  dplyr::select(-geometry)

## Clear Creek -----------------------------------------------------------------
### Flow Data Pull
#### Gage Agency (CDEC, IGO)
# Pull data
clear_creek_data_query <- dataRetrieval::read_waterdata_daily(
  "USGS-11372000",
  "00060"
)
clear_creek_daily_flows <- clear_creek_data_query |>
  dplyr::select(time, value) |>
  dplyr::as_tibble() |>
  dplyr::rename(date = time) |>
  dplyr::mutate(
    stream = "clear creek",
    site_group = "clear creek",
    gage_agency = "USGS",
    gage_number = "11372000",
    parameter = "flow",
    statistic = "mean" # if query returns instantaneous data then report a min, mean, and max
  ) |> 
  dplyr::select(-geometry) 

## Deer Creek ------------------------------------------------------------------
### Flow Data Pull
#### Gage Agency (USGS, 11383500)
# Pull data
deer_creek_data_query <- dataRetrieval::read_waterdata_daily(
  "USGS-11383500",
  "00060")

deer_creek_daily_flows <- deer_creek_data_query |>
  dplyr::select(time, value) |>
  dplyr::as_tibble() |>
  dplyr::rename(date = time) |>
  dplyr::mutate(
    stream = "deer creek",
    site_group = "deer creek",
    gage_agency = "USGS",
    gage_number = "11383500",
    parameter = "flow",
    statistic = "mean"
  ) |> 
  dplyr::select(-geometry)

## Feather River ---------------------------------------------------------------
#Pull data
# Feather High Flow Channel

# Guidance from Kassie Henley (DWR)
# Do not use GRL because unreliable, especially at low flows
# Use ORF + TFB + TAO to represent HFC
# See data-raw/analysis/feather-flow-qc for more details

# ORF
feather_orf_usgs_raw <- dataRetrieval::read_waterdata_daily(
  "USGS-11406930",
  "00060"
)
feather_orf_usgs <- feather_orf_usgs_raw |>
  dplyr::select(time, value) |>
  dplyr::as_tibble() |>
  dplyr::rename(date = time) |> 
  dplyr::mutate(date = as.Date(date))

feather_orf_cdec <- CDECRetrieve::cdec_query(
  station = "ORF",
  dur_code = "D",
  sensor_num = "41",
  start_date = "2025-10-01"
)

feather_orf_usgs_cdec <- feather_orf_usgs |>
  dplyr::select(-geometry) |>
  dplyr::mutate(gage_agency = "USGS", gage_number = "USGS-11406930") |>
  dplyr::bind_rows(
    feather_orf_cdec |>
      dplyr::select(-c(agency_cd, location_id, parameter_cd)) |>
      dplyr::rename(date = datetime, value = parameter_value) |>
      dplyr::mutate(gage_agency = "CDEC", gage_number = "ORF", date = as.Date(date))
  )
# TFB
feather_tfb_usgs_raw <- dataRetrieval::read_waterdata_daily(
  "USGS-11407000",
  "00060"
)

feather_tfb_usgs <- feather_tfb_usgs_raw |>
  dplyr::select(time, value) |>
  dplyr::as_tibble() |>
  dplyr::rename(date = time) |> 
  dplyr::mutate(date = as.Date(date))

feather_tfb_cdec <- CDECRetrieve::cdec_query(
  station = "TFB",
  dur_code = "D",
  sensor_num = "41",
  start_date = "2023-10-01"
)

feather_tfb_usgs_cdec <- feather_tfb_usgs |>
  dplyr::select(-geometry) |>
  dplyr::mutate(gage_agency = "USGS", gage_number = "USGS-11407000") |>
  dplyr::bind_rows(
    feather_tfb_cdec |>
      dplyr::select(-c(agency_cd, location_id, parameter_cd)) |>
      dplyr::rename(date = datetime, value = parameter_value) |>
      dplyr::mutate(gage_agency = "CDEC", gage_number = "TFB", date = as.Date(date))
  ) 
# TAO
feather_tao_usgs_raw <- dataRetrieval::read_waterdata_daily(
  "USGS-11406920",
  "00060"
)
feather_tao_usgs <- feather_tao_usgs_raw |>
  dplyr::select(time, value) |>
  dplyr::as_tibble() |>
  dplyr::rename(date = time) |>
  dplyr::mutate(gage_agency = "USGS", gage_number = "USGS-11406920") |>
  dplyr::select(-geometry)

# Combined HFC
feather_hfc <- feather_orf_usgs_cdec |>
  dplyr::select(date, orf = value) |>
  dplyr::full_join(
    feather_tfb_usgs_cdec |>
      dplyr::select(date, tfb = value)
  ) |>
  dplyr::full_join(
    feather_tao_usgs |>
      dplyr::select(date, tao = value)
  ) |> 
  dplyr::mutate(value = orf + tfb + tao,
                date = as.Date(date),
                stream = "feather river",
                site_group = "upper feather hfc",
                gage_agency = "USGS/CDEC",
                gage_number = "11407000/TFB + 11406930/ORF + 11406920/TAO",
                parameter = "flow",
                statistic = "mean") |> 
  dplyr::select(-c(tfb, orf, tao))

# Feather Low Flow Channel
# Guidance from Casey Campos (DWR): There is also side flow input from the hatchery that increases flow another ~100 cfs.
# There’s no publicly available single source to get the total flow downstream of the hatchery.
# You can use ORF + TFB to get the total LFC flow downstream of the hatchery.
feather_lfc <- feather_orf_usgs_cdec |>
  dplyr::select(date, orf = value) |>
  dplyr::full_join(
    feather_tfb_usgs_cdec |>
      dplyr::select(date, tfb = value)
  ) |>
  dplyr::mutate(
    date = as.Date(date),
    value = orf + tfb,
    stream = "feather river",
    site_group = "upper feather lfc",
    gage_agency = "USGS/CDEC",
    gage_number = "11407000/TFB + 11406930/ORF",
    parameter = "flow",
    statistic = "mean"
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

#Pull data
mill_creek_data_query <- dataRetrieval::read_waterdata_daily(
  "USGS-11381500",
  "00060"
)

mill_creek_daily_flows <- mill_creek_data_query |>
  dplyr::select(time, value) |>
  dplyr::as_tibble() |>
  dplyr::rename(date = time) |>
  dplyr::mutate(
    stream = "mill creek",
    site_group = "mill creek",
    gage_agency = "USGS",
    gage_number = "11381500",
    parameter = "flow",
    statistic = "mean"
  ) |> 
  dplyr::select(-geometry) 

## Sacramento River ------------------------------------------------------------
### Flow Data Pull
#### Gage Agency (USGS, 11381500)
# Pull data
sac_river_data_query <- dataRetrieval::read_waterdata_daily(
  "USGS-11390500",
  "00060"
)

sac_river_daily_flows <- sac_river_data_query |>
  dplyr::select(time, value) |>
  dplyr::as_tibble() |>
  dplyr::rename(date = time) |>
  dplyr::mutate(
    stream = "sacramento river",
    gage_agency = "USGS",
    gage_number = "11390500",
    parameter = "flow",
    statistic = "mean"
  ) |> 
  dplyr::select(-geometry)

# Red Bluff --------------------------------------------------------------------
# but may be in the future

### Flow Data Pull
#### Gage Agency (USGS, 11377100)
rbdd_data_query <- dataRetrieval::read_waterdata_daily(
  "USGS-11377100",
  "00060"
)

rbdd_daily_flows <- rbdd_data_query |>
  dplyr::select(time, value) |>
  dplyr::as_tibble() |>
  dplyr::rename(date = time) |>
  dplyr::mutate(
    stream = "sacramento river",
    site_group = "red bluff diversion dam",
    gage_agency = "USGS",
    gage_number = "11377100",
    parameter = "flow",
    statistic = "mean"
  ) |> 
  dplyr::select(-geometry)

## Yuba River ------------------------------------------------------------------
### Flow Data Pull
#### Gage Agency (USGS, 11421000)
# Pull data
yuba_river_data_query <- dataRetrieval::read_waterdata_daily(
  "USGS-11421000",
  "00060"
)

yuba_river_daily_flows <- yuba_river_data_query |>
  dplyr::select(time, value) |>
  dplyr::as_tibble() |>
  dplyr::rename(date = time) |>
  dplyr::mutate(
    stream = "yuba river",
    site_group = "yuba river",
    gage_agency = "USGS",
    gage_number = "11421000",
    parameter = "flow",
    statistic = "mean"
  ) |> 
  dplyr::select(-geometry)

# Define the required object names
required_objects <- c(
  "battle_creek_data_query",
  "butte_creek_data_query",
  "clear_creek_data_query",
  "deer_creek_data_query",
  "feather_hfc",
  "feather_lfc",
  "lower_feather_river_data_query",
  "mill_creek_data_query",
  "sac_river_data_query",
  "yuba_river_data_query"
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
flow_daily <- data.table::rbindlist(
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
  dplyr::filter(!is.na(week)) |>
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
