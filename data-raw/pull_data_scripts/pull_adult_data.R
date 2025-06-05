# Pull adult data from EDI (or other repositories)
# Adult data were originally stored in the SR JPE database
# however, for the short-term (until it is understand what and how we want to use those data
# it is easier to update the data on EDI and pull directly 

library(tidyverse)
library(EDIutils)
library(googleCloudStorageR)

gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
gcs_global_bucket(bucket = Sys.getenv("GCS_DEFAULT_BUCKET"))
# Set the scope for script to use API to download data from EDI
scope = "edi"

# Battle/Clear
# Upstream passage and redd data
# These data will be published on EDI but currently are not
# In the interim we will pull from the standard format datasets

# gcs_get_object(object_name = "standard-format-data/standard_daily_redd.csv",
#                bucket = gcs_get_global_bucket(),
#                saveToDisk = "data-raw/data-prep/standard-format-data/standard_daily_redd.csv",
#                overwrite = TRUE)
# standard_daily_redd <- read_csv("data-raw/data-prep/standard-format-data/standard_daily_redd.csv")
# 
# battle_clear_redd <- standard_daily_redd |> 
#   # remove any NA entries - there should not be any now that Feather issue fixed
#   # remove any non chinook species
#   filter(!is.na(date), species %in% c("chinook", "not recorded", "unknown")) |> 
#   select(date, latitude, longitude, reach, redd_id, age, velocity, run, stream, redd_count) |> 
#   # change format to date instead of datetime
#   mutate(date = as.Date(date),
#          redd_count = ifelse(is.na(redd_count),0,redd_count)) |> 
#   filter(stream %in% c("battle creek", "clear creek")) |>
#   filter(run %in% c("spring", "not recorded"),
#          # species %in% c("not recorded", NA, "chinook", "unknown"),
#          stream %in% c("battle creek", "clear creek"),
#          !reach %in% c("R6", "R6A", "R6B", "R7")) |> #TODO remove once reaches are standardized
#   group_by(year = year(date), stream) |> 
#   distinct(redd_id) |> 
#   mutate(redd_count = 1) |> 
#   summarize(count = sum(redd_count)) |> 
#   as.data.frame() |> 
#   add_row(year = 2022,
#           stream = "clear creek",
#           count = 6) |> 
#   add_row(year = 2023,
#           stream = "clear creek",
#           count = 0) |> 
#   add_row(year = 2024,
#           stream = "clear creek",
#           count = 4) |> 
#   mutate(data_type = "redd")
# write_csv(battle_clear_redd, "data-raw/helper-tables/battle_clear_redd_historical.csv")

battle_redd <- read_csv("data-raw/helper-tables/battle_clear_redd_historical.csv") |> 
  filter(stream == "battle creek")

clear_redd <- read_csv("data-raw/helper-tables/clear_redd_historical.csv") # Sam provided updated data for Clear redd on 5/21/2025 so use these instead

# gcs_get_object(object_name = "standard-format-data/standard_adult_passage_estimate.csv",
#                bucket = gcs_get_global_bucket(),
#                saveToDisk = "data-raw/data-prep/standard-format-data/standard_adult_passage_estimate.csv",
#                overwrite = TRUE)
# standard_passage_estimates <- read_csv("data-raw/data-prep/standard-format-data/standard_adult_passage_estimate.csv")

# upstream_passage_estimates_battle_clear <- standard_passage_estimates |>
#   filter(!is.na(passage_estimate), stream %in% c("battle creek", "clear creek")) |> 
#   select(year, stream, passage_estimate) |> 
#   # TODO these should be added to the database though we are likely moving away from db for adult data because too hard to maintain
#   add_row(year = 2022,
#           stream = "clear creek",
#           passage_estimate = 195) |> 
#   add_row(year = 2023,
#           stream = "clear creek",
#           passage_estimate = 0) |> 
#   # source of below data is e-mail chain from ashley / sam provins / gabby week of 1/14/2025
#   add_row(year = 2022,
#           stream = "battle creek",
#           passage_estimate = 152) |> 
#   add_row(year = 2023,
#           stream = "battle creek",
#           passage_estimate = 7) |> # one of these was a feather river spring run
#   add_row(year = 2024,
#           stream = "battle creek",
#           passage_estimate = 30) |> 
#   add_row(year = 2024,
#           stream = "clear creek",
#           passage_estimate = 6) |> 
#   rename(count = passage_estimate) |> 
#   mutate(data_type = "upstream_estimate")
# write_csv(upstream_passage_estimates_battle_clear, "data-raw/helper-tables/battle_clear_passage_estimates_historical.csv")

battle_clear_passage <- read_csv("data-raw/helper-tables/battle_clear_passage_estimates_historical.csv")
# Butte
# Carcass estimates
# Only agreed to publishing carcass estimates which are available on GrandTab
# The timing of availability on GrandTab is unknown so reach out to Grant/Anna
# and to request data on similar timeline as EDI workflow
# Currently Butte Creek is the only location where we will use the historically generated tables
# These were generated in JPE-datasets (https://github.com/SRJPE/JPE-datasets/tree/main/data/model-db)

