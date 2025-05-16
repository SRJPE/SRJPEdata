# This script prepares historical data for loading in the JPE DB
# Originally this was done in JPE-datasets but has been migrated here
# to keep majority of data processing together

library(lubridate)
library(tidyverse)
library(googleCloudStorageR)

f <- function(input, output) write_csv(input, file = output)

gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
gcs_global_bucket(bucket = Sys.getenv("GCS_DEFAULT_BUCKET"))

# Pull data from GCP ------------------------------------------------------
# All standard format datasets were created by combining data across streams
# That work remains in JPE-datasets: https://github.com/SRJPE/JPE-datasets/tree/main/data-raw/standard-format-data-prep

# Mark-Recapture Data for RST
# standard recapture data table
gcs_get_object(object_name = "standard-format-data/standard_recapture.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-prep/standard-format-data/standard_recapture.csv",
               overwrite = TRUE)
standard_recapture <- read_csv("data-prep/standard-format-data/standard_recapture.csv")
# standard release data table
gcs_get_object(object_name = "standard-format-data/standard_release.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-prep/standard-format-data/standard_release.csv",
               overwrite = TRUE)
standard_release <- read_csv("data-prep/standard-format-data/standard_release.csv")

# RST Monitoring Data
# standard rst catch data table
gcs_get_object(object_name = "standard-format-data/standard_rst_catch_051525.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-prep/standard-format-data/standard_catch.csv",
               overwrite = TRUE)
standard_catch <- read_csv("data-prep/standard-format-data/standard_catch.csv")

# standard rst trap data table
gcs_get_object(object_name = "standard-format-data/standard_rst_trap.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-prep/standard-format-data/standard_trap.csv",
               overwrite = TRUE)
standard_trap <- read_csv("data-prep/standard-format-data/standard_trap.csv")

# standard effort table
gcs_get_object(object_name = "standard-format-data/standard_rst_effort.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-prep/standard-format-data/standard_effort.csv",
               overwrite = TRUE)
standard_effort <- read_csv("data-prep/standard-format-data/standard_effort.csv")

# standard environmental covariate data collected during RST monitoring
gcs_get_object(object_name = "standard-format-data/standard_RST_environmental.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-prep/standard-format-data/standard_environmental.csv",
               overwrite = TRUE)
standard_environmental <- read_csv("data-prep/standard-format-data/standard_environmental.csv")

# rst site data
gcs_get_object(object_name = "standard-format-data/rst_trap_locations.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-prep/standard-format-data/rst_trap_locations.csv",
               overwrite = TRUE)
standard_sites <- read_csv("data-prep/standard-format-data/rst_trap_locations.csv")

# Standard Environmental Covariate Data
# standard flow
gcs_get_object(object_name = "standard-format-data/standard_flow.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-prep/standard-format-data/standard_flow.csv",
               overwrite = TRUE)
standard_flow <- read_csv("data-prep/standard-format-data/standard_flow.csv")
# standard temp
gcs_get_object(object_name = "standard-format-data/standard_temperature.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-prep/standard-format-data/standard_temperature.csv",
               overwrite = TRUE)
standard_temperature <- read_csv("data-prep/standard-format-data/standard_temperature.csv")

# Adult Upstream Data
gcs_get_object(object_name = "standard-format-data/standard_adult_upstream_passage.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-prep/standard-format-data/standard_adult_upstream.csv",
               overwrite = TRUE)
standard_upstream <- read_csv("data-prep/standard-format-data/standard_adult_upstream.csv")

gcs_get_object(object_name = "standard-format-data/standard_adult_passage_estimate.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/standard-format-data/standard_adult_passage_estimate.csv",
               overwrite = TRUE)
standard_passage_estimates <- read_csv("data/standard-format-data/standard_adult_passage_estimate.csv")

# Adult Holding Data
gcs_get_object(object_name = "standard-format-data/standard_holding.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-prep/standard-format-data/standard_holding.csv",
               overwrite = TRUE)
standard_holding <- read_csv("data-prep/standard-format-data/standard_holding.csv")

# Adult Redd Data
gcs_get_object(object_name = "standard-format-data/standard_annual_redd.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-prep/standard-format-data/standard_annual_redd.csv",
               overwrite = TRUE)
standard_annual_redd <- read_csv("data-prep/standard-format-data/standard_annual_redd.csv")

gcs_get_object(object_name = "standard-format-data/standard_daily_redd.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-prep/standard-format-data/standard_daily_redd.csv",
               overwrite = TRUE)
standard_daily_redd <- read_csv("data-prep/standard-format-data/standard_daily_redd.csv")

