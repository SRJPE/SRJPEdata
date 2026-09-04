# Cache flow data

# As of Aug 28 2026 dataRetrieval only allows 3 years of continuous data to be downloaded at once.
# Daily downloads do not have a time restriction though in some cases only mean daily flow is available.
# Min and max daily flows are important for salmon.

# The goal of this script is to pull the full record of continuous data for a site, calculate the mean, min, max
# and cache the data object. The pull_flow_data script would then pull the continuous data for the past two years
# merge with the cached data object and remove any duplicates.

# This script is NOT part of the biweekly data-raw/update_data.R pipeline. Pulling decades of
# 15-minute continuous data in 3-year chunks is slow, and the cached object only needs to be
# refreshed occasionally (e.g. once a year) to extend the historical record it covers.

library(tidyverse)
library(dataRetrieval)

# Only sites with a single USGS gage are cached here using continuous (15-minute) data. Feather
# River HFC/LFC are the sum of three separate gages (ORF + TFB + TAO), so a daily min/max can't be
# derived by combining each gage's own min/max. Lower Feather River comes from CDEC hourly data,
# which has no 3-year request limit. Both are pulled fresh each time in pull_flow_data.R instead.
flow_gage_lookup <- tibble::tribble(
  ~stream,             ~site_group,               ~gage_agency, ~gage_number,
  "battle creek",      "battle creek",            "USGS",       "11376550",
  "butte creek",       "butte creek",             "USGS",       "11390000",
  "clear creek",       "clear creek",             "USGS",       "11372000",
  "deer creek",        "deer creek",              "USGS",       "11383500",
  "mill creek",        "mill creek",              "USGS",       "11381500",
  "sacramento river",  "tisdale",                 "USGS",       "11390500",
  "sacramento river",  "knights landing",         "USGS",       "11390500",
  "sacramento river",  "red bluff diversion dam", "USGS",       "11377100",
  "yuba river",        "yuba river",              "USGS",       "11421000"
)

# Cache the continuous record up through two years ago. pull_flow_data.R covers the most recent
# two years (within dataRetrieval's 3-year request limit), so the two scripts never need to overlap.
cache_start_date <- as.Date("1988-01-01") # earliest continuous record for these gages is ~1987-1988
cache_end_date <- Sys.Date() - lubridate::years(2)

## Helper: pull and summarize the full continuous flow record for one gage -----------------
# dataRetrieval::read_waterdata_continuous() only allows 3 years per request, so this loops over
# sequential 3-year windows and summarizes each to a daily mean, min, and max. Out-of-range
# windows (e.g. before a gage's record begins) simply return no rows and are dropped.
cache_continuous_flow_stats <- function(gage_number, start_date, end_date) {
  chunk_starts <- seq(start_date, end_date, by = "3 years")

  daily_stats <- purrr::map(chunk_starts, function(chunk_start) {
    chunk_end <- min(chunk_start + lubridate::years(3) - lubridate::days(1), end_date)

    message(
      "Pulling continuous flow for USGS-", gage_number, ": ", chunk_start, " to ", chunk_end
    )

    continuous_query <- dataRetrieval::read_waterdata_continuous(
      monitoring_location_id = paste0("USGS-", gage_number),
      parameter_code = "00060",
      time = paste0(chunk_start, "/", chunk_end)
    )

    if (nrow(continuous_query) == 0) return(NULL)

    continuous_query |>
      dplyr::mutate(
        date = as.Date(time),
        value = ifelse(value < 0, NA_real_, value) # negative instantaneous readings are sensor noise
      ) |>
      dplyr::group_by(date) |>
      dplyr::summarise(
        mean = ifelse(all(is.na(value)), NA_real_, mean(value, na.rm = TRUE)),
        min = ifelse(all(is.na(value)), NA_real_, min(value, na.rm = TRUE)),
        max = ifelse(all(is.na(value)), NA_real_, max(value, na.rm = TRUE)),
        .groups = "drop"
      )
  })

  dplyr::bind_rows(daily_stats)
}

# Pull each distinct gage once (sac river gage covers both tisdale and knights landing site
# groups) and join the daily stats back onto every site_group that uses it -----------------
distinct_gages <- flow_gage_lookup |>
  dplyr::distinct(gage_agency, gage_number)

gage_daily_stats <- distinct_gages |>
  dplyr::mutate(
    daily_stats = purrr::map(
      gage_number,
      cache_continuous_flow_stats,
      start_date = cache_start_date,
      end_date = cache_end_date
    )
  ) |>
  tidyr::unnest(daily_stats)

flow_data_cached <- flow_gage_lookup |>
  # many-to-many is expected here: the sac river gage intentionally matches two site_groups
  # (tisdale, knights landing), and each site_group matches many dates
  dplyr::left_join(gage_daily_stats, by = c("gage_agency", "gage_number"), relationship = "many-to-many") |>
  tidyr::pivot_longer(c(mean, min, max), names_to = "statistic", values_to = "value") |>
  dplyr::mutate(parameter = "flow") |>
  dplyr::select(date, stream, site_group, gage_agency, gage_number, parameter, statistic, value) |>
  glimpse()

# Check for duplicates, same check used in pull_flow_data.R --------------------------------
find_duplicates <- flow_data_cached |>
  dplyr::group_by(date, stream, site_group, parameter, statistic) |>
  dplyr::tally() |>
  dplyr::filter(n > 1)

if (nrow(find_duplicates) > 0) {
  stop("Duplicates exist in flow_data_cached. Resolve these duplicates before proceeding.")
}

# Cache the object for pull_flow_data.R to read in, bind with the most recent two years of
# continuous data, and de-duplicate before reshaping to weekly stats -----------------------
dir.create("data-raw/pull_data_scripts/cached_data", showWarnings = FALSE)
saveRDS(flow_data_cached, "data-raw/pull_data_scripts/cached_data/flow_data_cached.rds")
