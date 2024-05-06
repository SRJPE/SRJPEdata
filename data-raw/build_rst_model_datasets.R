# Create data file for Run Size and Proportion Captured models.
# Assume that if trap was fished and no chinook caught, a value of u = 0 is in the input file
# and that if trap was not fished there is no record in file

# Scripts to prepare data for model
library(lubridate)
source("data-raw/pull_tables_from_database.R") # pulls in all standard datasets on GCP

# Catch Formatting --------------------------------------------------------------
# Rewrite script from catch pulled from JPE database
# Glimpse catch and chosen_site_years_to_model (prev known as stream_site_year_weeks_to_include.csv), now cached in vignettes/years_to_include_analysis.Rmd
rst_catch |> glimpse()
chosen_site_years_to_model |> glimpse()

# add lifestage and yearling logic to catch table, filter to chinook 
standard_catch_unmarked <- rst_catch |> 
  filter(species == "chinook") |>  # filter for only chinook
  mutate(month = month(date), # add to join with lad and yearling
         day = day(date)) |> 
  left_join(daily_yearling_ruleset) |> 
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
  filter(include_in_model) |> 
  select(-c(monitoring_year, min_date, max_date, year, week, include_in_model)) |>
  glimpse()

# summarize by week -----------------------------------------------------------
# Removed lifestage and yearling for now - can add back in but do not need for btspasx model input so removing
weekly_standard_catch_no_zeros <- catch_with_inclusion_criteria |> 
  mutate(week = week(date),
         year = year(date)) |> 
  group_by(week, year, stream, site, site_group, life_stage) %>% #removed run & adclip here 
  summarize(mean_fork_length = mean(fork_length, na.rm = T),
            mean_weight = mean(weight, na.rm = T),
            count = sum(count, na.rm = T))  |>  
  filter(count > 0) |> 
  mutate(site_year_week = paste0(site, "_", year, "_", week)) |> 
  ungroup() |> glimpse()

catch_site_year_weeks <- unique(weekly_standard_catch_no_zeros$site_year_week)

weekly_standard_catch_zeros <- catch_with_inclusion_criteria |> 
  mutate(week = week(date),
         year = year(date)) |> 
  group_by(week, year, stream, site, site_group, life_stage) %>% #removed run & adclip here  
  summarize(mean_fork_length = mean(fork_length, na.rm = T),
            mean_weight = mean(weight, na.rm = T),
            count = sum(count, na.rm = T))  |>  
  filter(count == 0) |> 
  mutate(site_year_week = paste0(site, "_", year, "_", week)) |> 
  filter(!site_year_week %in% catch_site_year_weeks) |> 
  glimpse()

weekly_standard_catch <- bind_rows(weekly_standard_catch_no_zeros, 
                                   weekly_standard_catch_zeros) |> glimpse()

# Add hatchery column 
hatch_per_week <- catch_with_inclusion_criteria |> 
  filter(adipose_clipped == TRUE) |> 
  mutate(week = week(date),
         year = year(date)) |> 
  group_by(week, year, stream, site, site_group, life_stage) |> 
  summarize(count = sum(count, na.rm = TRUE)) |> 
  ungroup() |> 
  mutate(expanded_weekly_hatch_count = ifelse(stream == "feather river", 
                                              count, 
                                              count * 4)) |> #ASSUMING 25% marking, add mark rates in here instead.
  select(-count) |> 
  glimpse()

# subtract these values from weekly_standard_catch 
weekly_standard_catch_with_hatch_designation <- weekly_standard_catch |> 
  left_join(hatch_per_week, 
            by = c("week", "year", "stream", "site", "site_group", "life_stage")) |> 
  mutate(expanded_weekly_hatch_count = ifelse(is.na(expanded_weekly_hatch_count), 0, expanded_weekly_hatch_count),
         natural = ifelse(count - expanded_weekly_hatch_count < 0, 0, count - expanded_weekly_hatch_count), 
         hatchery = ifelse(expanded_weekly_hatch_count > count, count, expanded_weekly_hatch_count)) |> 
  select(-count, -expanded_weekly_hatch_count) |>  
  pivot_longer(natural:hatchery, names_to = "origin", values_to = "count") |> 
  glimpse()


# TODO Create PLAD table - Ashley going to check what she sent nobel 
# Erin can add! In prep data for model - in JPE datasets 
# FL bins for year, week, stream, site 
# Bins need to match PLAD bins (or finer) so we can map
# Think through how hatchery would play in here  

# Trap Formatting ---------------------------------------------------------
# Weekly effort from vignette/trap_effort.Rmd
weekly_effort_by_site <- weekly_effort |> 
  group_by(week, year, stream, site, site_group) %>% 
  summarize(hours_fished = mean(hours_fished, na.rm = TRUE)) |> 
  ungroup()

# Catch & Effort ----------------------------------------------------------

# Join weekly effort data to weekly catch data
# there are a handful of cases where hours fished is NA. 
# weekly hours fished will be assumed to be 168 hours (24 hours * 7) as most
# traps fish continuously. Ideally these data points would be filled in, however,
# after extensive effort 54 still remain. It is unlikely that these datapoints
# will have a huge effect in such a large data set.
weekly_catch_effort <- left_join(weekly_standard_catch_unmarked, weekly_effort) |> 
  mutate(hours_fished = ifelse(is.na(hours_fished), 168, hours_fished))

# Environmental -----------------------------------------------------------
source("data-raw/pull_environmental_data.R")

# update site lookup so joins to env data better
lookup_updated_site_group <- site_lookup |>
  mutate(site_group = ifelse(site_group %in% 
                               c("upper feather lfc","upper feather hfc","lower feather river"),
                             site_group, NA))

