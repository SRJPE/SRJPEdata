# Scripts to prepare data for model
# TODO decide if we want to source weekly data summaries in the prep_data_for_model.R script instead of caching data objects here
library(lubridate)
source("data-raw/pull_tables_from_database.R") # pulls in all standard datasets on GCP

# Catch Formatting --------------------------------------------------------------
# Rewrite script from catch pulled from JPE database
# Glimpse catch and chosen_site_years_to_model (prev known as stream_site_year_weeks_to_include.csv), now cached in vignettes/years_to_include_analysis.Rmd
catch |> glimpse()
chosen_site_years_to_model |> glimpse()

# add lifestage and yearling logic to catch table, filter to chinook 
standard_catch_unmarked <- catch |> 
  filter(species == "chinook") |>  # filter for only chinook
  mutate(month = month(date), # add to join with lad and yearling
         day = day(date)) |> 
  left_join(daily_yearling_ruleset) |> 
  # TODO decide if we want to documenat lifestage for model in yearling vignette as well or elsewhere. 
  mutate(is_yearling = case_when((fork_length <= cutoff & !run %in% c("fall","late fall", "winter")) ~ F,
                                 (fork_length > cutoff & !run %in% c("fall","late fall", "winter")) ~ T,
                                 (run %in% c("fall","late fall", "winter")) ~ NA,
                                 T ~ NA), 
         life_stage = case_when(fork_length > cutoff & !run %in% c("fall","late fall", "winter") ~ "yearling",
                               fork_length <= cutoff & fork_length > 45 & !run %in% c("fall","late fall", "winter") ~ "smolt",
                               fork_length > 45 & run %in% c("fall", "late fall", "winter", "not recorded") ~ "smolt",
                               fork_length > 45 & stream == "sacramento river" ~ "smolt",
                               fork_length <= 45 ~ "fry", # logic from flora includes week (all weeks but 7, 8, 9 had this threshold) but I am not sure this is necessary, worth talking through
                               T ~ NA)) |> 
  select(-species, -month, -day, -cutoff, -actual_count) |> 
  glimpse()


# FL-based lifestage logic ------------------------------------------------
# TODO consider making this a vignette, at the very least explain our assumptions in a vignette 

# add logic to assign lifestage_for_model 
# extrapolate lifestage for model for plus count fish/fish without fork lenghts based on weekly fl probabilities
# Create table with prob fry, smolt, and yearlings for each stream, site, week, year
weekly_lifestage_bins <- standard_catch_unmarked |> 
  filter(!is.na(fork_length), count != 0) |> 
  mutate(year = year(date), week = week(date)) |> 
  group_by(year, week, stream, site) |> 
  summarize(percent_fry = sum(life_stage == "fry")/n(),
            percent_smolt = sum(life_stage == "smolt")/n(),
            percent_yearling = sum(life_stage == "yearling")/n()) |> 
  ungroup() |> 
  glimpse() 

# Use when no FL data for a year 
proxy_weekly_fl <- standard_catch_unmarked |> 
  mutate(year = year(date), week = week(date)) |> 
  filter(!is.na(life_stage)) |> 
  group_by(week, stream) |> 
  summarize(percent_fry = sum(life_stage == "fry")/n(),
            percent_smolt = sum(life_stage == "smolt")/n(),
            percent_yearling = sum(life_stage == "yearling")/n()) |> 
  ungroup() |> 
  glimpse() 

# Years without FL data 
proxy_lifestage_bins_for_weeks_without_fl <- standard_catch_unmarked |> 
  group_by(year = year(date), week = week(date), stream, site) |> 
  summarise(fork_length = mean(fork_length, na.rm = TRUE)) |> 
  filter(is.na(fork_length)) |> 
  left_join(proxy_weekly_fl, by = c("week" = "week", "stream" = "stream")) |> 
  select(-fork_length) |> 
  glimpse() 

all_lifestage_bins <- bind_rows(weekly_lifestage_bins, proxy_lifestage_bins_for_weeks_without_fl)

# create table of all na values that need to be filled
na_filled_lifestage <- standard_catch_unmarked |> 
  mutate(week = week(date), year = year(date)) |> 
  filter(is.na(fork_length) & count > 0) |> 
  left_join(all_lifestage_bins, by = c("week" = "week", "year" = "year", "stream" = "stream", "site" = "site")) |> 
  mutate(fry = round(count * percent_fry), 
         smolt = round(count * percent_smolt), 
         yearling = round(count * percent_yearling)) |> 
  select(-life_stage, -count, -week, -year) |> # remove because all na, assigning in next line
  pivot_longer(fry:yearling, names_to = 'life_stage', values_to = 'count') |> 
  select(-c(percent_fry, percent_smolt, percent_yearling)) |>  
  filter(count != 0) |> # remove 0 values introduced when 0 prop of a lifestage, significantly decreases size of DF 
  mutate(model_lifestage_method = "assign count based on weekly distribution",
         week = week(date), 
         year = year(date)) |> 
  glimpse()

# add filled values back into combined_rst 
# first filter combined rst to exclude rows in na_to_fill
# total of 
combined_rst_wo_na_fl <- standard_catch_unmarked |> 
  mutate(week = week(date), year = year(date)) |> 
  filter(!is.na(fork_length)) |> 
  mutate(model_lifestage_method = "assigned from fl cutoffs") |> 
  glimpse()

