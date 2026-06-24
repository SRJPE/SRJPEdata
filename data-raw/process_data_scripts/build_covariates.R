library(SRJPEdata)
library(lubridate)
library(dplyr)
library(CDECRetrieve)
library(dataRetrieval)
library(tidyverse)
library(zoo)
library(SRJPEdata)

# STOCK RECRUIT COVARIATES
# ----------------------------------------------------------------------------
# --- Source data ------------------------------------------------------------
standard_temperature <-  temp
standard_flow <- flow_daily         

# --- TEMP ---------------------------------------------------------------------
# --- Degree days (spawning/incubation, Aug-Dec) -----------------------------
# Sum of daily mean temperatures Aug-Dec by year and stream. For streams with
# multiple locations the max daily mean is selected.
monthly_mean <- standard_temperature |>
  filter(gage_number != "LCC" & !site_group %in% c("upper feather hfc", "lower feather river")) |> # UCC more representative of spawning; LFC more representative of spawning
  mutate(year = lubridate::year(date),
         month = lubridate::month(date),
         value = ifelse(is.nan(value), NA, value)) |>
  group_by(year, month, stream, statistic, parameter) |>
  summarize(monthly_average = mean(value, na.rm = T))

std_temp_dd_spawn <- standard_temperature |>
  filter(gage_number != "LCC" & !site_group %in% c("upper feather hfc", "lower feather river")) |> # UCC more representative of spawning
  mutate(year = year(date),
         rm = case_when(stream %in% c("feather river") & year == 1997 ~ "incomplete",
                        stream %in% c("feather river") & year == 1999 ~ "incomplete",
                        stream %in% c("deer creek", "mill creek") & year == 1998 ~ "incomplete",
                        stream %in% c("butte creek", "yuba river") & year == 1999 ~ "incomplete",
                        T ~ "complete"),
         value = ifelse(is.nan(value), NA, value)) |>
  group_by(year, stream, statistic, parameter) |>
  arrange() |>
  mutate(rolling_3_day_mean = rollapply(value, 3, mean, align = "center", fill = NA),
         value = ifelse(is.na(value), rolling_3_day_mean, value),
         month = month(date)) |>
  left_join(monthly_mean) |>
  mutate(value = ifelse(is.na(value), monthly_average, value)) |>
  filter(month(date) %in% c(8:12), stream != "sacramento river", rm != "incomplete") |> # spawning/incubation; tributaries only
  select(date, year, stream, statistic, value) |>
  pivot_wider(id_cols = c(date, year, stream),
              values_from = "value", names_from = "statistic") |>
  group_by(date, stream, year) |>
  summarize(max_mean = max(mean)) |>
  group_by(year, stream) |>
  summarize(gdd_spawn = sum(max_mean, na.rm = T)) |> glimpse()

# --- Sacramento thermal stress (migration, Mar-May) -------------------------
# Sum of days greater than 20 C. base threshold:
# https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0204274

gdd_base_sac <- 20
migratory_months <- 3:5

gdd_sac <- standard_temperature |>
  mutate(month = month(date),
         year = year(date)) |>
  filter(month %in% migratory_months,
         site_group == "knights landing",
         stream == "sacramento river",
         gage_number != "reported at RST",
         statistic == "mean",
         !is.na(value)) |>
  mutate(gdd_sac = value - gdd_base_sac,
         gdd_sac = ifelse(gdd_sac < 0, 0, gdd_sac)) |>
  group_by(year) |>
  summarise(value = sum(gdd_sac, na.rm = T)) |>
  ungroup() |>
  mutate(stream = "sacramento river",
         lifestage = "migration",
         covariate_type = "temperature",
         covariate_structure = "gdd_sacramento")