gcs_get_object(object_name = "standard-format-data/standard_carcass_cjs_estimate.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/standard-format-data/standard_carcass_cjs_estimate.csv",
               overwrite = TRUE)
standard_carcass_estimates <- read_csv("data/standard-format-data/standard_carcass_cjs_estimate.csv")
# Site handling -----------------------------------------------------------

# Based on multiple conversations about site handling, we will be adding a field
# called site_group that only applies to feather river. This will handle the 
# hfc/lfc grouping while retaining site/subsite variables.

lfc_subsites <- c("eye riffle_north", "eye riffle_side channel", "gateway main 400' up river", "gateway_main1", "gateway_rootball", "gateway_rootball_river_left", "#steep riffle_rst", "steep riffle_10' ext", "steep side channel")
hfc_subsites <- c("herringer_east", "herringer_upper_west", "herringer_west", "live oak", "shawns_east", "shawns_west", "sunset east bank", "sunset west bank")

lfc_sites <- c("eye riffle", "gateway riffle", "steep riffle")
hfc_sites <- c("herringer riffle", "live oak", "shawn's beach", "sunset pumps")

# Catch -------------------------------------------------------------------

# Add in missing dates where there was a trap visit
# Filter species to chinook
# Remove adult lifestage
# Remove any fish part of release trial
# Fix few NA subsites
# Remove June entry for Mill Creek

# when we filter the catch dataset to chinook we may lose some dates where the trap was running
# but no chinook were caught. the following code creates a list of all dates trap is assumed to be
# running so that if that date does not exist in the catch data we can assign chinook count = 0
dates_trap_running <- standard_trap |> 
  select(trap_start_date, trap_stop_date, stream, site, subsite, trap_functioning) |> 
  filter(trap_functioning != "trap not in service") |> 
  select(-c(trap_functioning)) |> 
  distinct(trap_start_date, trap_stop_date, stream, site, subsite) |> 
  glimpse()

date_ranges_trap_running <- dates_trap_running |> 
  mutate(diff = as.numeric(trap_stop_date - trap_start_date)) |> 
  filter(diff > 1) |>  
  rowwise() |> 
  mutate(date_list = list(seq.Date(from = as_date(trap_start_date), to = as_date(trap_stop_date), by = "day"))) |> 
  glimpse()

full_date_list <- date_ranges_trap_running |> 
  group_by(row_number()) |> 
  group_map(function(data, i) {
    data |> 
      tibble(dates = unlist(date_list)) |> 
      mutate(dates = as_date(dates))
  }) |> 
  list_rbind() |> 
  select(stream, site, subsite, dates) |> 
  bind_rows(dates_trap_running |> 
              select(stream, site, subsite, trap_start_date) |> 
              rename(dates = trap_start_date),
            dates_trap_running |> 
              select(stream, site, subsite, trap_stop_date) |> 
              rename(dates = trap_stop_date)) |> 
  distinct() |> 
  filter(!is.na(dates))

standard_catch_unmarked_raw <- standard_catch |> 
  mutate(lifestage = ifelse(is.na(lifestage), "not recorded", lifestage),
         subsite = case_when(site == "okie dam" & is.na(subsite) ~ "okie dam 1", # fix missing subsites
                             stream == "battle creek" & is.na(subsite) & year(date) > 2004 ~ "ubc",
                             site == "yuba river" ~ "hal",
                             T ~ subsite),
         site = case_when(stream == "battle creek" & is.na(site) & year(date) > 2004 ~ "ubc",
                          stream == "yuba river" ~ "hallwood",
                          T ~ site)) |> 
  filter(!(stream == "mill creek" & month(date) > 6 & year(date) == 2023)) |> # Remove June entry for Mill Creek
  filter(species == "chinook salmon", # filter for only chinook
         is.na(release_id), # filter for only unmarked fish, exclude recaptured fish that were part of efficiency trial
         lifestage != "adult") # remove the adult fish (mostly on Butte)

standard_catch_unmarked <- standard_catch_unmarked_raw |> 
  full_join(full_date_list |> rename(date = dates)) |> 
  # replace NA count with 0 for the dates where no chinook were caught
  mutate(count = ifelse(is.na(count), 0, count))

# Trap --------------------------------------------------------------------

# Create site group
# Fix NA subsite issue
# Join RST environmental data
# Remove commas in fish_processed variable
# Remove Mill Creek Jun 2023 entry
# Fix format of trap visit time start and end
# Fix INF rpm_end

