# Script to pull and process acoustic tagging data from ERDDAP NOAA 
# Load in packages
# install.packages("RMark")
library(RMark) # For running program MARK
library(tidyverse) # Data manipulations
# install.packages("rerddap")
library(rerddap) # To retrieve NOAA ERDDAP data
library(lubridate) # Date time manipulations
library(leaflet) # To visualize receiver locations quickly on a map
library(vroom) # Read CSV's quickly

### Clear Cache
# First clear cache or it will repull old data 
cache_delete_all()

### Load TaggedFish and ReceiverDeployments tables through ERDDAP --------------
# tagging_metadata tablel is used to get all FishIDs for a study, and release information
# reciever_deployment is used to get Region

# Set erddap url to use in pull data functions 
erddap_url <- "https://oceanview.pfeg.noaa.gov/erddap/"

# TAGGED FISH TABLE
# metadata for JSATS tagged fish table
fish_metadata <- info('FED_JSATS_taggedfish', url = erddap_url)
# load in table
fish <- tabledap(fish_metadata, url = erddap_url)  
updated_fish <- fish |> 
  mutate(fish_release_date = as.POSIXct(fish_release_date, 
                                        format = "%m/%d/%Y %H:%M:%S", 
                                        tz = "Etc/GMT+8"),
         fish_date_tagged = as.POSIXct(fish_date_tagged, 
                                        format = "%m/%d/%Y %H:%M:%S", 
                                        tz = "Etc/GMT+8"),
         fish_id_prefix = substr(fish_id, start = 1, stop = (nchar(fish_id)-4))) |> 
  glimpse()


# RECEIVER TABLE
# metadata for JSATS recievers table
reciever_metadata <- info('FED_JSATS_receivers', url = erddap_url)
reciever_data <- tabledap(reciever_metadata, url = erddap_url)

# Establish ERDDAP url and database name
detections_metadata <- info('FED_JSATS_detects', url = erddap_url)
# detections columns 
detections_metadata$variables
# Retrieve list of all studyIDs on FED_JSATS
study_ids <- tabledap(detections_metadata,
                       fields = "study_id",
                       url = erddap_url) |> 
  pull(study_id) |> 
  unique()

ids_with_spring <- which(str_detect(study_ids, "Spring"))
spring_ids <- study_ids[ids_with_spring]

# Cannot download all at once so just pull spring ids for now
 
pull_detections_data <- function(study_id_list){
  data <- tabledap('FED_JSATS_detects',
                  url = erddap_url, 
                  str2lang(noquote(paste0("'study_id=\"", study_id_list,"\"'"))))
  return(data)
}
# Test on one 
# study_id_list <- "SJ_Scarf_2019"
# pull_detections_data(study_id_list)
# Map through all spring ids 
spring_detections <- purrr::map(spring_ids[1:4], pull_detections_data) |> 
  reduce(bind_rows) |> 
  glimpse()

# TEST OUT ONE TO MATCH FLORAS TABLE -
coleman_detections <- purrr::map("ColemanFall_2013", pull_detections_data) |> 
  reduce(bind_rows) |> 
  glimpse()

c("Rel_")

# Clean up 
formatted_spring_detections <- coleman_detections |> 
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

# Join all tables together to get detections associated with fish releases 
joined_detections <- fish |> 
  inner_join(formatted_spring_detections, 
             by = c("study_id" = "study_id", 
                    "fish_id" = "fish_id")) |> # Used inner join because that is what the example ERDAPP script was doing, think through this more
  left_join(reciever_data, 
            by = c("dep_id" = "dep_id")) |> 
  mutate(latitude = as.numeric(latitude), 
         longitude = as.numeric(longitude)) |> 
  glimpse()

# Visualize Detections associated with one study 
BC_2018_detections <- joined_detections |> 
filter(study_id == "BC-Spring-2018")

detect_summary <- aggregate(list(fish_count = BC_2018_detections$fish_id), 
                            by = list(receiver_general_location = BC_2018_detections$receiver_general_location.x, 
                                      latitude = BC_2018_detections$receiver_general_latitude, 
                                      longitude = BC_2018_detections$receiver_general_longitude), function(x){length(unique(x))}) |> 
  mutate(latitude = as.numeric(latitude), 
        longitude = as.numeric(longitude)) |> glimpse()

library(ggplot2)
library(mapdata)
library(ggrepel)

## Set boundary box for map
xlim <- c(-123, -121)
ylim <- c(37.5, 40.6)
usa <- map_data("worldHires", ylim = ylim, xlim = xlim)
rivers <- map_data("rivers", ylim = ylim, xlim = xlim)
rivers <- rivers[rivers$lat < max(ylim),]
ggplot() +
  geom_polygon(data = usa, aes(x = long, y = lat, group = group), fill = "grey80") +
  geom_path(data = rivers, aes(x = long, y = lat, group = group), size = 1, color = "white", lineend = "round") +
  geom_point(data = detect_summary, aes(x = longitude, y = latitude), shape=23, fill="blue", color="darkred", size=3) +
  geom_text_repel(data = detect_summary, aes(x = longitude, y = latitude, label = fish_count)) +
  theme_bw() + ylab("latitude") + xlab("longitude") +
  coord_fixed(1.3, xlim = xlim, ylim = ylim) +
  ggtitle("Location of study detections w/ count of unique fish visits")