# --- Day/week of year when 7DADM is above 13 C ------------------------------
# Calculated on max temperature; interpolated NAs with weekly mean; first date
# above 13 C per year/stream (Mar-Dec, adults not in tribs Jan-Feb).
std_temp_7dadm <- standard_temperature |>
  filter(gage_number != "LCC" & !site_group %in% c("upper feather hfc", "lower feather river", "tisdale")) |>
  filter(statistic == "max") |>  # 7DADM requires max temperature
  mutate(year = year(date)) |>   # year grouping so rolling mean applies per year
  group_by(year, stream) |>
  arrange(stream, date) |>
  mutate(roll_7 = rollapply(value, 7, mean, align = "center", fill = NA))

# Weekly mean of the rolling mean, used to fill NAs
std_temp_7dadm_week <- std_temp_7dadm |>
  mutate(week = week(date)) |>
  group_by(week, stream, year) |>
  summarize(mean_7dadm = mean(roll_7, na.rm = T))

# Fill NAs with weekly mean
std_temp_7dadm_interpolated <- std_temp_7dadm |>
  mutate(week = week(date)) |>
  left_join(std_temp_7dadm_week) |>
  mutate(roll_7 = ifelse(is.na(roll_7), mean_7dadm, roll_7))

std_temp_7dadm_above_13 <- std_temp_7dadm_interpolated |>
  filter(roll_7 > 13, month(date) %in% 3:12) |> # exclude Jan/Feb (adults not in tribs)
  group_by(year, stream) |>
  slice_min(date) |>
  select(date, year, week, stream) |>
  rename(above_13 = week) |> glimpse()

# Computed for reference; NOT carried into the final table (below-13 is
# intentionally excluded -- see vignette rationale).
std_temp_7dadm_below_13 <- std_temp_7dadm_interpolated |>
  filter(roll_7 < 13) |>
  group_by(year, stream) |>
  slice_min(date) |>
  select(date, year, week, stream) |>
  rename(below_13 = week)

std_temp_7dadm_final <- std_temp_7dadm_above_13 |>
  rename(above_13_temp_week = above_13) |>
  mutate(above_13_temp_day = yday(date)) |>
  select(stream, above_13_temp_day, above_13_temp_week, year) |> glimpse()

# --- Max temperature (weekly max summarized to annual) ----------------------
std_temp_weekly <- standard_temperature |>
  filter(gage_number != "LCC" & !site_group %in% c("upper feather hfc", "lower feather river")) |>
  filter(month(date) %in% c(8:12), stream != "sacramento river") |>
  mutate(week = week(date),
         year = year(date)) |>
  group_by(week, year, stream) |>
  summarize(w_max = max(value, na.rm = T)) |>  # max weekly temperature
  ungroup() |>
  group_by(stream, year) |>
  summarize(weekly_max_temp_max = max(w_max, na.rm = T),
            weekly_max_temp_mean = mean(w_max, na.rm = T),
            weekly_max_temp_median = median(w_max, na.rm = T)) |> glimpse()

# --- FLOW ---------------------------------------------------------------------
# --- Spawning/incubation flow summary (Aug-Dec) -----------------------------
std_flow_spawn_summary <- standard_flow |>
  filter(!site_group %in% c("upper feather hfc", "lower feather river")) |> # LFC more representative of spawning
  mutate(year = year(date)) |>
  filter(month(date) %in% c(8:12), stream != "sacramento river") |>
  group_by(date, year, stream) |>
  summarize(flow_cfs = max(value)) |>
  group_by(year, stream) |>
  summarize(mean = mean(flow_cfs, na.rm = T),
            median = median(flow_cfs, na.rm = T),
            max = max(flow_cfs, na.rm = T),
            min = min(flow_cfs, na.rm = T)) |>
  pivot_longer(cols = mean:min, values_to = "value", names_to = "statistic") |>
  mutate(value = ifelse(is.nan(value) | is.infinite(value), NA_real_, value))

