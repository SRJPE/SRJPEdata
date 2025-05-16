# This script prepares the data from prep_for_db_denormalized.R to be loaded
# to db by creating IDs for all the lookups

source("data-raw/data-prep/prep_for_db_denormalized.R")

# Read in lookups ---------------------------------------------------------
# trap_location
gcs_get_object(object_name = "model-db/trap_location.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/model-db/trap_location.csv",
               overwrite = TRUE)
trap_location <- read_csv("data/model-db/trap_location.csv")
# run
gcs_get_object(object_name = "model-db/run.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/model-db/run.csv",
               overwrite = TRUE)
run <- read_csv("data/model-db/run.csv")
#lifestage
gcs_get_object(object_name = "model-db/lifestage.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/model-db/lifestage.csv",
               overwrite = TRUE)
lifestage <- read_csv("data/model-db/lifestage.csv")
#visit_type
gcs_get_object(object_name = "model-db/visit_type.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/model-db/visit_type.csv",
               overwrite = TRUE)
visit_type <- read_csv("data/model-db/visit_type.csv")
#trap_functioning
gcs_get_object(object_name = "model-db/trap_functioning.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/model-db/trap_functioning.csv",
               overwrite = TRUE)
trap_functioning <- read_csv("data/model-db/trap_functioning.csv")
#fish_processed
gcs_get_object(object_name = "model-db/fish_processed.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/model-db/fish_processed.csv",
               overwrite = TRUE)
fish_processed <- read_csv("data/model-db/fish_processed.csv")
#debris_level
gcs_get_object(object_name = "model-db/debris_level.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/model-db/debris_level.csv",
               overwrite = TRUE)
debris_level <- read_csv("data/model-db/debris_level.csv")
#environmental_parameter
gcs_get_object(object_name = "model-db/environmental_parameter.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/model-db/environmental_parameter.csv",
               overwrite = TRUE)
environmental_parameter <- read_csv("data/model-db/environmental_parameter.csv")
#gage_source
gcs_get_object(object_name = "model-db/gage_source.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/model-db/gage_source.csv",
               overwrite = TRUE)
gage_source <- read_csv("data/model-db/gage_source.csv")
#hatchery
gcs_get_object(object_name = "model-db/hatchery.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/model-db/hatchery.csv",
               overwrite = TRUE)
hatchery <- read_csv("data/model-db/hatchery.csv")
# origin
gcs_get_object(object_name = "model-db/origin.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/model-db/origin.csv",
               overwrite = TRUE)
origin <- read_csv("data/model-db/origin.csv")
# survey_location
gcs_get_object(object_name = "model-db/survey_location.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/model-db/survey_location.csv",
               overwrite = TRUE)
survey_location <- read_csv("data/model-db/survey_location.csv")
# sex
gcs_get_object(object_name = "model-db/sex.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/model-db/sex.csv",
               overwrite = TRUE)
sex <- read_csv("data/model-db/sex.csv")
# direction
gcs_get_object(object_name = "model-db/direction.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/model-db/direction.csv",
               overwrite = TRUE)
direction <- read_csv("data/model-db/direction.csv")


# Catch -------------------------------------------------------------------

catch <- standard_catch_unmarked |> 
  select(stream, site, subsite, date, count, run, lifestage, adipose_clipped, 
         dead, fork_length, weight) |> 
  # trap_location_id
  left_join(trap_location, by = c("stream", "site", "subsite")) |> 
  select(-c(stream, site, subsite, site_group, description)) |> 
  rename(trap_location_id = id) |> 
  # run_id
  left_join(select(run, -description), by = c("run" = "definition")) |> 
  rename(run_id = id) |> 
  select(-run) |> 
  # lifestage_id
  left_join(select(lifestage, -description), by = c("lifestage" = "definition")) |> 
  rename(lifestage_id = id) |> 
  select(-lifestage) |> 
  mutate(actual_count = NA)

try(if(any((unique(catch$trap_location_id) %in% trap_location$id) == F)) 
  stop("Missing Trap Location ID! Please fix!"))
try(if(any((unique(catch$run_id) %in% run$id) == F))
  stop("Missing Run ID! Please fix!"))
try(if(any((unique(catch$lifestage_id) %in% lifestage$id) == F))
  stop("Missing Lifestage ID! Please fix!"))

gcs_upload(catch,
           object_function = f,
           type = "csv",
           name = "model-db/catch.csv",
           predefinedAcl = "bucketLevel")

# Trap --------------------------------------------------------------------

