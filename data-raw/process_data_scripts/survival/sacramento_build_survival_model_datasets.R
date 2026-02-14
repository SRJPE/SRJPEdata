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
# ------------------------------------------------------------------------------

# SACRAMENTO
sacramento_joined_detections <- fish_data |> 
  filter(study_id %in% sacramento_studyIDs) |> 
  inner_join(sacramento_detections, 
             by = c("study_id" = "study_id", 
                    "fish_id" = "fish_id")) |> # Used inner join because that is what the example ERDAPP script was doing, think through this more
  left_join(reciever_data) |> 
  mutate(latitude = as.numeric(latitude), 
         longitude = as.numeric(longitude)) 

sacramento_detect_summary <- aggregate(list(fish_count = sacramento_joined_detections$fish_id), 
                            by = list(receiver_general_location = sacramento_joined_detections$receiver_general_location, 
                                      latitude = sacramento_joined_detections$receiver_general_latitude, 
                                      longitude = sacramento_joined_detections$receiver_general_longitude), function(x){length(unique(x))}) |> 
  mutate(latitude = as.numeric(latitude), 
         longitude = as.numeric(longitude)) 

## USE FLORA LOGIC TO FORMAT CH ------------------------------------------------
# ------------------------------------------------------------------------------
# SACRMAENTO
# Select columns that we want
sacramento_all_detections <- sacramento_joined_detections |> 
  select(study_id, fish_id, receiver_general_location, time,
         receiver_general_river_km, receiver_region, 
         receiver_general_latitude, receiver_general_longitude,
         fish_release_date, release_river_km, release_latitude,
         release_longitude, release_location)

# Get list of all receiver GEN
# reach.meta <- get_receiver_GEN(all_detections)
reach_metadata_sacramento <- get_receiver_sites_metadata(sacramento_all_detections)

# Manually select receiver locations to use and combine for Sac River study ----
# Will need to go back in and remap if we want new 
region_mapped_reach_metadata_sacramento <- reach_metadata_sacramento %>%
  filter(receiver_general_location %in% c("BattleCk_CNFH_Rel","RBDD_Rel","RBDD_Rel_Rec","Altube Island","MillCk_RST_Rel", 
                                          "MillCk2_Rel","DeerCk_RST_Rel",
                                          "Abv_WoodsonBr","Blw_Woodson", #"Mill_Ck_Conf",
                                          "IrvineFinch_Rel",
                                          "ButteBr","BlwButteBr","AbvButteBr",
                                          "I80-50_Br","TowerBridge", 
                                          "ToeDrainBase","Hwy84Ferry",
                                          "BeniciaE","BeniciaW","ChippsE","ChippsW")) %>%
  mutate(receiver_region = case_when(receiver_region == 'Battle Ck' ~ 'Release',
                                     receiver_region == 'DeerCk' ~ 'Release',
                                     receiver_region == 'Mill Ck' ~ 'Release',
                                     receiver_general_location == 'RBDD_Rel'& receiver_region == 'Upper Sac R' ~ 'Release',
                                     receiver_general_location == 'RBDD_Rel_Rec' & receiver_region == 'Upper Sac R' ~ 'Release',
                                     receiver_general_location == "Altube Island" & receiver_region == 'Upper Sac R' ~ 'Release', 
                                     receiver_general_location == "IrvineFinch_Rel" & receiver_region == "Upper Sac R" ~ "Release",
                                     receiver_region == 'Yolo Bypass' ~ 'Lower Sac R',
                                     receiver_region == 'North Delta' ~ 'Lower Sac R',
                                     receiver_region == 'West Delta' ~ 'End',
                                     receiver_region == 'Carquinez Strait' ~ 'End',
                                     TRUE ~ receiver_region))
 


# Aggregate receiver locations and detections ----------------------------------
aggregate_sacramento <- aggregate_detections_sacramento_clean(detections=sacramento_all_detections, 
                                                                      receiver_metadata = region_mapped_reach_metadata_sacramento)
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
                                                     released_fish_table = fish_data |> filter(study_id %in% sacramento_studyIDs)) |> 
  # TODO these are not in Floras data nor in the detections
  # I can't tell where they are getting filtered out, but they have incomplete capture histories
  # so filtering out here to help detections and ch datasets match
  filter(!fish_id %in% c("RBDD_WS2021-001", "RBDD_WS2021-008"))


