# If any of the queries do not work the code is set up to fail. This is on purpose
# because the queries aren't working we shouldn't be updating data.

### Pull Temperature Data for each JPE tributary -------------------------------

## Battle Creek ----------------------------------------------------------------
### Temp Data Pull
#### Gage #UBC
ubc_temp_raw <- readxl::read_excel(
  here::here("data-raw", "temperature-data", "battle_clear_temp.xlsx"),
  sheet = 4
)

ubc_temp_raw2 <- readxl::read_excel(
  here::here("data-raw", "temperature-data", "battle_clear_2022_2026.xlsx"),
  sheet = 3
) |> 
  dplyr::rename(TEMP_C = `Temp C`)

battle_creek_daily_temp <- dplyr::bind_rows(ubc_temp_raw, ubc_temp_raw2) |>
  dplyr::rename(date = DT, temp_degC = TEMP_C) |>
  dplyr::mutate(date = as_date(date, tz = "UTC")) |>
  dplyr::group_by(date) |>
  dplyr::summarise(
    mean = mean(temp_degC, na.rm = TRUE),
    max = max(temp_degC, na.rm = TRUE),
    min = min(temp_degC, na.rm = TRUE)
  ) |>
  tidyr::pivot_longer(
    mean:min,
    names_to = "statistic",
    values_to = "value"
  ) |>
  dplyr::mutate(
    stream = "battle creek",
    site_group = "battle creek",
    gage_agency = "USFWS",
    gage_number = "UBC",
    parameter = "temperature"
  )

## Butte Creek -----------------------------------------------------------------
### Temp Data Pull
#### Gage #BCK
butte_creek_temp_query <- dataRetrieval::read_waterdata_daily(
  "USGS-11390000",
  "00010"
)
butte_creek_daily_temp <- butte_creek_temp_query |>
  dplyr::select(time, value, statistic_id) |> 
  dplyr::as_tibble() |> 
  dplyr::select(-geometry) |> 
  tidyr::pivot_wider(names_from = "statistic_id", values_from = "value") |> 
  dplyr::rename(max = `00001`, min = `00002`, date = time) |> 
  dplyr::select(-c(`00008`,`00003`)) |> 
  dplyr::mutate(mean = (max + min) / 2) |>
  tidyr::pivot_longer(
    max:mean,
    names_to = "statistic",
    values_to = "value"
  ) |>
  dplyr::mutate(
    stream = "butte creek",
    site_group = "butte creek",
    gage_agency = "USGS",
    gage_number = "11390000",
    parameter = "temperature"
  )

## Clear Creek ----------------------------------------------------------------
### Temp Data Pull
# Upper Clear Creek
upperclear_temp_raw <- readxl::read_excel(
  here::here("data-raw", "temperature-data", "battle_clear_temp.xlsx"),
  sheet = 2
)

upperclear_temp_raw2 <- readxl::read_excel(
  here::here("data-raw", "temperature-data", "battle_clear_2022_2026.xlsx"),
  sheet = 1
)

upperclear_creek_daily_temp <- dplyr::bind_rows(upperclear_temp_raw, upperclear_temp_raw2) |>
  dplyr::rename(date = DT, temp_degC = TEMP_C) |>
  dplyr::mutate(date = as_date(date, tz = "UTC")) |>
  dplyr::group_by(date) |>
  dplyr::summarise(
    mean = mean(temp_degC, na.rm = TRUE),
    max = max(temp_degC),
    min = min(temp_degC)
  ) |>
  tidyr::pivot_longer(
    mean:min,
    names_to = "statistic",
    values_to = "value"
  ) |>
  dplyr::mutate(
    stream = "clear creek",
    site_group = "clear creek",
    site = "ucc",
    gage_agency = "USFWS",
    gage_number = "UCC",
    parameter = "temperature"
  )

#Lower Clear Creek
lowerclear_temp_raw <- readxl::read_excel(
  here::here("data-raw", "temperature-data", "battle_clear_temp.xlsx"),
  sheet = 3
)

lowerclear_temp_raw2 <- readxl::read_excel(
  here::here("data-raw", "temperature-data", "battle_clear_2022_2026.xlsx"),
  sheet = 2
)