trap <- trap_raw |> 
  # trap_location_id
  left_join(trap_location, by = c("stream", "site", "subsite")) |> 
  select(-c(stream, site, subsite, site_group, description)) |> 
  rename(trap_location_id = id) |> 
  # visit_type_id
  left_join(visit_type, by = c("visit_type" = "definition")) |> 
  rename(visit_type_id = id) |> 
  select(-visit_type, -description) |> 
  # trap_functioning_id
  left_join(trap_functioning, by = c("trap_functioning" = "definition")) |> 
  rename(trap_functioning_id = id) |> 
  select(-trap_functioning, -description) |> 
  # fish_processed_id
  left_join(fish_processed, by = c("fish_processed" = "definition")) |> 
  rename(fish_processed_id = id) |> 
  select(-fish_processed, -description) |> 
  # debris_level_id
  left_join(debris_level, by = c("debris_level" = "definition")) |> 
  rename(debris_level_id = id) |> 
  select(c(trap_location_id, visit_type_id, trap_visit_time_start, trap_visit_time_end,
           trap_functioning_id, in_half_cone_configuration, fish_processed_id,
           rpm_start, rpm_end, total_revolutions, debris_volume, debris_level_id,
           discharge, water_velocity, water_temp, turbidity, include))

try(if(any((unique(trap$trap_location_id) %in% trap_location$id) == F)) 
  stop("Missing Trap Location ID! Please fix!"))
try(if(any((unique(trap$visit_type_id) %in% visit_type$id) == F))
  stop("Missing Visit Type ID! Please fix!"))
try(if(any((unique(trap$trap_functioning_id) %in% trap_functioning$id) == F))
  stop("Missing Trap Functioning ID! Please fix!"))
try(if(any((unique(trap$fish_processed_id) %in% fish_processed$id) == F))
  stop("Missing Fish Processed ID! Please fix!"))
try(if(any((unique(trap$debris_level_id) %in% debris_level$id) == F))
  stop("Missing Debris Level ID! Please fix!"))

gcs_upload(trap,
           object_function = f,
           type = "csv",
           name = "model-db/trap_visit.csv",
           predefinedAcl = "bucketLevel")

# Release -----------------------------------------------------------------
release <- release_raw |> 
  # Releases are not at the subsite level so added NA subsite to trap location lookup
  left_join(trap_location, by = c("stream", "site", "subsite")) |> 
  select(-c(stream, site, subsite, site_group, description)) |> 
  rename(trap_location_id = id) |> 
  left_join(origin, by = c("origin_released" = "definition")) |> 
  rename(origin_id = id) |> 
  select(-origin_released, -description) |> 
  left_join(run, by = c("run_released" = "definition")) |> 
  rename(run_id = id) |> 
  select(-run_released, -description) |> 
  left_join(lifestage, by = c("lifestage_released" = "definition")) |> 
  rename(lifestage_id = id) |> 
  select(-lifestage_released, -description)

gcs_upload(release,
           object_function = f,
           type = "csv",
           name = "model-db/release.csv",
           predefinedAcl = "bucketLevel")

# Recaptured fish ---------------------------------------------------------
recaptured_fish <- recapture_fish_raw |> 
  # trap_location_id
  left_join(trap_location, by = c("stream", "site", "subsite")) |> 
  select(-c(stream, site, subsite, site_group, description)) |> 
  rename(trap_location_id = id) |> 
  # run_id
  left_join(select(run, -description), by = c("run" = "definition")) |> 
  rename(run_id = id) |> 
  select(-run) |> 
  # lifestage_id
  left_join(select(lifestage, -description), by = c("lifestage" = "definition")) |> 
  rename(lifestage_id = id) |> 
  select(-lifestage) 

gcs_upload(recaptured_fish,
           object_function = f,
           type = "csv",
           name = "model-db/recaptured_fish.csv",
           predefinedAcl = "bucketLevel")

# Carcass estimates -------------------------------------------------------

carcass_estimates <- carcass_estimates_raw |> 
  left_join(survey_location, by = c("stream", "reach")) |>
  select(-c(stream, reach, description)) |>
  rename(survey_location_id = id) |>
  # need to confirm the run and adipose clipped
  mutate(run = "spring",
         adipose_clipped = F) |> 
  # run_id
  left_join(run, by = c("run" = "definition")) |> 
  rename(run_id = id) |> 
  select(-run, -description) 

try(if(any((unique(carcass_estimates$survey_location_id) %in% survey_location$id) == F)) 
  stop("Missing Survey Location ID! Please fix!"))
try(if(any((unique(carcass_estimates$run_id) %in% run$id) == F))
  stop("Missing Run ID! Please fix!"))
try(if(any(is.na(carcass_estimates$year)))
  stop("Missing Year! Please fix!"))

gcs_upload(carcass_estimates,
           object_function = f,
           type = "csv",
           name = "model-db/carcass_estimates.csv",
           predefinedAcl = "bucketLevel")

