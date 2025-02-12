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

# butte
butte_joined_detections <- fish_data |> 
  filter(study_id %in% butte_studyIDs) |> 
  inner_join(butte_detections, 
             by = c("study_id" = "study_id", 
                    "fish_id" = "fish_id")) |> # Used inner join because that is what the example ERDAPP script was doing, think through this more
  left_join(reciever_data) |> 
  mutate(latitude = as.numeric(latitude), 
         longitude = as.numeric(longitude)) 

# MAP 
butte_detect_summary <- aggregate(list(fish_count = butte_joined_detections$fish_id), 
                            by = list(receiver_general_location = butte_joined_detections$receiver_general_location, 
                                      latitude = butte_joined_detections$receiver_general_latitude, 
                                      longitude = butte_joined_detections$receiver_general_longitude), function(x){length(unique(x))}) |> 
  mutate(latitude = as.numeric(latitude), 
         longitude = as.numeric(longitude)) 

## USE FLORA LOGIC TO FORMAT CH ------------------------------------------------
# ------------------------------------------------------------------------------
# SACRMAENTO
# Select columns that we want
butte_all_detections <- butte_joined_detections |> 
  select(study_id, fish_id, receiver_general_location, time,
         receiver_general_river_km, receiver_region, 
         receiver_general_latitude, receiver_general_longitude,
         fish_release_date, release_river_km, release_latitude,
         release_longitude, release_location)

# Get list of all receiver GEN
# reach.meta <- get_receiver_GEN(all_detections)
reach_metadata <- get_receiver_sites_metadata(butte_all_detections)

# Manually select receiver locations to use and combine for Sac River study ----
# Will need to go back in and remap if we want new 
region_mapped_reach_metadata <- reach_metadata %>%
  filter(receiver_general_location %in% c("UpperButte_RST_Rel","UpperButte_RST","UpperButte_SKWY",
                                          "SutterBypass_Weir2_RST_Rel","SutterBypass Weir2 RST",
                                          "Butte_Blw_Sanborn_Rel","Sanborn_Slough_Rel","North_Weir_Rel","Laux Rd",
                                          "I80-50_Br","TowerBridge", 
                                          "ToeDrainBase","Hwy84Ferry",
                                          "BeniciaE","BeniciaW","ChippsE","ChippsW")) %>%
  mutate(receiver_region = case_when(receiver_region == 'Sutter Bypass' ~ 'Butte Creek',
                                     receiver_region == 'Yolo Bypass' ~ 'Lower Sac R',
                                     receiver_region == 'North Delta' ~ 'Lower Sac R',
                                     receiver_region == 'West Delta' ~ 'End',
                                     receiver_region == 'Carquinez Strait' ~ 'End',
                                     TRUE ~ receiver_region))
 


# Aggregate receiver locations and detections ----------------------------------
# Looks like Flora is still using agregate detections sac for all
# TODO confirm that this is the case
aggregate_butte <- aggregate_detections_butte(detections = butte_all_detections, 
                                                        receiever_metadata = region_mapped_reach_metadata) 

# butte Analysis 
butte_all_aggregated <- aggregate_butte$detections
# View study reaches in map
map_reaches <- aggregate_butte$reach_meta_aggregate  %>% 
filter(receiver_general_location != "Releasepoint") %>% 
  rbind(c("UpperButte", 340.854,39.70936, -121.7506,'Butte Creek'), 
        c('SutterBypass',249.540,39.10239, -121.7588,'Butte Creek')) %>% 
  mutate(receiver_general_latitude = as.numeric(receiver_general_latitude),
         receiver_general_longitude = as.numeric(receiver_general_longitude))

(map_receiv_agg <- leaflet(data = aggregate_butte$reach_meta_aggregate) %>% addTiles() %>%
    addMarkers(~receiver_general_longitude, ~receiver_general_latitude, popup = ~as.character(receiver_general_location),
               label = ~as.character(receiver_general_location),
               labelOptions = labelOptions(noHide = T, textOnly = TRUE)) %>% 
    addProviderTiles("Esri.WorldTopoMap")
)


# Create Encounter History list and inp file for Sac River model------------------------------------------------------------------
butte_all_encounter_history <- make_fish_encounter_history(detections = butte_all_aggregated, 
                                                     aggregated_reciever_metadata = aggregate_butte$reach_meta_aggregate,
                                                     released_fish_table = fish_data |> filter(study_id %in% butte_studyIDs))


# Add in fish information to inp file
# First add in fish info
surv_model_inputs_with_fish_information <- butte_all_encounter_history %>%
  left_join(fish_data %>% 
              filter(study_id %in% butte_studyIDs) |> 
              select(fish_id, study_id, fish_length, fish_weight, fish_type,fish_release_date,
                     release_location), by = c("fish_id" = "fish_id")) |> 
  mutate(year = year(as.Date(fish_release_date, format="%m/%d/%Y"))) 

add_covariates <- surv_model_inputs_with_fish_information %>% 
  drop_na(fish_length) %>% 
  arrange(year , release_location) %>% 
  # Add dummy water year type variable
  mutate(rl = case_when(release_location == "Butte_Blw_Sanborn_Rel" ~ '1B',
                        release_location == "Laux Rd" ~ '2B',
                        release_location == "North_Weir_Rel" ~ '3B',
                        release_location == "Sanborn_Slough_Rel" ~ '4B',
                        release_location == "SutterBypass_Weir2_RST_Rel" ~ '5B',
                        TRUE ~ '6B'),
         wy_three_categories = case_when(year %in% c(2013, 2014, 2015, 2016, 2018, 2020, 2021) ~ 0,
                                         year %in% c(2017, 2019, 2023) ~ 1), #0 or 1 for 2 water year type categories: dry (C,D,BN) and wet (AN,W) water year 
         wy_four_categories = case_when(year %in% c(2014,2015, 2021) ~ 0,
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
  mutate(last_capture = case_when(ch == 100 ~ 1,
                                  ch == 110 ~ 2,
                                  ch == 111 ~ 3,
                                  ch == 101 ~ 3),
         trib_ind = case_when(release_location %in% c('FR_Boyds_Rel','FR_Gridley_Rel') ~ 2,
                              TRUE ~ 1),
         dist_rlsac = case_when(rl == "1B" ~ 120, # dist from Butte_Blw_Sanborn to Sac
                                rl == "2B" ~ 103.5, # dist from Laux Road to Sac
                                rl == "3B" ~ 117, # dist from North Weir to Sac
                                rl == "4B" ~ 116.7, # dist from Sanborn Slough to Sac
                                rl == "5B" ~ 78, # dist from Sutter Bypass Weir 2 to Sac
                                rl == "6B" ~ 168.5, # dist from Upper Butte to Sac
                                rl == "1F" ~ 115, # dist from Gridley to Sac
                                rl == "2F" ~ 69), # dist from Boyds to Sac
         dist_sacdelta = 110,
         dist_rlsac_standardized = dist_rlsac / 100, # standardize distances per 100km
         dist_sacdelta_standardized =dist_sacdelta / 100) %>% # standardize distances per 100km
  ungroup() |> glimpse()

survival_model_inputs_butte <- add_covariates

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


