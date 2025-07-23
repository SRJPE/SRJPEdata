# This script exists to pull certain data from EDI that cannot be loaded into
# jpe-db because they do not contain unique identifiers. We update fields in the
# database and are unable to do that without a unique identifier.

# Battle and Clear recapture, KNL pre 2004, Butte pre 2015

library(tidyverse)
library(EDIutils)
library(googleCloudStorageR)

pull_edi <- function(id, index, version) {
  scope <- "edi"
  identifier <- id
  # latest_version <- list_data_package_revisions(scope, identifier) |>
  #   tail(1)
  latest_version <- version
  package_id <- paste(scope, identifier, latest_version, sep = ".")
  res <- read_data_entity_names(packageId = package_id)
  raw <- read_data_entity(packageId = package_id, entityId = res$entityId[index])
  edi <- read_csv(file = raw)
}

gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
gcs_global_bucket(bucket = Sys.getenv("GCS_DEFAULT_BUCKET"))

gcs_get_object(object_name = "standard-format-data/standard_recapture.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-raw/helper-tables/standard_recapture.csv",
               overwrite = TRUE)
standard_recapture <- read_csv("data-raw/helper-tables/standard_recapture.csv")
# standard release data table
gcs_get_object(object_name = "standard-format-data/standard_release.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-raw/helper-tables/standard_release.csv",
               overwrite = TRUE)
standard_release <- read_csv("data-raw/helper-tables/standard_release.csv")

# RST Monitoring Data
# standard rst catch data table
gcs_get_object(object_name = "standard-format-data/standard_rst_catch_051525.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-raw/helper-tables/standard_catch.csv",
               overwrite = TRUE)
standard_catch <- read_csv("data-raw/helper-tables/standard_catch.csv")

# standard rst trap data table
gcs_get_object(object_name = "standard-format-data/standard_rst_trap.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-raw/helper-tables/standard_trap.csv",
               overwrite = TRUE)
standard_trap <- read_csv("data-raw/helper-tables/standard_trap.csv")

# Butte -------------------------------------------------------------------

# Using version 14 because this is the most up to date version before transitioning
# to zip file which is more difficult to load in. We are pulling pre 2015 data
# so it is OK to use an outdated version.

# Note there are no release/recapture data prior to 2015 so do not need to pull
catch_edi <- pull_edi("1497", 1, 14)
trap_edi <- pull_edi("1497", 4, 14)

butte_catch_edi <- catch_edi |> 
  mutate(commonName = tolower(commonName)) |> 
  filter(commonName == "chinook salmon",
         year(visitTime) < 2015) |> # we are only pulling pre 2015 data
  mutate(stream = "butte creek",
         site_group = "butte creek",
         adipose_clipped = case_when(fishOrigin == "Natural" ~ F,
                                     fishOrigin == "Hatchery" ~ T,
                                     T ~ NA),
         dead = NA,
         weight = NA,
         species = "chinook",
         site = case_when(siteName %in% c("parrot-phelan", "Parrott-Phelan canal trap box","Okie RST","Parrot-Phelan RST") ~ "okie dam",
                          T ~ siteName),
         subsite = case_when(subSiteName %in% c("pp rst","Okie RST","PP RST") ~ "okie dam 1",
                             subSiteName == "canal trap box" ~ "okie dam fyke trap",
                             subSiteName == "pp rst 2" ~ "okie dam 2",
                             subSiteName == "adams dam" ~ "adams dam",
                             T ~ NA)) |> 
  rename(date = visitTime,
         count = n,
         run = finalRun,
         life_stage = lifeStage,
         fork_length = forkLength,
         actual_count = actualCount) |> 
  select(date, stream, site, subsite, site_group, count, run, life_stage, adipose_clipped,
         dead, fork_length, weight, actual_count, species) 

butte_trap_edi <- trap_edi |> 
  filter(year(visitTime) < 2015) |> # we are only pulling pre 2015 data
  arrange(subSiteName, visitTime) |>
  mutate(trap_start_date = ymd_hms(lag(visitTime)),
         trap_stop_date = ymd_hms(visitTime),
         stream = "butte creek",
         site_group = "butte creek",
         site = case_when(siteName %in% c("parrot-phelan", "Parrott-Phelan canal trap box","Okie RST","Parrot-Phelan RST") ~ "okie dam",
                          T ~ siteName),
         subsite = case_when(subSiteName %in% c("pp rst","Okie RST","PP RST") ~ "okie dam 1",
                             subSiteName == "canal trap box" ~ "okie dam fyke trap",
                             subSiteName == "pp rst 2" ~ "okie dam 2",
                             subSiteName == "adams dam" ~ "adams dam",
                             T ~ NA)) |> 
  rename(visit_type = visitType,
         trap_functioning = trapFunctioning,
         fish_processed = fishProcessed,
         total_revolutions = counterAtEnd,
         rpm_start = rpmRevolutionsAtStart,
         rpm_end = rpmRevolutionsAtEnd,
         include = includeCatch,
         water_velocity = waterVel,
         water_temp = waterTemp) |> 
  select(trap_start_date, visit_type, trap_stop_date, stream, site, subsite,
         site_group, trap_functioning, fish_processed, rpm_start, rpm_end,
         total_revolutions, discharge, water_velocity, water_temp, turbidity,
         include)