lowerclear_creek_daily_temp <- dplyr::bind_rows(lowerclear_temp_raw, lowerclear_temp_raw2) |>
  dplyr::rename(date = DT, temp_degC = TEMP_C) |>
  dplyr::mutate(date = as_date(date, tz = "UTC")) |>
  dplyr::group_by(date) |>
  dplyr::summarise(
    mean = mean(temp_degC, na.rm = TRUE),
    max = max(temp_degC),
    min = min(temp_degC)
  ) |>
  tidyr::pivot_longer(
    mean:min,
    names_to = "statistic",
    values_to = "value"
  ) |>
  dplyr::mutate(
    stream = "clear creek",
    site_group = "clear creek",
    site = "lcc",
    gage_agency = "USFWS",
    gage_number = "LCC",
    parameter = "temperature"
  )

## Deer Creek ------------------------------------------------------------------
### Temp Data Pull
#### Gage # DVC
### Temp Data Pull Tests
deer_creek_temp_query <- CDECRetrieve::cdec_query(
  station = "DCV",
  dur_code = "H",
  sensor_num = "25",
  start_date = "1998-01-01"
)

deer_creek_daily_temp <- deer_creek_temp_query |>
  dplyr::mutate(
    date = as_date(datetime),
    temp_degC = SRJPEdata::fahrenheit_to_celsius(parameter_value)
  ) |>
  dplyr::filter(temp_degC < 40, temp_degC > 0) |>
  dplyr::group_by(date) |>
  dplyr::summarise(
    mean = mean(temp_degC, na.rm = TRUE),
    max = max(temp_degC, na.rm = TRUE),
    min = min(temp_degC, na.rm = TRUE)
  ) |>
  tidyr::pivot_longer(
    mean:min,
    names_to = "statistic",
    values_to = "value"
  ) |>
  dplyr::mutate(
    stream = "deer creek",
    site_group = "deer creek",
    gage_agency = "CDEC",
    gage_number = "DCV",
    parameter = "temperature"
  )

## Feather River ---------------------------------------------------------------
### Temp Data Pull
#### Interpolation Data
#GRL will represent the High Flow Channel (HFC) and FRA will represent the Low Flow Channel (LFC).
# Interpolation feather hfc
feather_hfc_interpolated <- readr::read_csv(here::here(
  "data-raw",
  "temperature-data",
  "feather_hfc_temp_interpolation.csv"
)) |>
  dplyr::mutate(date = as_date(date)) |>
  dplyr::mutate(
    parameter = "temperature",
    site_group = "upper feather hfc"
  )

#Note: There is no current updated gage for Feather High Flow Channel, we initially
#explored GRL gage from CDEC but most recent data is from 2007. Overall data coverage
#is out of range of our interest (2003-2017)
# Interpolation feather lfc
feather_lfc_interpolated <- readr::read_csv(here::here(
  "data-raw",
  "temperature-data",
  "feather_lfc_temp_interpolation.csv"
)) |>
  dplyr::mutate(date = as_date(date)) |>
  dplyr::mutate(
    parameter = "temperature",
    site_group = "upper feather lfc"
  )

### Temp Data Pull
#### Gage #FRA
# pulling temp data for Feather River Low Flow Channel - FRA
feather_lfc_temp_query <- CDECRetrieve::cdec_query(
  station = "FRA",
  dur_code = "H",
  sensor_num = "25",
  start_date = "1997-01-01"
)

feather_lfc_river_daily_temp <- feather_lfc_temp_query |>
  dplyr::mutate(
    date = as_date(datetime),
    year = year(datetime),
    parameter_value = SRJPEdata::fahrenheit_to_celsius(
      parameter_value
    )
  ) |>
  dplyr::group_by(date) |>
  dplyr::summarise(
    mean = mean(parameter_value, na.rm = TRUE),
    max = max(parameter_value, na.rm = TRUE),
    min = min(parameter_value, na.rm = TRUE)
  ) |>
  tidyr::pivot_longer(
    mean:min,
    names_to = "statistic",
    values_to = "query_value"
  ) |>
  dplyr::full_join(feather_lfc_interpolated) |>
  # we want to use the query values instead of the interpolated values where they exist
  dplyr::mutate(
    value = ifelse(!is.na(query_value), query_value, value),
    gage_agency = ifelse(!is.na(query_value), "CDEC", gage_agency),
    gage_number = ifelse(!is.na(query_value), "FRA", gage_number),
    stream = "feather river",
    site_group = "upper feather lfc",
    parameter = "temperature"
  ) |>
  dplyr::select(-query_value)

