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

years_exclude_nice_names <- years_to_exclude_rst_data_all |>
  select(
    "Stream" = stream,
    "Site" = site,
    "Run Year" = run_year,
    "Exclusion Type" = exclusion_type
  )
knitr::kable(head(years_exclude_nice_names, 10))



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
  )

knitr::kable(years_to_exclude_rst_data |> filter(grepl("spring run specific", exclusion_type)))

# Write Data 
usethis::use_data(years_to_exclude_rst_data, overwrite = TRUE)


### ADULT DATA -----------------------------------------------------------------