# The following script was run once
# These seed tables were stored on GCP (https://console.cloud.google.com/storage/browser/jpe-dev-bucket/model-db?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&authuser=1&project=jpe-development&supportedpurview=project)
# The carcass_estimates table was downloaded and saved to the repository.
# gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
# gcs_global_bucket(bucket = Sys.getenv("GCS_DEFAULT_BUCKET"))
# 
# gcs_get_object(object_name = "model-db/carcass_estimates.csv",
#                bucket = gcs_get_global_bucket(),
#                saveToDisk = "data-raw/helper-tables/carcass_estimates.csv",
#                overwrite = TRUE)
# gcs_get_object(object_name = "model-db/survey_location.csv",
#                bucket = gcs_get_global_bucket(),
#                saveToDisk = "data-raw/helper-tables/survey_location.csv",
#                overwrite = TRUE)

# carcass_estimates <- read_csv("data-raw/helper-tables/carcass_estimates.csv")
# survey_location <- read_csv("data-raw/helper-tables/survey_location.csv")
# 
# butte_historical <- carcass_estimates |> 
#   left_join(survey_location, by = c("survey_location_id" = "id")) |> 
#   select(stream, year, carcass_estimate, lower_bound_estimate, upper_bound_estimate, confidence_level) |> 
#   filter(stream == "butte creek") 
# 
# write_csv(butte_historical, "data-raw/helper-tables/butte_carcass_historical.csv")

# New years for Butte
# The process for updating years for Butte will be to read in a csv or manually add the data (simple format)
# These data can then be appended to the historical data
butte_historical <- read_csv("data-raw/helper-tables/butte_carcass_historical.csv")
butte_carcass <- butte_historical |> 
  add_row(stream = "butte creek",
          year = 2023,
          carcass_estimate = 44,
          lower_bound_estimate = 33,
          upper_bound_estimate = 61,
          confidence_level = 90) |> 
  add_row(stream = "butte creek",
          year = 2024,
          carcass_estimate = 28,
          lower_bound_estimate = 20,
          upper_bound_estimate = 40,
          confidence_level = 90) |> 
  rename(count = carcass_estimate) |> 
  mutate(data_type = "carcass_estimate")

# Holding data for Butte
# gcs_get_object(object_name = "standard-format-data/standard_holding.csv",
#                bucket = gcs_get_global_bucket(),
#                saveToDisk = "data-raw/data-prep/standard-format-data/standard_holding.csv",
#                overwrite = TRUE)
# standard_holding <- read_csv("data-raw/data-prep/standard-format-data/standard_holding.csv")
# 
# butte_holding <- standard_holding |> 
#   filter(stream == "butte creek") |> 
#   select(year, count, stream) |> 
#   mutate(data_type = "holding")
# write_csv(butte_holding, "data-raw/helper-tables/butte_holding_historical.csv")

butte_holding <- read_csv("data-raw/helper-tables/butte_holding_historical.csv")
# Deer/Mill
# Upstream passage data, redd (mill), holding (deer)
# These data are on EDI and should be updated following the EDI workflow
# https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1672.1
# When doing a data check with Ryan May 2025 we found a few discrepancies
# in the video passage data and all the redd data were off. Until
# this is fixed on EDI we will pull data from the spreadsheet Ryan provided

data_from_ryan <- read_csv("data-raw/helper-tables/mill_deer_adult_historical.csv")

# identifier = "1672"
# revision = list_data_package_revisions(scope, identifier, filter = "newest")
# package_id <- paste(scope, identifier, revision, sep = ".")

# List data entities of the data package
# res <- read_data_entity_names(package_id)
# 
# # Download the daily corrected passage
# name <- "deer_mill_upstream_passage_estimates.csv"
# entity_id <- res$entityId[res$entityName == name]
# raw <- read_data_entity(package_id, entity_id)
# upstream_passage_estimates_data <- read_csv(file = raw)
# # Note that there are some discrepancies between EDI and what Ryan is using
# # TODO we need to fix data on EDI
# # Until data are fixed on EDI make updates here
# deer_mill_upstream_passage_estimates <- upstream_passage_estimates_data |> 
#   group_by(year, stream, run) |> 
#   summarize(count = sum(passage_estimate, na.rm = T),
#             upper_bound_estimate = sum(ucl, na.rm = T),
#             lower_bound_estimate = sum(lcl, na.rm = T),
#             confidence_level = 90)
#   mutate(data_type = "upstream_estimate") |>
#   select(year, stream, count, data_type, upper_bound_estimate, lower_bound_estimate, confidence_level) |>
#   glimpse()
# 
# # redd data (Mill) ---
# name <- "deer_mill_redd.csv"
# entity_id <- res$entityId[res$entityName == name]
# raw <- read_data_entity(package_id, entity_id)
# redd_data <- read_csv(file = raw)
# 
# deer_mill_redd <- redd_data |> 
#   mutate(reach_number = NA,
#          latitude = NA,
#          longitude = NA,
#          velocity = NA,
#          redd_id = NA,
#          age = NA,
#          run = NA, # TODO are they all spring run?
#          date = as.Date(date)) |> 
#   select(date, stream, reach, latitude, longitude, run, velocity, redd_id, age, redd_count) |> 
#   group_by(year(date), stream) |> 
#   summarize(count = sum(redd_count, na.rm = T))
# 
# # holding (deer)
# name <- "deer_mill_holding.csv"
# entity_id <- res$entityId[res$entityName == name]
# raw <- read_data_entity(package_id, entity_id)
# holding_data <- read_csv(file = raw)
# 
# deer_mill_holding <- holding_data |> 
#   mutate(latitude = NA,
#          longitude = NA) |> 
#   select(date, stream, reach, count, adipose_clipped, run, latitude, longitude) |> 
#   glimpse()

