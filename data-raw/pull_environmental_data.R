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
### Flow Data Pull Tests
### Temp Data Pull 
### Temp Data Pull Tests  
## Deer Creek 
### Flow Data Pull 
### Flow Data Pull Tests 
### Temp Data Pull 
### Temp Data Pull Tests 
## Feather River 
### Flow Data Pull 
### Flow Data Pull Tests 
### Temp Data Pull 
### Temp Data Pull Tests 
## Mill Creek 
### Flow Data Pull 
### Flow Data Pull Tests 
### Temp Data Pull 
### Temp Data Pull Tests 
## Sacramento River 
### Flow Data Pull 
### Flow Data Pull Tests 
### Temp Data Pull 
### Temp Data Pull Tests 
## Yuba River 
### Flow Data Pull 
### Flow Data Pull Tests 
### Temp Data Pull 
### Temp Data Pull Tests 

