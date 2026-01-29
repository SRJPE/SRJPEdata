library(tidyverse)
# Confirm that pull acoustic tagging data has already been sourced
# TODO at the end, source this script (create_detection_history) at the bottom of combine survival datasets
source("data-raw/pull_data_scripts/combine_database_pull_and_save.R")
source("data-raw/pull_data_scripts/pull_acoustic_tagging_data.R")
source("data-raw/process_data_scripts/survival/sacramento_build_survival_model_datasets.R")
source("data-raw/process_data_scripts/survival/butte_build_survival_model_datasets.R")
source("data-raw/process_data_scripts/survival/feather_build_survival_model_datasets.R")

sacramento_detections <- aggregate_detections_sacramento(detections = sacramento_all_detections, 
                                                        receiver_metadata = region_mapped_reach_metadata_sacramento,
                                                        create_detection_history = TRUE) 

feather_detections <- aggregate_detections_feather(detections = feather_all_detections, 
                                                   receiver_metadata = region_mapped_reach_metadata_feather,
                                                   create_detection_history = TRUE) 

butte_detections <- aggregate_detections_butte(detections = butte_all_detections, 
                                               receiver_metadata = region_mapped_reach_metadata_butte,
                                               create_detection_history = TRUE) 

detection_history_sac <- sacramento_detections$detections |> 
  ungroup() |> 
  arrange(fish_id) |> 
  pivot_wider(id_cols = fish_id, 
              names_from = receiver_general_location, 
              values_from = min_time) |>
  select(fish_id, release_time = Releasepoint,
         butte_time = ButteBridge, woodson_time = WoodsonBridge,
         sacramento_time = Sacramento, endpoint_time = Endpoint) |> 
  mutate(TTfR1 = as.numeric(difftime(woodson_time, release_time, units = "days")),
         TTfR2 = as.numeric(difftime(butte_time, release_time, units = "days")),
         TTfR3 = as.numeric(difftime(sacramento_time, release_time, units = "days")),
         TTfR4 = as.numeric(difftime(endpoint_time, release_time, units = "days")),
         TTfR4 = if_else(TTfR4 < 0, NA_real_, TTfR4)) |># Replace negative TTfR4 with NA, example fish SP2023-810
  arrange(fish_id) |>
  select(fish_id, TTfR1, TTfR2, TTfR3, TTfR4) |> 
  mutate(stream = "sacramento")

detection_history_butte <- butte_detections$detections |> 
  ungroup() |> 
  arrange(fish_id) |> 
  pivot_wider(id_cols = fish_id, 
              names_from = receiver_general_location, 
              values_from = min_time) |> 
  select(fish_id, 
         release_time = Releasepoint,
         # butte_time = ButteBridge, 
         # woodson_time = WoodsonBridge,
         sacramento_time = Sacramento, 
         endpoint_time = Endpoint) |> 
  mutate(#TTfR1 = as.numeric(difftime(woodson_time, release_time, units = "days")),
         #TTfR2 = as.numeric(difftime(butte_time, release_time, units = "days")),
         TTfR3 = as.numeric(difftime(sacramento_time, release_time, units = "days")),
         TTfR4 = as.numeric(difftime(endpoint_time, release_time, units = "days")),
         TTfR4 = if_else(TTfR4 < 0, NA_real_, TTfR4)) |># Replace negative TTfR4 with NA, example fish SP2023-810
  arrange(fish_id) |>
  mutate(TTfR1 = NA, TTfR2 = NA) |> 
  select(fish_id, TTfR1, TTfR2, TTfR3, TTfR4) |> 
  mutate(stream = "butte")
  
  detection_history_feather <- feather_detections$detections |> 
    ungroup() |> 
    arrange(fish_id) |> 
    pivot_wider(id_cols = fish_id, 
                names_from = receiver_general_location, 
                values_from = min_time) |> 
    select(fish_id, 
           release_time = Releasepoint,
           # butte_time = ButteBridge, 
           # woodson_time = WoodsonBridge,
           sacramento_time = Sacramento, 
           endpoint_time = Endpoint) |> 
    mutate(# TTfR1 = as.numeric(difftime(woodson_time, release_time, units = "days")),
      # TTfR2 = as.numeric(difftime(butte_time, release_time, units = "days")),
      TTfR3 = as.numeric(difftime(sacramento_time, release_time, units = "days")),
      TTfR4 = as.numeric(difftime(endpoint_time, release_time, units = "days")),
      TTfR4 = if_else(TTfR4 < 0, NA_real_, TTfR4)) |># Replace negative TTfR4 with NA, example fish SP2023-810
    arrange(fish_id) |>
    mutate(TTfR1 = NA, TTfR2 = NA) |> 
    select(fish_id, TTfR1, TTfR2, TTfR3, TTfR4) |> 
    mutate(stream = "feather")
  
survival_model_detection_history <- bind_rows(detection_history_sac,
                                              detection_history_butte, 
                                              detection_history_feather)

use_this::use_data(survival_model_detection_history, overwrite = T)
  


