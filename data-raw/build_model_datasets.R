# Create data file for Run Size and Proportion Captured models.
# Assume that if trap was fished and no chinook caught, a value of u = 0 is in the input file
# and that if trap was not fished there is no record in file
source("data-raw/weekly_data_summaries.R")
# Confirm data objects loaded from sourcing weekly data summaries 
# TODO think through this process may want to save as CSVs and read in 
weekly_catch_unmarked  |> glimpse()
weekly_efficiency |> glimpse()
standard_flow |> glimpse()


# weekly flow and efficiency ----------------------------------------------

# reformat flow data and summarize weekly
flow_reformatted <- standard_flow |> 
  mutate(stream_site = paste(stream, site),
         year = year(date),
         week = week(date)) |> 
  group_by(year, week, site, stream, source, stream_site) |> 
  summarise(flow_cfs = mean(flow_cfs, na.rm = T)) |> 
  glimpse()

efficiency_reformatted <- weekly_efficiency |> 
  ungroup() |> 
  mutate(stream_site = paste(stream, site)) |> 
  filter(!is.na(site), !is.na(year_released)) |> 
  glimpse()

weekly_effort |> glimpse()

# site handling -----------------------------------------------------------

# Based on multiple conversations about site handling, we will be adding a field
# called site_group that only applies to feather river. This will handle the 
# hfc/lfc grouping while retaining site/subsite variables.

lfc_subsites <- c("eye riffle_north", "eye riffle_side channel", "gateway main 400' up river", "gateway_main1", "gateway_rootball", "gateway_rootball_river_left", "#steep riffle_rst", "steep riffle_10' ext", "steep side channel")
hfc_subsites <- c("herringer_east", "herringer_upper_west", "herringer_west", "live oak", "shawns_east", "shawns_west", "sunset east bank", "sunset west bank")

lfc_sites <- c("eye riffle", "gateway riffle", "steep riffle")
hfc_sites <- c("herringer riffle", "live oak", "shawn's beach", "sunset pumps")

# years to include by site (ruleset) ----------------------------------------------------

stream_week_site_year_include <- years_to_include |>
  group_by(monitoring_year, stream, site) |> 
  # decided to go inclusively 
  # if just take min week does not account for the monitoring year so need to find min date first
  summarise(min_date = min(min_date),
            min_week = week(min_date),
            max_date = max(max_date),
            max_week = week(max_date)) |> 
  # identified as excluded due to incomplete sampling
  mutate(exclude = case_when(monitoring_year == 2022 & stream == "battle creek" ~ T,
                             monitoring_year == 2005 & site == "yuba river" ~ T,
                             monitoring_year == 2008 & site == "yuba river" ~ T,
                             monitoring_year == 2007 & site == "sunset pumps" ~ T,
                             monitoring_year == 2009 & site == "sunset pumps" ~ T,
                             T ~ F),
         site_group = case_when(site %in% lfc_sites ~ "feather river lfc",
                                site %in% hfc_sites ~ "feather river hfc",
                                T ~ NA)) |> 
  filter(exclude == F) |> 
  select(monitoring_year, stream, site_group, site, min_date, min_week, max_date, max_week)

# gcs_upload(stream_week_site_year_include,
#            object_function = f,
#            type = "csv",
#            name = "jpe-model-data/stream_week_site_year_include.csv",
#            predefinedAcl = "bucketLevel")
# write_csv(stream_week_site_year_include, "data-raw/stream_week_site_year_include.csv")

# catch -------------------------------------------------------------------

# Filter standard_catch to include only unmarked fish (is.na(release_id), species == "chinook")
standard_catch_unmarked <- standard_catch %>% 
  filter(species == "chinook salmon", # filter for only chinook
         is.na(release_id)) %>%  # filter for only unmarked fish, exclude recaptured fish that were part of efficiency trial
  mutate(month = month(date), # add to join with lad and yearling
         day = day(date)) |> 
  left_join(daily_yearling_ruleset) |> 
  mutate(lifestage_for_model = case_when(fork_length > cutoff & !run %in% c("fall","late fall", "winter") ~ "yearling",
                                         fork_length <= cutoff & fork_length > 45 & !run %in% c("fall","late fall", "winter") ~ "smolt",
                                         fork_length > 45 & run %in% c("fall", "late fall", "winter", "not recorded") ~ "smolt",
                                         fork_length > 45 & stream == "sacramento river" ~ "smolt",
                                         fork_length <= 45 ~ "fry", # logic from flora includes week (all weeks but 7, 8, 9 had this threshold) but I am not sure this is necessary, worth talking through
                                         T ~ NA)) |> 
  select(-species, -release_id, -is_yearling, -month, -day, -cutoff) |> 
  glimpse()


