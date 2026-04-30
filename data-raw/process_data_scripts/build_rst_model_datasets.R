# Create data file for Run Size and Proportion Captured models.
# Assume that if trap was fished and no chinook caught, a value of u = 0 is in the input file
# and that if trap was not fished there is no record in file
library(SRJPEdata)
library(lubridate)
library(tidyverse)

# Catch Formatting --------------------------------------------------------------

# Processing:
# Filter out (1) adipose clipped fish, (2) yearlings
# Add rows for weeks that were not sampled where catch is NA
# Decision - Do not filter out "years to exclude" here to allow experimentation with modeling

yearling_ruleset <- SRJPEdata::daily_yearling_ruleset
# Remove all adipose clipped fish - we do not want to include hatchery fish
# Remove yearling fish - we do not want to include yearlings
updated_standard_catch_raw <- SRJPEdata::rst_catch |>
  mutate(
    remove = case_when(
      stream != "butte creek" & adipose_clipped == T ~ "remove", # remove adipose clipped fish (hatcher), Butte told us these should not be removed for them
      T ~ "keep"
    ),
    run = tolower(run),
    day = day(date),
    month = month(date)
  ) |>
  filter(remove == "keep") |>
  left_join(yearling_ruleset) |>
  mutate(
    life_stage = case_when(
      fork_length > cutoff &
        (run %in%
          c("spring", "not recorded", "unknown", "mixed") |
          is.na(run)) ~ "yearling",
      T ~ "young of the year"
    )
  )

# save separately so easy to tell which yearlings being removed
updated_standard_catch <- updated_standard_catch_raw |> # all NA fork length would be assumed YOY
  filter(life_stage == "young of the year") |>
  select(-c(remove, life_stage, day, month, cutoff))

# Set Up Week Lookup Tables --------------------------------------------------------------
# For the BTSPAS model we need to include all weeks that were not sampled. The code
# below sets up a table of all possible weeks (based on min sampling year and max sampling year). This is joined at the end

# Lookup that includes all weeks for streams and sites
rst_all_weeks <- SRJPEdata::rst_catch |>
  group_by(stream, site, subsite) |>
  summarise(min = min(date, na.rm = T), max = max(date, na.rm = T)) |>
  mutate(
    min = paste0(year(min), "-01-01"),
    max = paste0(year(max), "-12-31")
  ) |>
  pivot_longer(cols = c(min, max), values_to = "date") |>
  mutate(date = as_date(date)) |>
  select(-name) |>
  padr::pad(interval = "day", group = c("stream", "site")) |>
  mutate(week = week(date), year = year(date)) |>
  distinct(stream, site, year, week) |>
  mutate(run_year = ifelse(week >= 45, year + 1, year))

# It is possible that when removing adipose clipped fish and yearlings we may lose some weeks where sampled
# occurred but we no longer have counts.

# Lookup that includes weeks where sampling occurred and when it did not
weeks_sampled <- SRJPEdata::rst_catch |>
  filter(!is.na(count)) |> # remove when trap is not fishing
  mutate(
    week = week(date),
    year = year(date),
    run_year = ifelse(week >= 45, year + 1, year)
  ) |>
  select(stream, site, week, run_year) |>
  distinct() |>
  mutate(if_sampled = T) |>
  full_join(rst_all_weeks) |>
  mutate(if_sampled = ifelse(is.na(if_sampled), F, if_sampled))


# Summarize by week -----------------------------------------------------------
# Removed lifestage and yearling for now - can add back in but do not need for btspasx model input so removing
weekly_standard_catch <- updated_standard_catch |>
  mutate(week = week(date), year = year(date)) |>
  group_by(stream, site, site_group, week, year) %>%
  summarize(
    mean_fork_length = mean(fork_length, na.rm = T),
    mean_weight = mean(weight, na.rm = T),
    count = sum(count, na.rm = T)
  ) |>
  mutate(site_year_week = paste0(site, "_", year, "_", week)) |>
  ungroup() |>
  glimpse()

# Trap Formatting ---------------------------------------------------------
# Weekly effort from vignette/trap_effort.Rmd
weekly_effort_by_site <- SRJPEdata::weekly_hours_fished |>
  group_by(stream, site, site_group, week, year) %>%
  summarize(hours_fished = sum(hours_fished, na.rm = TRUE)) |> # weekly data is at the subsite level, we need to add together the subsites
  ungroup()

