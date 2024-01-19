library(tidyverse)
library(CDECRetrieve)
library(dataRetrieval)

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
  select(-site)  #TODO create lookup table to join at end 

# Confirm data pull did not error out, if does not exist - use existing flow, 
# if exists - reformat new data pull
try(if(!exists("butte_creek_data_query")) 
  butte_creek_daily_flows <- buttee_creek_existing_flow 
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

try(feather_river_data_query <- CDECRetrieve::cdec_query(station = "GRL", dur_code = "H", sensor_num = "20", start_date = "1996-01-01"))
# Filter existing data to use as a back up 
fether_river_existing_flow  <- SRJPEdata::environmental_data |> 
  filter(gage_agency == "CDEC" & 
           gage_number == "GRL" & 
           parameter == "flow") |> 
  select(-site)  

# Confirm data pull did not error out, if does not exist - use existing flow, 
# if exists - reformat new data pull
try(if(!exists("feather_river_data_query")) 
  feather_river_daily_flows <- feather_river_existing_flow 
  else(feather_river_daily_flows <- feather_river_data_query |> 
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
try(if(nrow(feather_river_daily_flows) < nrow(feather_river_existing_flow)) 
  feather_river_daily_flows <- feather_river_existing_flow)

### Temp Data Pull 
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
  select(-site)  

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
### Temp Data Pull Tests 