# Battle & Clear ----------------------------------------------------------

# TODO insert code to grab most recent version
recapture_edi <- pull_edi("1509", 3, 2)

battle_clear_recapture_edi <- recapture_edi |> 
  mutate(stream = case_when(grepl("clear creek", site) ~ "clear creek",
                            grepl("battle creek", site) ~ "battle creek"),
         site_group = stream,
         dead = NA,
         species = "chinook",
         site = case_when(site == "lower battle creek" ~ "lbc",
                          site == "upper battle creek" ~ "ubc",
                          site == "lower clear creek" ~ "lcc",
                          site == "upper clear creek" ~ "ucc"),
         subsite = site,
         life_stage = NA,
         weight = NA) |> 
  rename(date = date_recaptured,
         run = fws_run,
         adipose_clipped = hatchery_origin,
         count = number_recaptured,
         fork_length = median_fork_length_recaptured) |> 
  select(date, release_id, stream, site, subsite, site_group, count, run, life_stage, adipose_clipped,
         dead, fork_length, weight, species)

# Knights Landing ---------------------------------------------------------

# As of July 2025, pre 2004 data are not on EDI. The goal would be to add those data
# Until then we will pull the historic data from the standard datasets we created
# in JPE-datasets and saved on GCB in following paths:
# "standard-format-data/standard_recapture.csv"
# "standard-format-data/standard_release.csv"
# "standard-format-data/standard_rst_catch_051525.csv"
# "standard-format-data/standard_rst_trap.csv"

# The data were filtered to Knights Landing and saved to make workflow easier
# as these will not change

# knl_catch_standard <- standard_catch |> 
#   filter(site == "knights landing", year(date) < 2004) |> 
#   mutate(site_group = "knights landing") |> 
#   rename(life_stage = lifestage) |> 
#   select(date, stream, site, subsite, site_group, count, run, life_stage, adipose_clipped, dead, fork_length, weight, species)
# 
# knl_trap_standard <- standard_trap |> 
#   filter(site == "knights landing", year(trap_stop_date) < 2004) |> 
#   mutate(site_group = "knights landing") |> 
#   rename(total_revolutions = sample_period_revolutions,
#          rpm_start = rpms_start,
#          rpm_end = rpms_end) |> 
#   select(trap_start_date, trap_stop_date, stream, site, subsite, site_group, total_revolutions, visit_type, trap_functioning, fish_processed, rpm_start, rpm_end, include)
# 
# knl_recapture_standard <- standard_recapture |> 
#   filter(site == "knights landing", year(date_recaptured) < 2004) |> 
#   mutate(site_group = site) |> 
#   rename(date = date_recaptured,
#          count = number_recaptured,
#          fork_length = median_fork_length_recaptured) |> 
#   select(date, release_id, stream, site, subsite, site_group, count, fork_length)
# 
# knl_release_standard <- standard_release |> 
#   filter(site == "knights landing", year(date_released) < 2004) |> 
#   rename(origin = origin_released,
#          run = run_released,
#          life_stage = lifestage_released) |> 
#   mutate(site_group = "knights landing") |> 
#   select(date_released, release_id, stream, site, site_group, number_released, origin, run, life_stage)

# write_csv(knl_catch_standard, "data-raw/helper-tables/google_bucket/knl_catch_standard.csv")
# write_csv(knl_trap_standard, "data-raw/helper-tables/google_bucket/knl_trap_standard.csv")
# write_csv(knl_recapture_standard, "data-raw/helper-tables/google_bucket/knl_recapture_standard.csv")
# write_csv(knl_release_standard, "data-raw/helper-tables/google_bucket/knl_release_standard.csv")

knl_catch_standard <- read_csv("data-raw/helper-tables/google_bucket/knl_catch_standard.csv")
knl_trap_standard <- read_csv("data-raw/helper-tables/google_bucket/knl_trap_standard.csv")
knl_recapture_standard <- read_csv("data-raw/helper-tables/google_bucket/knl_recapture_standard.csv")
knl_release_standard <- read_csv("data-raw/helper-tables/google_bucket/knl_release_standard.csv")

# Combine -----------------------------------------------------------------

edi_catch <- bind_rows(butte_catch_edi,
                       knl_catch_standard)
edi_recapture <- bind_rows(battle_clear_recapture_edi,
                           knl_recapture_standard)
edi_release <- bind_rows(knl_release_standard)
edi_trap <- bind_rows(butte_trap_edi |> 
                        mutate(include = ifelse(include == "Yes", T, F)),
                      knl_trap_standard) |> 
  filter(!is.na(trap_start_date))
