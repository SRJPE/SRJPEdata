library(tidyverse)
library(hms)
# Bind together tables from SRJPE data and data tackle
source("data-raw/pull_data_scripts/pull_tables_from_database.R")
source("data-raw/pull_data_scripts/pull_tables_from_data_tackle_database.R")
source("data-raw/pull_data_scripts/pull_misfit_rst_data.R") # Battle and Clear recapture, KNL pre 2004, Butte pre 2015

# We use standard release to get fork length and origin (data that is not in EDI)
# and this dataset is cached in helper_data. This data is on GCP:
# "standard-format-data/standard_recapture.csv"
standard_release <- read_csv("data-raw/helper-tables/standard_release.csv")

# rst_trap ----------------------------------------------------------------

# processing code to assign the trap_visit_time_start for data from datatackle
rst_trap_query_pilot_processed <- rst_trap_query_pilot |>
  filter(trap_visit_time_end > as_date("2023-09-01")) |> # removes the entries from Jan 2023 (those go in previous season)
  arrange(trap_name, trap_visit_time_end) |>
  mutate(
    trap_visit_time_restart = case_when(
      is.na(trap_visit_time_restart) ~ trap_visit_time_end,
      T ~ trap_visit_time_restart
    ),
    # note that this is not perfect - ideally there is a trapvisit for when they restart the trap
    trap_visit_time_start = lag(trap_visit_time_restart),
    trap_visit_time_start = case_when(
      is.na(trap_visit_time_start) ~ as_date(trap_visit_time_end) - 1,
      # the first day will be NA
      as_date(trap_visit_time_end) - as_date(trap_visit_time_start) > 7 ~ as_date(trap_visit_time_end) - 1,
      # assuming trap was stopped and we just don't have that data
      as_date(trap_visit_time_end) - as_date(trap_visit_time_start) < 0 ~ as_date(trap_visit_time_end) - 1,
      # this is the first day for mill
      T ~ trap_visit_time_start
    ),
    trap_start_date = as_date(trap_visit_time_start),
    trap_start_time = as_hms(trap_visit_time_start),
    trap_stop_date = as_date(trap_visit_time_end),
    trap_stop_time = as_hms(trap_visit_time_end),
    subsite = site
  ) |>
  select(
    trap_visit_id,
    stream,
    site,
    subsite,
    trap_name,
    is_paper_entry,
    trap_start_date,
    trap_stop_date,
    trap_start_time,
    trap_stop_time,
    #trap_visit_time_start,
    #trap_visit_time_end,
    #trap_visit_time_restart,
    fish_processed,
    why_fish_not_processed,
    sample_gear,
    cone_depth,
    trap_functioning,
    why_trap_not_functioning,
    trap_status_at_end,
    total_revolutions,
    rpm_at_start,
    rpm_at_end,
    in_half_cone_configuration,
    debris_volume_gal
  )

rst_trap <- bind_rows(rst_trap, rst_trap_query_pilot_processed, edi_trap) |> 
  mutate(subsite = ifelse(is.na(subsite), site, subsite),
         site_group = ifelse(is.na(site_group), site, site_group)) |> 
  mutate(flag = case_when(trap_start_date < as_date("2022-10-17") & trap_start_date > as_date("2009-8-19") & site == "hallwood" ~ "remove",
                            T ~ "keep")) |> 
  filter(flag == "keep") |> 
  select(-flag)

# rst_catch ---------------------------------------------------------------

# Bind rows
rst_catch_prep <- bind_rows(rst_catch, rst_catch_query_pilot, edi_catch)

# special processing for butte creek
# find dates where the rst is fishing to use as a filter
okie_rst <- rst_catch_prep |>
  filter(site == "okie dam", subsite != "okie dam fyke trap") |>
  mutate(date = as_date(date)) |> # remove time so that won't affect it
  pull(date)