# Environmental -----------------------------------------------------------
env_with_sites <- SRJPEdata::environmental_data |>
  left_join(SRJPEdata::site_lookup, relationship = "many-to-many") |> # Confirmed that many to many makes sense, added relationship to silence warning
  glimpse()

weekly_flow <- env_with_sites |> filter(parameter == "flow")

# Note I don't think we are currently using temperature
weekly_temperature <- env_with_sites |> filter(parameter == "temperature")

# Efficiency Formatting ---------------------------------------------------------
# pulled in release_summary
# this dataset will be saved separately to retain the fork length and origin variables

# Josh needs origin released but need to summarize it by week
weekly_origin <-
  left_join(
    SRJPEdata::release,
    SRJPEdata::recaptures |> # need to summarize first so you don't get duplicated release data when joining
      group_by(stream, site, release_id) |>
      summarize(count = sum(count, na.rm = T)),
    by = c("release_id", "stream", "site")
  ) |>
  mutate(
    week_released = week(date_released),
    year_released = year(date_released),
    hatchery = ifelse(origin == "hatchery", 1, 0),
    natural = ifelse(origin == "natural", 1, 0),
    mixed = ifelse(origin == "mixed", 1, 0)
  ) |>
  select(
    stream,
    site,
    week_released,
    year_released,
    hatchery,
    natural,
    mixed
  ) |>
  group_by(stream, site, week_released, year_released) |>
  summarize(
    hatchery = sum(hatchery),
    natural = sum(natural),
    mixed = sum(mixed)
  ) |>
  mutate(
    origin_released = case_when(
      mixed > 0 ~ "mixed",
      hatchery == 0 & natural == 0 & mixed == 0 ~ NA,
      hatchery > 0 & natural == 0 & mixed == 0 ~ "hatchery",
      natural > 0 & hatchery == 0 & mixed == 0 ~ "natural",
      is.na(hatchery) & is.na(natural) & is.na(mixed) ~ NA,
      T ~ "mixed"
    )
  ) |>
  select(stream, site, week_released, year_released, origin_released)

weekly_efficiency <-
  left_join(
    SRJPEdata::release,
    SRJPEdata::recaptures |> # need to summarize first so you don't get duplicated release data when joining
      group_by(stream, site, site_group, release_id) |>
      summarize(count = sum(count, na.rm = T)),
    by = c("release_id", "stream", "site", "site_group")
  ) |>
  group_by(
    stream,
    site,
    site_group,
    week_released = week(date_released),
    year_released = year(date_released)
  ) |>
  summarize(
    number_released = sum(number_released, na.rm = TRUE),
    number_recaptured = sum(count, na.rm = TRUE),
    median_fork_length_released = median(median_fork_length_released, na.rm = T)
  ) |>
  ungroup() |>
  left_join(weekly_origin) |>
  glimpse()

# calculate average hours fished for weeks when efficiency trials were conducted by site across all weeks and years
average_hours_fished_efficiency <- weekly_efficiency |>
      group_by(week_released, year_released, stream, site) |> # we added in origin and fork length for post hoc figures but for the model data need to remove
      summarize(
        number_released = sum(number_released),
        number_recaptured = sum(number_recaptured)
      ) |> 
      left_join(weekly_effort_by_site, by = c("stream", "site", "week_released" = "week", "year_released" = "year")) |> 
  group_by(site) |> 
  summarize(average_hours_fished_during_efficiency_trials = mean(hours_fished, na.rm = T))

# reformat flow data and summarize weekly
flow_reformatted_raw <- rst_all_weeks |> # we want flows for all weeks, even if missing samples
  left_join(
    env_with_sites |>
      filter(parameter == "flow", statistic == "mean") |>
      group_by(stream, site, week, year, gage_agency, gage_number) |>
      summarise(flow_cfs = mean(value, na.rm = T))
  )
# To fill in NAs, find the average weekly flow across years
mean_flow_across_years <- flow_reformatted_raw |>
  group_by(stream, site, week) |>
  summarize(mean_flow_for_data_gaps = mean(flow_cfs, na.rm = T))

flow_reformatted <- flow_reformatted_raw |>
  left_join(mean_flow_across_years) |>
  mutate(
    flow_cfs = ifelse(is.na(flow_cfs), mean_flow_for_data_gaps, flow_cfs)
  ) |>
  select(-mean_flow_for_data_gaps)

