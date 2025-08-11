library(tidyverse)
library(CDECRetrieve)
library(dataRetrieval)

# If any of the queries do not work the code is set up to fail. This is on purpose
# because the queries aren't working we shouldn't be updating data.

### Pull Flow and Temperature Data for each JPE tributary ----------------------

## Battle Creek ----
### Flow Data Pull 
#### Gage Agency (USGS, # 11376550)

# Pull data 

### Flow Data Pull Tests
battle_creek_data_query <- dataRetrieval::readNWISdv(11376550, "00060", startDate = "1995-01-01")
battle_creek_daily_flows <- battle_creek_data_query |>  # rename to match new naming structure
         select(Date, value =  X_00060_00003) |>  # rename to value
         as_tibble() |> 
         rename(date = Date) |> 
         mutate(stream = "battle creek", # add additional columns for stream, gage info, and parameter 
                site_group = "battle creek",
                gage_agency = "USGS",
                gage_number = "11376550",
                parameter = "flow",
                statistic = "mean") # if query returns instantaneous data then report a min, mean, and max

### Temp Data Pull 
#### Gage #UBC
### Temp Data Pull Tests 
ubc_temp_raw <- readxl::read_excel(here::here("data-raw", "temperature-data", "battle_clear_temp.xlsx"), sheet = 4)

battle_creek_daily_temp <- ubc_temp_raw |> 
  rename(date = DT,
         temp_degC = TEMP_C) |> 
  mutate(date = as_date(date, tz = "UTC")) |> 
  group_by(date) |> 
  summarise(mean = mean(temp_degC, na.rm = TRUE),
            max = max(temp_degC, na.rm = TRUE),
            min = min(temp_degC, na.rm = TRUE)) |> 
  pivot_longer(mean:min, names_to = "statistic", values_to = "value") |>
  mutate(stream = "battle creek",  
         site_group = "battle creek",
         gage_agency = "USFWS",
         gage_number = "UBC",
         parameter = "temperature") |> 
  glimpse()

## Butte Creek ----
### Flow Data Pull 
#### Gage Agency (USGS, BCK)

# Grant Heneley at CDFW recommended using USGS instead of CDEC because CDEC will sometimes have weird datapoints
# Pull data 
butte_creek_data_query <- readNWISdv(11390000, "00060")
butte_creek_daily_flows <- butte_creek_data_query %>%
  select(Date, flow_cfs =  X_00060_00003) %>%
  as_tibble() %>%
  rename(date = Date,
         value = flow_cfs) |>
  mutate(value = ifelse(value < 0, NA_real_, value),
         stream = "butte creek",
         site_group = "butte creek",
         gage_agency = "USGS",
         gage_number = "11390000",
         parameter = "flow",
         statistic = "mean") 

### Temp Data Pull 
#### Gage #BCK
### Temp Data Pull Tests 
butte_creek_temp_query <- dataRetrieval::readNWISdv(11390000, "00010", statCd = c("00001","00002"), startDate = "1994-01-01")
butte_creek_daily_temp <- butte_creek_temp_query |> 
  select(Date, max =  X_00010_00001, min = X_00010_00002) %>%
  as_tibble() %>% 
  mutate(mean = (max + min) /2) |> 
  pivot_longer(max:mean, names_to = "statistic", values_to = "value") |> 
  rename(date = Date) %>% 
  mutate(stream = "butte creek",
         gage_agency = "USGS",
         gage_number = "11390000",
         parameter = "temperature")

## Clear Creek ----
### Flow Data Pull 
#### Gage Agency (CDEC, IGO)

#Pull data

### Flow Data Pull Tests 
clear_creek_data_query <- dataRetrieval::readNWISdv(11372000, "00060", startDate = "1995-01-01")

