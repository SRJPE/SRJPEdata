# Create data file for Run Size and Proportion Captured models.
# Assume that if trap was fished and no chinook caught, a value of u = 0 is in the input file
# and that if trap was not fished there is no record in file
library(SRJPEdata)
library(lubridate)
library(tidyverse)

# Catch Formatting --------------------------------------------------------------
# Rewrite script from catch pulled from JPE database
# Glimpse catch and chosen_site_years_to_model (prev known as stream_site_year_weeks_to_include.csv), now cached in vignettes/years_to_include_analysis.Rmd
SRJPEdata::rst_catch |> glimpse()
years_to_include_rst_data <- years_to_include_rst_data |> # if not loaded run years_to_include_analysis.Rmd vignette
  mutate(include = T)
yearling_ruleset <- SRJPEdata::daily_yearling_ruleset
# Remove all adipose clipped fish - we do not want to include hatchery fish
# Remove yearling fish - we do not want to include yearlings
updated_standard_catch_raw <- SRJPEdata::rst_catch |> 
  mutate(remove = case_when(stream != "butte creek" & adipose_clipped == T ~ "remove",
                            T ~ "keep"),
         run = tolower(run),
         day = day(date),
         month = month(date)) |> 
  filter(remove == "keep") |> 
  left_join(yearling_ruleset) |> 
  mutate(life_stage = case_when(fork_length > cutoff & 
                                  (run %in% c("spring", "not recorded", "unknown", "mixed") | is.na(run)) ~ "yearling",
                                T ~ "young of the year"))

# save separately so easy to tell which yearlings being removed
updated_standard_catch <- updated_standard_catch_raw |> # all NA fork length would be assumed YOY
  filter(life_stage == "young of the year") |> 
  select(-c(remove, life_stage, day, month, cutoff))

# yearlings_removed <- filter(updated_standard_catch_raw, life_stage == "yearling")
# write_csv(yearlings_removed, "data-raw/data-checks/stream_team_review/yearlings_removed.csv")

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
  #cross_join(tibble(life_stage = c("fry","smolt","yearling"))) |> 
  mutate(run_year = ifelse(week >= 45, year + 1, year)) |> 
  left_join(years_to_include_rst_data) |> # need to make sure to filter out years that have been excluded
  filter(include == T) |> 
  select(-include)

# Add is_yearling and lifestage from the lifestage_ruleset.Rmd vignette
### ----------------------------------------------------------------------------

# Filter to use inclusion criteria ---------------------------------------------

catch_with_inclusion_criteria <- updated_standard_catch |> 
  mutate(run_year = ifelse(week(date) >= 45, year(date) + 1, year(date))) |> 
  left_join(years_to_include_rst_data) |> 
  filter(include == T)

# summarize by week -----------------------------------------------------------
# Removed lifestage and yearling for now - can add back in but do not need for btspasx model input so removing
weekly_standard_catch <- catch_with_inclusion_criteria |> 
  mutate(week = week(date),
         year = year(date)) |> 
  group_by(stream, site, site_group, week, year) %>% 
  summarize(mean_fork_length = mean(fork_length, na.rm = T),
            mean_weight = mean(weight, na.rm = T),
            count = sum(count, na.rm = T))  |>  
  mutate(site_year_week = paste0(site, "_", year, "_", week)) |> 
  ungroup() |> glimpse()

# Trap Formatting ---------------------------------------------------------
# Weekly effort from vignette/trap_effort.Rmd
weekly_effort_by_site <- weekly_hours_fished |> 
  group_by(stream, site, site_group, week, year) %>% 
  summarize(hours_fished = sum(hours_fished, na.rm = TRUE)) |> # weekly data is at the subsite level, we need to add together the subsites
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

