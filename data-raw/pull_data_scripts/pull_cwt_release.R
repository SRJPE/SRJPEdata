library(tidyverse)

# Goal is to create (1) Table of CWT releases that can be joined with recaptures
# at Knights Landing and include distance from release location to Knights Landing
# (2) Table of Knights Landing recaptures that can be joined with the release table
# (3) Table of Feather River releases and the distance to Delta Entry


# Distances ---------------------------------------------------------------
# This table was generated in GIS and it is located in this folder: X:\GIS\Projects\028-03_SpringRunJPE_DataMgmt\APRX\cwt_data\cwt_distances
cwt_distances <- read_csv("data-raw/helper-tables/cwt_data/cwt_distances_summary.csv") |>
  add_row(Id = 8,
          to_name = "FEATHER BEL THRM HI FLOW", # this is a duplicate from feather at gridley 
          distance_rkm = 115.90392, # this is the distance at feather at gridley
          from_name = "Delta Entry 1st Bridge") |>
  mutate(delta_distance = round(distance_rkm, 2),
         release_location_name = to_name) |> 
  select(release_location_name, delta_distance)

# This table was provided by Brett and was created to determine a lat and long for each location
site_info_feather <- read_csv("data-raw/helper-tables/cwt_data/CWT_release_sites_latlong.csv") |> 
  filter(hatchery_location_name == "FEATHER R HATCHERY") |> 
  left_join(cwt_distances, by = "release_location_name") |> 
  rename(release_latitude = latitude,
         release_longitude = longitude) |> glimpse()

# read in lat/longs from https://www.rmpc.org/data-selection/rmis-queries/
rest_of_site_info <- read_csv(here::here("data-raw", "helper-tables", "cwt_data", "CSV55526.TXT")) |> 
  filter(!(name %in% unique(site_info_feather$release_location_name))) |> 
  select(release_latitude = latitude, release_longitude = longitude, 
         release_location_name = name) |> 
  glimpse()

site_info <- bind_rows(site_info_feather, rest_of_site_info) |> 
  filter(!is.na(release_latitude)) |> 
  distinct()

# do not have location information for: SACRA.-SAN JOAQ. SYS
# setdiff(unique(cwt_data_summary_all$release_location_name), locations$name)


# CWT releases ------------------------------------------------------------
# This dataset is from are from the Regional Mark Processing Center: https://www.rmpc.org/
cwt_data_raw_historical <- read_csv("data-raw/helper-tables/cwt_data/CWT_releases.csv") |> 
  mutate(first_release_date = as.Date(first_release_date, format = "%m/%d/%Y"),
         first_release_date = as.Date(format(first_release_date, "%Y-%m-%d")),
         last_release_date = as.Date(last_release_date, format = "%m/%d/%Y"),
         last_release_date = as.Date(format(last_release_date, "%Y-%m-%d"))) |> 
  select(
    release_location_name,
    avg_weight,
    avg_length,
    first_release_date,
    last_release_date,
    tag_code_or_release_id,
    cwt_1st_mark_count,
    cwt_2nd_mark_count,
    non_cwt_1st_mark_count,
    non_cwt_2nd_mark_count,
    tag_loss_rate,
    species,
    run,
    hatchery_location_name)
cwt_data_raw_2023 <- read_csv("data-raw/helper-tables/cwt_data/CWT_releases_2023_2025.csv") |> 
  mutate(first_release_date = ymd(first_release_date),
         last_release_date = ymd(last_release_date)) |> 
  select(
    release_location_name,
    avg_weight,
    avg_length,
    first_release_date,
    last_release_date,
    tag_code_or_release_id,
    cwt_1st_mark_count,
    cwt_2nd_mark_count,
    non_cwt_1st_mark_count,
    non_cwt_2nd_mark_count,
    tag_loss_rate,
    species,
    run,
    hatchery_location_name)

cwt_data_raw <- bind_rows(cwt_data_raw_historical, cwt_data_raw_2023)