# Additional processing for rst_catch
# If chinook salmon were not caught in the trap it will look like the trap didn't fish unless we join
# it with trap data. This is important for ensuring hours fished is accurate and count = 0 instead of NA
catch_dates <- rst_trap |>
  filter(
    visit_type %in% c("continue trapping", "end trapping", "not recorded") |
      is.na(visit_type)
  )  |>
  mutate(date = case_when(
    is.na(trap_stop_date) ~ as_date(trap_start_date),
    T ~ as_date(trap_stop_date)
  )) |>
  distinct(date, stream, site, subsite)

rst_catch <- full_join(catch_dates, rst_catch_prep) |>
  mutate(
    fork_length = ifelse(fork_length == 0, NA, fork_length),
    # looks like there were some cases where fork length is 0. this should be handled more upstream but fixing it here for now
    julian_week = week(date),
    julian_year = year(date),
    # adding week for noble
    life_stage = ifelse(is.na(life_stage), "not recorded", life_stage),
    subsite = case_when(
      site == "okie dam" &
        is.na(subsite) ~ "okie dam 1",
      # fix missing subsites
      is.na(subsite) ~ site,
      subsite == "yub" ~ "hal",
      # we made the decision to include these historical ones as halwood
      T ~ subsite
    ),
    site_group = case_when(!stream %in% c("feather river", "sacramento river") ~ stream,
                           site == "knights landing" ~ "knights landing",
                           site == "tisdale" ~ "tisdale",
                           site %in% c("eye riffle", "steep riffle", "gateway riffle") ~ "upper feather lfc",
                           site %in% c("live oak", "herringer riffle", "sunset pumps", "shawn's beach") ~ "upper feather hfc",
                           T ~ stream),
    species = case_when(
      species %in% c("chinook", "chinook salmon") ~ "chinook salmon",
      is.na(species) ~ "chinook salmon",
      T ~ species
    ),
    butte_fyke_filter = case_when(
      site == "okie dam" & as_date(date) %in% okie_rst ~ "rst & fyke",
      site == "okie dam" &
        !as_date(date) %in% okie_rst ~ "fyke only",
      T ~ "not butte"
    ),
    count = ifelse(is.na(count), 0, count)
  ) |> # few instances where count is NA prior to joining in trap data. some of these probably should not be NA but are from old data
  # some of these happen due to EDI join and the datatackle include more species than chinook
  filter(
    species == "chinook salmon",
    # filter for only chinook
    life_stage != "adult",
    # remove the adult fish (mostly on Butte)
    butte_fyke_filter != "fyke only",!is.na(stream),
    !is.na(date) # there are currently (12/19) 3 NA dates from battle/clear with count 0, believe this is an issue with trap data rather than catch
  ) |>  
  select(-c(butte_fyke_filter))

# release -----------------------------------------------------------------

release <- bind_rows(release_db,
                     release_query_pilot |>
                       mutate(release_id = as.character(release_id)),
                     edi_release)  |>
  filter(!is.na(number_released)) |> # there should not be any NAs
  left_join(
    standard_release |>
      filter(!is.na(median_fork_length_released)) |>
      select(site, release_id, median_fork_length_released) |>
      distinct()
  ) |>  # fork length is not on EDI but Josh needs it in weekly_efficiency
  left_join(standard_release |>
              select(site, release_id, origin_released) |>
              distinct())  # fork length is not on EDI but Josh needs it in weekly_efficiency

# recaptures --------------------------------------------------------------

recaptures <- bind_rows(
  recaptures_db,
  recaptures_query_pilot |> mutate(release_id = as.character(release_id)),
  edi_recapture
) |> glimpse()

## SAVE TO DATA PACKAGE ---
usethis::use_data(rst_catch, overwrite = TRUE)
usethis::use_data(rst_trap, overwrite = TRUE)
usethis::use_data(release, overwrite = TRUE)
usethis::use_data(recaptures, overwrite = TRUE)

