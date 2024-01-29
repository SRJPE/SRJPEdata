# Create data file for passage-to-spawner (P2S) model
library(tidyverse)
library(googleCloudStorageR)

# pull tables from google cloud (to be replaced with db) ------------------
# TODO source pull_tables_from_database
# TODO add adult tables to pull_tables_from_database
# Pull tables using pull data script 
source('data-raw/pull_data.R')

# read in tables 
upstream_passage_table <- read_csv("data-raw/database-tables/standard_adult_upstream.csv")
upstream_passage_estimate_table <- read_csv("data-raw/database-tables/standard_adult_passage_estimate.csv")
holding_table <- read_csv("data-raw/database-tables/standard_holding.csv")
redd_table <- read_csv("data-raw/database-tables/standard_daily_redd.csv")
carcass_estimates_table <- read_csv("data-raw/database-tables/standard_carcass_cjs_estimate.csv")
#carcass_table <- read_csv("data-raw/database-tables/standard_carcass.csv")

# upstream passage and estimates -----------------------------------------------
# upstream passage - use these data for passage timing calculations
upstream_passage <- upstream_passage_table |> 
  filter(!is.na(date)) |>
  mutate(stream = tolower(stream),
         year = year(date)) |>
  filter(run %in% c("spring", NA, "not recorded")) |>
  group_by(year, passage_direction, stream) |>
  summarise(count = sum(count, na.rm = T)) |>
  ungroup() |>
  pivot_wider(names_from = passage_direction, values_from = count) |>
  # calculate upstream passage for streams where passage direction is recorded
  mutate(down = ifelse(is.na(down), 0, down),
         up = case_when(stream %in% c("deer creek", "mill creek") ~ `NA`,
                        !stream %in% c("deer creek", "mill creek") & is.na(up) ~ 0,
                        TRUE ~ up)) |>
  select(-`NA`) |>
  group_by(year, stream) |>
  summarise(count = round(up - down), 0) |>
  select(year, count, stream) |>
  ungroup() |>
  glimpse()
# TODO think if we want to retain the adipose_clip and run info 

# pull in passage estimates and use these for upstream_count
upstream_passage_estimates <- upstream_passage_estimate_table |>
  mutate(passage_estimate = round(passage_estimate, 0)) |>
  glimpse()

# holding -----------------------------------------------------------------
holding <- holding_table |>
  group_by(year, stream) |>
  summarise(count = sum(count, na.rm = T)) |>
  ungroup() |>
  glimpse()

# redd --------------------------------------------------------------------
# have a method for each stream 
# Use max daily reach count summed across year to get max annual count for streams
# that do not have redd id 
redd_non_battle_clear <- redd_table |>
  filter(run %in% c("spring", "not recorded"),
         species != "steelhead",
         !stream %in% c("battle creek", "clear creek")) |> 
  group_by(stream, reach, date) |> 
  summarize(daily_reach_count = sum(redd_count, na.rm = TRUE)) |> 
  ungroup() |> 
  group_by(year = year(date), stream, reach) |> 
  summarize(max_daily_reach_count = max(daily_reach_count, na.rm = TRUE)) |> 
  ungroup() |> 
  group_by(stream, year) |> 
  summarize(count = sum(max_daily_reach_count, na.rm = TRUE)) |> 
  ungroup() |> 
  glimpse()
  
# for streams with redd id, just sum redd count (each redd id is only counted once)
battle_clear_redd <- redd_table |>
  filter(run %in% c("spring", "not recorded"),
         species %in% c("not recorded", NA, "chinook", "unknown"),
         stream %in% c("battle creek", "clear creek"),
         !reach %in% c("R6", "R6A", "R6B", "R7")) |> #TODO remove once reaches are standardized
  group_by(year = year(date), stream) |> 
  summarize(count = sum(redd_count, na.rm = TRUE)) |> 
  ungroup()

redd_data <- bind_rows(redd_non_battle_clear, battle_clear_redd) |> glimpse()


# carcass and CJS estimates -----------------------------------------------------------------
# raw carcass
carcass <- carcass_table |>
  filter(run %in% c("spring", NA, "unknown")) |>
  group_by(year(date), stream) |>
  summarise(count = sum(count, na.rm = T)) |>
  ungroup() |>
  select(year = `year(date)`, stream, count) |>
  glimpse()

# estimates from CJS model (carcass survey)
carcass_estimates <- carcass_estimates_table |> 
  rename(carcass_spawner_estimate = spawner_abundance_estimate) |>
  glimpse()

# join all together for raw input table for P2S (will be joined to environmental variables) -------------------------------
# previously titled "adult_model_input_raw"
observed_adult_input <- full_join(upstream_passage_estimates |>
                                     select(year, stream,
                                            upstream_estimate = passage_estimate),
                                   redd_data |> 
                                     rename(redd_count = count),
                                   by = c("year", "stream")) |>
  full_join(holding |>
              rename(holding_count = count),
            by = c("year", "stream")) |>
  full_join(carcass_estimates |>
              rename(carcass_estimate = carcass_spawner_estimate) |>
              select(-c(lower, upper, confidence_interval)),
            by = c("year", "stream")) |> 
  pivot_longer(c(upstream_estimate, redd_count, holding_count, carcass_estimate),
               values_to = "count",
               names_to = "data_type") |>
  filter(!is.na(count)) |>
  arrange(stream, year) |>
  glimpse()

usethis::use_data(observed_adult_input, overwrite = TRUE)
