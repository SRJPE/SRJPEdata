# Create data file for passage-to-spawner (P2S) model
library(tidyverse)
library(googleCloudStorageR)

# pull tables from google cloud (to be replaced with db) ------------------

# TODO source pull_tables_from_database
# TODO add adult tables to pull_tables_from_database

# for now, pull in the adult tables here using google cloud

gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
gcs_global_bucket(bucket = Sys.getenv("GCS_DEFAULT_BUCKET"))

upstream_passage_table <- read_csv(gcs_get_object(object_name = "standard-format-data/standard_adult_upstream_passage.csv",
                                                  bucket = gcs_get_global_bucket()))
upstream_passage_estimate_table <- read_csv(gcs_get_object(object_name = "standard-format-data/standard_adult_passage_estimate.csv",
                                                      bucket = gcs_get_global_bucket()))

holding_table <- read_csv(gcs_get_object(object_name = "standard-format-data/standard_holding.csv",
                                         bucket = gcs_get_global_bucket()))

redd_table <- read_csv(gcs_get_object(object_name = "standard-format-data/standard_annual_redd.csv",
                                      bucket = gcs_get_global_bucket()))

carcass_table <- read_csv(gcs_get_object(object_name = "standard-format-data/standard_carcass.csv",
                                         bucket = gcs_get_global_bucket()))

carcass_estimates_table <- read_csv(gcs_get_object(object_name = "standard-format-data/standard_carcass_cjs_estimate.csv",
                                                   bucket = gcs_get_global_bucket()))

# upstream passage and estimates ------------------------------------------
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

# pull in passage estimates and use these for upstream_count
upstream_passage_estimates <- upstream_passage_estimate_table |>
  mutate(upstream_count = round(passage_estimate, 0)) |>
  glimpse()

# holding -----------------------------------------------------------------
holding <- holding_table |>
  group_by(year, stream) |>
  summarise(count = sum(count, na.rm = T)) |>
  ungroup() |>
  glimpse()

# redd --------------------------------------------------------------------
redd <- redd_table |>
  filter(run %in% c("spring", "not recorded")) |>
  # TODO keep this processing? redds in these reaches are likely fall, so set to 0 for battle & clear 
  mutate(max_yearly_redd_count = case_when(reach %in% c("R6", "R6A", "R6B", "R7") &
                                             stream %in% c("battle creek", "clear creek") ~ 0,
                                           TRUE ~ max_yearly_redd_count)) |>
  group_by(year, stream) |>
  summarise(count = sum(max_yearly_redd_count, na.rm = T)) |>
  ungroup() |>
  select(year, stream, count) |>
  glimpse()

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
adult_model_counts_raw <- full_join(upstream_passage_estimates |>
                                     select(year, stream,
                                            upstream_estimate = upstream_count),
                                   redd |>
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

usethis::use_data(adult_model_counts_raw, overwrite = TRUE)