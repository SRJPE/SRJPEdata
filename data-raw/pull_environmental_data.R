library(tidyverse)
library(CDECRetrieve)
library(dataRetrieval)
library(weathermetrics)

### Read in lookup table for environmental data --------------------------------

# save as data object 

### Pull Flow and Temperature Data for each JPE tributary ----------------------
## Battle Creek 
### Flow Data Pull 
#### Gage Agency (USGS, # 11376550)
# Pull data 
try(battle_creek_data_query <- dataRetrieval::readNWISdv(11376550, "00060"), silent = TRUE)
# Filter existing data to use as a back up 
battle_creek_existing_flow  <- SRJPEdata::environmental_data |> 
  filter(gage_agency == "USGS" & 
         gage_number == "11376550" & 
         parameter == "flow") |> 
  select(-site)  #TODO create lookup table to join at end 

# Confirm data pull did not error out, if does not exist - use existing flow, 
# if exists - reformat new data pull
try(if(!exists("battle_creek_data_query")) 
    battle_creek_daily_flows <- battle_creek_existing_flow 
    else(battle_creek_daily_flows <- battle_creek_data_query %>% # rename to match new naming structure
            select(Date, value =  X_00060_00003) %>% # rename to value
            as_tibble() %>%
            rename(date = Date) |> 
            mutate(stream = "battle creek", # add additional columns for stream, gage info, and parameter 
                   gage_agency = "USGS",
                   gage_number = "11376550",
                   parameter = "flow",
                   statistic = "mean" # if query returns instantaneous data then report a min, mean, and max
                   )))

# Do a few additional flow data pull tests to confirm that new data pull has 
# more data
try(if(nrow(battle_creek_daily_flows) < nrow(battle_creek_existing_flow)) 
  battle_creek_daily_flows <- battle_creek_existing_flow)



### Temp Data Pull 
#### Gage # 

### Temp Data Pull Tests 
ubc_temp_raw <- readxl::read_excel(here::here("data-raw", "battle_clear_temp.xlsx"), sheet = 4)

ubc_temp <- ubc_temp_raw |> 
  rename(date = DT,
         temp_degC = TEMP_C) |> 
  mutate(date = as_date(date, tz = "UTC")) |> 
  group_by(date) |> 
  summarise(mean = mean(temp_degC, na.rm = TRUE),
             max = max(temp_degC, na.rm = TRUE),
             min = min(temp_degC, na.rm = TRUE)) |> 
  pivot_longer(mean:min, names_to = "statistic", values_to = "value") |>
  mutate(stream = "battle creek",  
         gage_agency = "USFWS",
         gage_number = "UBC",
         parameter = "temperature") |> 
  glimpse()
  

## Butte Creek 
### Flow Data Pull 
#### Gage Agency (CDEC, BCK)
# Pull data 
### Flow Data Pull Tests

try(butte_creek_data_query <- CDECRetrieve::cdec_query(station = "BCK", dur_code = "H", sensor_num = "20", start_date = "1995-01-01"))
# Filter existing data to use as a back up 
butte_creek_existing_flow  <- SRJPEdata::environmental_data |> 
  filter(gage_agency == "CDEC" & 
           gage_number == "BCK" & 
           parameter == "flow") |> 
  select(-site)  
# Confirm data pull did not error out, if does not exist - use existing flow, 
# if exists - reformat new data pull
try(if(!exists("butte_creek_data_query")) 
  butte_creek_daily_flows <- butte_creek_existing_flow 
  else(butte_creek_daily_flows <- butte_creek_data_query |> 
         mutate(parameter_value = ifelse(parameter_value < 0, NA_real_, parameter_value)) |> 
         group_by(date = as.Date(datetime)) |> 
         summarise(mean = mean(parameter_value, na.rm = TRUE),
                   max = max(parameter_value, na.rm = TRUE),
                   min = min(parameter_value, na.rm = TRUE)) |> 
         pivot_longer(mean:min, names_to = "statistic", values_to = "value") |> 
         mutate(stream = "butte creek",
                gage_agency = "CDEC",
                gage_number = "BCK",
                parameter = "flow"
         )))


# Do a few additional flow data pull tests to confirm that new data pull has 
# more data
try(if(nrow(butte_creek_daily_flows) < nrow(butte_creek_existing_flow)) 
  butte_creek_daily_flows <- butte_creek_existing_flow)


### Temp Data Pull 
bck_temp_raw <- cdec_query(station = "BCK", dur_code = "H", sensor_num = "25", start_date = "2000-01-01")

