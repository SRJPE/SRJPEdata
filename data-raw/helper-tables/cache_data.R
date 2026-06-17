if (requireNamespace("devtools", quietly = TRUE)) devtools::load_all(".", quiet = TRUE)
library(SRJPEdata)
library(tidyverse)
library(lubridate)

### Script to run and cache all helper tables 

### RST DATA -------------------------------------------------------------------
stream_site_with_efficiency_data <- weekly_efficiency |>
  ungroup() |> 
  distinct(stream, site) |>
  mutate(if_efficiency_data = T)

# Assign stream/site/year as exclude or not based on criteria
exclusion_catch <- weekly_juvenile_abundance_catch_data |>
  filter(!is.na(count)) |> # remove when trap is not fishing
  filter(week %in% c(45:53, 1:22)) |> # select to the week window used in BTSPASX
  select(stream, site, week, run_year) |>
  distinct() |>
  group_by(stream, site, run_year) |>
  summarise(number_weeks = n()) |>
  # other exclusion rules are included in case this changes in the future
  mutate(
    exclude_20 = ifelse(number_weeks < 6, TRUE, FALSE),
    exclude_40 = ifelse(number_weeks < 13, TRUE, FALSE),
    exclude_60 = ifelse(number_weeks < 19, TRUE, FALSE),
    exclude_65 = ifelse(number_weeks < 21, TRUE, FALSE),
    exclude_70 = ifelse(number_weeks < 22, TRUE, FALSE),
    exclude_75 = ifelse(number_weeks < 24, TRUE, FALSE)
  ) |> 
  left_join(stream_site_with_efficiency_data) |> 
  mutate(if_efficiency_data = if_else(is.na(if_efficiency_data), F, T)) 

years_to_exclude_rst_data_all <- exclusion_catch |>
  filter(exclude_60 == T | if_efficiency_data == F) |> 
  select(stream, site, run_year, number_weeks) |>
  mutate(exclusion_type = "60% of weeks sampled", apply_to = "all runs")

# ADD spring specific row 
years_to_exclude_rst_data <- years_to_exclude_rst_data_all |>
  ungroup() |>
  add_row(
    stream = "sacramento river",
    site = "tisdale",
    run_year = 2013,
    number_weeks = 20,
    exclusion_type = "spring run specific - 11 consecutive weeks not sampled Dec 16 to Feb 19",
    apply_to = "spring"
  ) |>
  add_row(
    stream = "feather river",
    site = "herringer riffle",
    run_year = 2008,
    number_weeks = 21,
    exclusion_type = "spring run specific - 9 weeks missing Nov 04 to Jan 01",
    apply_to = "spring"
  ) |> 
  mutate(exclude = TRUE)

# Add years to include
years_to_include_rst_data <- exclusion_catch |>
  filter(exclude_60 == F & if_efficiency_data == T) |>
  select(stream, site, run_year)  |> 
  mutate(exclude = FALSE)

# Combine for overall table 
rst_model_years <- bind_rows(years_to_exclude_rst_data, years_to_include_rst_data)

# Save data object 
usethis::use_data(rst_model_years, overwrite = TRUE)

### ADULT DATA -----------------------------------------------------------------
# years to exclude already applied to pull_adult_data.R

years_to_exclude_adult <- read_csv(here::here("data-raw", "helper-tables", "years_to_exclude_adult_datasets.csv")) |> 
  mutate(exclude = TRUE)

years_to_include_adult <- annual_adult |> 
  mutate(data_type = case_when(data_type == "upstream_estimate" ~ "upstream passage",
                               data_type == "carcass_estimate" ~ "carcass",
                               T ~ data_type)) |> 
  select(year, stream, data_type) |> 
  mutate(exclude = FALSE)

adult_model_years <- bind_rows(years_to_exclude_adult, years_to_include_adult)

usethis::use_data(adult_model_years, overwrite = TRUE)
