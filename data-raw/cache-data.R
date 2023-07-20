library(tidyverse)
library(waterYearType)

# upstream passage - use these data for passage timing calculations
upstream_passage <- read_csv("data-raw/standard_adult_upstream.csv") |>
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
  ungroup()

usethis::use_data(upstream_passage, overwrite = TRUE)

upstream_passage_estimates <- read_csv("data-raw/standard_adult_passage_estimate.csv") |>
  mutate(upstream_count = round(passage_estimate, 0))

usethis::use_data(upstream_passage_estimates, overwrite = TRUE)

holding <- read_csv("data-raw/standard_holding.csv") |>
  group_by(year, stream) |>
  summarise(count = sum(count, na.rm = T)) |>
  ungroup()

usethis::use_data(holding, overwrite = TRUE)

redd <- read_csv("data-raw/standard_annual_redd.csv") |>
  filter(run %in% c("spring", "not recorded")) |>
  # redds in these reaches are likely fall, so set to 0 for battle & clear
  mutate(max_yearly_redd_count = case_when(reach %in% c("R6", "R6A", "R6B", "R7") &
                                             stream %in% c("battle creek", "clear creek") ~ 0,
                                           TRUE ~ max_yearly_redd_count)) |>
  group_by(year, stream) |>
  summarise(count = sum(max_yearly_redd_count, na.rm = T)) |>
  ungroup() |>
  select(year, stream, count)

usethis::use_data(redd, overwrite = TRUE)

carcass <- standard_carcass <- read_csv("data-raw/standard_carcass.csv") |>
  filter(run %in% c("spring", NA, "unknown")) |>
  group_by(year(date), stream) |>
  summarise(count = sum(count, na.rm = T)) |>
  ungroup() |>
  select(year = `year(date)`, stream, count)

usethis::use_data(carcass, overwrite = TRUE)

carcass_estimates <- standard_carcass_estimates <- read_csv("data-raw/standard_carcass_cjs_estimate.csv") |>
  rename(carcass_spawner_estimate = spawner_abundance_estimate)

usethis::use_data(carcass_estimates, overwrite = TRUE)

adult_model_input <- full_join(upstream_passage_estimates |>
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
  arrange(stream, year)

usethis::use_data(adult_model_input, overwrite = TRUE)

# covariates for adult model ----------------------------------------------

# https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0204274
# https://www.rdocumentation.org/packages/pollen/versions/0.82.0/topics/gdd
# https://www.researchgate.net/publication/279930331_Fish_growth_and_degree-days_I_Selecting_a_base_temperature_for_a_within-population_study

temperature_threshold <- 20 # https://www.noaa.gov/sites/default/files/legacy/document/2020/Oct/07354626766.pdf

standard_temperature <- read_csv("data-raw/standard_temperature.csv")

migratory_temp <- standard_temperature |>
  filter(stream == "sacramento river") |>
  filter(month(date) %in% 3:5) |>
  group_by(year(date)) |>
  mutate(above_threshold = ifelse(mean_daily_temp_c > threshold, TRUE, FALSE)) |>
  summarise(prop_days_exceed_threshold = round(sum(above_threshold, na.rm = T)/length(above_threshold), 2)) |>
  ungroup() |>
  mutate(prop_days_below_threshold = 1 - prop_days_exceed_threshold,
         prop_days_below_threshold = ifelse(prop_days_below_threshold == 0, 0.001, prop_days_below_threshold)) |>
  rename(year = `year(date)`) |>
  select(year, prop_days_exceed_threshold_migratory = prop_days_exceed_threshold)

holding_temp <- standard_temperature |>
  filter(month(date) %in% 5:7) |>
  group_by(year(date), stream) |>
  mutate(above_threshold = ifelse(mean_daily_temp_c > threshold, TRUE, FALSE)) |>
  summarise(prop_days_exceed_threshold = round(sum(above_threshold, na.rm = T)/length(above_threshold), 2)) |>
  ungroup() |>
  mutate(prop_days_below_threshold = 1 - prop_days_exceed_threshold,
         prop_days_below_threshold = ifelse(prop_days_below_threshold == 0, 0.001, prop_days_below_threshold)) |>
  rename(year = `year(date)`) |>
  select(prop_days_exceed_threshold_holding = prop_days_exceed_threshold,
         stream, year)

temp_index_sac <- standard_temperature |>
  filter(month(date) %in% 3:5, stream == "sacramento river") |>
  mutate(gdd_sac = mean_daily_temp_c - temperature_threshold,
         gdd_sac = ifelse(gdd_sac < 0, 0, gdd_sac)) |>
  group_by(year(date)) |>
  summarise(gdd_sac = sum(gdd_sac, na.rm = T)) |>
  rename(year = `year(date)`) |>
  ungroup()

temp_index_trib <- standard_temperature |>
  filter(month(date) %in% 5:8 & stream != "sacramento river") |>
  mutate(gdd_trib = mean_daily_temp_c - temperature_threshold,
         gdd_trib = ifelse(gdd_trib < 0, 0, gdd_trib)) |>
  group_by(year(date), stream) |>
  summarise(gdd_trib = sum(gdd_trib, na.rm = T)) |>
  rename(year = `year(date)`) |>
  ungroup()

temperature_index <- left_join(temp_index_trib, temp_index_sac, by = c("year")) |>
  mutate(gdd_sac = ifelse(is.na(gdd_sac), 0, gdd_sac),
         gdd_total = round(gdd_sac + gdd_trib, 2))

flow_index <- read_csv("data-raw/standard_flow.csv") |>
  filter(month(date) %in% 3:8) |>
  mutate(year = year(date)) |>
  group_by(stream, year) |>
  summarise(mean_flow = mean(flow_cfs, na.rm = T),
            max_flow = max(flow_cfs, na.rm = T))

water_year_data <- waterYearType::water_year_indices |>
  mutate(water_year_type = case_when(Yr_type %in% c("Wet", "Above Normal") ~ "wet",
                                     Yr_type %in% c("Dry", "Below Normal", "Critical") ~ "dry",
                                     TRUE ~ Yr_type)) |>
  filter(location == "Sacramento Valley") |>
  dplyr::select(WY, water_year_type)

adult_model_covariates_standard <- full_join(flow_index,
                                             temperature_index,
                                             by = c("year", "stream")) |>
  full_join(water_year_data,
            by = c("year" = "WY")) |>
  filter(!is.na(stream),
         stream != "sacramento river") |>
  select(-c(mean_flow, gdd_trib, gdd_sac)) |>
  mutate(wy_type = ifelse(water_year_type == "dry", 0, 1),
         max_flow_std = as.vector(scale(max_flow)),
         gdd_std = as.vector(scale(gdd_total))) |>
  select(year, stream, wy_type, max_flow_std, gdd_std) |>
  arrange(stream, year)

usethis::use_data(adult_model_covariates_standard, overwrite = TRUE)


# Flora data inputs -------------------------------------------------------
# TODO

# Josh data inputs --------------------------------------------------------
# TODO

# Noble data inputs -------------------------------------------------------
# TODO

# stock recruit data inputs -----------------------------------------------
# TODO




