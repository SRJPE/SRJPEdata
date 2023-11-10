# Create data file for Run Size and Proportion Captured models.
# Assume that if trap was fished and no chinook caught, a value of u = 0 is in the input file
# and that if trap was not fished there is no record in file
source("data-raw/weekly_data_summaries.R")
# Confirm data objects loaded from sourcing weekly data summaries 
# TODO think through this process may want to save as CSVs and read in 
weekly_standard_catch_unmarked  |> glimpse()
weekly_efficiency |> glimpse()
standard_flow |> glimpse()

# reformat flow data and summarize weekly
# TODO josh has stream site column, we are keeping separate and will need to refactor his code
flow_reformatted <- standard_flow |> 
  mutate(year = year(date),
         week = week(date)) |> 
  group_by(year, week, site, stream, source) |> 
  summarise(flow_cfs = mean(flow_cfs, na.rm = T)) |> 
  glimpse()

weekly_efficiency |> glimpse()

weekly_effort |> glimpse()

# TODO do we want to do adipose clipped, josh had it but sounds like maybe we want to do all 
#data frames for chinook of any kind and for spring run only (exclude hatchery in both cases)
catch_reformatted <- weekly_standard_catch_unmarked |> 
  filter(run %in% c("spring", NA, "not recorded")) |> glimpse()

# Combine all 3 tables together 
weekly_model_data <- catch_reformatted |> 
  left_join(weekly_effort, by = c("year", "week", "stream", "site", "subsite")) |> 
  # Join efficnecy data to catch data
  left_join(efficiency_reformatted, 
            by = c("week" = "week_released",
                   "year" = "year_released", "stream", 
                   "site")) |> 
  # join flow data to dataset
  left_join(flow_reformatted, by = c("week", "year", "site", "stream")) |> 
  # select columns that josh uses 
  select(year, week, stream, site, count, life_stage, is_yearling, mean_fork_length, 
         origin_released, number_released, number_recaptured, effort = hours_fished, 
         flow_cfs) |> 
  # TODO add efficiency flow to database 
  # efficiency_flow = flow_at_recapture_day1) |>
  mutate(run_year = ifelse(week >= 45, year + 1, year)) |> 
  glimpse()

# TODO data checks 
# Why does battle start in 2007 - did we intentionally leave early years out of database 
usethis::use_data(weekly_model_data, overwrite = TRUE)