# Feather
# Data provided by Casey Campos
# To get spring run in river spawning number we would take "broodstock tagged" minus "broodstock returning to the hatchery" minus"over summer mortality"
# The more I thought about it I realized that those redd survey data are not going to be the best to use because the effort has been inconsistent. We now have the drone-based redd surveys that will have a similar effort every year and could be used in conjunction with the weir counts, but turning the images into redd counts is a bottleneck.
# For incorporating the historic data, my initial thought is to use the number of fish we tag for broodstock at the Hatchery in the spring minus the number that return in the fall as an indicator of the in-river spring-run population size. We know we that it will always be an underestimate because not all the spring-run go to the Hatchery in the spring.
# Prior to year 1 of the weir, we were unsure how much of the run were making it to the Hatchery and being tagged. What we saw year 1, was a large percentage of the fish passing the weir did go into the hatchery (see table below).
# Th table shows the number of spring-run tagged for broodstock, number returning to the Hatchery in the fall, the number of over summer mortalities during the same period, and includes the corrected count at the weir for 2024.

feather_adult_raw <- read_csv(here::here("data-raw","helper-tables","feather_adult_052925.csv"))

feather_spring_spawner <- feather_adult_raw |> 
  rename(broodstock_tagged = `broodstock tagged `,
         broodstock_returns = `broodstock returning to the Hatchery`,
         over_summer_mortality = `Over summer Mortality`,
         fms_corrected_count = `FMS corrected count`) |> 
  mutate(count = broodstock_tagged - broodstock_returns - over_summer_mortality,
         stream = "feather river",
         data_type = "broodstock_tag") |> 
  select(year, stream, count, data_type)

# Yuba
# Upstream passage data
# These data are on EDI and should be updated following the EDI workflow
# https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1707.1 

identifier = "1707"
revision = list_data_package_revisions(scope, identifier, filter = "newest")
package_id <- paste(scope, identifier, revision, sep = ".")

# List data entities of the data package
res <- read_data_entity_names(package_id)

# Download the daily corrected passage
name <- "yuba_daily_corrected_passage.csv"
entity_id <- res$entityId[res$entityName == name]
raw <- read_data_entity(package_id, entity_id)
data <- read_csv(file = raw)

# process into format as previously defined by database
yuba_passage_estimates <- data |> 
  mutate(run = ifelse(run %in% c("early spring", "late spring"), "spring", run)) |> 
  group_by(year = year(date), run, adipose_clipped) |> 
  dplyr::summarize(passage_estimate = sum(count, na.rm = T)) |> 
  mutate(stream = "yuba river")

yuba_spring_passage_estimates <- yuba_passage_estimates |> 
  filter(run == "spring",
         adipose_clipped == F,
         !year %in% c(2016, 2017, 2019)) |> 
  rename(count = passage_estimate) |> 
  ungroup() |> 
  mutate(data_type = "upstream_estimate") |> 
  select(year, stream, count, data_type)

# Combine and save
annual_adult_raw <- bind_rows(battle_redd,
                          clear_redd,
                          battle_clear_passage,
                          butte_carcass,
                          butte_holding,
                          data_from_ryan,
                          feather_spring_spawner,
                          yuba_spring_passage_estimates)

# Apply years to exclude

adult_years_exclude <- read_csv("data-raw/helper-tables/years_to_exclude_adult_datasets.csv") |> 
  select(-reason_for_exclusion) |> 
  mutate(exclude = T,
         data_type = case_when(data_type == "carcass" ~ "carcass_estimate",
                               data_type == "upstream passage" ~ "upstream_estimate",
                               T ~ data_type))
annual_adult <- annual_adult_raw |> 
  left_join(adult_years_exclude) |> 
  filter(is.na(exclude)) |> 
  select(-exclude)

usethis::use_data(annual_adult, overwrite = TRUE)
