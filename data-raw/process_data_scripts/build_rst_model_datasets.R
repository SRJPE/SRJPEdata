# Create data file for Run Size and Proportion Captured models.
# Assume that if trap was fished and no chinook caught, a value of u = 0 is in the input file
# and that if trap was not fished there is no record in file
library(SRJPEdata)
library(lubridate)
library(tidyverse)
library(data.table)

# Catch Formatting --------------------------------------------------------------
# Rewrite script from catch pulled from JPE database
# Glimpse catch and chosen_site_years_to_model (prev known as stream_site_year_weeks_to_include.csv), now cached in vignettes/years_to_include_analysis.Rmd
SRJPEdata::rst_catch |> glimpse()
#updated_standard_catch |> glimpse() #if not loaded run lifestage_ruleset.Rmd vignette 
years_to_include_rst_data <- years_to_include_rst_data |> # if not loaded run years_to_include_analysis.Rmd vignette
  mutate(include = T)
# Remove all adipose clipped fish - we do not want to include hatchery fish
updated_standard_catch <- rst_catch |> 
  mutate(remove = case_when(stream != "butte creek" & adipose_clipped == T ~ "remove",
                            T ~ "keep")) |> 
  filter(remove == "keep") |> 
  select(-remove)
# For the BTSPAS model we need to include all weeks that were not sampled. The code
# below sets up a table of all weeks (based on min sampling year and max sampling year)
# This is joined at the end
rst_all_weeks <- rst_catch |> 
  group_by(stream, site, subsite) |> 
  summarise(min = min(date, na.rm = T),
            max = max(date, na.rm = T)) |> 
  mutate(min = paste0(year(min),"-01-01"),
         max = paste0(year(max),"-12-31")) |> 
  pivot_longer(cols = c(min, max), values_to = "date") |> 
  mutate(date = as_date(date)) |> 
  select(-name) |> 
  padr::pad(interval = "day", group = c("stream", "site")) |> 
  mutate(week = week(date),
         year = year(date)) |> 
  distinct(stream, site, year, week) |> 
  cross_join(tibble(life_stage = c("fry","smolt","yearling"))) |> 
  mutate(run_year = ifelse(week >= 45, year + 1, year)) |> 
  left_join(years_to_include_rst_data) |> # need to make sure to filter out years that have been excluded
  filter(include == T) |> 
  select(-include) |> 
  filter(run_year != 2025) # TODO remove once we want to include 2025 data

# Add is_yearling and lifestage from the lifestage_ruleset.Rmd vignette
### ----------------------------------------------------------------------------

# Filter to use inclusion criteria ---------------------------------------------

# Converted to data.table for performance reasons
# Convert your data.frames to data.tables (if not already in data.table format)
updated_standard_catch <- as.data.table(updated_standard_catch) 
years_to_include_rst_data <- as.data.table(years_to_include_rst_data)

# Step-by-step translation of the dplyr code
catch_with_inclusion_criteria <- updated_standard_catch[
  # Step 1: Create monitoring_year
  , run_year := ifelse(week(date) >= 45, year(date) + 1, year(date))
][
  # Step 2: Perform the left join with chosen_site_years_to_model
  years_to_include_rst_data, on = .(run_year, stream, site), nomatch = 0
][
  # Step 3: Filter rows where include_in_model is TRUE
  include == TRUE
][
  # Step 4: Select and remove columns (similar to select in dplyr)
  , !c("run_year", "include")
]


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

weekly_standard_catch_zeros <- catch_with_inclusion_criteria |> 
  mutate(week = week(date),
         year = year(date)) |> 
  group_by(week, year, stream, site, site_group, life_stage) %>% #removed run & adclip here  
  summarize(mean_fork_length = mean(fork_length, na.rm = T),
            mean_weight = mean(weight, na.rm = T),
            count = sum(count, na.rm = T))  |>  
  filter(count == 0) |> 
  mutate(site_year_week = paste0(site, "_", year, "_", week)) |> 
  glimpse()

weekly_standard_catch <- bind_rows(weekly_standard_catch_no_zeros, 
                                   weekly_standard_catch_zeros) |> glimpse()

# Add hatchery column 
# Currently not included in josh model data but can be added by changing join on 
# line 176 below
# we are not handling hatchery rates in the data processing, instead assuming it 
# can be handled by PLAD
# hatch_per_week <- catch_with_inclusion_criteria |> 
#   filter(adipose_clipped == TRUE) |> 
#   mutate(week = week(date),
#          year = year(date)) |> 
#   group_by(week, year, stream, site, site_group, life_stage) |> 
#   summarize(count = sum(count, na.rm = TRUE)) |> 
#   ungroup() |> 
#   mutate(expanded_weekly_hatch_count = ifelse(stream == "feather river", 
#                                               count, 
#                                               count * 4)) |> #ASSUMING 25% marking, add mark rates in here instead.
#   select(-count) |> 
#   glimpse()

