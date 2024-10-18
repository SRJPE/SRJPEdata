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
updated_standard_catch |> glimpse() #if not loaded run lifestage_ruleset.Rmd vignette 
chosen_site_years_to_model |> glimpse() 
# Note: updated below years_to_include to chosen_site_years_to_model (this is more up to date version)
# TODO however, years_to_include included a subsite (CONFIRM that we do not need subsite), after discussing, delete old version

# Add is_yearling and lifestage from the lifestage_ruleset.Rmd vignette

### ----------------------------------------------------------------------------

# Filter to use inclusion criteria ---------------------------------------------
# TODO this is the slowest block...
# catch_with_inclusion_criteria <- updated_standard_catch |> 
#   mutate(monitoring_year = ifelse(month(date) %in% 9:12, year(date) + 1, year(date))) |> 
#   left_join(chosen_site_years_to_model) |> 
#   mutate(include_in_model = ifelse(date >= min_date & date <= max_date, TRUE, FALSE),
#          # if the year was not included in the list of years to include then should be FALSE
#          include_in_model = ifelse(is.na(min_date), FALSE, include_in_model)) |> 
#   filter(include_in_model) |> 
#   select(-c(monitoring_year, min_date, max_date, year, week, include_in_model)) |>
#   glimpse()

# Converted to data.table for performance reasons
# Convert your data.frames to data.tables (if not already in data.table format)
updated_standard_catch <- as.data.table(updated_standard_catch)
chosen_site_years_to_model <- as.data.table(chosen_site_years_to_model)

# Step-by-step translation of the dplyr code
catch_with_inclusion_criteria <- updated_standard_catch[
  # Step 1: Create monitoring_year
  , monitoring_year := ifelse(month(date) %in% 9:12, year(date) + 1, year(date))
][
  # Step 2: Perform the left join with chosen_site_years_to_model
  chosen_site_years_to_model, on = .(monitoring_year, stream, site, site_group), nomatch = 0
][
  # Step 3: Mutate include_in_model column based on conditions
  , include_in_model := ifelse(date >= min_date & date <= max_date, TRUE, FALSE)
][
  # Step 4: Adjust include_in_model for missing min_date
  , include_in_model := ifelse(is.na(min_date), FALSE, include_in_model)
][
  # Step 5: Filter rows where include_in_model is TRUE
  include_in_model == TRUE
][
  # Step 6: Select and remove columns (similar to select in dplyr)
  , !c("monitoring_year", "min_date", "max_date", "year", "week", "include_in_model")
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
# Currently not included in josh model data but can be added by changing join on 
# line 176 below
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

weekly_temperature <- env_with_sites |> filter(parameter == "temperature")

# Efficiency Formatting ---------------------------------------------------------
# pulled in release_summary
weekly_efficiency <- 
  left_join(release, 
            recaptures |> # need to summarize first so you don't get duplicated release data when joining
              group_by(release_id, stream, site, site_group) |> 
              summarize(count = sum(count, na.rm = T)),
            by = c("release_id", "stream", "site", "site_group")) |> 
  group_by(stream, 
           site, 
           site_group, 
           week_released = week(date_released), 
           year_released = year(date_released)) |> 
  summarize(number_released = sum(number_released, na.rm = TRUE),
            number_recaptured = sum(count, na.rm = TRUE)) |> 
  ungroup() |> 
  glimpse()

weekly_efficiency |> glimpse()

# reformat flow data and summarize weekly
# TODO 32 NAs, fill in somehow  
flow_reformatted <- env_with_sites |> 
  filter(parameter == "flow",
         statistic == "mean") |> 
  group_by(year, week, site, stream, gage_agency, gage_number) |> 
  summarise(flow_cfs = mean(value, na.rm = T)) |> 
  glimpse()

# Combine catch (weekly_standard_catch), weekly efficiency, and weekly effort by site 
weekly_efficiency |> glimpse()

weekly_effort_by_site |> glimpse()

# TODO do we want to use the weekly_standard_catch_with_hatch_designation instead
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
  mutate(site = sub(".*_", "", Stream_Site)) |>
  select(site, run_year = RunYr, week = Jweek, special_prior = lgN_max) |> glimpse()

# JOIN special priors with weekly model data
# first, assign special prior (if relevant), else set to default, then fill in for weeks without catch
weekly_juvenile_abundance_model_data <- weekly_model_data_with_eff_flows |>
  left_join(btspasx_special_priors_data, by = c("run_year", "week", "site")) |>
  mutate(lgN_prior = ifelse(!is.na(special_prior), special_prior, log(((count / 1000) + 1) / 0.025))) |> # maximum possible value for log N across strata
  select(-special_prior)

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
  # map through sites
  purrr::map(site, check_for_full_season) |> reduce(append)
})

# Split up into 2 data objects, efficiency, and catch 
# Catch 
weekly_juvenile_abundance_catch_data <- weekly_juvenile_abundance_model_data |> 
  select(-c(number_released, number_recaptured, standardized_efficiency_flow))

# Efficiency
weekly_juvenile_abundance_efficiency_data <- weekly_juvenile_abundance_model_data |> 
  select(year, run_year, week, stream, site, number_released, number_recaptured, standardized_efficiency_flow) |> 
  filter(!is.na(number_released) & !is.na(number_recaptured)) |> 
  distinct(site, run_year, week, number_released, number_recaptured, .keep_all = TRUE)

# write to package 
usethis::use_data(weekly_juvenile_abundance_catch_data, overwrite = TRUE)
usethis::use_data(weekly_juvenile_abundance_efficiency_data, overwrite = TRUE)
