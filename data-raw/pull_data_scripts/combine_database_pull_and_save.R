library(tidyverse)
# Bind together tables from SRJPE data and data tackle 
source("data-raw/pull_data_scripts/pull_tables_from_database.R")
source("data-raw/pull_data_scripts/pull_tables_from_data_tackle_database.R")
source("data-raw/pull_data_scripts/pull_misfit_rst_data.R") # Battle and Clear recapture, KNL pre 2004, Butte pre 2015

# We use standard release to get fork length and origin (data that is not in EDI)
# and this dataset is cached in helper_data. This data is on GCP:
# "standard-format-data/standard_recapture.csv"
standard_release <- read_csv("data-raw/helper-tables/standard_release.csv")

# Bind rows 
rst_catch_prep <- bind_rows(rst_catch, rst_catch_query_pilot, edi_catch) |> 
  mutate(fork_length = ifelse(fork_length == 0, NA, fork_length), # looks like there were some cases where fork length is 0. this should be handled more upstream but fixing it here for now
         julian_week = week(date),
         julian_year = year(date),# adding week for noble
         life_stage = ifelse(is.na(life_stage), "not recorded", life_stage),
         subsite = case_when(site == "okie dam" & is.na(subsite) ~ "okie dam 1", # fix missing subsites
                             is.na(subsite) ~ site,
                             T ~ subsite)) |> 
  glimpse()

# find dates where the rst is fishing to use as a filter
okie_rst <- rst_catch_prep |> 
  filter(site == "okie dam", subsite != "okie dam fyke trap") |> 
  mutate(date = as_date(date)) |> # remove time so that won't affect it
  pull(date)

rst_catch <- rst_catch_prep |> 
  mutate(butte_fyke_filter = case_when(site == "okie dam" & as_date(date) %in% okie_rst ~ "rst & fyke",
                                       site == "okie dam" & !as_date(date) %in% okie_rst ~ "fyke only",
                                       T ~ "not butte")) |> 
  # some of these happen due to EDI join and the datatackle include more species than chinook
  filter(species %in% c("chinook","chinook salmon"), # filter for only chinook
         life_stage != "adult",# remove the adult fish (mostly on Butte)
         !is.na(stream),# 7 NAs I think come from knights landings
         butte_fyke_filter != "fyke only") |> 
  select(-c(butte_fyke_filter))

rst_trap <- bind_rows(rst_trap, rst_trap_query_pilot, edi_trap)  |> glimpse()
release <- bind_rows(release_db, release_query_pilot |> 
                       mutate(release_id = as.character(release_id)), edi_release)  |> 
  filter(!is.na(number_released)) |> # there should not be any NAs
  left_join(standard_release |> 
              filter(!is.na(median_fork_length_released)) |> 
              select(site, release_id, median_fork_length_released) |> 
              distinct()) |>  # fork length is not on EDI but Josh needs it in weekly_efficiency
  left_join(standard_release |> 
              select(site, release_id, origin_released) |> 
              distinct())  # fork length is not on EDI but Josh needs it in weekly_efficiency
recaptures <- bind_rows(recaptures_db, recaptures_query_pilot |> mutate(release_id = as.character(release_id)), edi_recapture) |> glimpse()

## SAVE TO DATA PACKAGE ---
usethis::use_data(rst_catch, overwrite = TRUE)
usethis::use_data(rst_trap, overwrite = TRUE)
usethis::use_data(release, overwrite = TRUE)
usethis::use_data(recaptures, overwrite = TRUE)