# Combine all 3 tables together
weekly_model_data_wo_efficiency_flows <- weekly_standard_catch |>
  left_join(weekly_effort_by_site, by = c("stream", "site", "week", "year")) |>
  # Join efficiency data to catch data
  left_join(
    weekly_efficiency |>
      group_by(week_released, year_released, stream, site) |> # we added in origin and fork length for post hoc figures but for the model data need to remove
      summarize(
        number_released = sum(number_released),
        number_recaptured = sum(number_recaptured)
      ),
    by = c("stream", "site", "week" = "week_released", "year" = "year_released")
  ) |>
  left_join(average_hours_fished_efficiency, by = c("site")) |>  # add the average_hours_fished_during_efficiency_trials
  # join flow data to dataset, full_join because we want to keep flow even for missing weeks
  full_join(flow_reformatted, by = c("stream", "site", "week", "year")) |>
  # select columns that josh uses
  select(
    year,
    week,
    stream,
    site,
    count,
    mean_fork_length,
    number_released,
    number_recaptured,
    hours_fished,
    average_hours_fished_during_efficiency_trials,
    flow_cfs
  ) |>
  group_by(site) |>
  mutate(average_stream_hours_fished = mean(hours_fished, na.rm = TRUE)) |> # this is used to fill in gaps where hours fished data is missing
  ungroup() |>
  mutate(
    run_year = ifelse(week >= 45, year + 1, year),
    hours_fished = ifelse(
      (hours_fished == 0 | is.na(hours_fished)) & count >= 0,
      average_stream_hours_fished,
      hours_fished
    ),
    hours_fished = ifelse(is.na(count), 0, hours_fished) # adds 0 hours fished for padded weeks with NA catch
  ) |> 
  select(-average_stream_hours_fished)

# calculate mean and sd used to standardize flows. should be mean and
# sd of efficiency flows except for lbc

# for lbc, use mean and sd of catch flow because we have no efficiency flows
standardizing_lbc <- weekly_model_data_wo_efficiency_flows |>
  filter(site == "lbc") |>
  summarise(
    mean_eff_flow = mean(flow_cfs, na.rm = T),
    sd_eff_flow = sd(flow_cfs, na.rm = T)
  ) |>
  ungroup() |>
  mutate(site = "lbc")

# all others
standardizing_lookup <- weekly_model_data_wo_efficiency_flows |>
  filter(
    !is.na(flow_cfs),
    !is.na(number_released),
    !is.na(number_recaptured)
  ) |>
  group_by(site) |>
  summarise(
    mean_eff_flow = mean(flow_cfs, na.rm = T),
    sd_eff_flow = sd(flow_cfs, na.rm = T)
  ) |>
  ungroup() |>
  bind_rows(standardizing_lbc)

# Add in standardized efficiency flows
mainstem_standardized_efficiency_flows <- weekly_model_data_wo_efficiency_flows |>
  filter(
    site %in% c("knights landing", "tisdale", "red bluff diversion dam"),
    !is.na(flow_cfs),
    !is.na(number_released),
    !is.na(number_recaptured)
  ) |>
  left_join(standardizing_lookup, by = "site") |>
  group_by(site) |>
  mutate(
    standardized_efficiency_flow = (flow_cfs - mean_eff_flow) /
      sd_eff_flow
  ) |>
  select(year, week, stream, site, standardized_efficiency_flow)

tributary_standardized_efficiency_flows <- weekly_model_data_wo_efficiency_flows |>
  filter(
    !site %in% c("knights landing", "tisdale", "red bluff diversion dam"),
    !is.na(flow_cfs),
    !is.na(number_released),
    !is.na(number_recaptured)
  ) |>
  left_join(standardizing_lookup, by = "site") |>
  group_by(site) |>
  mutate(
    standardized_efficiency_flow = (flow_cfs - mean_eff_flow) /
      sd_eff_flow
  ) |>
  select(year, week, stream, site, standardized_efficiency_flow)

efficiency_standard_flows <- bind_rows(
  mainstem_standardized_efficiency_flows,
  tributary_standardized_efficiency_flows
) |>
  glimpse()