# weeks we cannot predict lifestage
gap_weeks <- proxy_lifestage_bins_for_weeks_without_fl |> 
  filter(is.na(percent_fry) & is.na(percent_smolt) & is.na(percent_yearling)) |> 
  select(year, week, stream, site)

formatted_standard_catch <- standard_catch_unmarked |> 
  mutate(week = week(date), year = year(date)) |> glimpse()

weeks_wo_lifestage <- gap_weeks |> 
  left_join(formatted_standard_catch, by = c("year" = "year", "stream" = "stream", "week" = "week", "site" = "site")) |> 
  filter(!is.na(count), count > 0) |> 
  mutate(model_lifestage_method = "Not able to determine, no weekly fl data ever") |> 
  glimpse()

no_catch <- standard_catch_unmarked |> 
  mutate(week = week(date), year = year(date)) |>
  filter(is.na(fork_length) & count == 0)

# less rows now than in original, has to do with removing count != 0 in line 104, is there any reason not to do this?
updated_standard_catch <- bind_rows(combined_rst_wo_na_fl, na_filled_lifestage, no_catch, weeks_wo_lifestage) |> glimpse()

# Quick plot to check that we are not missing data 
updated_standard_catch |> 
  ggplot() + 
  geom_line(aes(x = date, y = count, color = site)) + facet_wrap(~stream, scales = "free")

### ----------------------------------------------------------------------------

# Filter to use includion criteria ---------------------------------------------
catch_with_inclusion_criteria <- updated_standard_catch |> 
  mutate(monitoring_year = ifelse(month(date) %in% 9:12, year(date) + 1, year(date))) |> 
  left_join(years_to_include) |> 
  mutate(include_in_model = ifelse(date >= min_date & date <= max_date, TRUE, FALSE),
         # if the year was not included in the list of years to include then should be FALSE
         include_in_model = ifelse(is.na(min_date), FALSE, include_in_model)) |> 
  select(-c(monitoring_year, min_date, max_date, year, week)) |> 
  glimpse()

# summarize by week -----------------------------------------------------------
weekly_standard_catch_unmarked <- catch_with_inclusion_criteria %>% 
  mutate(week = week(date),
         year = year(date)) %>% 
  group_by(week, year, stream, site, subsite, site_group, run, life_stage, adipose_clipped, include_in_model, is_yearling) %>% 
  summarize(mean_fork_length = mean(fork_length, na.rm = T),
            mean_weight = mean(weight, na.rm = T),
            count = sum(count)) %>% 
  ungroup() |> glimpse()

# TADA - catch is matching up 
# TODO Decide if we want to rename or save differently 
usethis::use_data(weekly_standard_catch_unmarked, overwrite = TRUE)


# Trap Formatting ---------------------------------------------------------
# Weekly effort from vignette/trap_effort.Rmd
weekly_effort |> glimpse()

# Catch & Effort ----------------------------------------------------------

# Join weekly effort data to weekly catch data
# there are a handful of cases where hours fished is NA. 
# weekly hours fished will be assumed to be 168 hours (24 hours * 7) as most
# traps fish continuously. Ideally these data points would be filled in, however,
# after extensive effort 54 still remain. It is unlikely that these datapoints
# will have a huge effect in such a large data set.
weekly_catch_effort <- left_join(weekly_standard_catch_unmarked, weekly_effort) |> 
  mutate(hours_fished = ifelse(is.na(hours_fished), 168, hours_fished))

usethis::use_data(weekly_catch_effort, overwrite = TRUE)
# Environmental -----------------------------------------------------------

# TODO pull flow_standard_format.Rmd into this repo as a vignette, clean up 
# # Source vignette 
weekly_flow <- standard_flow |> 
  mutate(week = week(date),
         year = year(date)) |> 
  group_by(week, year, stream, site, source) |> 
  summarize(mean_flow = mean(flow_cfs, na.rm = T)) |> glimpse()

# TODO pull temperature_standard_format.Rmd into this repo as a vignette, clean up 
# # Source vignette 
weekly_temperature <- standard_temperature |> 
  mutate(week = week(date),
         year = year(date)) |> 
  group_by(week, year, stream, site, subsite, source) |> 
  summarize(mean_temperature = mean(mean_daily_temp_c, na.rm = T)) |> glimpse()
# Trap with Catch --------------------------------------------------------------
# TODO is this used? NO remove for now - can add back in later 

# Efficiency Formatting ---------------------------------------------------------
# pulled in release_summary
glimpse(efficiency_summary)

# TODO add in flow and median fork length info (currently not in database)
weekly_efficiency <- efficiency_summary |> 
  group_by(stream, site, site_group, 
           week_released = day(date_released), 
           year_released = year(date_released)) |> 
  summarize(number_released = sum(number_released, na.rm = TRUE),
            number_recaptured = sum(number_recaptured, na.rm = TRUE)) |> 
  ungroup() |> 
  glimpse()

# TODO update to source this file and save direct model inputs instead 
usethis::use_data(weekly_efficiency, overwrite = TRUE)

