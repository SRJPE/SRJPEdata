library(tidyverse)
# Bind together tables from SRJPE data and data tackle 
source("data-raw/pull_data_scripts/pull_tables_from_database.R")
source("data-raw/pull_data_scripts/pull_tables_from_data_tackle_database.R")
source("data-raw/pull_data_scripts/TEMP_pull_from_edi.R") # remove after data get added to db
# Bind rows 
rst_catch <- bind_rows(rst_catch, rst_catch_query_pilot, temp_catch) |> 
  mutate(fork_length = ifelse(fork_length == 0, NA, fork_length), # looks like there were some cases where fork length is 0. this should be handled more upstream but fixing it here for now
         julian_week = week(date)) |> # adding week for noble
  glimpse()
rst_trap <- bind_rows(rst_trap, rst_trap_query_pilot, temp_trap)  |> glimpse()
release <- bind_rows(release, release_query_pilot |> 
                       mutate(release_id = as.character(release_id)), temp_release)  |> 
  filter(!is.na(number_released)) |> # there should not be any NAs
  glimpse()
recaptures <- bind_rows(recaptures, recaptures_query_pilot |> mutate(release_id = as.character(release_id)), temp_recapture) |> glimpse()

## SAVE TO DATA PACKAGE ---
usethis::use_data(rst_catch, overwrite = TRUE)
usethis::use_data(rst_trap, overwrite = TRUE)
usethis::use_data(release, overwrite = TRUE)
usethis::use_data(recaptures, overwrite = TRUE)


# Adult save as is, no adult data in datatackle so no need to combine 
## SAVE TO DATA PACKAGE ---
usethis::use_data(upstream_passage, overwrite = TRUE)
usethis::use_data(upstream_passage_estimates, overwrite = TRUE)
usethis::use_data(holding, overwrite = TRUE)
usethis::use_data(redd, overwrite = TRUE)
usethis::use_data(carcass_estimates, overwrite = TRUE)