weekly_model_data_with_eff_flows <- weekly_model_data_wo_efficiency_flows |>
  left_join(standardizing_lookup, by = "site") |>
  # standardize catch flow using mean and sd of mark recap flow
  mutate(
    standardized_flow = (flow_cfs - mean_eff_flow) /
      sd_eff_flow
  ) |>
  left_join(
    efficiency_standard_flows,
    by = c("year", "week", "stream", "site")
  ) |>
  select(-c(mean_eff_flow, sd_eff_flow))


# ADD special priors data in
btspasx_special_priors_data <- read.csv(here::here(
  "data-raw",
  "helper-tables",
  "Special_Priors.csv"
)) |>
  mutate(site = sub(".*_", "", Stream_Site)) |>
  select(site, run_year = RunYr, week = Jweek, special_prior = lgN_max) |>
  glimpse()

# Fill in missing weeks that were sampled or not sampled ---------------------------------------------------------
# JOIN special priors with weekly model data
# first, assign special prior (if relevant), else set to default, then fill in for weeks without catch
weekly_juvenile_abundance_model_data_raw <- weekly_model_data_with_eff_flows |>
  left_join(btspasx_special_priors_data, by = c("run_year", "week", "site")) |>
  mutate(
    lgN_prior = ifelse(
      !is.na(special_prior),
      special_prior,
      log(((count / 1000) + 1) / 0.025)
    )
  ) |> # maximum possible value for log N across strata
  select(-special_prior) |>
  full_join(weeks_sampled) |> 
  mutate(
    count = case_when(
      is.na(count) & if_sampled == T ~ 0,
      is.na(count) & if_sampled == F ~ NA,
      T ~ count
    )
  ) |>  
  select(-if_sampled)


# when we join rst_all_weeks we end up with some run years that have all NA sampling
# these should be removed
remove_run_year <- weekly_juvenile_abundance_model_data_raw |>
  mutate(count2 = ifelse(is.na(count), 0, 1)) |>
  group_by(run_year, stream, site, count2) |>
  tally() |>
  pivot_wider(names_from = count2, values_from = n) |>
  filter(`0` > 0 & is.na(`1`)) |> # filter for run_years where count is only NA
  select(-c(`0`, `1`)) |>
  mutate(remove = T)

# Final processing ---------------------------------------------------------
weekly_juvenile_abundance_model_data <- weekly_juvenile_abundance_model_data_raw |>
  left_join(remove_run_year) |>
  mutate(remove = ifelse(is.na(remove), F, remove)) |>
  filter(remove == F) |>
  select(-remove)

# Split up into 2 data objects, efficiency, and catch
# Catch
weekly_juvenile_abundance_catch_data <- weekly_juvenile_abundance_model_data |>
  select(
    -c(number_released, number_recaptured, standardized_efficiency_flow)
  ) |>
  # ensure weeks are organized by water year for indexing in BTSPASX
  group_by(site) |>
  arrange(year, week) |>
  ungroup()

# Efficiency
weekly_juvenile_abundance_efficiency_data_raw <- weekly_juvenile_abundance_model_data |>
  select(
    year,
    run_year,
    week,
    stream,
    site,
    number_released,
    number_recaptured,
    standardized_efficiency_flow,
    flow_cfs
  ) |>
  filter(!is.na(number_released) & !is.na(number_recaptured)) |>
  distinct(
    site,
    run_year,
    week,
    number_released,
    number_recaptured,
    .keep_all = TRUE
  ) |>
  # ensure weeks are organized by water year for indexing in BTSPASX
  group_by(site) |>
  arrange(year, week) |>
  ungroup()

# check for rows where number released > number recaptured
eff_trial_data_check <- weekly_juvenile_abundance_efficiency_data_raw |>
  filter(number_recaptured > number_released)

if (nrow(eff_trial_data_check) > 0) {
  warning(paste(
    nrow(eff_trial_data_check),
    "row(s) in the efficiency data have more recaptures than releases. Filtering here but should be addressed."
  ))
}

# remove erroneous rows
weekly_juvenile_abundance_efficiency_data <- weekly_juvenile_abundance_efficiency_data_raw |>
  filter(number_released >= number_recaptured)

# write to package
usethis::use_data(weekly_juvenile_abundance_catch_data, overwrite = TRUE)
usethis::use_data(weekly_juvenile_abundance_efficiency_data, overwrite = TRUE)
usethis::use_data(weekly_efficiency, overwrite = TRUE)