BCK_temps <- bck_temp_raw |> 
  mutate(date = as_date(datetime),
         temp_degC = fahrenheit.to.celsius(parameter_value, round = 1)) |>
  filter(temp_degC < 40, temp_degC > 0) |>
  group_by(date) |> 
  summarise(mean = mean(temp_degC, na.rm = TRUE),
            max = max(temp_degC, na.rm = TRUE),
            min = min(temp_degC, na.rm = TRUE)) |> 
  pivot_longer(mean:min, names_to = "statistic", values_to = "value") |>
  mutate(stream = "battle creek",
         gage_agency = "CDEC",
         gage_number = "BCK",
         parameter = "temperature") |> 
    glimpse()

### Temp Data Pull Tests  


## Clear Creek
### Flow Data Pull 
#### Gage Agency (CDEC, IGO)
### Flow Data Pull Tests 
try(clear_creek_data_query <- CDECRetrieve::cdec_query(station = "IGO", dur_code = "H", sensor_num = "20", start_date = "2003-01-01"))
# Filter existing data to use as a back up 
clear_creek_existing_flow  <- SRJPEdata::environmental_data |> 
  filter(gage_agency == "CDEC" & 
           gage_number == "IGO" & 
           parameter == "flow") |> 
  select(-site)  
# Confirm data pull did not error out, if does not exist - use existing flow, 
# if exists - reformat new data pull
try(if(!exists("clear_creek_data_query")) 
  clear_creek_daily_flows <- clear_creek_existing_flow 
  else(clear_creek_daily_flows <- clear_creek_data_query |> 
         mutate(parameter_value = ifelse(parameter_value < 0, NA_real_, parameter_value)) |> 
         group_by(date = as.Date(datetime)) |> 
         summarise(mean = mean(parameter_value, na.rm = TRUE),
                   max = max(parameter_value, na.rm = TRUE),
                   min = min(parameter_value, na.rm = TRUE)) |> 
         pivot_longer(mean:min, names_to = "statistic", values_to = "value") |> 
         mutate(stream = "clear creek",
                gage_agency = "CDEC",
                gage_number = "IGO",
                parameter = "flow"
         )))


# Do a few additional flow data pull tests to confirm that new data pull has 
# more data
try(if(nrow(clear_creek_daily_flows) < nrow(clear_creek_existing_flow)) 
  clear_creek_daily_flows <- clear_creek_existing_flow)


### Temp Data Pull 

upperclear_temp_raw <- readxl::read_excel(here::here("data-raw", "battle_clear_temp.xlsx"), sheet = 2)

upperclear_temp <- upperclear_temp_raw |> 
  rename(date = DT,
         temp_degC = TEMP_C) |> 
  mutate(date = as_date(date, tz = "UTC")) |>
  group_by(date) |> 
  summarise(mean = mean(temp_degC, na.rm = TRUE),
            max = max(temp_degC),
            min = min(temp_degC)) |> 
  pivot_longer(mean:min, names_to = "statistic", values_to = "value") |>
  mutate(stream = "upper clear creek",  
         gage_agency = "USFWS",
         gage_number = "UCC",
         parameter = "temperature") |> 
  glimpse()
         

lowerclear_temp_raw <- readxl::read_excel(here::here("data-raw", "battle_clear_temp.xlsx"), sheet = 3)

lowerclear_temp <- lowerclear_temp_raw |> 
  rename(date = DT,
         temp_degC = TEMP_C) |> 
  mutate(date = as_date(date, tz = "UTC")) |>
  group_by(date) |> 
  summarise(mean = mean(temp_degC, na.rm = TRUE),
            max = max(temp_degC),
            min = min(temp_degC)) |> 
  pivot_longer(mean:min, names_to = "statistic", values_to = "value") |>
  mutate(stream = "lower clear creek",  
         gage_agency = "USFWS",
         gage_number = "LCC",
         parameter = "temperature") |> 
  glimpse()

### Temp Data Pull Tests  

## Deer Creek 
### Flow Data Pull 
#### Gage Agency (USGS, 11383500)
### Flow Data Pull Tests 
try(deer_creek_data_query <- dataRetrieval::readNWISdv(11383500, "00060"), silent = TRUE)
# Filter existing data to use as a back up 
deer_creek_existing_flow  <- SRJPEdata::environmental_data |> 
  filter(gage_agency == "USGS" & 
           gage_number == "11383500" & 
           parameter == "flow") |> 
  select(-site)  

