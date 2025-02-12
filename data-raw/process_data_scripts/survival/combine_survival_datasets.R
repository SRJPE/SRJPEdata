# Confirm that pull acoustic tagging data has already been sourced

source("data-raw/process_data_scripts/survival/sacramento_build_survival_model_datasets.R")
source("data-raw/process_data_scripts/survival/butte_build_survival_model_datasets.R")
source("data-raw/process_data_scripts/survival/feather_build_survival_model_datasets.R")

# Combine data
survival_model_inputs <- bind_rows(survival_model_inputs_sacramento, 
                                   survival_model_inputs_butte, 
                                   survival_model_inputs_feather) |> 
  mutate(fish_weight = as.numeric(fish_weight), fish_length = as.numeric(fish_length))

# save as data object
usethis::use_data(survival_model_inputs, overwrite = TRUE)
