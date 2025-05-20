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
               saveToDisk = "data-raw/data-prep/standard-format-data/standard_recapture.csv",
               overwrite = TRUE)
standard_recapture <- read_csv("data-raw/data-prep/standard-format-data/standard_recapture.csv")
# standard release data table
gcs_get_object(object_name = "standard-format-data/standard_release.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-raw/data-prep/standard-format-data/standard_release.csv",
               overwrite = TRUE)
standard_release <- read_csv("data-raw/data-prep/standard-format-data/standard_release.csv")

# RST Monitoring Data
# standard rst catch data table
gcs_get_object(object_name = "standard-format-data/standard_rst_catch_051525.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-raw/data-prep/standard-format-data/standard_catch.csv",
               overwrite = TRUE)
standard_catch <- read_csv("data-raw/data-prep/standard-format-data/standard_catch.csv")

# standard rst trap data table
gcs_get_object(object_name = "standard-format-data/standard_rst_trap.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-raw/data-prep/standard-format-data/standard_trap.csv",
               overwrite = TRUE)
standard_trap <- read_csv("data-raw/data-prep/standard-format-data/standard_trap.csv")

# Adult Upstream Data
gcs_get_object(object_name = "standard-format-data/standard_adult_upstream_passage.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-raw/data-prep/standard-format-data/standard_adult_upstream.csv",
               overwrite = TRUE)
standard_upstream <- read_csv("data-raw/data-prep/standard-format-data/standard_adult_upstream.csv")

gcs_get_object(object_name = "standard-format-data/standard_adult_passage_estimate.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-raw/data-prep/standard-format-data/standard_adult_passage_estimate.csv",
               overwrite = TRUE)
standard_passage_estimates <- read_csv("data-raw/data-prep/standard-format-data/standard_adult_passage_estimate.csv")

# Adult Holding Data
gcs_get_object(object_name = "standard-format-data/standard_holding.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-raw/data-prep/standard-format-data/standard_holding.csv",
               overwrite = TRUE)
standard_holding <- read_csv("data-raw/data-prep/standard-format-data/standard_holding.csv")

# Adult Redd Data
gcs_get_object(object_name = "standard-format-data/standard_annual_redd.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-raw/data-prep/standard-format-data/standard_annual_redd.csv",
               overwrite = TRUE)
standard_annual_redd <- read_csv("data-raw/data-prep/standard-format-data/standard_annual_redd.csv")

gcs_get_object(object_name = "standard-format-data/standard_daily_redd.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-raw/data-prep/standard-format-data/standard_daily_redd.csv",
               overwrite = TRUE)
standard_daily_redd <- read_csv("data-raw/data-prep/standard-format-data/standard_daily_redd.csv")

gcs_get_object(object_name = "standard-format-data/standard_carcass_cjs_estimate.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-raw/data-prep/standard-format-data/standard_carcass_cjs_estimate.csv",
               overwrite = TRUE)
standard_carcass_estimates <- read_csv("data-raw/data-prep/standard-format-data/standard_carcass_cjs_estimate.csv")
# Knights Landing RST pre 2006 --------------------------------------------

catch_standard <- standard_catch |> 
  filter(site == "knights landing", date < as_date("2006-10-02")) |> 
  rename(life_stage = lifestage) |> 
  select(date, stream, site, subsite, site_group, count, run, life_stage, adipose_clipped, dead, fork_length, weight, species)
trap_standard <- standard_trap |> 
  filter(site == "knights landing", trap_stop_date < as_date("2006-10-02")) |> 
  rename(total_revolutions = sample_period_revolutions,
         rpm_start = rpms_start,
         rpm_end = rpms_end) |> 
  select(trap_start_date, trap_stop_date, stream, site, subsite, total_revolutions, visit_type, trap_functioning, fish_processed, rpm_start, rpm_end, include)
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
  select(date_released, release_id, stream, site, number_released, origin, run, life_stage)

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
  filter(!is.na(number_released)) |> # there should not be any NAs
  glimpse()
recaptures <- bind_rows(recapture_standard, recaptures_query_pilot |> mutate(release_id = as.character(release_id)), temp_recapture) |> glimpse()

## SAVE TO DATA PACKAGE ---
usethis::use_data(rst_catch, overwrite = TRUE)
usethis::use_data(rst_trap, overwrite = TRUE)
usethis::use_data(release, overwrite = TRUE)
usethis::use_data(recaptures, overwrite = TRUE)

# Carcass estimates -------------------------------------------------------
carcass_estimates <- standard_carcass_estimates |> 
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

redd <- standard_daily_redd |> 
  # remove any NA entries - there should not be any now that Feather issue fixed
  # remove any non chinook species
  filter(!is.na(date), species %in% c("chinook", "not recorded", "unknown")) |> 
  select(date, latitude, longitude, reach, redd_id, age, velocity, run, stream, redd_count) |> 
  # change format to date instead of datetime
  mutate(date = as.Date(date),
         redd_count = ifelse(is.na(redd_count),0,redd_count)) 

# Passage count ----------------------------------------------------------

# Remove missing dates
upstream_passage <- standard_upstream |> 
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

upstream_passage_estimates <- standard_passage_estimates|> 
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

holding <- standard_holding |> 
  select(date, reach, count, latitude, longitude, stream) |> 
  # remove all that are missing date
  filter(!is.na(date)) |> 
  mutate(run = "spring",
         adipose_clipped = F) 


# Adult save as is, no adult data in datatackle so no need to combine 
## SAVE TO DATA PACKAGE ---
usethis::use_data(upstream_passage, overwrite = TRUE)
usethis::use_data(upstream_passage_estimates, overwrite = TRUE)
usethis::use_data(holding, overwrite = TRUE)
usethis::use_data(redd, overwrite = TRUE)
usethis::use_data(carcass_estimates, overwrite = TRUE)