# Confirm data pull did not error out, if does not exist - use existing flow, 
# if exists - reformat new data pull
try(if(!exists("deer_creek_data_query")) 
  deer_creek_daily_flows <- deer_creek_existing_flow 
  else(deer_creek_daily_flows <- deer_creek_data_query|> 
         select(Date, value =  X_00060_00003) |> 
         as_tibble() %>%
         rename(date = Date) |> 
         mutate(stream = "deer creek", 
                gage_agency = "USGS",
                gage_number = "11383500",
                parameter = "flow",
                statistic = "mean" 
         )))

# Do a few additional flow data pull tests to confirm that new data pull has 
# more data
try(if(nrow(deer_creek_daily_flows) < nrow(deer_creek_existing_flow)) 
  deer_creek_daily_flows <- deer_creek_existing_flow)


### Temp Data Pull 





### Temp Data Pull Tests 
## Feather River 
### Flow Data Pull 
#### Gage Agency (CDEC, GRL)
### Flow Data Pull Tests 

try(feather_hfc_river_data_query <- CDECRetrieve::cdec_query(station = "GRL", dur_code = "H", sensor_num = "20", start_date = "1996-01-01"))
# Filter existing data to use as a back up 
feather_hfc_river_existing_flow  <- SRJPEdata::environmental_data |> 
  filter(gage_agency == "CDEC" & 
           gage_number == "GRL" & 
           parameter == "flow") |> 
  select(-site)  

# Confirm data pull did not error out, if does not exist - use existing flow, 
# if exists - reformat new data pull
try(if(!exists("feather_hfc_river_data_query")) 
  feather_hfc_river_daily_flows <- feather_hfc_river_existing_flow 
  else(feather_hfc_river_daily_flows <- feather_hfc_river_data_query |> 
         mutate(parameter_value = ifelse(parameter_value < 0, NA_real_, parameter_value)) |> 
         group_by(date = as.Date(datetime)) |> 
         summarise(mean = mean(parameter_value, na.rm = TRUE),
                   max = ifelse(all(is.na(parameter_value)), NA, max(parameter_value, na.rm = TRUE)),
                   min = ifelse(all(is.na(parameter_value)), NA, min(parameter_value, na.rm = TRUE))) |> 
         pivot_longer(mean:min, names_to = "statistic", values_to = "value") |> 
         mutate(stream = "feather river",  
                gage_agency = "CDEC",
                gage_number = "GRL",
                parameter = "flow"
         )))
# Do a few additional flow data pull tests to confirm that new data pull has 
# more data
try(if(nrow(feather_hfc_river_daily_flows) < nrow(feather_hfc_river_existing_flow)) 
  feather_hfc_river_daily_flows <- feather_hfc_river_existing_flow)

#Pull Lower Flow Channel Feather
try(feather_lfc_river_data_query <- dataRetrieval::readNWISdv(11407000, "00060"), silent = TRUE)
# Filter existing data to use as a back up 
feather_lfc_river_existing_flow  <- SRJPEdata::environmental_data |> 
  filter(gage_agency == "USGS" & 
           gage_number == "11407000" & 
           parameter == "flow") |> 
  select(-site)  

# Confirm data pull did not error out, if does not exist - use existing flow, 
# if exists - reformat new data pull
try(if(!exists("feather_lfc_river_data_query")) 
  feather_lfc_river_daily_flows <- feather_lfc_river_existing_flow 
  else(feather_lfc_river_daily_flows <- feather_lfc_river_data_query|> 
         select(Date, value =  X_00060_00003) |> 
         as_tibble() %>%
         rename(date = Date) |> 
         mutate(stream = "feather river", 
                gage_agency = "USGS",
                gage_number = "11407000",
                parameter = "flow",
                statistic = "mean" 
         )))

# Do a few additional flow data pull tests to confirm that new data pull has 
# more data
try(if(nrow(feather_lfc_river_daily_flows) < nrow(feather_lfc_river_existing_flow)) 
  feather_lfc_river_daily_flows <- feather_lfc_river_existing_flow)

#Pull Lower Feather data
try(lower_feather_river_data_query <- CDECRetrieve::cdec_query(station = "FSB", dur_code = "H", sensor_num = "20", start_date = "2010-01-01"))
# Filter existing data to use as a back up 
lower_feather_river_existing_flow  <- SRJPEdata::environmental_data |> 
  filter(gage_agency == "CDEC" & 
           gage_number == "FSB" & 
           parameter == "flow") |> 
  select(-site)  

