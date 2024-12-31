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
         longitude = as.numeric(longitude)) 

# MAP 
detect_summary <- aggregate(list(fish_count = joined_detections$fish_id), 
                            by = list(receiver_general_location = joined_detections$receiver_general_location, 
                                      latitude = joined_detections$receiver_general_latitude, 
                                      longitude = joined_detections$receiver_general_longitude), function(x){length(unique(x))}) |> 
  mutate(latitude = as.numeric(latitude), 
         longitude = as.numeric(longitude)) 

library(ggplot2)
library(mapdata)
library(ggrepel)

# Map for data check -----------------------------------------------------------
## Set boundary box for map
# xlim <- c(-123, -121)
# ylim <- c(37.5, 40.6)
# usa <- map_data("worldHires", ylim = ylim, xlim = xlim)
# rivers <- map_data("rivers", ylim = ylim, xlim = xlim)
# rivers <- rivers[rivers$lat < max(ylim),]
# ggplot() +
#   geom_polygon(data = usa, aes(x = long, y = lat, group = group), fill = "grey80") +
#   geom_path(data = rivers, aes(x = long, y = lat, group = group), size = 1, color = "white", lineend = "round") +
#   geom_point(data = detect_summary, aes(x = longitude, y = latitude), shape=23, fill="blue", color="darkred", size=3) +
#   geom_text_repel(data = detect_summary, aes(x = longitude, y = latitude, label = fish_count)) +
#   theme_bw() + ylab("latitude") + xlab("longitude") +
#   coord_fixed(1.3, xlim = xlim, ylim = ylim) +
#   ggtitle("Location of study detections w/ count of unique fish visits")

## USE FLORA LOGIC TO FORMAT CH ------------------------------------------------
# she groups fish into 4 detection sites


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

# Manually select receiver locations to use and combine for Sac River study ----
# Will need to go back in and remap if we want new 
# TODO add mapping to show/add new sites (including the butte sites bsased on what Flora put) 
region_mapped_reach_metadata <- reach_metadata %>%
  # TODO confirm with Flora that these filtered generatl locations remain the same
  filter(receiver_general_location %in% c("BattleCk_CNFH_Rel","RBDD_Rel","RBDD_Rel_Rec","Altube Island","MillCk_RST_Rel",
                                          "MillCk2_Rel","DeerCk_RST_Rel","Mill_Ck_Conf",
                                          "Abv_WoodsonBr","Blw_Woodson", "ButteBr","BlwButteBr",
                                          "I80-50_Br","TowerBridge",
                                          "ToeDrainBase","Hwy84Ferry",
                                          "BeniciaE","BeniciaW","ChippsE","ChippsW")) %>%
  # TODO which ones are the feather river reciever regions? 
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



# Aggregate receiver locations and detections ----------------------------------
# TODO - Fix butte once we have correct mapping identified above 
aggregate_butte <- aggregate_detections_butte(detections = all_detections |> filter(study_id %in% jpe_ids_feather_butte), 
                                              receiever_metadata = region_mapped_reach_metadata) 

aggregate_sacramento <- aggregate_detections_sacramento(detections = all_detections |> filter(study_id %in% jpe_ids_sac), 
                                                        receiever_metadata = region_mapped_reach_metadata) 

# Sacramento Analysis 
sacramento_all_aggregated <- aggregate_sacramento$detections
# View study reaches in map
map_reaches <- aggregate_sacramento$reach_meta_aggregate %>%
  filter(receiver_general_location != "Releasepoint") %>%
  rbind(c("Battle Creek",517.344,40.39816,-122.1456,"Release"),
        c("RBDD",461.579, 40.15444, -122.2025,'Release'),
        c("Mill Creek",450.703,40.05479, -122.0321,'Release'),
        c('Deer Creek',441.728,39.99740,-121.9677,'Release')) %>%
  mutate(receiver_general_latitude = as.numeric(receiver_general_latitude),
         receiver_general_longitude = as.numeric(receiver_general_longitude))

(map_receiv_agg <- leaflet(data = aggregate_sacramento$reach_meta_aggregate) %>% 
    addTiles() %>%
    addMarkers(~receiver_general_longitude, 
               ~receiver_general_latitude, 
               popup = ~as.character(receiver_general_location),
               label = ~as.character(receiver_general_location),
               labelOptions = labelOptions(noHide = T, textOnly = TRUE)) %>%
    addProviderTiles("Esri.WorldTopoMap")
)


# Create Encounter History list and inp file for Sac River model------------------------------------------------------------------
sacramento_all_encounter_history <- make_fish_encounter_history(detections = sacramento_all_aggregated, 
                                                     aggregated_reciever_metadata = aggregate_sacramento$reach_meta_aggregate,
                                                     released_fish_table = fish_data |> filter(study_id %in% jpe_ids))


# Add in fish information to inp file
# First add in fish info
surv_model_inputs_with_fish_information <- sacramento_all_encounter_history %>%
  left_join(fish_data %>% 
              filter(study_id %in% jpe_ids) |> 
              select(fish_id, study_id, fish_length, fish_weight, fish_type,fish_release_date,
                     release_location), by = c("fish_id" = "fish_id")) |> 
  mutate(year = year(as.Date(fish_release_date, format="%m/%d/%Y"))) 

