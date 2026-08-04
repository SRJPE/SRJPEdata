library(tidyverse)
library(lubridate)


trap <- SRJPEdata::rst_trap
catch <- SRJPEdata::rst_catch

# SIMPLE PADDING
padded_catch <- catch |>
  mutate(date = as_date(date)) |> # drop the stray 12:00:00 timestamps so padr treats same-day records as one
  group_by(stream, site, subsite, site_group, date) |>
  summarise(count = sum(count, na.rm = TRUE), .groups = "drop") |>
  padr::pad(interval = "day", group = c("stream", "site", "subsite", "site_group")) |>
  mutate(
    trap_status = case_when(
      is.na(count) ~ "trap not fishing (assumed)",
      count > 0 ~ "trap fishing - fish caught",
      count == 0 ~ "trap fishing - zero catch"
    )
  )


padded_catch |> count(trap_status)


selected_stream <- "butte creek"
selected_site <- "okie dam" 
selected_subsite <- "okie dam 1"

plot_data <- padded_catch |>
  filter(stream == selected_stream, site == selected_site, subsite == selected_subsite) |>
  mutate(year = year(date), day = yday(date))

ggplot(plot_data, aes(x = day, y = year, color = trap_status)) +
  geom_point(size = 1) +
  scale_color_manual(values = c(
    "trap not fishing (assumed)" = "#DC863B",
    "trap fishing - fish caught" = "#A5C2A3",
    "trap fishing - zero catch" = "#3F5151"
  )) +
  scale_y_reverse(breaks = scales::pretty_breaks()) +
  labs(
    title = paste0("Trap status by day: ", selected_stream, " - ", selected_site),
    x = "Day of year", y = "Year", color = "Trap status"
  ) +
  theme_minimal()









# ALTERNATIVE APROACH - TEST 
# Ultimatly too complicated and not enough data to consistantly support it 
# TRAPPING PERIODS -------------------------------------------------------------
# looking at trapping periods
trapping_periods <- trap |>
  arrange(stream, site, subsite, trap_start_date, trap_stop_date) |>
  group_by(stream, site, subsite, site_group) |>
  mutate(
    start_date = as_date(trap_start_date),
    stop_date = as_date(trap_stop_date),
    start_date = if_else(is.na(start_date), as_date(lag(stop_date)), start_date),
    stop_date = if_else(is.na(stop_date), as_date(lead(start_date)), stop_date)
  ) |>
  ungroup() |>
  filter(!is.na(start_date), !is.na(stop_date)) |>
  mutate(interval_days = as.numeric(stop_date - start_date)) |>
  select(stream, site, subsite, site_group, start_date, stop_date, interval_days)

# Lots of weird intervals....
excluded_trap_periods <- trapping_periods |>
  filter(interval_days < 0 | interval_days > 7)

trap_periods <- trapping_periods |>
  filter(interval_days >= 0, interval_days <= 7)

# Expand each visit into the individual days the trap was deployed ----------
trap_operational_days <- trap_periods |>
  mutate(date = map2(start_date, stop_date, seq, by = "day")) |>
  select(stream, site, subsite, site_group, date) |>
  unnest(date) |>
  distinct() |>
  mutate(trap_operational = TRUE)

# Build a complete daily calendar spanning each trap's period of record -----
trap_daily_calendar <- trap_operational_days |>
  group_by(stream, site, subsite, site_group) |>
  summarise(min_date = min(date), max_date = max(date), .groups = "drop") |>
  mutate(date = map2(min_date, max_date, seq, by = "day")) |>
  select(stream, site, subsite, site_group, date) |>
  unnest(date)

# Daily catch, summed in case of multiple records per trap/day --------------
daily_catch <- catch |>
  group_by(stream, site, subsite, site_group, date) |>
  summarise(count = sum(count, na.rm = TRUE), has_catch_record = TRUE, .groups = "drop")

# Combine calendar, operational days, and catch to classify every day -------
traps_not_trapping <- trap_daily_calendar |>
  left_join(trap_operational_days, by = c("stream", "site", "subsite", "site_group", "date")) |>
  left_join(daily_catch, by = c("stream", "site", "subsite", "site_group", "date")) |>
  mutate(
    trap_operational = coalesce(trap_operational, FALSE),
    has_catch_record = coalesce(has_catch_record, FALSE),
    trap_status = case_when(
      !trap_operational ~ "trap not fishing",
      trap_operational & has_catch_record & count > 0 ~ "trap fishing - fish caught",
      trap_operational & has_catch_record & count == 0 ~ "trap fishing - zero catch",
      trap_operational & !has_catch_record ~ "trap fishing - no catch record"
    )
  ) |>
  select(stream, site, subsite, site_group, date, trap_operational, count, trap_status) |>
  arrange(stream, site, subsite, date)

traps_not_trapping |>
  count(trap_status) |>
  print()

plot_data_alt_approach <- traps_not_trapping |>
  filter(stream == selected_stream, site == selected_site, subsite == selected_subsite) |>
  mutate(year = year(date), day = yday(date))

ggplot(plot_data_alt_approach, aes(x = day, y = year, color = trap_status)) +
  geom_point(size = 1) +
  scale_color_manual(values = c(
    "trap not fishing" = "#DC863B",
    "trap fishing - fish caught" = "#A5C2A3",
    "trap fishing - zero catch" = "#3F5151",
    "trap fishing - no catch record" = "#9B110E")) +
  scale_y_reverse(breaks = scales::pretty_breaks()) +
  labs(
    title = paste0("Trap status by day: ", selected_stream, " - ", selected_site),
    x = "Day of year", y = "Year", color = "Trap status"
  ) +
  theme_minimal()


# check butte creek 

rst_trap |> 
  filter(stream == "butte creek", site == "okie dam") |> 
  filter(year(trap_start_date) %in% c(2025)) |> 
  View()

                                                                          