# --- Rearing flow summary (tribs Nov-Jul, Sacramento Jan-Jul) ---------------
std_flow_rear_summary <- standard_flow |>
  mutate(year = ifelse(month(date) %in% c(1:7), year(date) - 1, year(date))) |> # brood year
  filter(month(date) %in% c(11:12, 1:7), stream != "sacramento river") |>
  group_by(date, year, stream) |>
  summarize(flow_cfs = max(value)) |>
  group_by(year, stream) |>
  summarize(mean = mean(flow_cfs, na.rm = T),
            median = median(flow_cfs, na.rm = T),
            max = max(flow_cfs, na.rm = T),
            min = min(flow_cfs, na.rm = T)) |>
  pivot_longer(cols = mean:min, values_to = "value", names_to = "statistic") |>
  mutate(value = ifelse(is.nan(value) | is.infinite(value), NA_real_, value))

# Sacramento rearing months trimmed (Nov-Dec considered too early)
std_flow_rear_sac_summary <- standard_flow |>
  mutate(year = ifelse(month(date) %in% c(1:7), year(date) - 1, year(date))) |> # brood year
  filter(month(date) %in% c(1:7), stream == "sacramento river") |>
  group_by(date, year, stream) |>
  summarize(flow_cfs = max(value)) |>
  group_by(year, stream) |>
  summarize(mean = mean(flow_cfs, na.rm = T),
            median = median(flow_cfs, na.rm = T),
            max = max(flow_cfs, na.rm = T),
            min = min(flow_cfs, na.rm = T)) |>
  pivot_longer(cols = mean:min, values_to = "value", names_to = "statistic") |>
  mutate(value = ifelse(is.nan(value) | is.infinite(value), NA_real_, value))

std_flow_rear_combined <- bind_rows(std_flow_rear_summary, std_flow_rear_sac_summary)

std_flow_final <- std_flow_spawn_summary |>
  pivot_wider(id_cols = c(year, stream), values_from = "value", names_from = "statistic") |>
  rename(mean_flow = mean,
         median_flow = median,
         max_flow = max,
         min_flow = min) |>
  mutate(lifestage = "spawning and incubation") |>
  bind_rows(std_flow_rear_combined |>
              pivot_wider(id_cols = c(year, stream), values_from = "value", names_from = "statistic") |>
              rename(mean_flow = mean,
                     median_flow = median,
                     max_flow = max,
                     min_flow = min) |>
              mutate(lifestage = "rearing"))

# --- SAVE ---------------------------------------------------------------------
# Combined into one long table, joinable to SRJPEdata::site_lookup by site/year.

stock_recruit_covariates <- std_temp_dd_spawn |>
  mutate(lifestage = "spawning and incubation",
         covariate_type = "temperature") |>
  full_join(std_temp_7dadm_final |>
              mutate(lifestage = "spawning and incubation",
                     covariate_type = "temperature")) |>
  full_join(std_temp_weekly |>
              mutate(lifestage = "spawning and incubation",
                     covariate_type = "temperature")) |>
  full_join(std_flow_final |>
              mutate(covariate_type = "flow")) |>
  pivot_longer(cols = c(gdd_spawn, above_13_temp_day, above_13_temp_week,
                        weekly_max_temp_max, weekly_max_temp_mean, weekly_max_temp_median,
                        mean_flow, max_flow, min_flow, median_flow),
               values_to = "value", names_to = "covariate_structure") |>
  bind_rows(gdd_sac) |>
  filter(!is.na(value)) |>
  select(year, stream, lifestage, covariate_type, covariate_structure, value)

usethis::use_data(stock_recruit_covariates, overwrite = TRUE)

# FORECAST COVARIATES
# ----------------------------------------------------------------------------
# --- Spawning & incubation flow ---------------------------------------------
sr_covariates <- stock_recruit_covariates
si_min_flow <- sr_covariates |>
  filter(lifestage == "spawning and incubation", covariate_structure == "min_flow") |>
  as_tibble() |>
  mutate(name = "si_min_flow",
         water_year = NA) |>
  select(name, year, water_year, stream, value)

si_max_flow <- sr_covariates |>
  filter(lifestage == "spawning and incubation", covariate_structure == "max_flow") |>
  as_tibble() |>
  mutate(name = "si_max_flow",
         water_year = NA) |>
  select(name, year, water_year, stream, value)