# subtract these values from weekly_standard_catch 
# weekly_standard_catch_with_hatch_designation <- weekly_standard_catch |> 
#   left_join(hatch_per_week, 
#             by = c("week", "year", "stream", "site", "site_group", "life_stage")) |> 
#   mutate(expanded_weekly_hatch_count = ifelse(is.na(expanded_weekly_hatch_count), 0, expanded_weekly_hatch_count),
#          natural = ifelse(count - expanded_weekly_hatch_count < 0, 0, count - expanded_weekly_hatch_count), 
#          hatchery = ifelse(expanded_weekly_hatch_count > count, count, expanded_weekly_hatch_count)) |> 
#   select(-count, -expanded_weekly_hatch_count) |>  
#   pivot_longer(natural:hatchery, names_to = "origin", values_to = "count") |> 
#   glimpse()


# TODO Create PLAD table - Ashley going to check what she sent nobel 
# Erin can add! In prep data for model - in JPE datasets 
# FL bins for year, week, stream, site 
# Bins need to match PLAD bins (or finer) so we can map
# Think through how hatchery would play in here  

# Trap Formatting ---------------------------------------------------------
# Weekly effort from vignette/trap_effort.Rmd
weekly_effort_by_site <- weekly_hours_fished |> 
  group_by(week, year, stream, site, site_group) %>% 
  summarize(hours_fished = mean(hours_fished, na.rm = TRUE)) |> 
  ungroup()

# Environmental -----------------------------------------------------------
env_with_sites <- environmental_data |> 
  left_join(site_lookup, relationship = "many-to-many") |> # Confirmed that many to many makes sense, added relationship to silence warning
  glimpse()
# 
# weekly_flow <- env_with_sites |> 
#   filter(parameter == "flow",
#          statistic == "mean") |> 
#   mutate(week = week(date),
#          year = year(date)) |> 
#   group_by(week, year, stream, site, site_group, gage_agency, gage_number) |> 
#   summarize(mean_flow = mean(value, na.rm = T)) |> glimpse()

# Convert env_with_sites to a data.table (if not already one)
env_with_sites <- as.data.table(env_with_sites)

# Filter, mutate, and summarize using data.table syntax
weekly_flow <- env_with_sites |> filter(parameter == "flow")

# weekly_temperature <- env_with_sites |> 
#   filter(parameter == "temperature",
#          statistic == "mean")  |> 
#   mutate(week = week(date),
#          year = year(date)) |> 
#   group_by(week, year, stream, site, site_group, gage_agency, gage_number) |> 
#   summarize(mean_temperature = mean(value, na.rm = T)) |> glimpse()

# Note I don't think we are currently using temperature
weekly_temperature <- env_with_sites |> filter(parameter == "temperature")

# Efficiency Formatting ---------------------------------------------------------
# pulled in release_summary
# this dataset will be saved separately to retain the fork length and origin variables
weekly_efficiency <- 
  left_join(release, 
            recaptures |> # need to summarize first so you don't get duplicated release data when joining
              group_by(release_id, stream, site, site_group) |> 
              summarize(count = sum(count, na.rm = T)),
            by = c("release_id", "stream", "site", "site_group")) |> 
  group_by(stream, 
           site, 
           site_group, 
           #origin,
           #median_fork_length_released, # we add origin and fork length for figures
           week_released = week(date_released), 
           year_released = year(date_released)) |> 
  summarize(number_released = sum(number_released, na.rm = TRUE),
            number_recaptured = sum(count, na.rm = TRUE)) |> 
  ungroup() |> 
  #rename(origin_released = origin) |> 
  glimpse()

# reformat flow data and summarize weekly
flow_reformatted_raw <- rst_all_weeks |> # we want flows for all weeks, even if missing samples
  left_join(
  env_with_sites |> 
  filter(parameter == "flow",
         statistic == "mean") |> 
  group_by(year, week, site, stream, gage_agency, gage_number) |> 
  summarise(flow_cfs = mean(value, na.rm = T)))
# To fill in NAs, find the average weekly flow across years
mean_flow_across_years <- flow_reformatted_raw |> 
  group_by(week, site, stream) |> 
  summarize(mean_flow_for_data_gaps = mean(flow_cfs, na.rm = T))

flow_reformatted <- flow_reformatted_raw |> 
  left_join(mean_flow_across_years) |> 
  mutate(flow_cfs = ifelse(is.na(flow_cfs), mean_flow_for_data_gaps, flow_cfs)) |> 
  select(-mean_flow_for_data_gaps)

# Combine catch (weekly_standard_catch), weekly efficiency, and weekly effort by site 
weekly_efficiency |> glimpse()

weekly_effort_by_site |> glimpse()

# TODO do we want to use the weekly_standard_catch_with_hatch_designation instead
catch_reformatted <- weekly_standard_catch |>  glimpse()

