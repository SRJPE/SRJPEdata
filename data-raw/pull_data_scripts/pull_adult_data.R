# Pull adult data from EDI (or other repositories)
# Adult data were originally stored in the SR JPE database
# however, for the short-term (until it is understand what and how we want to use those data
# it is easier to update the data on EDI and pull directly 

library(tidyverse)
library(EDIutils)
# library(googleCloudStorageR)

# Set the scope for script to use API to download data from EDI
scope = "edi"

# Battle/Clear
# Upstream passage and redd data
# These data will be published on EDI but currently are not

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
          confidence_level = 90)

# Deer/Mill
# Upstream passage data, redd (mill), holding (deer)
# These data are on EDI and should be updated following the EDI workflow
# https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1672.1
identifier = "1672"
revision = list_data_package_revisions(scope, identifier, filter = "newest")
package_id <- paste(scope, identifier, revision, sep = ".")

# List data entities of the data package
res <- read_data_entity_names(package_id)

# Download the daily corrected passage
name <- "deer_mill_upstream_passage_estimates.csv"
entity_id <- res$entityId[res$entityName == name]
raw <- read_data_entity(package_id, entity_id)
upstream_passage_estimates_data <- read_csv(file = raw)

upstream_passage_estimates_data_clean <- upstream_passage_estimates_data |> 
  mutate(reach = NA,
         adipose_clipped = NA,
         upper_bound_estimate = ucl,
         lower_bound_estimate = lcl,
         confidence_level = confidence_interval) |>
  select(year, stream, reach, passage_estimate, adipose_clipped, run, upper_bound_estimate, lower_bound_estimate, confidence_level) |>
  glimpse()

# redd data (Mill) ---
name <- "deer_mill_redd.csv"
entity_id <- res$entityId[res$entityName == name]
raw <- read_data_entity(package_id, entity_id)
redd_data <- read_csv(file = raw)

redd_data_clean <- redd_data |> 
  mutate(reach_number = NA,
         latitude = NA,
         longitude = NA,
         velocity = NA,
         redd_id = NA,
         age = NA,
         run = NA) |> # TODO are they all spring run?
  select(date, stream, reach, latitude, longitude, run, velocity, redd_id, age, redd_count) |> 
  glimpse()


# Feather
# These data are not on EDI and currently we do not have a plan to use them
# because we cannot separate out spring run
# On hold until we decide what to do

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
  summarize(passage_estimate = sum(count, na.rm = T)) |> 
  mutate(stream = "yuba river",
         reach = NA,
         upper_bound_estimate = NA,
         lower_bound_estimate = NA,
         confidence_level = NA)

yuba_spring_passage_estimates <- yuba_passage_estimates |> 
  filter(run != "fall") 

# Combine and save
carcass_estimates <- butte_carcass
upstream_passage_estimate <- yuba_spring_passage_estimates # add battle, clear, deer, mill when ready
# redd <-
# holding <-