# Daily redd --------------------------------------------------------------
daily_redd <- daily_redd_raw |> 
  left_join(survey_location, by = c("stream", "reach")) |>
  select(-c(stream, reach, description)) |>
  rename(survey_location_id = id) |>
  # run_id
  left_join(run, by = c("run" = "definition")) |> 
  rename(run_id = id) |> 
  select(-run, -description) 

try(if(any((unique(daily_redd$survey_location_id) %in% survey_location$id) == F)) 
  stop("Missing Survey Location ID! Please fix!"))
try(if(any((unique(daily_redd$run_id) %in% run$id) == F))
  stop("Missing Run ID! Please fix!"))
try(if(any(is.na(daily_redd$date)))
  stop("Missing Date! Please fix!"))

gcs_upload(daily_redd,
           object_function = f,
           type = "csv",
           name = "model-db/daily_redd.csv",
           predefinedAcl = "bucketLevel")


# Passage counts ----------------------------------------------------------

passage <- passage_raw |> 
  # need to add survey location lookup
  left_join(survey_location, by = c("stream", "reach")) |>
  select(-c(stream, reach, description)) |>
  rename(survey_location_id = id) |>
  # run_id
  left_join(run, by = c("run" = "definition")) |> 
  rename(run_id = id) |> 
  select(-run, -description) |> 
  # sex_id
  left_join(sex, by = c("sex" = "definition")) |> 
  rename(sex_id = id) |> 
  select(-sex, -description) |> 
  #direction_id
  left_join(direction, by = c("passage_direction" = "definition")) |> 
  rename(direction_id = id) |> 
  select(-passage_direction, -description) |> 
  # method
  left_join(upstream_method, by = c("method" = "definition")) |> 
  rename(upstream_method_id = id) |> 
  select(-method, -description)

try(if(any((unique(passage$survey_location_id) %in% survey_location$id) == F)) 
  stop("Missing Survey Location ID! Please fix!"))
try(if(any((unique(passage$run_id) %in% run$id) == F))
  stop("Missing Run ID! Please fix!"))
try(if(any((unique(passage$sex_id) %in% sex$id) == F))
  stop("Missing Sex ID! Please fix!"))
try(if(any((unique(passage$direction_id) %in% direction$id) == F))
  stop("Missing Direction ID! Please fix!"))
try(if(any(is.na(passage$date)))
  stop("Missing Date! Please fix!"))

gcs_upload(passage,
           object_function = f,
           type = "csv",
           name = "model-db/passage_counts.csv",
           predefinedAcl = "bucketLevel")

# Passage estimates -------------------------------------------------------
passage_estimates <- passage_estimates_raw |> 
  left_join(survey_location, by = c("stream", "reach")) |>
  select(-c(stream, reach, description)) |>
  rename(survey_location_id = id) |>
  # run_id
  left_join(run, by = c("run" = "definition")) |> 
  rename(run_id = id) |> 
  select(-run, -description, -ucl, -lcl, -confidence_interval) |> 
  # ladder_id
  left_join(upstream_ladder, by = c("ladder" = "definition")) |> 
  rename(ladder_id = id) |> 
  select(-ladder, -description)

try(if(any((unique(passage_estimates$survey_location_id) %in% survey_location$id) == F)) 
  stop("Missing Survey Location ID! Please fix!"))
try(if(any((unique(passage_estimates$run_id) %in% run$id) == F))
  stop("Missing Run ID! Please fix!"))
try(if(any(is.na(passage_estimates$year)))
  stop("Missing Year! Please fix!"))

gcs_upload(passage_estimates,
           object_function = f,
           type = "csv",
           name = "model-db/passage_estimates.csv",
           predefinedAcl = "bucketLevel")

# Daily holding -----------------------------------------------------------
daily_holding <- daily_holding_raw |> 
  left_join(survey_location, by = c("stream", "reach")) |>
  select(-c(stream, reach, description)) |>
  rename(survey_location_id = id) |> 
  # run_id
  left_join(run, by = c("run" = "definition")) |> 
  rename(run_id = id) |> 
  select(-run, -description)  

try(if(any((unique(daily_holding$survey_location_id) %in% survey_location$id) == F)) 
  stop("Missing Survey Location ID! Please fix!"))
try(if(any((unique(daily_holding$run_id) %in% run$id) == F))
  stop("Missing Run ID! Please fix!"))
try(if(any(is.na(daily_holding$date)))
  stop("Missing Date! Please fix!"))

gcs_upload(daily_holding,
           object_function = f,
           type = "csv",
           name = "model-db/daily_holding.csv",
           predefinedAcl = "bucketLevel")