cwt_data_summary_all <- cwt_data_raw |> 
  replace_na(list(tag_loss_rate = 0,
                  non_cwt_1st_mark_count = 0,
                  non_cwt_2nd_mark_count = 0,
                  cwt_1st_mark_count = 0,
                  cwt_2nd_mark_count = 0)) |>
  mutate(
    date_span = 1 + as.numeric(difftime(last_release_date, first_release_date, units = "days")), # can be used to summarize conditions over release period
    total_marked_N =  round((cwt_1st_mark_count + cwt_2nd_mark_count) * (1 - tag_loss_rate)),
    total_unmarked_N = non_cwt_1st_mark_count + non_cwt_2nd_mark_count + round((cwt_1st_mark_count + cwt_2nd_mark_count) * (tag_loss_rate)),
    total_release_N = cwt_1st_mark_count + cwt_2nd_mark_count + non_cwt_1st_mark_count + non_cwt_2nd_mark_count,
    mark_rate = total_marked_N/total_release_N, # will serve as expansion factor for catch analysis
    mid_release_date = first_release_date + (date_span/2)) |>   # use to apply conditions for group
  left_join(site_info |> select(-hatchery_location_name), by = "release_location_name" ) |>  # left_join delta_distance, release_latitude, release_longitude columns
  filter(!tag_code_or_release_id %in% c("065809", "060107")) |> # excluding for now
  # Tag 065809 was released during an unspecified date span in December 1977 - January 1978
  # Tag 060107 was released during an unspecified date span in December 1976
  select(-c(non_cwt_1st_mark_count, non_cwt_2nd_mark_count, cwt_1st_mark_count, cwt_2nd_mark_count)) |> 
  group_by(
    release_location_name,
    hatchery_location_name,
    release_latitude,
    release_longitude,
    species,
    run, 
    avg_weight,
    avg_length,
    first_release_date,
    last_release_date,
    date_span,
    mid_release_date) |> 
  mutate(release_group_id = cur_group_id()) |> # add a release_group_id that can be used to group similar tag codes together
  glimpse()

# For the analysis on the Knights Landing release/recapture table, we need to group
# tag codes that have the same characteristics to allow for greater sample size
# reduce pseudo samples. The challenge is then joining this to the recaptures
# because the common variable is tag code. We will create a lookup table that creates
# these groups and assigns each tag code to a group

cwt_release_group_lookup <- cwt_data_summary_all |> 
  ungroup() |> 
  select(tag_code_or_release_id, release_group_id) |> 
  rename(tag_code = tag_code_or_release_id)

# Covariates --------------------------------------------------------------
# Josh prefers the table that is grouped by release and wanted to include environmental
# covariates that Flora uses in survival/TT model which are the 3_category_flow_exceedance_year_type and monthly_max_flow
exceedence_flows <- SRJPEdata::forecast_covariates |>
  filter(name == "3_category_flow_exceedance_year_type",
         stream == "feather river") |>
  mutate(value = case_when(text_value == "Wet" ~ 2,
                           text_value == "Average" ~ 1,
                           TRUE ~ 0)) |>
  # Flora's code calls year the same thing as water year (assumption)
  select(year = water_year, value) |>
  arrange(year) |> 
  rename(exceedance_flow_year_type = value)

max_flows <- SRJPEdata::forecast_covariates |>
  filter(name == "monthly_max_flow",
         stream == "feather river") |>
  arrange(stream, year, month) |>
  select(year, month, value) |> 
  rename(monthly_max_flow = value)


# Releases - summarized by similar releases ------------------------------------------
# MW: Note that exceedance_flow_year_type will be NA until 1996
hatchery_release_all <- cwt_data_summary_all |>
  group_by(
    release_location_name,
    hatchery_location_name,
    release_latitude,
    release_longitude,
    species,
    run, 
    avg_weight,
    avg_length,
    first_release_date,
    last_release_date,
    date_span,
    mid_release_date, 
    release_group_id) |> 
summarise(
  group_total_marked_N = sum(total_marked_N),
  group_total_unmarked_N = sum(total_unmarked_N),
  group_total_release_N = sum(total_release_N)) |> 
  mutate(
    # prefer first_release_date; fall back to last_release_date
    release_date_use = coalesce(first_release_date, last_release_date),
    group_mark_rate = round(group_total_marked_N / group_total_release_N, 4),
    month = month(release_date_use),
    year = ifelse(month %in% 10:12, year(release_date_use) + 1, year(release_date_use))) |>
  ungroup() |>
  left_join(exceedence_flows) |>
  left_join(max_flows) |>
  select(-release_date_use) |>
  glimpse()