clear_creek_daily_flows <- clear_creek_data_query |> 
         select(Date, value =  X_00060_00003) |> 
         as_tibble() |> 
         rename(date = Date) |>
         mutate(stream = "clear creek",
                site_group = "clear creek",
                gage_agency = "USGS",
                gage_number = "11372000",
                parameter = "flow",
                statistic = "mean" # if query returns instantaneous data then report a min, mean, and max
         )

### Temp Data Pull 
#### Existing temp data
### Temp Data Pull Tests 
#Upper Clear Creek
upperclear_temp_raw <- readxl::read_excel(here::here("data-raw","temperature-data", "battle_clear_temp.xlsx"), sheet = 2)

upperclear_creek_daily_temp <- upperclear_temp_raw |> 
  rename(date = DT,
         temp_degC = TEMP_C) |> 
  mutate(date = as_date(date, tz = "UTC")) |>
  group_by(date) |> 
  summarise(mean = mean(temp_degC, na.rm = TRUE),
            max = max(temp_degC),
            min = min(temp_degC)) |> 
  pivot_longer(mean:min, names_to = "statistic", values_to = "value") |>
  mutate(stream = "clear creek",  
         site_group = "clear creek",
         site = "ucc",
         gage_agency = "USFWS",
         gage_number = "UCC",
         parameter = "temperature") |> 
  glimpse()

#Lower Clear Creek
lowerclear_temp_raw <- readxl::read_excel(here::here("data-raw", "temperature-data", "battle_clear_temp.xlsx"), sheet = 3)

lowerclear_creek_daily_temp <- lowerclear_temp_raw |> 
  rename(date = DT,
         temp_degC = TEMP_C) |> 
  mutate(date = as_date(date, tz = "UTC")) |>
  group_by(date) |> 
  summarise(mean = mean(temp_degC, na.rm = TRUE),
            max = max(temp_degC),
            min = min(temp_degC)) |> 
  pivot_longer(mean:min, names_to = "statistic", values_to = "value") |>
  mutate(stream = "clear creek", 
         site_group = "clear creek",
         site = "lcc",
         gage_agency = "USFWS",
         gage_number = "LCC",
         parameter = "temperature") |> 
  glimpse()

## Deer Creek ----
### Flow Data Pull 
#### Gage Agency (USGS, 11383500)

#Pull data

### Flow Data Pull Tests 
deer_creek_data_query <- dataRetrieval::readNWISdv(11383500, "00060", startDate = "1986-01-01")

deer_creek_daily_flows <- deer_creek_data_query|> 
         select(Date, value =  X_00060_00003) |> 
         as_tibble() |> 
         rename(date = Date) |> 
         mutate(stream = "deer creek", 
                site_group = "deer creek",
                gage_agency = "USGS",
                gage_number = "11383500",
                parameter = "flow",
                statistic = "mean")

### Temp Data Pull 
#### Gage #DVC
### Temp Data Pull Tests 
deer_creek_temp_query <- cdec_query(station = "DCV", dur_code = "H", sensor_num = "25", start_date = "1986-01-01")

deer_creek_daily_temp <- deer_creek_temp_query |> 
         mutate(date = as_date(datetime),
                temp_degC = SRJPEdata::fahrenheit_to_celsius(parameter_value)) |>
         filter(temp_degC < 40, temp_degC > 0) |> 
         group_by(date) |> 
         summarise(mean = mean(temp_degC, na.rm = TRUE),
                   max = max(temp_degC, na.rm = TRUE),
                   min = min(temp_degC, na.rm = TRUE)) |>
         pivot_longer(mean:min, names_to = "statistic", values_to = "value") |>
         mutate(stream = "deer creek",
                site_group = "deer creek",
                gage_agency = "CDEC",
                gage_number = "DCV",
                parameter = "temperature")

## Feather River ----