standard_trap_w_site_group <- standard_trap |> 
  rename(in_half_cone_configuration = is_half_cone_configuration,
         rpm_start = rpms_start,
         rpm_end = rpms_end,
         total_revolutions = sample_period_revolutions)  |> 
  mutate(site_group = case_when(site %in% lfc_sites ~ "feather river lfc",
                                site %in% hfc_sites ~ "feather river hfc",
                                T ~ NA),
         subsite = case_when(site == "okie dam" & is.na(subsite) ~ "okie dam 1",
                             stream == "battle creek" & is.na(subsite) ~ "ubc",
                             site == "yuba river" & is.na(subsite) ~ "yub",
                             site == "yuba river" ~ "hal",
                             T ~ subsite),
          site = case_when(stream == "battle creek" & is.na(site) ~ "ubc",
                           stream == "yuba river" ~ "hallwood",
                           T ~ site),
          fish_processed = case_when(fish_processed == "no catch data, fish released" ~ "no catch data and fish released",
                                    fish_processed == "no catch data, fish left in live box" ~ "no catch data and fish left in live box",
                                    T ~ fish_processed),
          trap_visit_time_start = case_when(!is.na(trap_start_time) ~ ymd_hms(paste(trap_start_date, trap_start_time)),
                                           T ~ ymd_hms(paste0(trap_start_date, "00:00:00"))),
          trap_visit_time_end = case_when(!is.na(trap_stop_time) ~ ymd_hms(paste(trap_stop_date, trap_stop_time)),
                                         T ~ ymd_hms(paste0(trap_stop_date, "00:00:00"))),
          rpm_end = ifelse(is.infinite(rpm_end), NA, rpm_end)) |> 
  filter(!(stream == "mill creek" & month(trap_stop_date) > 6 & year(trap_stop_date) == 2023))

discharge <- filter(standard_environmental, parameter == "discharge") |> 
  select(-c(parameter, text)) |> 
  rename(discharge = value) |> 
  group_by(date, stream, site, subsite) |> 
  summarize(discharge = mean(discharge, na.rm = T))
water_velocity <- filter(standard_environmental, parameter == "velocity") |> 
  select(-c(parameter, text)) |> 
  rename(water_velocity = value) |> 
  group_by(date, stream, site, subsite) |> 
  summarize(water_velocity = mean(water_velocity, na.rm = T))
water_temp <- filter(standard_environmental, parameter == "temperature") |> 
  select(-c(parameter, text)) |> 
  rename(water_temp = value) |> 
  group_by(date, stream, site, subsite) |> 
  summarize(water_temp = mean(water_temp, na.rm = T))
turbidity <- filter(standard_environmental, parameter == "turbidity") |> 
  select(-c(parameter, text)) |> 
  rename(turbidity = value) |> 
  group_by(date, stream, site, subsite) |> 
  summarize(turbidity = mean(turbidity, na.rm = T))

trap_raw <- standard_trap_w_site_group |> 
  select(stream, site, subsite, visit_type,  trap_start_date, trap_start_time,
         trap_stop_date, trap_stop_time, trap_functioning, in_half_cone_configuration,
         fish_processed, rpm_start, rpm_end, total_revolutions,
         debris_volume, debris_level, include) |> 
  left_join(discharge, by = c("stream", "site", "subsite", "trap_stop_date" = "date")) |> 
  left_join(water_velocity, by = c("stream", "site", "subsite", "trap_stop_date" = "date")) |> 
  left_join(water_temp, by = c("stream", "site", "subsite", "trap_stop_date" = "date")) |> 
  left_join(turbidity, by = c("stream", "site", "subsite", "trap_stop_date" = "date"))

# Release --------------------------------------------------------------

# Fix format of date when time is NA
# Run released is other then unknown
# Subsite is NA - note that for somewhere like Butte NA may be relevant

release_raw <- standard_release |> 
  select(stream, site, release_id, date_released, time_released, median_fork_length_released,
         origin_released, lifestage_released, run_released, number_released) |>
  # When run this there is a WARNING about 110 failed to parse but there are
  # no NA dates so I think it is OK
  mutate(date_released = case_when(is.na(time_released) ~ ymd(date_released),
                                   T ~ ymd_hms(paste(date_released, time_released))),
         run_released = ifelse(run_released == "other", "unknown", run_released),
         # no subsite for release trials, need this to join with trap location lookup
         subsite = NA) |> 
  select(-time_released)


# Recaptures --------------------------------------------------------------

# the goal of pulling from the standard catch is that there is more infomation
# for recaptured fish than in the recapture table though not all release id
# are in standard catch so need to pull from both
standard_catch_recaptures <- standard_catch %>%
  filter(species == "chinook salmon", # filter for only chinook
         !is.na(release_id)) %>%  # filter for only recaptured fish that were part of efficiency trial
  select(-species)

release_id_recapture <- standard_catch_recaptures |> 
  select(stream, site, subsite, release_id) |> 
  distinct() |> 
  mutate(exists_catch = T)