# Josh needs origin released but need to summarize it by week
weekly_origin <- 
  left_join(release, 
            recaptures |> # need to summarize first so you don't get duplicated release data when joining
              group_by(stream, site, release_id) |> 
              summarize(count = sum(count, na.rm = T)),
            by = c("release_id", "stream", "site")) |> 
  mutate(week_released = week(date_released), 
        year_released = year(date_released),
        hatchery = ifelse(origin_released == "hatchery", 1, 0),
        natural = ifelse(origin_released == "natural", 1, 0),
        mixed = ifelse(origin_released == "mixed", 1, 0)) |> 
  select(stream, site, week_released, year_released, hatchery, natural, mixed) |> 
  group_by(stream, site, week_released, year_released) |> 
  summarize(hatchery = sum(hatchery),
            natural = sum(natural),
            mixed = sum(mixed)) |> 
  mutate(origin_released = case_when(mixed > 0 ~ "mixed",
                                     hatchery == 0 & natural == 0 & mixed == 0 ~ NA,
                                     hatchery > 0 & natural == 0 & mixed == 0 ~ "hatchery",
                                     natural > 0 & hatchery == 0 & mixed == 0 ~ "natural",
                                     is.na(hatchery) & is.na(natural) & is.na(mixed) ~ NA,
                                     T ~ "mixed")) |> 
  select(stream, site, week_released, year_released, origin_released)

weekly_efficiency <- 
  left_join(release, 
            recaptures |> # need to summarize first so you don't get duplicated release data when joining
              group_by(stream, site, site_group, release_id) |> 
              summarize(count = sum(count, na.rm = T)),
            by = c("release_id", "stream", "site", "site_group")) |> 
  group_by(stream, 
           site, 
           site_group, 
           week_released = week(date_released), 
           year_released = year(date_released)) |> 
  summarize(number_released = sum(number_released, na.rm = TRUE),
            number_recaptured = sum(count, na.rm = TRUE),
            median_fork_length_released = median(median_fork_length_released, na.rm = T)) |> 
  ungroup() |> 
  left_join(weekly_origin) |> 
  glimpse()

# reformat flow data and summarize weekly
flow_reformatted_raw <- rst_all_weeks |> # we want flows for all weeks, even if missing samples
  left_join(
  env_with_sites |> 
  filter(parameter == "flow",
         statistic == "mean") |> 
  group_by(stream, site, week, year, gage_agency, gage_number) |> 
  summarise(flow_cfs = mean(value, na.rm = T)))
# To fill in NAs, find the average weekly flow across years
mean_flow_across_years <- flow_reformatted_raw |> 
  group_by(stream, site, week) |> 
  summarize(mean_flow_for_data_gaps = mean(flow_cfs, na.rm = T))

flow_reformatted <- flow_reformatted_raw |> 
  left_join(mean_flow_across_years) |> 
  mutate(flow_cfs = ifelse(is.na(flow_cfs), mean_flow_for_data_gaps, flow_cfs)) |> 
  select(-mean_flow_for_data_gaps)

# Combine all 3 tables together 
weekly_model_data_wo_efficiency_flows <- weekly_standard_catch |> 
  left_join(weekly_effort_by_site, by = c("stream", "site", "week","year")) |> 
  # Join efficnecy data to catch data
  left_join(weekly_efficiency |> 
              group_by(week_released, year_released, stream, site) |> # we added in origin and fork length for post hoc figures but for the model data need to remove
              summarize(number_released = sum(number_released),
                        number_recaptured = sum(number_recaptured)), 
            by = c("stream", 
                   "site",
                   "week" = "week_released",
                   "year" = "year_released")) |> 
  # join flow data to dataset, full_join because we want to keep flow even for missing weeks
  full_join(flow_reformatted, by = c("stream","site","week", "year")) |> 
  # select columns that josh uses 
  select(year, week, stream, site, count, mean_fork_length, 
         number_released, number_recaptured,
         hours_fished, 
         flow_cfs) |> 
  group_by(site) |> 
  mutate(average_stream_hours_fished = mean(hours_fished, na.rm = TRUE)) |> 
  ungroup() |> 
  mutate(run_year = ifelse(week >= 45, year + 1, year),
         catch_standardized_by_hours_fished = ifelse((hours_fished == 0 | is.na(hours_fished)), count, round(count * average_stream_hours_fished / hours_fished, 0)),
         hours_fished = ifelse((hours_fished == 0 | is.na(hours_fished)) & count >= 0, average_stream_hours_fished, hours_fished),
         hours_fished = ifelse(is.na(count), 0, hours_fished) # adds 0 hours fished for padded weeks with NA catch
         ) |> # add logic for situations where trap data is missing
  glimpse()