#Pull data
# Feather High Flow Channel 
# Do not use GRL because unreliable
# From Kassie 05/20/2025: I wanted to update you on the Feather flow data- specifically the gage at Gridley. It has been historically unreliable and we use the gage at Fish Barrier Dam (FRB) + Hatchery (ORF) + Thermalito Afterbay Outlet (which we get monthly via email). They have recalibrated it (not sure when) so I think moving forward we can use it but for historical flow data maybe we use our database. I’ve attached our flow database that Katie updates regularly. She also updates our temperature database from our Vemco receivers and we can provide that data as well just let me know.
# feather_hfc_river_data_query <- CDECRetrieve::cdec_query(station = "GRL", dur_code = "H", sensor_num = "20", start_date = "1997-01-01")
# 
# feather_hfc_river_daily_flows <- feather_hfc_river_data_query |> 
#          mutate(parameter_value = ifelse(parameter_value < 0, NA_real_, parameter_value)) |> 
#          group_by(date = as.Date(datetime)) |> 
#          summarise(mean = ifelse(all(is.na(parameter_value)), NA, mean(parameter_value, na.rm = TRUE)),
#                    max = ifelse(all(is.na(parameter_value)), NA, max(parameter_value, na.rm = TRUE)),
#                    min = ifelse(all(is.na(parameter_value)), NA, min(parameter_value, na.rm = TRUE))) |> 
#          pivot_longer(mean:min, names_to = "statistic", values_to = "value") |> 
#          mutate(stream = "feather river", 
#                 site_group = "upper feather hfc",
#                 gage_agency = "CDEC",
#                 gage_number = "GRL",
#                 parameter = "flow")


# Kassie sent their flow database
# I wanted to update you on the Feather flow data- specifically the gage at Gridley. It has been historically unreliable and we use the gage at Fish Barrier Dam (FRB) + Hatchery (ORF) + Thermalito Afterbay Outlet (which we get monthly via email). They have recalibrated it (not sure when) so I think moving forward we can use it but for historical flow data maybe we use our database. I’ve attached our flow database that Katie updates regularly. She also updates our temperature database from our Vemco receivers and we can provide that data as well just let me know.
# # library(googleCloudStorageR)
# library(Hmisc)
# gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
# gcs_global_bucket(bucket = Sys.getenv("GCS_DEFAULT_BUCKET"))
# gcs_get_object(object_name = "environmental/data-raw/feather_Flows_4.9.25.accdb",
#                bucket = gcs_get_global_bucket(),
#                saveToDisk = "data-raw/TEMP_data/feather_flow_db.accdb",
#                overwrite = TRUE)
# feather_flow_db <- here::here("data-raw", "TEMP_data", "feather_flow_db.accdb")
# mdb.get(feather_flow_db, tables = T)
# feather_flow_raw <- mdb.get(feather_flow_db, tables = "Flows Master")
# feather_gage_raw <- mdb.get(feather_flow_db, tables = "Gauge Locations")
# # Assume that Hatch.Oroville is FRB+ORF then need to add TAO
# detach(package:Hmisc)
# feather_flow <- feather_flow_raw |> 
#   group_by(Date) |> 
#   summarize(hatch_oroville = mean(Hatch.Oroville, na.rm = T),
#             TAO = mean(TAO, na.rm = T)) |> 
#   mutate(value = hatch_oroville+TAO) |> 
#   select(-c(hatch_oroville, TAO)) |> 
#   rename(date = Date) |> 
#   filter(date <= "2025-03-31") |> 
#   mutate(stream = "feather river", 
#          site_group = "upper feather hfc",
#          gage_agency = "DWR Feather",
#          gage_number = "FRB+ORF+TAO",
#          parameter = "flow",
#          statistic = "mean")
# write_csv(feather_flow, "data-raw/helper-tables/feather_flow_db.csv")

feather_flow <- read_csv("data-raw/helper-tables/feather_flow_db.csv")
### Flow Data Pull Tests 
#Feather Low Flow Channel 
# From Casey: There is also side flow input from the hatchery that increases flow another ~100 cfs. 
# There’s no publicly available single source to get the total flow downstream of the hatchery.
# You can use ORF + TFB to get the total LFC flow downstream of the hatchery.