# Combine all 3 tables together 
weekly_model_data_wo_efficiency_flows <- catch_reformatted |> 
  left_join(weekly_effort_by_site, by = c("year", "week", "stream", "site")) |> 
  # Join efficnecy data to catch data
  left_join(weekly_efficiency |> 
              group_by(week_released, year_released, stream, site) |> # we added in origin and fork length for post hoc figures but for the model data need to remove
              summarize(number_released = sum(number_released),
                        number_recaptured = sum(number_recaptured)), 
            by = c("week" = "week_released",
                   "year" = "year_released", "stream", 
                   "site")) |> 
  # join flow data to dataset, full_join because we want to keep flow even for missing weeks
  full_join(flow_reformatted, by = c("week", "year", "site", "stream", "life_stage")) |> 
  # select columns that josh uses 
  select(year, week, stream, site, count, mean_fork_length, 
         number_released, number_recaptured,
         hours_fished, 
         flow_cfs, life_stage) |> 
  group_by(stream) |> 
  mutate(average_stream_hours_fished = mean(hours_fished, na.rm = TRUE),
         standardized_flow = as.vector(scale(flow_cfs))) |> # standardizes and centers see ?scale
  ungroup() |> 
  mutate(run_year = ifelse(week >= 45, year + 1, year),
         catch_standardized_by_hours_fished = ifelse((hours_fished == 0 | is.na(hours_fished)), count, round(count * average_stream_hours_fished / hours_fished, 0)),
         hours_fished = ifelse((hours_fished == 0 | is.na(hours_fished)) & count >= 0, average_stream_hours_fished, hours_fished),
         hours_fished = ifelse(is.na(count), 0, hours_fished) # adds 0 hours fished for padded weeks with NA catch
         ) |> # add logic for situations where trap data is missing
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
  mutate(site = sub(".*_", "", Stream_Site)) |>
  select(site, run_year = RunYr, week = Jweek, special_prior = lgN_max) |> glimpse()

# JOIN special priors with weekly model data
# first, assign special prior (if relevant), else set to default, then fill in for weeks without catch
weekly_juvenile_abundance_model_data_raw <- weekly_model_data_with_eff_flows |>
  left_join(btspasx_special_priors_data, by = c("run_year", "week", "site")) |>
  mutate(lgN_prior = ifelse(!is.na(special_prior), special_prior, log(((count / 1000) + 1) / 0.025))) |> # maximum possible value for log N across strata
  select(-special_prior) |> 
  full_join(rst_all_weeks)

# when we join rst_all_weeks we end up with some run years that have all NA sampling
# these should be removed
remove_run_year <- weekly_juvenile_abundance_model_data_raw |> 
  mutate(count2 = ifelse(is.na(count), 0, 1)) |> 
  group_by(run_year, stream, site, count2) |> 
  tally() |> 
  pivot_wider(names_from = count2, values_from = n) |> 
  filter(`0` > 0 & is.na(`1`)) |> # filter for run_years where count is only NA
  select(-c(`0`,`1`)) |> 
  mutate(remove = T)

weekly_juvenile_abundance_model_data <- weekly_juvenile_abundance_model_data_raw |> 
  left_join(remove_run_year) |> 
  mutate(remove = ifelse(is.na(remove), F, remove)) |> 
  filter(remove == F) |> 
  select(-remove) 

# filter to only include complete season data 
if (month(Sys.Date()) %in% c(9:12, 1:5)) {
  weekly_juvenile_abundance_model_data <- weekly_juvenile_abundance_model_data |> 
    filter(run_year <= year(Sys.Date()))
}

tryCatch({
  site <- weekly_juvenile_abundance_model_data$site |> unique()
  check_for_full_season <- function(selected_site) {
    filtered_data <- weekly_juvenile_abundance_model_data |> 
      filter(site == selected_site)
    max_year <- max(filtered_data$run_year)
    max_week <- filtered_data |> 
      filter(run_year == max_year, week < 45) |> 
      pull(week) |> 
      max()
    if (max_week < 20) {
      warning(paste("The data for", selected_site, "in", max_year, "only goes to week", max_week, "and should not be used as a full season."))
    } 
  }
  # map through sites purrr::map(site, check_for_full_season) |> reduce(append)
})

# Split up into 2 data objects, efficiency, and catch 
# Catch 
weekly_juvenile_abundance_catch_data <- weekly_juvenile_abundance_model_data |> 
  select(-c(number_released, number_recaptured, standardized_efficiency_flow))

# Efficiency
weekly_juvenile_abundance_efficiency_data <- weekly_juvenile_abundance_model_data |> 
  select(year, run_year, week, stream, site, number_released, number_recaptured, standardized_efficiency_flow, flow_cfs) |> 
  filter(!is.na(number_released) & !is.na(number_recaptured)) |> 
  distinct(site, run_year, week, number_released, number_recaptured, .keep_all = TRUE)

# write to package 
usethis::use_data(weekly_juvenile_abundance_catch_data, overwrite = TRUE) 
usethis::use_data(weekly_juvenile_abundance_efficiency_data, overwrite = TRUE)
usethis::use_data(weekly_efficiency, overwrite = TRUE) 
