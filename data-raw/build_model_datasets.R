# Create data file for Run Size and Proportion Captured models.
# Assume that if trap was fished and no chinook caught, a value of u = 0 is in the input file
# and that if trap was not fished there is no record in file
source("data-raw/weekly_data_summaries.R")
# Confirm data objects loaded from sourcing weekly data summaries 
# TODO think through this process may want to save as CSVs and read in 
weekly_catch_unmarked  |> glimpse()
weekly_efficiency |> glimpse()
standard_flow |> glimpse()

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