# ORF
feather_orf_river_data_query <- dataRetrieval::readNWISdv(11406930, "00060", startDate = "1997-01-01")

feather_orf_river_daily_flows <- feather_orf_river_data_query |> 
  select(Date, orf_value =  X_00060_00003) |> 
  as_tibble() |> 
  rename(date = Date)

feather_orf_river_data_query2 <- CDECRetrieve::cdec_query(station = "ORF", dur_code = "D", sensor_num = "41", start_date = "2024-10-01")

feather_orf <- feather_orf_river_daily_flows |> 
  bind_rows(feather_orf_river_data_query2 |> 
              select(date = datetime, orf_value = parameter_value))
# TFB
# USGS site is through 9/20/2023 so needed to add a CDEC site for continuity
feather_lfc_river_data_query <- dataRetrieval::readNWISdv(11407000, "00060", startDate = "1997-01-01")

feather_lfc_river_daily_flows <- feather_lfc_river_data_query|> 
         select(Date, tfb_value =  X_00060_00003) |> 
         as_tibble() |> 
  rename(date = Date)

feather_lfc2_river_data_query <- CDECRetrieve::cdec_query(station = "TFB", dur_code = "D", sensor_num = "41", start_date = "2023-10-01")

feather_tfb <- feather_lfc_river_daily_flows |> 
  bind_rows(feather_lfc2_river_data_query |> 
              select(date = datetime, tfb_value = parameter_value))

feather_lfc2_river_daily_flows <- feather_lfc2_river_data_query |> 
  mutate(parameter_value = ifelse(parameter_value < 0, NA_real_, parameter_value)) |> 
  group_by(date = as.Date(datetime)) |> 
  summarise(mean = ifelse(all(is.na(parameter_value)), NA, mean(parameter_value, na.rm = TRUE)),
            max = ifelse(all(is.na(parameter_value)), NA, max(parameter_value, na.rm = TRUE)),
            min = ifelse(all(is.na(parameter_value)), NA, min(parameter_value, na.rm = TRUE))) |> 
  pivot_longer(mean:min, names_to = "statistic", values_to = "value") |> 
  mutate(stream = "feather river",  
         site_group = "upper feather lfc", 
         gage_agency = "CDEC",
         gage_number = "TFB",
         parameter = "flow")


feather_lfc <- full_join(feather_orf, feather_tfb) |> 
  mutate(date = as_date(date),
         value = tfb_value + orf_value,
         stream = "feather river", 
         site_group = "upper feather lfc",
         gage_agency = "USGS/CDEC",
         gage_number = "11407000/TFB + 11406930/ORF",
         parameter = "flow",
         statistic = "mean") |> 
  select(-c(tfb_value, orf_value))

### Flow Data Pull Tests 
#Lower Feather data 
lower_feather_river_data_query <- CDECRetrieve::cdec_query(station = "FSB", dur_code = "E", sensor_num = "20", start_date = "2010-01-01")

lower_feather_river_daily_flows <- lower_feather_river_data_query |> 
         mutate(parameter_value = ifelse(parameter_value < 0, NA_real_, parameter_value)) |> 
         group_by(date = as.Date(datetime)) |> 
         summarise(mean = ifelse(all(is.na(parameter_value)), NA, mean(parameter_value, na.rm = TRUE)),
                   max = ifelse(all(is.na(parameter_value)), NA, max(parameter_value, na.rm = TRUE)),
                   min = ifelse(all(is.na(parameter_value)), NA, min(parameter_value, na.rm = TRUE))) |> 
         pivot_longer(mean:min, names_to = "statistic", values_to = "value") |> 
         mutate(stream = "feather river",  
                site_group = "lower feather river", 
                gage_agency = "CDEC",
                gage_number = "FSB",
                parameter = "flow")

