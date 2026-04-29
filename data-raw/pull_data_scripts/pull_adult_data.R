# Pull adult data from EDI (or other repositories)
# Adult data were originally stored in the SR JPE database
# however, for the short-term (until we understand what and how we want to use those data
# it is easier to update the data on EDI and pull directly) 

library(tidyverse)
library(EDIutils)

# Set the scope for script to use API to download data from EDI
scope = "edi"

# Battle/Clear
# Upstream passage and redd data
# These data will be published on EDI but currently are not
# In the interim we will pull from the standard format datasets which originally were saved on GCP - "standard-format-data/standard_daily_redd.csv"

# Instruction for updating - when Battle and Clear provided an updated value, open the csv, add the new value and save.
battle_redd <- read_csv("data-raw/helper-tables/battle_clear_redd_historical.csv") |> 
  filter(stream == "battle creek")

clear_redd <- read_csv("data-raw/helper-tables/battle_clear_redd_historical.csv") |>  
  filter(stream == "clear creek")

battle_clear_passage <- read_csv("data-raw/helper-tables/battle_clear_passage_estimates_historical.csv")

# Butte
# Carcass estimates
# Only agreed to publishing carcass estimates which are available on GrandTab
# The timing of availability on GrandTab is unknown so reach out to Grant/Anna
# and to request data on similar timeline as EDI workflow

# New years for Butte
# The process for updating years for Butte will be to read in a csv or manually add the data to the csv
butte_carcass <- read_csv("data-raw/helper-tables/butte_carcass_historical.csv") |> 
  rename(count = carcass_estimate) |> 
  mutate(data_type = "carcass estimate")

# Deer/Mill
# Upstream passage data, redd (mill), holding (deer)
# These data are on EDI and should be updated following the EDI workflow
# https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1672.1
# When doing a data check with Ryan May 2025 we found a few discrepancies
# in the video passage data and all the redd data were off. Until
# this is fixed on EDI we will pull data from the spreadsheet Ryan provided

data_from_ryan_raw <- read_csv("data-raw/helper-tables/mill_deer_adult_historical.csv")

# Interpolate Mill Redd data based on 
# adult-holding-redd-and-carcass-surveys_mill-creek_data-raw_Mill Creek SRCS Redd Counts by Section 1997-2020 Reformatted.xlsx
# See data-raw/analysis/mill-redd-analysis.Rmd for methodology 
redd_interpolation_data <- read_csv(here::here("data-raw", "analysis", "mill_redd_fill_table.csv"))

mill_redd <- data_from_ryan_raw |> 
  filter(data_type == "redd",
         stream == "mill creek") |>  
  left_join(redd_interpolation_data) |> 
  mutate(redd_multiplier = ifelse(is.na(redd_multiplier), 1, redd_multiplier), # for years 2021-2024 where we don't have a multiplier. these are expected to be complete surveys
         new_count = round(count * redd_multiplier, 0)) |> 
  select(year, count = new_count, data_type, stream) |> 
  glimpse()

data_from_ryan <- data_from_ryan_raw |> 
  filter(!(data_type == "redd" & stream == "mill creek")) |> 
  bind_rows(mill_redd)

# identifier = "1672"
# revision = list_data_package_revisions(scope, identifier, filter = "newest")
# package_id <- paste(scope, identifier, revision, sep = ".")

# List data entities of the data package
# res <- read_data_entity_names(package_id)
# 
# # Download the daily corrected passage
# name <- "deer_mill_upstream_passage_estimates.csv"
# entity_id <- res$entityId[res$entityName == name]
# raw <- read_data_entity(package_id, entity_id)
# upstream_passage_estimates_data <- read_csv(file = raw)
# # Note that there are some discrepancies between EDI and what Ryan is using
# # TODO we need to fix data on EDI
# # Until data are fixed on EDI make updates here
# deer_mill_upstream_passage_estimates <- upstream_passage_estimates_data |> 
#   group_by(year, stream, run) |> 
#   summarize(count = sum(passage_estimate, na.rm = T),
#             upper_bound_estimate = sum(ucl, na.rm = T),
#             lower_bound_estimate = sum(lcl, na.rm = T),
#             confidence_level = 90)
#   mutate(data_type = "upstream_estimate") |>
#   select(year, stream, count, data_type, upper_bound_estimate, lower_bound_estimate, confidence_level) |>
#   glimpse()
# 
# # redd data (Mill) ---
# name <- "deer_mill_redd.csv"
# entity_id <- res$entityId[res$entityName == name]
# raw <- read_data_entity(package_id, entity_id)
# redd_data <- read_csv(file = raw)
# 
# deer_mill_redd <- redd_data |> 
#   mutate(reach_number = NA,
#          latitude = NA,
#          longitude = NA,
#          velocity = NA,
#          redd_id = NA,
#          age = NA,
#          run = NA, # TODO are they all spring run?
#          date = as.Date(date)) |> 
#   select(date, stream, reach, latitude, longitude, run, velocity, redd_id, age, redd_count) |> 
#   group_by(year(date), stream) |> 
#   summarize(count = sum(redd_count, na.rm = T))
# 
# # holding (deer)
# name <- "deer_mill_holding.csv"
# entity_id <- res$entityId[res$entityName == name]
# raw <- read_data_entity(package_id, entity_id)
# holding_data <- read_csv(file = raw)
# 
# deer_mill_holding <- holding_data |> 
#   mutate(latitude = NA,
#          longitude = NA) |> 
#   select(date, stream, reach, count, adipose_clipped, run, latitude, longitude) |> 
#   glimpse()

