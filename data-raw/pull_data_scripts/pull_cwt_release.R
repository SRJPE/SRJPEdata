library(tidyverse)

# This table was generated in GIS and it is located in this folder: X:\GIS\Projects\028-03_SpringRunJPE_DataMgmt\APRX\cwt_data\cwt_distances
cwt_distances <- read_csv("data-raw/cwt_data/cwt_distances_summary.csv") |>
  add_row(Id = 8,
          to_name = "FEATHER BEL THRM HI FLOW", # this is a duplicate from feather at gridley 
          distance_rkm = 115.90392, # this is the distance at feather at gridley
          from_name = "Delta Entry 1st Bridge") |>
  mutate(delta_distance = round(distance_rkm, 2),
         release_location_name = to_name) |> 
  select(release_location_name, delta_distance)

# This table was provided by Brett and was created to determine a lat and long for each location
site_info <- read_csv("data-raw/cwt_data/CWT_release_sites_latlong.csv") |> 
  filter(hatchery_location_name == "FEATHER R HATCHERY") |> 
  left_join(cwt_distances, by = "release_location_name") |> 
  rename(release_latitude = latitude,
         release_longitude = longitude) |> glimpse()

# This dataset is fro are from the Regional Mark Processing Center: https://www.rmpc.org/
cwt_data_raw_historical <- read_csv("data-raw/cwt_data/CWT_releases.csv") |> 
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
cwt_data_raw_2023 <- read_csv("data-raw/cwt_data/CWT_releases_2023_2025.csv") |> 
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

cwt_data_summary <- cwt_data_raw |> 
  filter(
    species == 1,
    run == 1,
    release_location_name %in% c("FEATHER THERMALITO BYPASS", "YUBA AT HALLWOOD BLVD", "YUBA RIVER", "FEATHER BOYDS PUMP RAMP", "FEATHER AT LIVE OAK", 
                                 "FEATHER AT GRIDLEY", "FEATHER AT YUBA CITY", "FEATHER BEL THRM HI FLOW", "FEATHER R HATCHERY"),
    hatchery_location_name == "FEATHER R HATCHERY") |> 
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
  ungroup() |> 
  left_join(site_info |> select(-hatchery_location_name), by = "release_location_name" ) |>  # left_join delta_distance, release_latitude, release_longitude columns
  filter(!tag_code_or_release_id %in% c("065809", "060107")) |> # excluding for now
  # Tag 065809 was released during an unspecified date span in December 1977 - January 1978
  # Tag 060107 was released during an unspecified date span in December 1976
  select(-c(non_cwt_1st_mark_count, non_cwt_2nd_mark_count, cwt_1st_mark_count, cwt_2nd_mark_count)) |> 
  glimpse()

# Josh is currently not using this table so we are not including it in the package
#write_csv(cwt_data_summary, "data-raw/cwt_data/cwt_data_summary.csv")
# usethis::use_data(cwt_data_summary, overwrite = TRUE)

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

feather_hatchery_release <- cwt_data_summary |> 
  group_by(
    release_location_name,
    avg_weight,
    avg_length,
    first_release_date,
    last_release_date,
    date_span,
    mid_release_date,
    delta_distance,
    release_latitude,
    release_longitude) |> 
  summarise(
    group_tagcode = paste(tag_code_or_release_id, collapse = "_"),
    group_total_marked_N = sum(total_marked_N),
    group_total_unmarked_N = sum(total_unmarked_N),
    group_total_release_N = sum(total_release_N))|> 
  mutate(
    group_mark_rate = round(group_total_marked_N / group_total_release_N, 4),
    month = month(first_release_date),
    year = ifelse(month %in% 10:12, year(first_release_date) + 1, year(first_release_date))) |> # this is water year to align with the covariates
  ungroup() |> 
  left_join(exceedence_flows) |> 
  left_join(max_flows)

# write_csv(feathery_hatchery_release, "data-raw/cwt_data/cwt_data_grouped.csv")
usethis::use_data(feather_hatchery_release, overwrite = TRUE)