### Temp Data Pull 
#### Interpolation Data
#GRL will represent the High Flow Channel (HFC) and FRA will represent the Low Flow Channel (LFC).

#Interpolation feather hfc
feather_hfc_interpolated <- read_csv(here::here("data-raw", "temperature-data", "feather_hfc_temp_interpolation.csv")) |> 
  mutate(date = as_date(date)) |> 
  mutate(parameter = "temperature",
         site_group = "upper feather hfc") |> 
  glimpse()

#Note: There is no current updated gage for Feather High Flow Channel, we initially
#explored GRL gage from CDEC but most recent data is from 2007. Overall data coverage
#is out of range of our interest (2003-2017)

#Interpolation feather lfc
feather_lfc_interpolated <- read_csv(here::here("data-raw", "temperature-data", "feather_lfc_temp_interpolation.csv")) |> 
  mutate(date = as_date(date)) |> 
  mutate(parameter = "temperature",
         site_group = "upper feather lfc") |> 
  glimpse()

### Temp Data Pull 
#### Gage #FRA
### Temp Data Pull Tests 

#pulling temp data for Feather River Low Flow Channel - FRA
feather_lfc_temp_query <- cdec_query(station = "FRA", dur_code = "H", sensor_num = "25", start_date = "1997-01-01")

feather_lfc_river_daily_temp <- feather_lfc_temp_query |> 
         mutate(date = as_date(datetime),
                year = year(datetime),
                parameter_value = SRJPEdata::fahrenheit_to_celsius(parameter_value)) |> 
         group_by(date) |> 
         summarise(mean= mean(parameter_value, na.rm = TRUE),
                   max = max(parameter_value, na.rm = TRUE),
                   min = min(parameter_value, na.rm = TRUE)) |> 
         pivot_longer(mean:min, names_to = "statistic", values_to = "query_value") |>
         full_join(feather_lfc_interpolated) |> 
         # we want to use the query values instead of the interpolated values where they exist
         mutate(value = ifelse(!is.na(query_value), query_value, value),
                gage_agency = ifelse(!is.na(query_value), "CDEC", gage_agency),
                gage_number = ifelse(!is.na(query_value), "FRA", gage_number),
                stream = "feather river",
                site_group = "upper feather lfc",
                parameter = "temperature") |> 
         select(-query_value)

# Temperature data for HFC Feather River
# pulling temp data for Feather River Low Flow Channel - FRA
feather_hfc_temp_query <- cdec_query(station = "GRL", dur_code = "E", sensor_num = "25",  start_date = "1997-01-01")

feather_hfc_river_daily_temp <- feather_hfc_temp_query |> 
         mutate(date = as_date(datetime),
                year = year(datetime),
                parameter_value = SRJPEdata::fahrenheit_to_celsius(parameter_value)) |> 
         group_by(date) |> 
         summarise(mean= mean(parameter_value, na.rm = TRUE),
                   max = max(parameter_value, na.rm = TRUE),
                   min = min(parameter_value, na.rm = TRUE)) |> 
         pivot_longer(mean:min, names_to = "statistic", values_to = "query_value") |>
         full_join(feather_hfc_interpolated) |> 
         # we want to use the query values instead of the interpolated values where they exist
         mutate(value = ifelse(!is.na(query_value), query_value, value),
                gage_agency = ifelse(!is.na(query_value), "CDEC", gage_agency),
                gage_number = ifelse(!is.na(query_value), "GRL", gage_number),
                stream = "feather river",
                site_group = "upper feather hfc",
                parameter = "temperature") |> 
         select(-query_value)

## Mill Creek ----
### Flow Data Pull 
#### Gage Agency (USGS, 11381500)

#Pull data

### Flow Data Pull Tests 
# MLM
mill_creek_data_query <- dataRetrieval::readNWISdv(11381500, "00060", startDate = "1995-01-01")