# --- Spawning & incubation temperature --------------------------------------
si_max_temp <- sr_covariates |>
  filter(lifestage == "spawning and incubation", covariate_structure == "weekly_max_temp_max") |>
  as_tibble() |>
  mutate(name = "si_max_temp",
         water_year = NA) |>
  select(name, year, water_year, stream, value)

above_13 <- sr_covariates |>
  filter(covariate_structure == "above_13_temp_week") |>
  as_tibble() |>
  mutate(name = "above_13",
         water_year = NA) |>
  select(name, year, water_year, stream, value)

# --- Reservoir storage: Keswick (KES) ---------------------------------------
# https://cdec.water.ca.gov/dynamicapp/QueryMonthly?s=KES
# Earliest data available 1965. stream is NA -- applies to all streams, do not
# join on stream.
rs_keswick_monthly_raw <- cdec_query(station = "KES", sensor = "15",
                                     dur_code = "M", start_date = "1965-10-01")

rs_keswick_monthly <- rs_keswick_monthly_raw |>
  mutate(date = as.Date(datetime),
         year = year(date),
         value = parameter_value,
         name = "rs_keswick_monthly",
         water_year = NA,
         month = month(date),
         stream = NA) |>
  filter(month %in% c(12, 1, 2, 3)) |>
  select(name, year, water_year, month, stream, value)

# --- Reservoir storage: Shasta (11370000) -----------------------------------
# https://waterdata.usgs.gov/monitoring-location/11370000/
# Pulling the instantaneous value at midnight (statCd = 32400), which is the
# only way the query works; matches the data Flora provided in an excel.
rs_shasta_monthly_raw <- dataRetrieval::readNWISdv(siteNumbers = 11370000,
                                                   statCd = 32400,
                                                   parameterCd = "00054",
                                                   startDate = "1950-01-01",
                                                   endDate = "2025-01-01")

rs_shasta_monthly <- rs_shasta_monthly_raw |>
  mutate(date = as.Date(Date),
         year = year(date),
         value = X_00054_32400,
         name = "rs_shasta_monthly",
         water_year = NA,
         month = month(date),
         stream = NA) |>
  group_by(month, name, year, water_year, stream) |>
  summarise(value = mean(value, na.rm = TRUE)) |>
  filter(month %in% c(12, 1, 2, 3)) |>
  select(name, year, water_year, month, stream, value)

# --- Peak flow --------------------------------------------------------------
# Mean daily flow, max per month/year/stream. Sacramento River kept separate
# by site_group; other streams summarized by stream.
peak_flow_monthly <- flow_daily |>
  filter(statistic == "mean", stream == "sacramento river") |>
  mutate(month = month(date),
         year = year(date),
         name = "monthly_max_flow") |>
  group_by(stream, site_group, month, year, name) |>
  summarize(value = max(value, na.rm = TRUE)) |>
  bind_rows(
    flow_daily |>
      filter(statistic == "mean", stream != "sacramento river") |>
      mutate(month = month(date),
             year = year(date),
             name = "monthly_max_flow") |>
      group_by(stream, month, year, name) |>
      summarize(value = max(value, na.rm = TRUE))
  )

# --- 3-category water year type ---------------------------------------------
# CA Open Data Portal. Aggregate WYT into 3 categories: C, D/BN/AN, W.
wy_url <- "https://data.cnra.ca.gov/dataset/8f7c9792-652a-4f5e-95ad-707961dfc3f5/resource/da64051a-7751-48e1-ab59-39c73a3ea52d/download/cdec-water-year-type-jun-2025.xlsx"
temp_file <- tempfile(fileext = ".xlsx")
download.file(wy_url, temp_file, mode = "wb")
wy_raw <- readxl::read_xlsx(temp_file)

