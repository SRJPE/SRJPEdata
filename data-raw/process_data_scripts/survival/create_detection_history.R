library(tidyverse)
# Confirm that pull acoustic tagging data has already been sourced
source("data-raw/pull_data_scripts/combine_database_pull_and_save.R")
source("data-raw/process_data_scripts/survival/sacramento_build_survival_model_datasets.R")
source("data-raw/process_data_scripts/survival/butte_build_survival_model_datasets.R")
source("data-raw/process_data_scripts/survival/feather_build_survival_model_datasets.R")

sacramento_detections <- aggregate_detections_sacramento(detections = sacramento_all_detections, 
                                                        receiever_metadata = region_mapped_reach_metadata_sacramento,
                                                        create_detection_history = TRUE) 

sacramento_detections$detections |> glimpse()
  arrange(FishID) |> 
  pivot_wider(id_cols = FishID, names_from = GEN, values_from = min_time) |>
  select(fish_id = FishID, release_time = Releasepoint,
         butte_time = ButteBridge, woodson_time = WoodsonBridge,
         sacramento_time = Sacramento, endpoint_time = Endpoint) |>
  mutate(TTfR1 = as.numeric(difftime(woodson_time, release_time, units = "days")),
         TTfR2 = as.numeric(difftime(butte_time, release_time, units = "days")),
         TTfR3 = as.numeric(difftime(sacramento_time, release_time, units = "days")),
         TTfR4 = as.numeric(difftime(endpoint_time, release_time, units = "days")),
         TTfR4 = if_else(TTfR4 < 0, NA_real_, TTfR4)) |># Replace negative TTfR4 with NA, example fish SP2023-810
  arrange(fish_id) |>
  select(TTfR1, TTfR2, TTfR3, TTfR4)
