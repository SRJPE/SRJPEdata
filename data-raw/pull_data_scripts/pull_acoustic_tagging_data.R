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
fish_data <- pull_fish_data_from_ERDDAP() |> as.data.frame()

# RECEIVER TABLE
reciever_data <- pull_reciever_data_from_ERDDAP() |> as.data.frame()

# Retrieve list of all studyIDs on FED_JSATS
study_ids <- pull_study_ids_from_ERDDAP() |> as.data.frame()

# SACRAMENTO
sacramento_studyIDs <- c("ColemanFall_2013","ColemanFall_2016","ColemanFall_2017",
             "CNFH_FMR_2019","CNFH_FMR_2020","CNFH_FMR_2021",
             "RBDD_2017","RBDD_2018","Wild_stock_Chinook_RBDD_2022",
             "SacRiverSpringJPE_2022","SacRiverSpringJPE_2023", 
             "Spring_Pulse_2023",
             "DeerCk_Wild_CHK_2018","DeerCk_Wild_CHK_2020",
             "MillCk_Wild_CHK_2013","MillCk_Wild_CHK_2015","MillCk_Wild_CHK_2017",
             "Wild_stock_Chinook_Rbdd_2021",
             # 2026 version additions
             "Wild_stock_Chinook_Rbdd_2024", "SacRiverSpringJPE_2024", "Seasonal_Survival_2024", 
             "Spring_Pulse_2024", "MillCk_Wild_CHK_2022"
             )
# FOR TROUBLESHOOTING
# sacramento_studyIDs <- "ColemanFall_2013"
sacramento_detections <- purrr::map(sacramento_studyIDs, pull_detections_data_from_ERDDAP) |> 
  reduce(bind_rows) |> 
  mutate(first_time = as.POSIXct(first_time, 
                                 format = "%Y-%d-%m %H:%M:%S", 
                                 tz = "Etc/GMT+8"),
         last_time = as.POSIXct(last_time, 
                                format = "%Y-%d-%m %H:%M:%S", 
                                tz = "Etc/GMT+8"),
         time = as.POSIXct(time, 
                           format = "%Y-%d-%mT%H:%M:%S", 
                           tz = "Etc/GMT+8")) |>
  glimpse()

# BUTTE
butte_studyIDs <- c("SB_Spring_2015","SB_Spring_2016","SB_Spring_2017","SB_Spring_2018",
                    "SB_Spring_2019","SB_Spring_2023", "Butte_Sink_2023",
                    "Butte_Sink_2021","Upper_Butte_2019","Upper_Butte_2020",'Upper_Butte_2021',
                    "Butte_Sink_2024") # studies with 0 detection in Sac

butte_detections <- purrr::map(butte_studyIDs, pull_detections_data_from_ERDDAP) |> 
  reduce(bind_rows) |> 
  mutate(first_time = as.POSIXct(first_time, 
                                 format = "%Y-%d-%m %H:%M:%S", 
                                 tz = "Etc/GMT+8"),
         last_time = as.POSIXct(last_time, 
                                format = "%Y-%d-%m %H:%M:%S", 
                                tz = "Etc/GMT+8"),
         time = as.POSIXct(time, 
                           format = "%Y-%d-%mT%H:%M:%S", 
                           tz = "Etc/GMT+8")) |>
  glimpse()


# FEATHER
feather_studyIDs <- c("FR_Spring_2013","FR_Spring_2014","FR_Spring_2015","FR_Spring_2019","FR_Spring_2020",
                      "FR_Spring_2021","FR_Spring_2023", "FR_Spring_2024") 

feather_detections <- purrr::map(feather_studyIDs, pull_detections_data_from_ERDDAP) |> 
  reduce(bind_rows) |> 
  mutate(first_time = as.POSIXct(first_time, 
                                 format = "%Y-%d-%m %H:%M:%S", 
                                 tz = "Etc/GMT+8"),
         last_time = as.POSIXct(last_time, 
                                format = "%Y-%d-%m %H:%M:%S", 
                                tz = "Etc/GMT+8"),
         time = as.POSIXct(time, 
                           format = "%Y-%d-%mT%H:%M:%S", 
                           tz = "Etc/GMT+8")) |>
  glimpse()