# add in proxy lifestage bins ---------------------------------------------
# logic to assign lifestage_for_model
weekly_lifestage_bins <- standard_catch_unmarked |> 
  filter(!is.na(fork_length), count != 0) |> 
  mutate(year = year(date), week = week(date)) |> 
  group_by(year, week, stream, site) |> 
  summarize(percent_fry = sum(lifestage_for_model == "fry")/n(),
            percent_smolt = sum(lifestage_for_model == "smolt")/n(),
            percent_yearling = sum(lifestage_for_model == "yearling")/n()) |> 
  ungroup() |> 
  glimpse() 

# Use when no FL data for a year 
proxy_weekly_fl <- standard_catch_unmarked |> 
  mutate(year = year(date), week = week(date)) |> 
  filter(!is.na(lifestage_for_model)) |> 
  group_by(week, stream) |> 
  summarize(percent_fry = sum(lifestage_for_model == "fry")/n(),
            percent_smolt = sum(lifestage_for_model == "smolt")/n(),
            percent_yearling = sum(lifestage_for_model == "yearling")/n()) |> 
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
  select(-lifestage_for_model, -count, -week, -year) |> # remove because all na, assigning in next line
  pivot_longer(fry:yearling, names_to = 'lifestage_for_model', values_to = 'count') |> 
  select(-c(percent_fry, percent_smolt, percent_yearling)) |>  
  filter(count != 0) |> # remove 0 values introduced when 0 prop of a lifestage, significantly decreases size of DF 
  mutate(model_lifestage_method = "assign count based on weekly distribution",
         week = week(date), 
         year = year(date)) |> 
  glimpse()

# add filled values back into combined_rst 
# first filter combined rst to exclude rows in na_to_fill
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


# add in proxy run bins ---------------------------------------------------
updated_standard_catch_na_run <- updated_standard_catch |> 
  mutate(run = ifelse(run %in% c("not recorded", "unknown", NA_character_), NA_character_, run)) |> glimpse()

updated_standard_catch_na_run |> 
  group_by(stream, run) |> 
  summarise(n = n()) |> 
  mutate(freq = n / sum(n)) |> 
  filter(is.na(run))

updated_standard_catch_na_run |> 
  filter(stream == "clear creek") |> 
  group_by(site, week) |> 
  summarise(n = n(),
            prop_spring = sum(run == "spring", na.rm = T) / n,
            prop_other = sum(run %in% c("fall", "late fall", "winter", NA_character_) / n)) |> 
  ggplot(aes(x = week, y = prop_spring)) + 
  geom_bar(stat = "identity") +
  facet_wrap(~site, scales = "free")

updated_standard_catch_na_run_no_deer_mill <- updated_standard_catch_na_run |> 
  filter(!stream %in% c("deer creek", "mill creek")) |> 
  glimpse()

# create weekly proportion bins for run (spring / not spring / unknown)
weekly_run_bins <- updated_standard_catch_na_run_no_deer_mill |> 
  filter(!is.na(run), count != 0) |> 
  mutate(year = year(date), week = week(date)) |> 
  group_by(year, week, stream, site) |>
  summarize(percent_spring = sum(run == "spring", na.rm = T)/n(),
            percent_not_spring = sum(run != "spring", na.rm = T) / n()) |> 
  ungroup() |> 
  glimpse()

# Use when no run data for a year 
proxy_weekly_run <- updated_standard_catch_na_run_no_deer_mill |>
  mutate(year = year(date), week = week(date)) |>
  filter(count > 0, !is.na(run)) |> 
  group_by(week, stream, site) |>
  summarise(percent_spring = sum(run == "spring", na.rm = T)/n(),
            percent_not_spring = sum(run != "spring", na.rm = T)/n()) |>
  ungroup() |>
  glimpse()

# # Years without run data 
proxy_run_bins_for_weeks_without_run <- updated_standard_catch_na_run_no_deer_mill |>
  filter(count > 0) |> 
  group_by(year, week, stream, site) |>
  summarise(all_na = sum(is.na(run)) == n()) |> 
  ungroup() |> 
  filter(all_na) |> 
  left_join(proxy_weekly_run, by = c("week", "stream", "site")) |>
  select(-all_na) |>
  glimpse()