mill_creek_daily_flows <- mill_creek_data_query |> 
         select(Date, value =  X_00060_00003) |>  
         as_tibble() |> 
         rename(date = Date) |> 
         mutate(stream = "mill creek", 
                site_group = "mill creek",
                gage_agency = "USGS",
                gage_number = "11381500",
                parameter = "flow",
                statistic = "mean")

### Temp Data Pull 
#### Gage #MLM
### Temp Data Pull Tests 
mill_creek_temp_query <- cdec_query(station = "MLM", dur_code = "H", sensor_num = "25", start_date = "1995-01-01")

mill_creek_daily_temp <- mill_creek_temp_query |> 
         mutate(date = as_date(datetime),
                temp_degC = SRJPEdata::fahrenheit_to_celsius(parameter_value)) |>
         filter(temp_degC < 40, temp_degC > 0) |>
         group_by(date) |> 
         summarise(mean = mean(temp_degC, na.rm = TRUE),
                   max = max(temp_degC, na.rm = TRUE),
                   min = min(temp_degC, na.rm = TRUE)) |> 
         pivot_longer(mean:min, names_to = "statistic", values_to = "value") |>
         mutate(stream = "mill creek",
                site_group = "mill creek",
                gage_agency = "CDEC",
                gage_number = "MLM",
                parameter = "temperature")

## Sacramento River ----
### Flow Data Pull 
#### Gage Agency (USGS, 11381500)

#Pull data

### Flow Data Pull Tests 
sac_river_data_query <- dataRetrieval::readNWISdv(11390500, "00060", startDate = "1994-01-01")

sac_river_daily_flows <- sac_river_data_query |>  
         select(Date, value =  X_00060_00003) |>  
         as_tibble() |> 
         rename(date = Date) |> 
         mutate(stream = "sacramento river",
                gage_agency = "USGS",
                gage_number = "11390500",
                parameter = "flow",
                statistic = "mean")

### Temp Data Pull 
#### Gage #11390500: large data gap between 1998 and 2016
# Looked for additional gages - 11425500 (at verona only has 2016-2017), WLK only starts in 2012
# Decided to use temperature data reported with RSTs to fill in gap but then
# pull a different statistic and no longer need the rst gage data

sac_river_temp_query <- dataRetrieval::readNWISdv(11390500, "00010", statCd = c("00001","00002"), startDate = "1994-01-01")

sac_river_daily_temp_raw <- sac_river_temp_query |> 
  select(Date, max =  X_00010_00001, min = X_00010_00002) %>%
  as_tibble() %>% 
  mutate(mean = (max + min) /2) |> 
  pivot_longer(max:mean, names_to = "statistic", values_to = "value") |> 
  rename(date = Date) %>% 
  mutate(stream = "sacramento river",
         gage_agency = "USGS",
         gage_number = "11390500",
         parameter = "temperature")

# sac_rst_temp_data <- SRJPEdata::rst_trap |> 
#   filter(stream == "sacramento river", !is.na(trap_start_date)) |> 
#   mutate(date = as_date(trap_start_date)) |> 
#   group_by(date) |> 
#   summarize(value = mean(water_temp, na.rm = T)) |> 
#   mutate(gage_agency = "CDFW",
#          gage_number = "reported at RST",
#          parameter = "temperature",
#          statistic = "mean",
#          stream = "sacramento river")

sac_river_daily_temp <- sac_river_daily_temp_raw 
# |> 
#   bind_rows(sac_rst_temp_data)

# Red Bluff ---------------------------------------------------------------
# Note that RBDD is not currently being used in SRJPE modeling (Feb 2025)
# but may be in the future

### Flow Data Pull 
#### Gage Agency (USGS, 11377100)
rbdd_data_query <- dataRetrieval::readNWISdv(11377100, "00060", startDate = "1994-01-01")

