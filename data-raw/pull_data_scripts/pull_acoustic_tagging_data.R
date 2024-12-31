# Script to pull and process acoustic tagging data from ERDDAP NOAA 
# Load in packages
# install.packages("RMark")
library(RMark) # For running program MARK
library(tidyverse) # Data manipulations
# install.packages("rerddap")
library(rerddap) # To retrieve NOAA ERDDAP data
library(lubridate) # Date time manipulations
library(leaflet) # To visualize receiver locations quickly on a map
library(SRJPEdata)

### Clear Cache
# First clear cache or it will repull old data 
cache_delete_all()

### Load TaggedFish and ReceiverDeployments tables through ERDDAP --------------
# tagging_metadata table is used to get all FishIDs for a study, and release information
# receiver_deployment is used to get Region

# TAGGED FISH TABLE
fish_data <- pull_fish_data_from_ERDDAP()

# RECEIVER TABLE
reciever_data <- pull_reciever_data_from_ERDDAP()

# Retrieve list of all studyIDs on FED_JSATS
study_ids <- pull_study_ids_from_ERDDAP()

# ids_with_spring <- which(str_detect(study_ids, "Spring"))
# spring_ids <- study_ids[ids_with_spring]
# Cannot download all at once so just pull jpe ids for now
floras_sac_ids <- read_csv("data-raw/archive/floras_data_prep/data/SacInp.csv") |> pull(StudyID) |> unique()
floras_feather_butte_ids <- read_csv("data-raw/archive/floras_data_prep/data/FeatherButteInp.csv") |> pull(StudyID) |> unique()
jpe_ids_sac <- floras_sac_ids
jpe_ids_feather_butte <- floras_feather_butte_ids
jpe_ids <- c(floras_sac_ids, floras_feather_butte_ids)

jpe_detections <- purrr::map(jpe_ids, pull_detections_data_from_ERDDAP) |> 
  reduce(bind_rows) |> 
  mutate(first_time = as.POSIXct(first_time, 
                                 format = "%m/%d/%Y %H:%M:%S", 
                                 tz = "Etc/GMT+8"),
         last_time = as.POSIXct(last_time, 
                                format = "%m/%d/%Y %H:%M:%S", 
                                tz = "Etc/GMT+8"),
         time = as.POSIXct(time, 
                           format = "%m/%d/%Y %H:%M:%S", 
                           tz = "Etc/GMT+8")) |>
  glimpse()