# Add in fish information to inp file
# First add in fish info
surv_model_inputs_with_fish_information <- sacramento_all_encounter_history %>%
  left_join(fish_data %>% 
              filter(study_id %in% sacramento_studyIDs) |> 
              select(fish_id, study_id, fish_length, fish_weight, fish_type,fish_release_date,
                     release_location), by = c("fish_id" = "fish_id")) |> 
  mutate(year = year(as.Date(fish_release_date, format="%m/%d/%Y"))) 

add_covariates <- surv_model_inputs_with_fish_information %>% 
  drop_na(fish_length) %>% 
  arrange(year , release_location) %>% 
  # Add dummy water year type variable
  mutate(rl = case_when(release_location == "BattleCk_CNFH_Rel" ~ '1S',
                        release_location == "RBDD_Rel" ~ '2S',
                        release_location == "Altube Island" ~ '3S',
                        # TODO RB river park? in Flora's 2026 code but not in our data
                        release_location == "IrvineFinch_Rel" ~ "5S",
                        release_location == "MillCk_RST_Rel" ~ '6S',
                        release_location == "DeerCk_RST_Rel" ~ '7S'), 
         wy_two_categories = case_when(year %in% c(2013,2015,2016,2018,2020, 2021,2022) ~ 0,
                         year %in% c(2017, 2019, 2023) ~ 1), #0 or 1 for 2 water year type categories: dry (C,D,BN) and wet (AN,W) water year 
         wy_three_categories = case_when(year %in% c(2015, 2021, 2022) ~ 0,
                         year %in% c(2013, 2016, 2018, 2020) ~ 1,
                         year %in% c(2017, 2019, 2023) ~ 2), #0, 1 or 2 for 3 water year type categories: C, D-BN-AN, W water year
         first_capture = 1, # define first capture location, it is always the release location
         length_standardized = as.numeric(scale(as.numeric(fish_length))), #standardized length
         weight_standardized = as.numeric(scale(as.numeric(fish_weight))),#standardized weight
         fish_k = (100 * as.numeric(fish_weight)) / (as.numeric(fish_length) ^ 3), 
         condition_standardized = as.numeric(scale(fish_k))
         ) %>%  #standardized condition factor
  group_by(fish_id) %>% 
  # find last capture location for each fish and each potential capture history ch
  mutate(last_capture = case_when(ch == 10000 ~ 1,
                             ch == 11000 ~ 2,
                             ch %in% c(11100, 10100) ~ 3,
                             ch %in% c(11110, 10110, 10010, 11010) ~ 4 ,
                             ch %in% c(11111, 10111, 11011, 11101, 11001, 10011, 10101, 10001) ~ 5),
         dist_rlwoodson = case_when(rl == "1S" ~ 91.8, # dist from Battle Creek to Woodson Bridge
                                    rl == "2S" ~ 36.9, # dist from RBDD to Woodson Bridge
                                    rl == "3S" ~ 36.9, # same as RBDD
                                    # TODO placeholder for rl "4S", # dist from RB River Park to Woodson Bridge, same as RBDD
                                    rl == "5S" ~ 36.9, # dist from Irvine Finch to Woodson Bridge, same as RBDD
                                    rl == "6S" ~ 25.7, # dist from Mill Creek to Woodson Bridge
                                    rl == "7S" ~ 16.6), # dist from Deer Creek to Woodson Bridge
         dist_woodsonbutte = 88, # distance in km from Woodson Bridge to Butte Bridge
         dist_buttesac = 170, # distance in km from Butte Bridge to Sac
         dist_sacdelta = 110,
         dist_rlwoodson_standardized = dist_rlwoodson / 100, # standardize distances per 100km
         dist_woodsonbutte_standardized = dist_woodsonbutte / 100,# standardize distances per 100km
         dist_buttesac_standardized = dist_buttesac / 100, # standardize distances per 100km
         dist_sacdelta_standardized = dist_sacdelta / 100) %>% # standardize distances per 100km
  ungroup() |> glimpse()


survival_model_inputs_sacramento <- add_covariates

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