env_with_sites <- environmental_data |> 
  left_join(lookup_updated_site_group)  |> glimpse()

weekly_flow <- env_with_sites |> 
  filter(parameter == "flow",
         statistic == "mean") |> 
  mutate(week = week(date),
         year = year(date)) |> 
  group_by(week, year, stream, site, site_group, gage_agency, gage_number) |> 
  summarize(mean_flow = mean(value, na.rm = T)) |> glimpse()

weekly_temperature <- env_with_sites |> 
  filter(parameter == "temperature",
         statistic == "mean")  |> 
  mutate(week = week(date),
         year = year(date)) |> 
  group_by(week, year, stream, site, site_group, gage_agency, gage_number) |> 
  summarize(mean_temperature = mean(value, na.rm = T)) |> glimpse()

# Efficiency Formatting ---------------------------------------------------------
# pulled in release_summary
glimpse(efficiency_summary)

weekly_efficiency <- efficiency_summary |> 
  group_by(stream, site, site_group, 
           week_released = day(date_released), 
           year_released = year(date_released)) |> 
  summarize(number_released = sum(number_released, na.rm = TRUE),
            number_recaptured = sum(number_recaptured, na.rm = TRUE)) |> 
  ungroup() |> 
  glimpse()

weekly_standard_catch_unmarked  |> glimpse()
weekly_efficiency |> glimpse()

# reformat flow data and summarize weekly
# TODO 32 NAs, fill in somehow  
flow_reformatted <- env_with_sites |> 
  filter(parameter == "flow",
         statistic == "mean") |> 
  mutate(year = year(date),
         week = week(date)) |> 
  group_by(year, week, site, stream, gage_agency, gage_number) |> 
  summarise(flow_cfs = mean(value, na.rm = T)) |> 
  glimpse()

weekly_efficiency |> glimpse()

weekly_effort_by_site |> glimpse()

catch_reformatted <- weekly_standard_catch |>  glimpse()

# Combine all 3 tables together 
weekly_model_data_wo_efficiency_flows <- catch_reformatted |> 
  left_join(weekly_effort_by_site, by = c("year", "week", "stream", "site")) |> 
  # Join efficnecy data to catch data
  left_join(weekly_efficiency, 
            by = c("week" = "week_released",
                   "year" = "year_released", "stream", 
                   "site")) |> 
  # join flow data to dataset
  left_join(flow_reformatted, by = c("week", "year", "site", "stream")) |> 
  # select columns that josh uses 
  select(year, week, stream, site, count, mean_fork_length, 
         number_released, number_recaptured, hours_fished, 
         flow_cfs, life_stage) |> 
  group_by(stream) |> 
  mutate(average_stream_hours_fished = mean(hours_fished, na.rm = TRUE),
         standardized_flow = as.vector(scale(flow_cfs))) |> # standardizes and centers see ?scale
  ungroup() |> 
  mutate(run_year = ifelse(week >= 45, year + 1, year),
         catch_standardized_by_hours_fished = ifelse(is.na(hours_fished), count, round(count * average_stream_hours_fished / hours_fished, 0))) |> 
  glimpse()

# Add in standardized efficiency flows 
mainstem_standardized_efficiency_flows <- weekly_model_data_wo_efficiency_flows |>
  filter(site %in% c("knights landing", "tisdale", "red bluff diversion dam"),
         !is.na(flow_cfs), 
         !is.na(number_released),
         !is.na(number_recaptured)) |>
  group_by(stream) |>
  mutate(standardized_efficiency_flow = (flow_cfs - mean(flow_cfs, na.rm = T)) / 
           sd(flow_cfs, na.rm = T)) |> 
  select(year, week, stream, site, standardized_efficiency_flow)

tributary_standardized_efficiency_flows <- weekly_model_data_wo_efficiency_flows |>
  filter(!site %in% c("knights landing", "tisdale", "red bluff diversion dam"),
         !is.na(flow_cfs),
         !is.na(number_released),
         !is.na(number_recaptured)) |>
  group_by(stream) |>
  mutate(standardized_efficiency_flow = (flow_cfs - mean(flow_cfs, na.rm = T)) / 
           sd(flow_cfs, na.rm = T)) |> 
  select(year, week, stream, site, standardized_efficiency_flow)

efficiency_standard_flows <- bind_rows(mainstem_standardized_efficiency_flows, 
                                       tributary_standardized_efficiency_flows) |> 
  distinct()

weekly_model_data_with_eff_flows <- weekly_model_data_wo_efficiency_flows |> 
  left_join(efficiency_standard_flows, by = c("year", "week", "stream", "site"))

# ADD special priors data in 
btspasx_special_priors_data <- read.csv(here::here("data-raw", "helper-tables", "Special_Priors.csv")) |>
  mutate(site = ifelse(Stream_Site == "battle creek_ubc", "ubc", NA)) |>
  select(site, run_year = RunYr, week = Jweek, special_prior = lgN_max)

# JOIN special priors with weekly model data
# first, assign special prior (if relevant), else set to default, then fill in for weeks without catch
weekly_juvenile_abundance_model_data <- weekly_model_data_with_eff_flows |>
  left_join(btspasx_special_priors_data, by = c("run_year", "week", "site")) |>
  mutate(lgN_prior = ifelse(!is.na(special_prior), special_prior, log((count / 1000) + 1) / 0.025)) |> # maximum possible value for log N across strata
  select(-special_prior)


# TODO data checks 
# Why does battle start in 2007 - did we intentionally leave early years out of database 
usethis::use_data(weekly_juvenile_abundance_model_data, overwrite = TRUE)

weekly_juvenile_abundance_model_data |> filter(site == "ubc", year == 2009, week == 4) 