# Confirm data pull did not error out, if does not exist - use existing flow, 
# if exists - reformat new data pull
try(if(!exists("lower_feather_river_data_query")) 
  lower_feather_river_daily_flows <- lower_feather_river_existing_flow 
  else(lower_feather_river_daily_flows <- lower_feather_river_data_query |> 
         mutate(parameter_value = ifelse(parameter_value < 0, NA_real_, parameter_value)) |> 
         group_by(date = as.Date(datetime)) |> 
         summarise(mean = mean(parameter_value, na.rm = TRUE),
                   max = ifelse(all(is.na(parameter_value)), NA, max(parameter_value, na.rm = TRUE)),
                   min = ifelse(all(is.na(parameter_value)), NA, min(parameter_value, na.rm = TRUE))) |> 
         pivot_longer(mean:min, names_to = "statistic", values_to = "value") |> 
         mutate(stream = "feather river",  
                gage_agency = "CDEC",
                gage_number = "FBL",
                parameter = "flow"
         )))
# Do a few additional flow data pull tests to confirm that new data pull has 
# more data
try(if(nrow(lower_feather_river_daily_flows) < nrow(lower_feather_river_existing_flow)) 
  lower_feather_river_daily_flows <- lower_feather_river_existing_flow)

### Temp Data Pull 

#GRL will represent the High Flow Channel (HFC) and FRA will represent the Low Flow Channel (LFC).

grl_temp_raw <- cdec_query(station = "GRL", dur_code = "H", sensor_num = "25", start_date = "2003-03-05", end_date = "2007-06-01")

GRL_temps <- grl_temp_raw |> 
  mutate(date = as_date(datetime),
         temp_degC = fahrenheit.to.celsius(parameter_value, round = 1)) |>
  filter(temp_degC < 40, temp_degC > 0) |> 
  group_by(date) |> 
  summarise(mean = mean(temp_degC, na.rm = TRUE),
            max = max(temp_degC, na.rm = TRUE),
            min = min(temp_degC, na.rm = TRUE)) |> 
  pivot_longer(mean:min, names_to = "statistic", values_to = "value") |>
  mutate(stream = "HFC Feather",
         gage_agency = "CDEC",
         gage_number = "GRL",
         parameter = "temperature") |> 
  glimpse()

fra_temp_raw <- cdec_query(station = "FRA", dur_code = "H", sensor_num = "25", start_date = "1996-01-01")

FRA_temps <- fra_temp_raw |> 
  mutate(date = as_date(datetime),
         temp_degC = fahrenheit.to.celsius(parameter_value, round = 1)) |>
  filter(temp_degC < 40, temp_degC > 0) |> 
  group_by(date) |> 
  summarise(mean = mean(temp_degC, na.rm = TRUE),
            max = max(temp_degC, na.rm = TRUE),
            min = min(temp_degC, na.rm = TRUE)) |> 
  pivot_longer(mean:min, names_to = "statistic", values_to = "value") |>
  mutate(stream = "LFC Feather",
         gage_agency = "CDEC",
         gage_number = "FRA",
         parameter = "temperature") |> 
  glimpse()



### Temp Data Pull Tests 
## Mill Creek 
### Flow Data Pull 
#### Gage Agency (USGS, 11381500)
### Flow Data Pull Tests 

try(mill_creek_data_query <- dataRetrieval::readNWISdv(11381500, "00060"), silent = TRUE)
# Filter existing data to use as a back up 
mill_creek_existing_flow  <- SRJPEdata::environmental_data |> 
  filter(gage_agency == "USGS" & 
           gage_number == "11381500" & 
           parameter == "flow") |> 
  select(-site)  #TODO finish data cleaning

# Confirm data pull did not error out, if does not exist - use existing flow, 
# if exists - reformat new data pull
try(if(!exists("mill_creek_data_query")) 
  mill_creek_daily_flows <- mill_creek_existing_flow 
  else(mill_creek_daily_flows <- mill_creek_data_query |> 
         select(Date, value =  X_00060_00003) |>  
         as_tibble() |> 
         rename(date = Date) |> 
         mutate(stream = "mill creek", 
                gage_agency = "USGS",
                gage_number = "11381500",
                parameter = "flow",
                statistic = "mean" 
         )))

# Do a few additional flow data pull tests to confirm that new data pull has 
# more data
try(if(nrow(mill_creek_daily_flows) < nrow(mill_creek_existing_flow)) 
  mill_creek_daily_flows <- mill_creek_existing_flow)



### Temp Data Pull 

mill_temp_raw <- cdec_query(station = "MLM", dur_code = "H", sensor_num = "25", start_date = "1996-01-01")

