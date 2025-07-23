# Pull any missing data from standard format
# This is for the interim until all data are loaded on database
library(lubridate)
library(tidyverse)
library(googleCloudStorageR)

source("data-raw/pull_data_scripts/pull_tables_from_data_tackle_database.R")
source("data-raw/pull_data_scripts/TEMP_pull_from_edi.R") # remove after data get added to db

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

# Knights Landing RST pre 2006 & Butte Creek pre 2015 --------------------------

catch_standard <- standard_catch |> 
  filter(site == "knights landing", date < as_date("2006-10-02")) |> 
  mutate(site_group = "knights landing") |> 
  bind_rows(standard_catch |> 
              filter(stream == "butte creek", date < as_date("2015-11-03")) |> 
              mutate(site_group = "butte creek")) |> 
  rename(life_stage = lifestage) |> 
  select(date, stream, site, subsite, site_group, count, run, life_stage, adipose_clipped, dead, fork_length, weight, species)

trap_standard <- standard_trap |> 
  filter(site == "knights landing", trap_stop_date < as_date("2006-10-02")) |> 
  mutate(site_group = "knights landing") |> 
  bind_rows(standard_trap |> 
              filter(stream == "butte creek", trap_stop_date < as_date("2015-11-03")) |> 
              mutate(site_group = "butte creek")) |> 
  rename(total_revolutions = sample_period_revolutions,
         rpm_start = rpms_start,
         rpm_end = rpms_end) |> 
  select(trap_start_date, trap_stop_date, stream, site, subsite, site_group, total_revolutions, visit_type, trap_functioning, fish_processed, rpm_start, rpm_end, include)

# Butte did not have release trials prior to 2021
recapture_standard <- standard_recapture |> 
  filter(site == "knights landing", date_recaptured < as_date("2006-10-02")) |> 
  mutate(site_group = site) |> 
  rename(date = date_recaptured,
         count = number_recaptured,
         fork_length = median_fork_length_recaptured) |> 
  select(date, release_id, stream, site, subsite, site_group, count, fork_length)

release_standard <- standard_release |> 
  filter(site == "knights landing", date_released < as_date("2006-10-02")) |> 
  rename(origin = origin_released,
         run = run_released,
         life_stage = lifestage_released) |> 
  mutate(site_group = "knights landing") |> 
  select(date_released, release_id, stream, site, site_group, number_released, origin, run, life_stage)

# Combine RST data -----------------------------------------------------------------

# Join the Knights Landing standard catch with EDI data
# Join data from Data Tackle
rst_catch_prep <- bind_rows(temp_catch, catch_standard, rst_catch_query_pilot) |> 
  mutate(fork_length = ifelse(fork_length == 0, NA, fork_length), # looks like there were some cases where fork length is 0. this should be handled more upstream but fixing it here for now
         julian_week = week(date),
         julian_year = year(date), # adding week for noble
         life_stage = ifelse(is.na(life_stage), "not recorded", tolower(life_stage)),
         subsite = case_when(site == "okie dam" & is.na(subsite) ~ "okie dam 1", # fix missing subsites
                             stream == "battle creek" & is.na(subsite) & year(date) > 2004 ~ "ubc",
                             site == "yuba river" ~ "hal",
                             T ~ subsite),
         site = case_when(stream == "battle creek" & is.na(site) & year(date) > 2004 ~ "ubc",
                          stream == "yuba river" ~ "hallwood",
                          T ~ site))
# find dates where only the fyke trap is fishing
okie_rst <- rst_catch_prep |> 
  filter(site == "okie dam", subsite != "okie dam fyke trap") |> 
  mutate(date = as_date(date)) |> # remove time so that won't affect it
  pull(date)

# okie_fyke_only <- rst_catch_prep |>
#   mutate(date = as_date(date)) |> 
#   filter(site == "okie dam", !date %in% okie_rst)
# write_csv(okie_fyke_only, "data-raw/data-checks/stream_team_review/butte/fyke_only_dates.csv")
  
rst_catch <- rst_catch_prep |> 
  mutate(butte_fyke_filter = case_when(site == "okie dam" & as_date(date) %in% okie_rst ~ "rst & fyke",
                                       site == "okie dam" & !as_date(date) %in% okie_rst ~ "fyke only",
                                       T ~ "not butte")) |> 
  filter(!(stream == "mill creek" & month(date) > 6 & year(date) == 2023)) |> # Remove June entry for Mill Creek
  filter(species %in% c("chinook","chinook salmon"), # filter for only chinook
         life_stage != "adult",# remove the adult fish (mostly on Butte)
         !is.na(stream),# 7 NAs I think come from knights landings
         butte_fyke_filter != "fyke only") |> 
  select(-c(butte_fyke_filter))

rst_trap <- bind_rows(temp_trap, trap_standard, rst_trap_query_pilot)  |> 
  mutate(subsite = case_when(site == "okie dam" & is.na(subsite) ~ "okie dam 1", # fix missing subsites
                             stream == "battle creek" & is.na(subsite) & year(trap_stop_date) > 2004 ~ "ubc",
                             site == "yuba river" ~ "hal",
                             T ~ subsite),
         site = case_when(stream == "battle creek" & is.na(site) & year(trap_stop_date) > 2004 ~ "ubc",
                          stream == "yuba river" ~ "hallwood",
                          T ~ site)) |> 
  filter(!is.na(stream)) |> 
  glimpse()
release <- bind_rows(release_standard, release_query_pilot |> 
                       mutate(release_id = as.character(release_id)), temp_release)  |> 
  mutate(site = ifelse(is.na(site) & stream == "butte creek", "okie dam", site)) |> 
  filter(!is.na(number_released), year(date_released) != 1900) |> # there should not be any NAs
  left_join(standard_release |> 
              filter(!is.na(median_fork_length_released)) |> 
              select(site, release_id, median_fork_length_released) |> 
              distinct()) # fork length is not on EDI but Josh needs it in weekly_efficiency
recaptures <- bind_rows(recapture_standard, recaptures_query_pilot |> mutate(release_id = as.character(release_id)), temp_recapture) |> glimpse()

## SAVE TO DATA PACKAGE ---
usethis::use_data(rst_catch, overwrite = TRUE)
usethis::use_data(rst_trap, overwrite = TRUE)
usethis::use_data(release, overwrite = TRUE)
usethis::use_data(recaptures, overwrite = TRUE)