# Temperature data for HFC Feather River
# pulling temp data for Feather River Low Flow Channel - FRA
feather_hfc_temp_query <- CDECRetrieve::cdec_query(
  station = "GRL",
  dur_code = "H",
  sensor_num = "25",
  start_date = "1997-01-01"
)

feather_hfc_river_daily_temp <- feather_hfc_temp_query |>
  dplyr::mutate(
    date = as_date(datetime),
    year = year(datetime),
    parameter_value = SRJPEdata::fahrenheit_to_celsius(
      parameter_value
    )
  ) |>
  dplyr::group_by(date) |>
  dplyr::summarise(
    mean = mean(parameter_value, na.rm = TRUE),
    max = max(parameter_value, na.rm = TRUE),
    min = min(parameter_value, na.rm = TRUE)
  ) |>
  tidyr::pivot_longer(
    mean:min,
    names_to = "statistic",
    values_to = "query_value"
  ) |>
  dplyr::full_join(feather_hfc_interpolated) |>
  # we want to use the query values instead of the interpolated values where they exist
  dplyr::mutate(
    value = ifelse(!is.na(query_value), query_value, value),
    gage_agency = ifelse(!is.na(query_value), "CDEC", gage_agency),
    gage_number = ifelse(!is.na(query_value), "GRL", gage_number),
    stream = "feather river",
    site_group = "upper feather hfc",
    parameter = "temperature"
  ) |>
  dplyr::select(-query_value)

## Mill Creek ------------------------------------------------------------------
### Temp Data Pull
#### Gage #MLM
mill_creek_temp_query <- CDECRetrieve::cdec_query(
  station = "MLM",
  dur_code = "H",
  sensor_num = "25",
  start_date = "1995-01-01"
)

mill_creek_daily_temp <- mill_creek_temp_query |>
  dplyr::mutate(
    date = as_date(datetime),
    temp_degC = SRJPEdata::fahrenheit_to_celsius(parameter_value)
  ) |>
  dplyr::filter(temp_degC < 40, temp_degC > 0) |>
  dplyr::group_by(date) |>
  dplyr::summarise(
    mean = mean(temp_degC, na.rm = TRUE),
    max = max(temp_degC, na.rm = TRUE),
    min = min(temp_degC, na.rm = TRUE)
  ) |>
  tidyr::pivot_longer(
    mean:min,
    names_to = "statistic",
    values_to = "value"
  ) |>
  dplyr::mutate(
    stream = "mill creek",
    site_group = "mill creek",
    gage_agency = "CDEC",
    gage_number = "MLM",
    parameter = "temperature"
  )

## Sacramento River ------------------------------------------------------------
### Temp Data Pull
### USCS 11390500
sac_river_temp_query <- dataRetrieval::read_waterdata_daily(
  "USGS-11390500",
  "00010"
)

sac_river_daily_temp_raw <- sac_river_temp_query |>
  dplyr::select(time, value, statistic_id) |> 
  dplyr::as_tibble() |> 
  dplyr::select(-geometry) |> 
  tidyr::pivot_wider(names_from = "statistic_id", values_from = "value") |> 
  dplyr::rename(max = `00001`, min = `00002`, date = time) |> 
  dplyr::select(-c(`00003`)) |> 
  dplyr::mutate(mean = (max + min) / 2) |>
  tidyr::pivot_longer(
    max:mean,
    names_to = "statistic",
    values_to = "value"
  ) |>
  dplyr::mutate(
    stream = "sacramento river",
    gage_agency = "USGS",
    gage_number = "11390500",
    parameter = "temperature"
  ) 

sac_river_daily_temp <- sac_river_daily_temp_raw

# Red Bluff --------------------------------------------------------------------
# NO TEMP DATA

## Yuba River ------------------------------------------------------------------
### Temp Data Pull
#### Interpolation pull for Yuba
yuba_river_interpolated <- readr::read_csv(here::here(
  "data-raw",
  "temperature-data",
  "yuba_temp_interpolation.csv"
)) |>
  dplyr::mutate(parameter = "temperature")

### Temp Data Pull
#### Gage #YR7
### Temp Data Pull Tests
yuba_river_temp_query <- CDECRetrieve::cdec_query(
  station = "YR7",
  dur_code = "E",
  sensor_num = "146",
  start_date = "1999-01-01"
)