MLM_temps <- mill_temp_raw |> 
  mutate(date = as_date(datetime),
         temp_degC = fahrenheit.to.celsius(parameter_value, round = 1)) |>
  filter(temp_degC < 40, temp_degC > 0) |> 
  group_by(date) |> 
  summarise(mean = mean(temp_degC, na.rm = TRUE),
            max = max(temp_degC, na.rm = TRUE),
            min = min(temp_degC, na.rm = TRUE)) |> 
  pivot_longer(mean:min, names_to = "statistic", values_to = "value") |>
  mutate(stream = "Mill Creek",
         gage_agency = "CDEC",
         gage_number = "MLM",
         parameter = "temperature") |> 
  glimpse()
#TODO double check that this is the only Mill Creek staion we are using, if so clarify on temp data prep since there is another CDEC station listed (MCH) in addition to MLM

### Temp Data Pull Tests 
## Sacramento River 
### Flow Data Pull 
#### Gage Agency (USGS, 11381500)
### Flow Data Pull Tests 

try(sac_river_data_query <- dataRetrieval::readNWISdv(11390500, "00060"), silent = TRUE)
# Filter existing data to use as a back up 
sac_river_existing_flow  <- SRJPEdata::environmental_data |> 
  filter(gage_agency == "USGS" & 
           gage_number == "11390500" & 
           parameter == "flow") |> 
  select(-site)  

# Confirm data pull did not error out, if does not exist - use existing flow, 
# if exists - reformat new data pull
try(if(!exists("sac_river_data_query")) 
  sac_river_daily_flows <- sac_river_existing_flow 
  else(sac_river_daily_flows <- sac_river_data_query |>  
         select(Date, value =  X_00060_00003) |>  
         as_tibble() |> 
         rename(date = Date) |> 
         mutate(stream = "sacramento river", 
                gage_agency = "USGS",
                gage_number = "11390500",
                parameter = "flow",
                statistic = "mean" 
         )))


### Temp Data Pull 
### Temp Data Pull Tests 
## Yuba River 
### Flow Data Pull 
#### Gage Agency (USGS, 11421000)
### Flow Data Pull Tests

try(yuba_river_data_query <- dataRetrieval::readNWISdv(11421000, "00060"), silent = TRUE)
# Filter existing data to use as a back up 
yuba_river_existing_flow  <- SRJPEdata::environmental_data |> 
  filter(gage_agency == "USGS" & 
           gage_number == "11421000" & 
           parameter == "flow") |> 
  select(-site)  #TODO create lookup table to join at end 

# Confirm data pull did not error out, if does not exist - use existing flow, 
# if exists - reformat new data pull
try(if(!exists("yuba_river_data_query")) 
  yuba_river_daily_flows <- yuba_river_existing_flow 
  else(yuba_river_daily_flows <- yuba_river_data_query |>  
         select(Date, value =  X_00060_00003)  |>  
         as_tibble() |> 
         rename(date = Date) |> 
         mutate(stream = "yuba river",  
                gage_agency = "USGS",
                gage_number = "11421000",
                parameter = "flow",
                statistic = "mean"
         )))

# Do a few additional flow data pull tests to confirm that new data pull has 
# more data
try(if(nrow(yuba_daily_flows) < nrow(yuba_existing_flow)) 
  yuba_daily_flows <- yuba_existing_flow)


### Temp Data Pull 
yuba_temp_raw <- cdec_query(station = "YR7", dur_code = "E", sensor_num = "146", start_date = "1995-01-01")

YR7_temps <- yuba_temp_raw |> 
  mutate(date = as_date(datetime),
         temp_degC = fahrenheit.to.celsius(parameter_value, round = 1)) |>
  filter(temp_degC < 40, temp_degC > 0) |> 
  group_by(date) #TODO continue to clean up

### Temp Data Pull Tests 

#Combine all flow data from different streams
all_flow <- bind_rows(battle_creek_daily_flows,
                      butte_creek_daily_flows, 
                      clear_creek_daily_flows,
                      deer_creek_daily_flows,
                      feather_hfc_river_daily_flows,
                      lower_feather_river_daily_flows,
                      feather_lfc_river_daily_flows,
                      mill_creek_daily_flows,
                      sac_river_daily_flows,
                      yuba_river_daily_flows) |> 
  glimpse()

ggplot(all_flow |> 
         filter(statistic == "mean"),
         aes(x= date, y = value, color=stream)) +
  geom_line() +
  facet_wrap(~stream)

