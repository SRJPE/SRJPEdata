# Script to cache helper tables to rda 

library(tidyverse)
library(readxl)

# Read in river km table 
sites_to_remove <- c("lbc",  "adams dam", "live oak", "sunset pumps", "shawns beach")
river_km_lookup <- read_xlsx("data-raw/helper-tables/rst_distances_rkm_v4.xlsx") |>
  select(stream, site, site_latitude, site_longitude, group, distance_to, rkm_distance) |> 
  mutate(site = ifelse(site == "parrott_phelan_div_dam", "butte creek", site)) |> 
  filter(!site %in% sites_to_remove) |> 
  glimpse()

usethis::use_data(river_km_lookup, overwrite = TRUE)
