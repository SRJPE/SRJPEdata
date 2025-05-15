## Review dataset handling of hatchery 
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
         natural = count - expanded_weekly_hatch_count, 
         hatchery = ifelse(expanded_weekly_hatch_count > count, 
                           NA, expanded_weekly_hatch_count)) |> 
  # select(-count, -expanded_weekly_hatch_count) |>  
  # pivot_longer(natural:hatchery, names_to = "origin", values_to = "count") |> 
  glimpse()

# Histogram plot
weekly_standard_catch_with_hatch_designation |> 
  filter(count != 0) |> 
  ggplot(aes(x = natural)) + 
  geom_histogram() + 
  facet_wrap(~stream, scales = "free_x")

weekly_standard_catch_with_hatch_designation |> 
  filter(count != 0) |> 
  select(-count) |> 
  pivot_longer(natural:hatchery, names_to = "origin", values_to = "count") |>
  ggplot(aes(x = count, fill = origin)) +
  geom_histogram() + 
  facet_wrap(~stream, scales = "free_x")

# Plot to see which values are negative
negative_values <- weekly_standard_catch_with_hatch_designation |> 
  filter(natural < 0 ) |> glimpse()

# where are these
negative_values$stream |> unique()
negative_values$site |> unique()

# one instance on butte creek, count was 1 so expanded was 4 and therefore negative 
negative_values |> filter(site == "okie dam") |> glimpse()

# one hallwood where catch was 195 and expanded hatch count was 200, check that this coincides with release trial 
negative_values |> filter(site == "hallwood") |> glimpse()

# Dig in a little more on what is happening with these records 
negative_values |> filter(site == "knights landing") |> glimpse()


## pull in hatchery release data 
## Data from sturrock et all data analysis done as part of recent hatchery analysis
## https://baydeltalive.com/fish/hatchery-releases
## ONLY CONTAINS FALL RUN RELEASES, find date for adipose clipped 
hatchery_release <- readxl::read_excel("data-raw/helper-tables/CVFRChin_RELEASE DB_v2_POSTED011519.xlsx", 
                   sheet = 2) |> 
  filter(Hatchery %in% c("CNFH", "COL", "FRH", "FEA") & 
           Year_start > 1991, 
           `Use?` == "Y") |> 
  # FIND SITES UPSTREAM OF SRJPE TRAPS
  filter(Release_site %in% c("Red Bluff Diversion Dam", "Verona", "Coleman NFH", "Princeton", 
                              "Glenn", "Balls Ferry", "Hunters MHP", "Bow River Boat Ramp", 
                              "Below Red Bluff Diversion Dam", "Woodson Bridge", "Research", 
                              "Los Molinos", "Feather River Hatchery", "Gridley", "Dry Creek", 
                              "Honcut Creek South Fork", "Bear River", "Grimes", "Lake Almanor", 
                              "Lake Oroville", "Honcut Creek North Fork", "Live Oak Boat Ramp", 
                              "Tisdale Weir", "Yuba City", "Oroville Wildlife Area", "Spaulding Reservoir", 
                              "Shasta Lake", "River Mile 206", "Boyd's Pump", "3331 Walnut Ave., Marysville, Ca. 95901", 
                              "Lime Saddle", "Mill Creek", "Deer Creek")) |> 
  glimpse()
  
# looks like lots of huge releases on battle, 
# a bunch on feather, a few on yuba, and then a lot that would effect sacramento
hatchery_release |> 
  ggplot(aes(x = Release_year, y = Total_N, color = Release_type)) +
  geom_point() +
  facet_wrap(~Release_location, scales = "free_y")

# group for relevant SRJPE stream 
hatchery_release_groups <- hatchery_release |> 
  mutate(srjpe_stream = tolower(case_when(Release_location == "Battle Creek" ~ "Battle Creek", 
                                  Release_location %in% c("Bear Rier", "Dry Creek", 
                                                           "Honcut River", "Sacramento River") ~ "Sacramento River", 
                                  Release_location == "Feather River" ~ "Feather River", 
                                  Release_location == "Yuba River" ~ "Yuba Creek"))) |>
  select(year = Year_start, 
         month = Month_start, 
         day = Day_start, 
         hatchery = Hatchery, 
         total_released = Total_N, 
         release_site = Release_site, 
         stream = srjpe_stream) |> 
  glimpse()

# Join with catch data
catch_with_hatch <- catch_with_inclusion_criteria |> 
  mutate(year = lubridate::year(date), 
         month = lubridate::month(date), 
         day = lubridate::day(date)) |> 
  left_join(hatchery_release_groups)

catch_with_hatch |> 
  filter(count != 0, 
         stream == "sacramento river", 
         site != "red bluff diversion dam", year == 2020) |> 
  ggplot(aes(x = date, 
             y = count, 
             color = adipose_clipped, 
             alpha = .5)) +
  geom_point() 

# Quick map to filter down release sites to ~30 
library(ggplot2)
library(osmdata)
library(sf)
library(ggspatial) 
filtered_hatchery_release <- hatchery_release |>
  filter(Release_site_long < -115,
         Release_site_lat > 38.75) |> glimpse()

filtered_hatchery_release$Release_site |> unique()

hatchery_sf <- st_as_sf(filtered_hatchery_release, 
                        coords = c("Release_site_long", "Release_site_lat"), 
                        crs = 4326)

# Get OpenStreetMap background for the bounding box of the data
bbox <- st_bbox(hatchery_sf)  # Bounding box of the dataset

# Create the map
ggplot() +
  annotation_map_tile(type = "osm") +  # OpenStreetMap tiles
  geom_sf(data = hatchery_sf, color = "red", size = 3) +  # Plot release points
  labs(title = "Hatchery Release Sites", x = "Longitude", y = "Latitude") +
  theme_minimal()