all_run_bins <- bind_rows(weekly_run_bins, proxy_run_bins_for_weeks_without_run) |>
  glimpse()


# create table of all na values that need to be filled
na_filled_run <- updated_standard_catch_na_run_no_deer_mill |> 
  filter(is.na(run) & count > 0) |> 
  left_join(all_run_bins, by = c("year", "week", "stream", "site")) |> 
  mutate(spring_run = round(count * percent_spring),
         not_spring_run = round(count * percent_not_spring)) |> 
  select(-c(count, week, year, run)) |> # remove bc all NA, assigning in next line
  pivot_longer(spring_run:not_spring_run, names_to = 'run_for_model', values_to = 'count') |> 
  select(-c(percent_spring, percent_not_spring)) |>  
  filter(count != 0) |> # remove 0 values introduced when 0 prop of a lifestage, significantly decreases size of DF 
  mutate(model_run_method = "assign run based on weekly distribution",
         week = week(date), 
         year = year(date)) |> 
  select(-run_method) |> 
  glimpse()

# add filled values back into combined_rst 
# first filter combined rst to exclude rows in na_to_fill
combined_rst_wo_na_run <- updated_standard_catch_na_run_no_deer_mill |> 
  filter(!is.na(run) & count > 0) |> 
  mutate(run_for_model = if_else(run == "spring", "spring_run", "not_spring_run")) |> 
  mutate(model_run_method = ifelse(is.na(run_method), "not recorded", run_method)) |> 
  select(-run_method) |> 
  glimpse() 

mill_and_deer <- updated_standard_catch_na_run |> 
  filter(stream %in% c("mill creek", "deer creek")) |> 
  mutate(run_for_model = NA,
         model_run_method = "mill and deer - no data to interpolate") |> 
  select(-run_method)

no_catch_run <- updated_standard_catch_na_run_no_deer_mill |> 
  filter(count == 0) |> 
  mutate(run_for_model = NA,
         model_run_method = "count is 0") |> 
  select(-run_method)

updated_standard_catch_with_run <- bind_rows(combined_rst_wo_na_run, na_filled_run, no_catch_run, mill_and_deer) |> glimpse()

# TODO do we save this as a data object? what will josh be using?
# for now
write_csv(updated_standard_catch, "data-raw/updated_standard_catch_with_proxy_lifestage.csv")
write_csv(updated_standard_catch_with_run, "data-raw/updated_standard_catch_with_proxy_lifestage_and_run.csv")



#data frames for chinook of any kind and for spring run only (exclude hatchery in both cases)
catch_reformatted <- weekly_catch_unmarked |> 
  mutate(stream_site = paste(stream, site)) |> 
  filter(adipose_clipped == FALSE,
         run %in% c("spring", NA, "not recorded")) |> glimpse()
# TODO update lifestage using logic below from flora 

# Combine all 3 tables together 

weekly_model_data <- catch_reformatted |> 
  left_join(weekly_effort, by = c("year", "week", "stream", "site", "subsite")) |> 
  # Join efficnecy data to catch data
  left_join(efficiency_reformatted, 
            by = c("week" = "week_released",
                   "year" = "year_released", "stream", 
                   "site", "stream_site")) |> 
  # join flow data to dataset
  left_join(flow_reformatted, by = c("week", "year", "site", "stream", "stream_site")) |> 
  # select columns that josh uses 
  # TODO confirm we do not need night release
  select(year, week, stream, site, count, lifestage, is_yearling, mean_fork_length, 
         origin_released, number_released, number_recaptured, effort = hours_fished, 
         flow_cfs, efficiency_flow = flow_at_recapture_day1) |> 
  # TODO add run year
  glimpse()

# TODO 
# Potential lifestage update
#  else if ((Jmon[Weeks[iwk]] >= 1 &
# Jmon[Weeks[iwk]] < 3 & sz > 45 & sz <= 60) |
#   (Jmon[Weeks[iwk]] >= 3 &
#      Jmon[Weeks[iwk]] < 7 & sz > 45 & sz <= 100)) {
#        Spr_Stage[k] = "Smolt"
#      } else if ((Jmon[Weeks[iwk]] > 10 &
#                  sz <= 45) | (Jmon[Weeks[iwk]] <= 6 & sz <= 45)) {
#        Spr_Stage[k] = "Fry"
#      }