add_covariates <- surv_model_inputs_with_fish_information %>% 
  drop_na(fish_length) %>% 
  arrange(year , release_location) %>% 
  # Add dummy water year type variable
  mutate(wy_three_categories = case_when(year %in% c(2013,2015,2016,2018,2020, 2021,2022) ~ 0,
                         year %in% c(2017, 2019, 2023) ~ 1), #0 or 1 for 2 water year type categories: dry (C,D,BN) and wet (AN,W) water year 
         wy_four_categories = case_when(year %in% c(2015, 2021, 2022) ~ 0,
                         year %in% c(2013, 2016, 2018, 2020) ~ 1,
                         year %in% c(2017, 2019, 2023) ~ 2), #0, 1 or 2 for 3 water year type categories: C, D-BN-AN, W water year
         first_capture = 1, # define first capture location, it is always the release location
         length_standardized = scale(as.numeric(fish_length)), #standardized length
         weight_standardized = scale(as.numeric(fish_weight)),#standardized weight
         # TODO we are missing fisk_k in our data, see how flora gets this
         # condition_standardized = scale(fish_k) 
         ) %>%  #standardized condition factor
  group_by(fish_id) %>% 
  # find last capture location for each fish and each potential capture history ch
  mutate(lastCap = case_when(ch == 10000 ~ 1,
                             ch == 11000 ~ 2,
                             ch %in% c(11100, 10100) ~ 3,
                             ch %in% c(11110, 10110, 10010, 11010) ~ 4 ,
                             ch %in% c(11111, 10111, 11011, 11101, 11001, 10011, 10101, 10001) ~ 5),
         # TODO, we do not have these as release locations, get script where flora creates theses "1S"...ect
         dist_rlwoodson = case_when(release_location == "1S" ~ 91.8, # dist from Battle Creek to Woodson Bridge
                                    release_location == "2S" ~ 36.9, # dist from RBDD to Woodson Bridge
                                    release_location == "3S" ~ 36.9, # same as RBDD
                                    release_location == "4S" ~ 25.7, # dist from Mill Creek to Woodson Bridge
                                    release_location == "5S" ~ 16.6), # dist from Deer Creek to Woodson Bridge
         dist_woodsonbutte = 88, # distance in km from Woodson Bridge to Butte Bridge
         dist_buttesac = 170, # distance in km from Butte Bridge to Sac
         dist_sacdelta = 110,
         dist_rlwoodson_standardized = dist_rlwoodson / 100, # standardize distances per 100km
         dist_woodsonbutte_standardized = dist_woodsonbutte / 100,# standardize distances per 100km
         dist_buttesac_standardized= dist_buttesac / 100, # standardize distances per 100km
         dist_sacdelta_standardized =dist_sacdelta / 100) %>% # standardize distances per 100km
  ungroup() |> glimpse()

# TODO add this once we get feather butte mapping
# d_FeaBut_sort <- d_FeaBut %>% 
#   arrange(year,rl) %>% 
#   # Add dummy water year type variable
#   mutate(WY2 = case_when(year %in% c(2013,2014,2015,2016,2018,2020, 2021) ~ 0,
#                          year %in% c(2017, 2019, 2023) ~ 1), #0 or 1 for 2 water year type categories: dry (C,D,BN) and wet (AN,W) water year 
#          WY3 = case_when(year %in% c(2014,2015, 2021) ~ 0,
#                          year %in% c(2013, 2016, 2018, 2020) ~ 1,
#                          year %in% c(2017, 2019, 2023) ~ 2), #0, 1 or 2 for 3 water year type categories: C, D-BN-AN, W water year
#          firstCap = 1, # define first capture location, it is always the release location
#          length.z = scale(fish_length), #standardized length
#          weight.z = scale(fish_weight),#standardized weight
#          k.z = scale(fish_k)) %>%  #standardized condition factor)  
#   group_by(FishID) %>% 
#   # find last capture location for each fish and each potential capture history ch
#   mutate(lastCap = case_when(ch == 100 ~ 1,
#                              ch == 110 ~ 2,
#                              ch == 111 ~ 3,
#                              ch == 101 ~ 3),
#          trib_ind = case_when(release_location %in% c('FR_Boyds_Rel','FR_Gridley_Rel') ~ 2,
#                               TRUE ~ 1),
#          dist_rlsac = case_when(rl == "1B" ~ 120, # dist from Butte_Blw_Sanborn to Sac
#                                 rl == "2B" ~ 103.5, # dist from Laux Road to Sac
#                                 rl == "3B" ~ 117, # dist from North Weir to Sac
#                                 rl == "4B" ~ 116.7, # dist from Sanborn Slough to Sac
#                                 rl == "5B" ~ 78, # dist from Sutter Bypass Weir 2 to Sac
#                                 rl == "6B" ~ 168.5, # dist from Upper Butte to Sac
#                                 rl == "1F" ~ 115, # dist from Gridley to Sac
#                                 rl == "2F" ~ 69), # dist from Boyds to Sac
#          dist_sacdelta = 110,
#          dist_rlsac.z =dist_rlsac/100, # standardize distances per 100km
#          dist_sacdelta.z = dist_sacdelta/100) %>% # standardize distances per 100km
#   ungroup()


# TODO, join Butte to Sacramento Data 

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
            recaptured_site_3 = sum(str_split(ch, "")[[1]][3] == "1")) 

# TODO ADD DISTANCE FROM RECIEVER LOCATION FROM Floras new PrepData.R Script
# Also add water year