standardizing_lookup <- weekly_model_data_wo_efficiency_flows |> 
  filter(!is.na(flow_cfs), 
         !is.na(number_released),
         !is.na(number_recaptured)) |> 
  group_by(site) |> 
  summarise(mean_eff_flow = mean(flow_cfs, na.rm = T),
            sd_eff_flow = sd(flow_cfs, na.rm = T)) |> 
  ungroup()

# Add in standardized efficiency flows 
mainstem_standardized_efficiency_flows <- weekly_model_data_wo_efficiency_flows |>
  filter(site %in% c("knights landing", "tisdale", "red bluff diversion dam"),
         !is.na(flow_cfs), 
         !is.na(number_released),
         !is.na(number_recaptured)) |>
  left_join(standardizing_lookup, by = "site") |> 
  group_by(site) |>
  mutate(standardized_efficiency_flow = (flow_cfs - mean_eff_flow) / 
           sd_eff_flow) |> 
  select(year, week, stream, site, standardized_efficiency_flow)

tributary_standardized_efficiency_flows <- weekly_model_data_wo_efficiency_flows |>
  filter(!site %in% c("knights landing", "tisdale", "red bluff diversion dam"),
         !is.na(flow_cfs),
         !is.na(number_released),
         !is.na(number_recaptured)) |>
  left_join(standardizing_lookup, by = "site") |> 
  group_by(site) |>
  mutate(standardized_efficiency_flow = (flow_cfs - mean_eff_flow) / 
           sd_eff_flow) |> 
  select(year, week, stream, site, standardized_efficiency_flow)

efficiency_standard_flows <- bind_rows(mainstem_standardized_efficiency_flows, 
                                       tributary_standardized_efficiency_flows) |> 
  glimpse()

weekly_model_data_with_eff_flows <- weekly_model_data_wo_efficiency_flows |> 
  left_join(standardizing_lookup, by = "site") |> 
  # standardize catch flow using mean and sd of mark recap flow
  mutate(standardized_flow = (flow_cfs - mean_eff_flow) / 
           sd_eff_flow) |> 
  left_join(efficiency_standard_flows, by = c("year", "week", "stream", "site"))  |> 
  select(-c(mean_eff_flow, sd_eff_flow))
  

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
  select(-c(number_released, number_recaptured, standardized_efficiency_flow)) |> 
  # ensure weeks are organized by water year for indexing in BTSPASX
  group_by(site) |> 
  arrange(year, week) |> 
  ungroup()

# Efficiency
weekly_juvenile_abundance_efficiency_data_raw <- weekly_juvenile_abundance_model_data |> 
  select(year, run_year, week, stream, site, number_released, number_recaptured, standardized_efficiency_flow, flow_cfs) |> 
  filter(!is.na(number_released) & !is.na(number_recaptured)) |> 
  distinct(site, run_year, week, number_released, number_recaptured, .keep_all = TRUE) |> 
  # ensure weeks are organized by water year for indexing in BTSPASX
  group_by(site) |> 
  arrange(year, week) |> 
  ungroup()

# check for rows where number released > number recaptured
eff_trial_data_check <- weekly_juvenile_abundance_efficiency_data_raw |> 
  filter(number_recaptured > number_released)

if(nrow(eff_trial_data_check) > 0) {
  warning(paste(nrow(eff_trial_data_check), "rows in the efficiency data have more recaptures than releases. Filtering here but should be addressed."))
}

# remove erroneous rows
weekly_juvenile_abundance_efficiency_data <- weekly_juvenile_abundance_efficiency_data_raw |> 
  filter(number_released >= number_recaptured)

ck <- weekly_juvenile_abundance_catch_data |>
  select(year, week, stream, site, count) |>
  rename(srjpedata = count) |>
  full_join(SRJPEdata::weekly_juvenile_abundance_catch_data |>
              select(year, week, stream, site, count))
filter(ck, srjpedata != count)

# write to package 
usethis::use_data(weekly_juvenile_abundance_catch_data, overwrite = TRUE) 
usethis::use_data(weekly_juvenile_abundance_efficiency_data, overwrite = TRUE)
usethis::use_data(weekly_efficiency, overwrite = TRUE) 
