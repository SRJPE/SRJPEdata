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

# Join all tables together to get detections associated with fish releases 
joined_detections <- fish_data |> 
  filter(study_id %in% jpe_ids) |> 
  inner_join(jpe_detections, 
             by = c("study_id" = "study_id", 
                    "fish_id" = "fish_id")) |> # Used inner join because that is what the example ERDAPP script was doing, think through this more
  left_join(reciever_data) |> 
  mutate(latitude = as.numeric(latitude), 
         longitude = as.numeric(longitude)) |> 
  glimpse()

# MAP 
detect_summary <- aggregate(list(fish_count = joined_detections$fish_id), 
                            by = list(receiver_general_location = joined_detections$receiver_general_location, 
                                      latitude = joined_detections$receiver_general_latitude, 
                                      longitude = joined_detections$receiver_general_longitude), function(x){length(unique(x))}) |> 
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

## USE FLORA LOGIC TO FORMAT CH ---- she groups fish into 4 detection sites,
# use floras functions to generate table with CH 

# Select columns that we want
all_detections <- joined_detections |> 
  select(study_id, fish_id, receiver_general_location, time,
         receiver_general_river_km, receiver_region, 
         receiver_general_latitude, receiver_general_longitude,
         fish_release_date, release_river_km, release_latitude,
         release_longitude, release_location)

# Get list of all receiver GEN
# reach.meta <- get_receiver_GEN(all_detections)
reach_metadata <- get_receiver_sites_metadata(all_detections)
# Manually select receiver locations to use and combine for Sac River study
# Will need to go back in and remap if we want new 
region_mapped_reach_metadata <- reach_metadata %>%
  filter(receiver_general_location %in% c("BattleCk_CNFH_Rel","RBDD_Rel","RBDD_Rel_Rec","Altube Island","MillCk_RST_Rel",
                    "MillCk2_Rel","DeerCk_RST_Rel","Mill_Ck_Conf",
                    "Abv_WoodsonBr","Blw_Woodson", "ButteBr","BlwButteBr",
                    "I80-50_Br","TowerBridge",
                    "ToeDrainBase","Hwy84Ferry",
                    "BeniciaE","BeniciaW","ChippsE","ChippsW"))%>%
  mutate(receiver_region = case_when(receiver_region == 'Battle Ck' ~ 'Release',
                            receiver_region == 'DeerCk' ~ 'Release',
                            receiver_region == 'Mill Ck' ~ 'Release',
                            receiver_general_location == 'RBDD_Rel'& receiver_region == 'Upper Sac R' ~ 'Release',
                            receiver_general_location == 'RBDD_Rel_Rec'& receiver_region == 'Upper Sac R' ~ 'Release',
                            receiver_region == 'Yolo Bypass' ~ 'Lower Sac R',
                            receiver_region == 'North Delta' ~ 'Lower Sac R',
                            receiver_region == 'West Delta' ~ 'End',
                            receiver_region == 'Carquinez Strait' ~ 'End',
                            TRUE ~ receiver_region))

# Aggregate receiver locations and detections
# TODO - THIS LOGIC WILL VARY BASED ON SITE... WE ALSO HAVE ONE FOR BUTTE BUT CAN WE MAKE A MORE GENERALIZED ONE
aggregate <- aggregate_detections_sacramento(detections = all_detections, 
                                             receiever_metadata = region_mapped_reach_metadata)
all_aggregated <- aggregate$detections
# View study reaches in map
map_reaches <- aggregate$reach_meta_aggregate %>%
  filter(receiver_general_location != "Releasepoint") %>%
  rbind(c("Battle Creek",517.344,40.39816,-122.1456,"Release"),
        c("RBDD",461.579, 40.15444, -122.2025,'Release'),
        c("Mill Creek",450.703,40.05479, -122.0321,'Release'),
        c('Deer Creek',441.728,39.99740,-121.9677,'Release')) %>%
  mutate(receiver_general_latitude = as.numeric(receiver_general_latitude),
         receiver_general_longitude = as.numeric(receiver_general_longitude))

(map_receiv_agg <- leaflet(data = aggregate$reach_meta_aggregate) %>% 
    addTiles() %>%
    addMarkers(~receiver_general_longitude, 
               ~receiver_general_latitude, 
               popup = ~as.character(receiver_general_location),
               label = ~as.character(receiver_general_location),
               labelOptions = labelOptions(noHide = T, textOnly = TRUE)) %>%
    addProviderTiles("Esri.WorldTopoMap")
)


# Create Encounter History list and inp file for Sac River model------------------------------------------------------------------
all_encounter_history <- make_fish_encounter_history(detections = all_aggregated, 
                                                     aggregated_reciever_metadata = aggregate$reach_meta_aggregate,
                                                     released_fish_table = fish_data |> filter(study_id %in% jpe_ids))


# Add in fish information to inp file
# First add in fish info
surv_model_inputs_with_fish_information <- all_encounter_history %>%
  left_join(fish_data %>% 
              filter(study_id %in% jpe_ids) |> 
              select(fish_id, study_id, fish_length, fish_weight, fish_type,fish_release_date,
                                   release_location), by = c("fish_id" = "fish_id")) |> 
  mutate(year = year(as.Date(fish_release_date, format="%m/%d/%Y"))) |> glimpse()

survival_model_inputs <- surv_model_inputs_with_fish_information
usethis::use_data(survival_model_inputs, overwrite = TRUE)

# Summarize fish info
fish_summary <- surv_model_inputs_with_fish_information %>%
  group_by(year, study_id) %>%
  summarise(minFL = min(as.numeric(fish_length),na.rm=TRUE),
            maxFL = max(as.numeric(fish_length),na.rm=TRUE),
            minweight = min(as.numeric(fish_weight),na.rm=TRUE),
            maxweight = max(as.numeric(fish_weight),na.rm=TRUE),
            N=n(),
            recaptured_site_1 = sum(str_split(ch, "")[[1]][2] == "1"),
            recaptured_site_2 = sum(str_split(ch, "")[[1]][3] == "1"),
            recaptured_site_3 = sum(str_split(ch, "")[[1]][3] == "1")) |> glimpse()