# Feather
# Data provided by Casey Campos
# To get spring run in river spawning number we would take "broodstock tagged" minus "broodstock returning to the hatchery" minus"over summer mortality"
# The more I thought about it I realized that those redd survey data are not going to be the best to use because the effort has been inconsistent. We now have the drone-based redd surveys that will have a similar effort every year and could be used in conjunction with the weir counts, but turning the images into redd counts is a bottleneck.
# For incorporating the historic data, my initial thought is to use the number of fish we tag for broodstock at the Hatchery in the spring minus the number that return in the fall as an indicator of the in-river spring-run population size. We know we that it will always be an underestimate because not all the spring-run go to the Hatchery in the spring.
# Prior to year 1 of the weir, we were unsure how much of the run were making it to the Hatchery and being tagged. What we saw year 1, was a large percentage of the fish passing the weir did go into the hatchery (see table below).
# Th table shows the number of spring-run tagged for broodstock, number returning to the Hatchery in the fall, the number of over summer mortalities during the same period, and includes the corrected count at the weir for 2024.

# Casey provided updated data in Dec 2025 that includes data dating back to 2004 to expand the adult dataset
feather_adult_raw <- read_csv(here::here("data-raw","helper-tables","feather_adult_data_for_stock_recruit_dec_2025.csv"))

feather_spring_spawner <- feather_adult_raw |> 
  filter(!is.na(`Hallprint Tagged1`)) |> 
  rename(count = `Estimated in-river spring-run`,
         year = Year) |> 
  select(year, count) |> 
  mutate(stream = "feather river",
         data_type = "broodstock_tag",
         year = as.numeric(year))


# Yuba
# Upstream passage data
# These data are on EDI and should be updated following the EDI workflow
# https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1707.1 

identifier = "1707"
revision = list_data_package_revisions(scope, identifier, filter = "newest")
package_id <- paste(scope, identifier, revision, sep = ".")

# List data entities of the data package
res <- read_data_entity_names(package_id)

# Download the daily corrected passage
name <- "yuba_daily_corrected_passage.csv"
entity_id <- res$entityId[res$entityName == name]
raw <- read_data_entity(package_id, entity_id)
data <- read_csv(file = raw)

# process into format as previously defined by database
yuba_passage_estimates <- data |> 
  mutate(run = ifelse(run %in% c("early spring", "late spring"), "spring", run)) |> 
  group_by(year = year(date), run) |> 
  dplyr::summarize(passage_estimate = sum(count, na.rm = T)) |> 
  mutate(stream = "yuba river")

yuba_spring_passage_estimates <- yuba_passage_estimates |> 
  filter(run == "spring",
         !year %in% c(2016, 2017, 2019)) |> 
  rename(count = passage_estimate) |> 
  ungroup() |> 
  mutate(data_type = "upstream_estimate") |> 
  select(year, stream, count, data_type)

# Combine and save
annual_adult_raw <- bind_rows(battle_redd,
                          clear_redd,
                          battle_clear_passage,
                          butte_carcass,
                          data_from_ryan,
                          feather_spring_spawner,
                          yuba_spring_passage_estimates)

# Apply years to exclude

adult_years_exclude <- read_csv("data-raw/helper-tables/years_to_exclude_adult_datasets.csv") |> 
  select(-reason_for_exclusion) |> 
  mutate(exclude = T,
         data_type = case_when(data_type == "carcass" ~ "carcass_estimate",
                               data_type == "upstream passage" ~ "upstream_estimate",
                               T ~ data_type))
annual_adult <- annual_adult_raw |> 
  left_join(adult_years_exclude) |> 
  filter(is.na(exclude)) |> 
  select(-exclude)

usethis::use_data(annual_adult, overwrite = TRUE)