rbdd_daily_flows <- rbdd_data_query |>  
  select(Date, value =  X_00060_00003) |>  
  as_tibble() |> 
  rename(date = Date) |> 
  mutate(stream = "sacramento river",
         site_group = "red bluff diversion dam",
         gage_agency = "USGS",
         gage_number = "11377100",
         parameter = "flow",
         statistic = "mean")

### Temp Data Pull 
# No temperature data available at this gage.

## Yuba River ----
### Flow Data Pull 
#### Gage Agency (USGS, 11421000)

#Pull data

### Flow Data Pull Tests
yuba_river_data_query <- dataRetrieval::readNWISdv(11421000, "00060", startDate = "1999-01-01")

yuba_river_daily_flows <- yuba_river_data_query |>  
         select(Date, value =  X_00060_00003)  |>  
         as_tibble() |> 
         rename(date = Date) |> 
         mutate(stream = "yuba river",  
                site_group = "yuba river",
                gage_agency = "USGS",
                gage_number = "11421000",
                parameter = "flow",
                statistic = "mean")

### Temp Data Pull 
#### Interpolation pull for Yuba
yuba_river_interpolated <- read_csv(here::here("data-raw", "temperature-data", "yuba_temp_interpolation.csv")) |> 
  mutate(parameter = "temperature") |> 
  glimpse()

### Temp Data Pull 
#### Gage #YR7
### Temp Data Pull Tests 
yuba_river_temp_query <- cdec_query(station = "YR7", dur_code = "E", sensor_num = "146", start_date = "1999-01-01")

yuba_river_daily_temp <- yuba_river_temp_query |> 
    mutate(date = as_date(datetime)) |> 
    mutate(year = year(datetime)) |> 
    group_by(date) |> 
    summarise(mean= mean(parameter_value, na.rm = TRUE),
              max = max(parameter_value, na.rm = TRUE),
              min = min(parameter_value, na.rm = TRUE)) |> 
    pivot_longer(mean:min, names_to = "statistic", values_to = "query_value") |>
      full_join(yuba_river_interpolated) |> 
      # we want to use the query values instead of the interpolated values where they exist
      mutate(value = ifelse(!is.na(query_value), query_value, value),
             gage_agency = ifelse(!is.na(query_value), "CDEC", gage_agency),
             gage_number = ifelse(!is.na(query_value), "YR7", gage_number),
             stream = "yuba river",
             site_group = "yuba river",
             parameter = "temperature") |> 
      select(-query_value)


# Define the required object names
required_objects <- c("battle_creek_data_query", "butte_creek_data_query", "butte_creek_temp_query",
                      "clear_creek_data_query", "deer_creek_data_query", "deer_creek_temp_query",
                      "feather_flow", "feather_lfc_river_data_query", "lower_feather_river_data_query",
                      "feather_lfc_temp_query", "feather_hfc_temp_query", 
                      "mill_creek_data_query", "mill_creek_temp_query", 
                      "sac_river_data_query", "sac_river_temp_query",
                      "yuba_river_temp_query", "yuba_river_data_query")

# Check if all objects exist
if (!all(sapply(required_objects, exists))) {
  stop("One or more of the flow or temp queries do not exist in the environment.")
}

# If all objects exist, continue with the rest of the code
print("All required objects exist. Proceeding...")

# Load data.table library
library(data.table)
# Combine all flow data from different streams
# Created a site group variable so that the hfc and lfc will bind with the correct sites
# so need to bind feather to the site lookup separately
flow_daily <- rbindlist(list(battle_creek_daily_flows,
                  butte_creek_daily_flows, 
                  clear_creek_daily_flows,
                  deer_creek_daily_flows,
                  mill_creek_daily_flows,
                  sac_river_daily_flows |> mutate(site_group = "tisdale"),
                  sac_river_daily_flows |> mutate(site_group = "knights landing"),
                  rbdd_daily_flows,
                  yuba_river_daily_flows,
                  feather_flow, # data from DWR
                  feather_lfc, # sum of TFB and ORF
                  lower_feather_river_daily_flows), use.names = TRUE, fill = TRUE) |> 
  glimpse()