recaptured_fish_raw <- standard_catch_recaptures |> 
  select(stream, site, subsite, date, count, run, lifestage, adipose_clipped, dead, fork_length, weight,
         release_id) |> 
  bind_rows(standard_recapture |> 
            left_join(release_id_recapture) |> # remove any that are being pulled from standard catch
            filter(is.na(exists_catch)) |> 
            rename(date = date_recaptured,
                   count = number_recaptured,
                   fork_length = median_fork_length_recaptured)) |> 
  select(-exists_catch) |> 
  mutate(subsite = case_when(subsite == "okie RST" ~ "okie dam 1",
                             subsite == "not recorded" ~ NA_character_,
                             T ~ subsite)) 

# Carcass estimates -------------------------------------------------------
carcass_estimates_raw <- standard_carcass_estimates|> 
  rename(carcass_estimate = spawner_abundance_estimate,
         upper_bound_estimate = upper,
         lower_bound_estimate = lower,
         confidence_level = confidence_interval) |> 
  # this is so we can join to survey_location
  mutate(reach = NA,
         confidence_level = case_when(confidence_level == "90%" ~ 90,
                                      confidence_level == "95%" ~ 95,
                                      T ~ as.numeric(confidence_level)),
         run = "spring",
         adipose_clipped = F) 

# Redd --------------------------------------------------------------------

# remove any non chinook species
# If NA redd count then 0

daily_redd_raw <- standard_daily_redd |> 
  # remove any NA entries - there should not be any now that Feather issue fixed
  # remove any non chinook species
  filter(!is.na(date), species %in% c("chinook", "not recorded", "unknown")) |> 
  select(date, latitude, longitude, reach, redd_id, age, velocity, run, stream, redd_count) |> 
  # change format to date instead of datetime
  mutate(date = as.Date(date),
         redd_count = ifelse(is.na(redd_count),0,redd_count)) 

# Passage count ----------------------------------------------------------

# Remove missing dates

passage_raw <- standard_upstream |> 
  # remove missing dates
  filter(!is.na(date)) |> 
  # warning failed to parse here but it is OK because no missing dates
  mutate(date = case_when(!is.na(time) ~ ymd_hms(paste0(date,time)),
                          T ~ ymd_hms(paste0(date, " 00:00:00")))) |> 
  rename(hours_sampled = hours) |> 
  select(-c(time, viewing_condition, spawning_condition, jack_size, ladder, 
            flow, temperature)) |> 
  # survey_location_id
  mutate(stream = tolower(stream),
         reach = NA,
         sex = ifelse(is.na(sex), "not recorded", sex),
         passage_direction = ifelse(is.na(passage_direction), "not recorded", passage_direction),
         count = case_when(count < 0 ~ 0,
                           T ~ round(count))) 

# Passage estimates -------------------------------------------------------

# Remove any NA

passage_estimates_raw <- standard_passage_estimates|> 
  filter(!is.na(passage_estimate)) |> 
  # survey_location_id
  mutate(reach = NA,
         # these fields will be filled in when we get this information
         upper_bound_estimate = ucl,
         lower_bound_estimate = lcl,
         confidence_level = confidence_interval,
# these are fall and late-fall and somehow were included in the table but labelled as spring
         not_spring = case_when(year == 2009 & stream == "mill creek" & passage_estimate != 237 ~ "remove",
                              year == 2010 & stream == "mill creek" & passage_estimate != 205 ~ "remove",
                              year == 2014 & stream == "deer creek" & passage_estimate != 512 ~ "remove",
                              T ~ "do not remove")) |> 
  filter(stream != "butte creek", not_spring != "remove") |> 
  # TODO these should be added to the database though we are likely moving away from db for adult data because too hard to maintain
  add_row(year = 2022,
          stream = "clear creek",
          passage_estimate = 195) |> 
  add_row(year = 2023,
          stream = "clear creek",
          passage_estimate = 0) |> 
  # source of below data is e-mail chain from ashley / sam provins / gabby week of 1/14/2025
  add_row(year = 2022,
          stream = "battle creek",
          passage_estimate = 152) |> 
  add_row(year = 2023,
          stream = "battle creek",
          passage_estimate = 7) |> # one of these was a feather river spring run
  add_row(year = 2024,
          stream = "battle creek",
          passage_estimate = 30) |> 
  add_row(year = 2024,
          stream = "clear creek",
          passage_estimate = 6)

# Holding -----------------------------------------------------------------

# Remove missing dates

daily_holding_raw <- standard_holding |> 
  select(date, reach, count, latitude, longitude, stream) |> 
  # remove all that are missing date
  filter(!is.na(date)) |> 
  mutate(run = "spring",
         adipose_clipped = F) 