yuba_river_daily_temp <- yuba_river_temp_query |>
  dplyr::mutate(date = as_date(datetime)) |>
  dplyr::mutate(year = year(datetime)) |>
  dplyr::group_by(date) |>
  dplyr::summarise(
    mean = mean(parameter_value, na.rm = TRUE),
    max = max(parameter_value, na.rm = TRUE),
    min = min(parameter_value, na.rm = TRUE)
  ) |>
  tidyr::pivot_longer(
    mean:min,
    names_to = "statistic",
    values_to = "query_value"
  ) |>
  dplyr::full_join(yuba_river_interpolated) |>
  # we want to use the query values instead of the interpolated values where they exist
  dplyr::mutate(
    value = ifelse(!is.na(query_value), query_value, value),
    gage_agency = ifelse(!is.na(query_value), "CDEC", gage_agency),
    gage_number = ifelse(!is.na(query_value), "YR7", gage_number),
    stream = "yuba river",
    site_group = "yuba river",
    parameter = "temperature"
  ) |>
  dplyr::select(-query_value)

# Define the required object names
required_objects <- c(
  "butte_creek_temp_query",
  "clear_creek_data_query",
  "deer_creek_temp_query",
  "feather_lfc_temp_query",
  "feather_hfc_temp_query",
  "mill_creek_temp_query",
  "sac_river_temp_query",
  "yuba_river_temp_query"
)

# Check if all objects exist
if (!all(sapply(required_objects, exists))) {
  stop(
    "One or more of the temp queries do not exist in the environment."
  )
}

# If all objects exist, continue with the rest of the code
print("All required objects exist. Proceeding...")

#Combine all temperature data from different streams
temp <- data.table::rbindlist(
  list(
    battle_creek_daily_temp,
    butte_creek_daily_temp,
    deer_creek_daily_temp,
    mill_creek_daily_temp,
    sac_river_daily_temp |> dplyr::mutate(site_group = "tisdale"),
    sac_river_daily_temp |>
      dplyr::mutate(site_group = "knights landing"),
    yuba_river_daily_temp,
    feather_lfc_river_daily_temp,
    feather_hfc_river_daily_temp,
    # TODO do we need a lower feather river temp?
    upperclear_creek_daily_temp,
    lowerclear_creek_daily_temp
  ),
  use.names = TRUE,
  fill = TRUE
) |>
  dplyr::select(-site)

data.table::setDT(temp)


# Reshape the data to 'wider' format (like pivot_wider)
reshaped_temp<- data.table::dcast(
  temp,
  ... ~ statistic,
  value.var = "value"
)


# Group by week and year, and perform the summarization
updated_temp_data <- reshaped_temp[,
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
print(head(updated_temp_data))

longer_updated_temp_data <- updated_temp_data |>
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

# For Knights Landing we pull RST temperature to fill in data gaps
kl_rst <- longer_updated_temp_data |>
  dplyr::filter(
    gage_number == "reported at RST" & site_group == "knights landing"
  ) |>
  dplyr::rename(
    rst_value = value,
    gage_number_rst = gage_number,
    gage_agency_rst = gage_agency
  )
kl_temp <- longer_updated_temp_data |>
  dplyr::filter(
    gage_number != "reported at RST" &
      site_group == "knights landing" &
      parameter == "temperature"
  ) |>
  dplyr::full_join(kl_rst) |>
  dplyr::mutate(
    gage_number = ifelse(
      is.na(value) & !is.na(rst_value),
      gage_number_rst,
      gage_number
    ),
    gage_agency = ifelse(
      is.na(value) & !is.na(rst_value),
      gage_agency_rst,
      gage_agency
    ),
    value = ifelse(is.na(value) & !is.na(rst_value), rst_value, value)
  ) |>
  dplyr::select(-c(gage_number_rst, gage_agency_rst, rst_value))

temperature_data <- longer_updated_temp_data |>
  # remove knights landing temperature
  dplyr::mutate(
    rm = ifelse(
      site_group == "knights landing" &
        parameter == "temperature",
      "remove",
      "keep"
    )
  ) |>
  dplyr::filter(rm != "remove" | is.na(rm)) |>
  dplyr::select(-rm) |>
  # add on knights landing temperature where gaps have been filled in
  dplyr::bind_rows(kl_temp)

#Save package
usethis::use_data(temperature_data, overwrite = TRUE)