## QC plot 
# ggplot(flow |> 
#          filter(statistic == "mean"),
#        aes(x= date, y = value, color=site_group)) +
#   geom_line() +
#   facet_wrap(~stream)

#Combine all temperature data from different streams
temp <- rbindlist(list(battle_creek_daily_temp,
                       butte_creek_daily_temp,
                       deer_creek_daily_temp,
                       mill_creek_daily_temp,
                       sac_river_daily_temp |> mutate(site_group = "tisdale"),
                       sac_river_daily_temp |> mutate(site_group = "knights landing"),
                       yuba_river_daily_temp,
                       feather_lfc_river_daily_temp,
                       feather_hfc_river_daily_temp,
                       # TODO do we need a lower feather river temp? 
                       upperclear_creek_daily_temp,
                       lowerclear_creek_daily_temp), use.names = TRUE, fill = TRUE) |> 
  select(-site) |> 
  glimpse()

# Quick QC plot
# ggplot(temp |> 
#          filter(statistic == "mean"),
#        aes(x= date, y = value, color=site_group)) +
#   geom_line() +
#   facet_wrap(~stream)
setDT(temp)
setDT(flow_daily)

# Bind the rows of temp and flow with use.names=TRUE to match by column name
combined_data <- rbindlist(list(temp, flow_daily), use.names = TRUE, fill = TRUE) |> distinct()

# Reshape the data to 'wider' format (like pivot_wider)
reshaped_data <- dcast(combined_data, ... ~ statistic, value.var = "value")

# Group by week and year, and perform the summarization
updated_environmental_data <- reshaped_data[
  , .(max = max(max, na.rm = TRUE), 
      mean = mean(mean, na.rm = TRUE), 
      min = min(min, na.rm = TRUE)),
  by = .(week = lubridate::week(date), 
         year = lubridate::year(date), 
         stream, 
         gage_number, 
         gage_agency, 
         site_group, 
         parameter)
]

# Display the final result
print(head(updated_environmental_data))

longer_updated_environmental_data <- updated_environmental_data |> 
  filter(!is.na(week)) |> 
  mutate(max = ifelse(max == "-Inf", NA, max),
         min = ifelse(min == "Inf", NA, min)) |> 
  pivot_longer(max:min, names_to = "statistic", values_to = "value") |> glimpse()

# For Knights Landing we pull RST temperature to fill in data gaps
kl_rst <- longer_updated_environmental_data |> 
  filter(gage_number == "reported at RST" & site_group == "knights landing") |> 
  rename(rst_value = value, 
         gage_number_rst = gage_number,
         gage_agency_rst = gage_agency)
kl_temp <- longer_updated_environmental_data |> 
  filter(gage_number != "reported at RST" & site_group == "knights landing" & parameter == "temperature") |> 
  full_join(kl_rst) |> 
  mutate(gage_number = ifelse(is.na(value) & !is.na(rst_value), gage_number_rst, gage_number),
         gage_agency = ifelse(is.na(value) & !is.na(rst_value), gage_agency_rst, gage_agency),
         value = ifelse(is.na(value) & !is.na(rst_value), rst_value, value)) |> 
  select(-c(gage_number_rst, gage_agency_rst, rst_value))
environmental_data <- longer_updated_environmental_data |> 
  # remove knights landing temperature
  mutate(rm = ifelse(site_group == "knights landing" & parameter == "temperature", "remove","keep")) |> 
  filter(rm != "remove") |> 
  select(-rm) |> 
  # add on knights landing temperature where gaps have been filled in
  bind_rows(kl_temp)

#Save package
usethis::use_data(environmental_data, overwrite = TRUE)