# Releases - Feather River ------------------------------------------------
feather_hatchery_release <- hatchery_release_all |> 
  filter(
    species == 1,
    run == 1,
    release_location_name %in% c("FEATHER THERMALITO BYPASS", "YUBA AT HALLWOOD BLVD", "YUBA RIVER", "FEATHER BOYDS PUMP RAMP", "FEATHER AT LIVE OAK", 
                                 "FEATHER AT GRIDLEY", "FEATHER AT YUBA CITY", "FEATHER BEL THRM HI FLOW", "FEATHER R HATCHERY"),
    hatchery_location_name == "FEATHER R HATCHERY") |> 
  mutate(species = "chinook salmon",
         run = case_when(run == 1 ~ "spring",
                         run == 3 ~ "fall",
                         run == 4 ~ "winter",
                         run == 7 ~ "late fall"))


# RST recaptures ----------------------------------------------------------
recaptures_raw <- readxl::read_excel(here::here("data-raw", "helper-tables", "cwt_data", "KL.CWT.Data.1999-2024.UPDATED.1.xlsx")) |> 
  janitor::clean_names()

rst_cwt_recaptures <- recaptures_raw |> 
  mutate(date_chr = str_trim(date),
         date_mdy = suppressWarnings(mdy(date_chr, quiet = TRUE)),
         date_excel = suppressWarnings(as_date(as.numeric(date_chr), origin = "1899-12-30")),
         date_parsed = case_when(
           str_detect(date_chr, "^[0-9]+(\\.[0-9]+)?$") & is.na(date_mdy) ~ date_excel,
           TRUE ~ date_mdy)) |> 
  select(date = date_parsed, forklength = fl, weight = wt, tag_code = cwt) |> 
  mutate(stream = "sacramento river",
         site = "knights landing") |> 
  filter(!is.na(tag_code)) |> 
  filter(tag_code != "N/A") |> 
  mutate(
    julian_week  = isoweek(date),
    week_index   = if_else(
      julian_week >= 40,
      julian_week - 39,
      julian_week + (53 - 39)
    )
  ) |> 
  select(-julian_week) |> 
  left_join(cwt_release_group_lookup) |> 
  glimpse()

# QC check: 
cwt_tag_codes <- unique(cwt_data_summary_all$tag_code_or_release_id)
rst_tag_codes <- unique(rst_cwt_recaptures$tag_code)
filter(rst_cwt_recaptures, is.na(release_group_id)) |> tally()

### returns tag codes that appear in RST recaptures but NOT in hatchery releases
setdiff(rst_tag_codes, cwt_tag_codes)

### Summary - Some releases were not reported
rst_cwt_recaptures  |> 
  mutate(tag_code = str_trim(tag_code))  |> 
  anti_join(
    cwt_data_summary_all  |> 
      mutate(tag_code = str_trim(tag_code_or_release_id))
  ) |>  
  count(tag_code, sort = TRUE)  |> summarize(n = sum(n))

# Pull recaptures that are included in the hatchery release table ---------
# hatchery_release_recaptures <- rst_cwt_recaptures |> 
#   mutate(tag_code = str_trim(tag_code))  |> 
#   left_join(
#     hatchery_release_all  |> 
#       mutate(tag_code = str_trim(tag_code))
#   ) |> 
#   filter(!is.na(release_location_name))

# this file is saved so that we can calculate the distances to knights landing
# recapture_location <- hatchery_release_recaptures |> 
#   select(release_location_name, release_latitude, release_longitude) |> 
#   distinct() |> 
#   write_csv("data-raw/helper-tables/recapture_locations.csv")

# This table is calculated in analysis/recapture_distances.R
knight_distances <- read_csv("data-raw/helper-tables/knights_landing_cwt_distances.csv") 
  
# build final table
hatchery_release <- knight_distances |>
  left_join(hatchery_release_all) |> 
  mutate(release_to_knights_landing_distance = dist_along_mi * 1.60934, # change to river km
         species = "chinook salmon",
         run = case_when(run == 1 ~ "spring",
                         run == 3 ~ "fall",
                         run == 4 ~ "winter",
                         run == 7 ~ "late fall")) |>  
  select(-dist_along_mi)

# save data  --------------------------------------------------------------
# write_csv(feathery_hatchery_release, "data-raw/cwt_data/cwt_data_grouped.csv")
usethis::use_data(feather_hatchery_release, overwrite = TRUE)
usethis::use_data(hatchery_release, overwrite = TRUE)
usethis::use_data(rst_cwt_recaptures, overwrite = TRUE)
