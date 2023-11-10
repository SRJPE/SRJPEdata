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
catch_reformatted <- weekly_standard_catch_unmarked |>  glimpse()

# Combine all 3 tables together 
# 
# TODO from josh_origional_model_code_script. Standardize flow for efficiency trials 
# analyze efficiency trials for all relevant sites (do not filter to site)
mainstem_standardized_effort_flows <- bt_spas_x_input_data |>
  filter(site %in% c("knights landing", "tisdale", "red bluff diversion dam"),
         !is.na(flow_cfs), # TODO change to efficiency flow when available
         !is.na(number_released),
         !is.na(number_recaptured)) |>
  group_by(stream) |>
  mutate(standardized_flow = (flow_cfs - mean(flow_cfs, na.rm = T)) / sd(flow_cfs, na.rm = T)) # TODO change first instance of flow to efficiency_flow once available



# TODO standardize flow_cfs 
input_data <- input_data |>
  group_by(week) |>
  mutate(catch_flow = ifelse(is.na(catch_flow), mean(catch_flow, na.rm = T), catch_flow)) |>
  ungroup() |>
  mutate(catch_flow = as.vector(scale(catch_flow))) # standardizes and centers see ?scale

weekly_model_data <- catch_reformatted |> 
  left_join(weekly_effort, by = c("year", "week", "stream", "site", "subsite")) |> 
  # Join efficnecy data to catch data
  left_join(weekly_efficiency, 
            by = c("week" = "week_released",
                   "year" = "year_released", "stream", 
                   "site")) |> 
  # join flow data to dataset
  left_join(flow_reformatted, by = c("week", "year", "site", "stream")) |> 
  # select columns that josh uses 
  select(year, week, stream, site, count, mean_fork_length, 
         number_released, number_recaptured, effort = hours_fished, 
         flow_cfs) |> 
  # TODO add efficiency flow to database - Standardize using code above 
  # efficiency_flow = flow_at_recapture_day1) |>
  group_by(stream) |> 
  mutate(average_stream_effort = mean(effort, na.rm = TRUE)) |> 
  ungroup() |> 
  mutate(run_year = ifelse(week >= 45, year + 1, year),
         catch_standardized_by_effort = ifelse(is.na(effort), count, round(count * average_stream_effort / effort, 0))) |> 
  glimpse()

# TODO dig into yearling & lifestage splitting up data too much 
# TODO create differnt weekly_model without lifestage and yearlings so liz can run that - bt_spas_x_input_data

# TODO data checks 
# Why does battle start in 2007 - did we intentionally leave early years out of database 
usethis::use_data(weekly_model_data, overwrite = TRUE)

weekly_model_data |> filter(count > 0, effort == 0) |> glimpse()