wy <- wy_raw |>
  filter(!is.na(WY)) |>
  mutate(wy_type = case_when(WYT %in% c("D", "BN", "AN") ~ "D/BN/AN",
                             TRUE ~ WYT),
         year = NA,
         water_year = WY,
         name = "3_category_wy_type",
         stream = NA,
         text_value = wy_type) |>
  select(name, year, water_year, stream, text_value)

# --- 3-category flow exceedance year type -----------------------------------
# Per CDFW-IFP-005 flow duration methodology. Mean annual discharge per stream,
# ranked and split into Wet (top 33%) / Average (mid) / Dry (bottom).

gage_ids <- c(
  `battle creek`     = "11376550",
  `butte creek`      = "11390000",
  `clear creek`      = "11372000",
  `deer creek`       = "11383500",
  `feather river`    = "11407000",
  `mill creek`       = "11381500",
  `yuba river`       = "11421000",
  `sacramento river` = "11390500"
)

start_date <- format(Sys.Date() - 30 * 365, "%Y-%m-%d")  # ~30 years ago
end_date   <- format(Sys.Date(), "%Y-%m-%d")

flow_list <- lapply(gage_ids, function(site) {
  readNWISdv(siteNumbers = site, parameterCd = "00060",
             startDate = start_date, endDate = end_date)
})

feather_post_2023 <- CDECRetrieve::cdec_query(station = "TFB", dur_code = "H",
                                              sensor_num = "20",
                                              start_date = "2023-10-01") |>
  mutate(parameter_value = ifelse(parameter_value < 0, NA_real_, parameter_value)) |>
  group_by(date = as.Date(datetime)) |>
  summarise(flow_cfs = ifelse(all(is.na(parameter_value)), NA, mean(parameter_value, na.rm = TRUE))) |>
  mutate(site_name = "feather river",
         month = month(date),
         year = year(date),
         water_year = ifelse(month >= 10, year + 1, year))

combined_flow <- bind_rows(
  lapply(names(flow_list), function(name) {
    flow_list[[name]] |>
      mutate(
        date = as.Date(Date),
        flow_cfs = X_00060_00003,
        site_name = name,
        month = month(date),
        year = year(date),
        water_year = ifelse(lubridate::month(date) >= 10,
                            lubridate::year(date) + 1,
                            lubridate::year(date))) |>
      select(site_name, date, flow_cfs, month, year, water_year)
  })) |>
  bind_rows(feather_post_2023) |>
  filter(!is.na(date))

mean_discharge_by_site <- combined_flow |>
  group_by(site_name, water_year) |>
  summarize(mean_discharge = mean(flow_cfs, na.rm = TRUE), .groups = "drop")

# Flow exceedance: P = 100 * [ M / (n + 1) ]. Essentially the same as the
# rank/3 approach; using exceedance for consistency with CDFW.
water_year_types <- mean_discharge_by_site |>
  group_by(site_name) |>
  arrange(desc(mean_discharge)) |>
  mutate(rank = row_number(),
         n_years = n(),
         exceedance_probability = 100 * (rank / (n_years + 1)),
         water_year_type = case_when(
           exceedance_probability <= 33.3 ~ "Wet",
           exceedance_probability > 33.3 & exceedance_probability <= 66.3 ~ "Average",
           TRUE ~ "Dry"))

flow_water_year_type <- water_year_types |>
  mutate(name = "3_category_flow_exceedance_year_type",
         year = NA,
         stream = site_name,
         text_value = as.character(water_year_type)) |>
  ungroup() |>
  select(name, year, water_year, stream, text_value)

# =============================================================================
# Combine and save
forecast_covariates <- bind_rows(
  si_min_flow, si_max_flow, si_max_temp, above_13,
  rs_keswick_monthly, rs_shasta_monthly,
  flow_water_year_type, wy, peak_flow_monthly
)

# checks
# unique(forecast_covariates$name)
# unique(forecast_covariates$stream)
# filter(forecast_covariates, !name %in% c("rs_monthly", "3_category_wy_type") & is.na(stream))

usethis::use_data(forecast_covariates, overwrite = TRUE)
