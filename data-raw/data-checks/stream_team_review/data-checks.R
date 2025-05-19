library(tidyverse)
library(SRJPEdata)
library(lubridate)

colors_full <-  c("#9A8822", "#F5CDB4", "#F8AFA8", "#FDDDA0", "#74A089", #Royal 2
                  "#899DA4", "#C93312", "#DC863B", # royal 1 (- 3)
                  "#F1BB7B", "#FD6467", "#5B1A18", # Grand Budapest 1 (-4)
                  "#D8B70A", "#02401B", "#A2A475", # Cavalcanti 1
                  "#E6A0C4", "#C6CDF7", "#D8A499", "#7294D4", #Grand Budapest 2
                  "#9986A5", "#EAD3BF", "#AA9486", "#B6854D", "#798E87" # Isle of dogs 2 altered slightly
)

#source("data-raw/pull_data_scripts/TEMP_pull_from_edi.R")
#write_csv(temp_catch, "data-raw/data-checks/stream_team_review/temp_catch2.csv")
weekly_juv_srjpedata <- SRJPEdata::weekly_juvenile_abundance_catch_data
temp_catch1 <- read_csv("data-raw/data-checks/stream_team_review/temp_catch1.csv")
temp_catch2 <- read_csv("data-raw/data-checks/stream_team_review/temp_catch2.csv")
# compare_temp_catch <- temp_catch |> 
#   rename(count_og = count) |> 
#   full_join(temp_catch1)
# 
# compare_weekly_temp_catch <- weekly_edi_catch2 |>
#   rename(count_og = count) |>
#   full_join(weekly_edi_catch2_1)
# filter(compare_weekly_temp_catch, count_og != count)
# filter to chinook
weekly_edi_catch1 <- temp_catch1 |> 
  mutate(week = week(date),
         year = year(date),
         species = tolower(species)) |> 
  filter(species %in% c("chinook", "chinook salmon") | is.na(species)) |> 
  group_by(stream, site, week, year) |> 
  summarize(count = sum(count, na.rm = T))

# remove adults and adipose clipped
weekly_edi_catch2 <- temp_catch1 |> 
  mutate(subsite = case_when(site == "okie dam" & is.na(subsite) ~ "okie dam 1", # fix missing subsites
                             stream == "battle creek" & is.na(subsite) & year(date) > 2004 ~ "ubc",
                             site == "yuba river" ~ "hal",
                             T ~ subsite),
         site = case_when(stream == "battle creek" & is.na(site) & year(date) > 2004 ~ "ubc",
                          stream == "yuba river" ~ "hallwood",
                          T ~ site),
         week = week(date),
         year = year(date),
         species = tolower(species),
         life_stage = ifelse(is.na(life_stage), "not recorded", tolower(life_stage)),
         remove = case_when(stream != "butte creek" & adipose_clipped == T ~ "remove",
                            T ~ "keep")) |> 
  filter((species %in% c("chinook", "chinook salmon") | is.na(species)),
         life_stage != "adult",
         remove == "keep") |> 
  group_by(stream, site, week, year) |> 
  summarize(count = sum(count, na.rm = T))

# weekly_edi_catch2_1 <- temp_catch2 |>
#   mutate(subsite = case_when(site == "okie dam" & is.na(subsite) ~ "okie dam 1", # fix missing subsites
#                              stream == "battle creek" & is.na(subsite) & year(date) > 2004 ~ "ubc",
#                              site == "yuba river" ~ "hal",
#                              T ~ subsite),
#          site = case_when(stream == "battle creek" & is.na(site) & year(date) > 2004 ~ "ubc",
#                           stream == "yuba river" ~ "hallwood",
#                           T ~ site),
#          week = week(date),
#          year = year(date),
#          species = tolower(species),
#          life_stage = ifelse(is.na(life_stage), "not recorded", tolower(life_stage)),
#          remove = case_when(stream != "butte creek" & adipose_clipped == T ~ "remove",
#                             T ~ "keep")) |>
#   filter((species %in% c("chinook", "chinook salmon") | is.na(species)),
#          life_stage != "adult",
#          remove == "keep") |>
#   group_by(stream, site, week, year) |>
#   summarize(count = sum(count, na.rm = T))

weekly_rst_catch <- SRJPEdata::rst_catch |> 
  mutate(week = week(date),
         year = year(date)) |> 
  group_by(stream, site, week, year) |> 
  summarize(count = sum(count, na.rm = T))

catch_compare_1 <- full_join(weekly_rst_catch |> 
                               rename(srjpedata_count = count),
                             weekly_edi_catch1) |> 
  mutate(p_diff = ((abs(count - srjpedata_count))/((count + srjpedata_count)/2)) * 100)

catch_compare_2 <- full_join(weekly_juv_srjpedata |> 
                               select(year, week, stream, site, count) |> 
                               rename(srjpedata_count = count),
                             weekly_edi_catch2) |> 
  mutate(p_diff = ((abs(count - srjpedata_count))/((count + srjpedata_count)/2)) * 100)

p_diff_summary_plot <- function(data_select, stream_select) {
  data_select |> 
    filter(stream == stream_select) |> 
    ggplot(aes(x = week, y = p_diff, color = site)) +
    geom_point() +
    scale_color_manual(values = colors_full) +
    facet_wrap(~year) +
    theme_bw() +
    labs(y = "percent difference")
}

p_diff_greater_than_2 <- function(data_select, stream_select) {
  data_select |> 
    filter(stream == stream_select, p_diff > 2) |> 
    ggplot(aes(x = week, y = p_diff, color = site)) +
    geom_point() +
    scale_color_manual(values = colors_full) +
    facet_wrap(~year) +
    theme_bw() +
    labs(y = "percent difference")
}

na_plot <- function(data_select, site_select) {
  data_select |> 
    filter(site== site_select, (is.na(srjpedata_count) & !is.na(count)) | (!is.na(srjpedata_count) & is.na(count))) |> 
    pivot_longer(cols = c(srjpedata_count, count), names_to = "count_type", values_to = "value") |> 
    ggplot(aes(x = week, y = value, color = count_type)) +
    geom_point() +
    scale_color_manual(values = colors_full) +
    facet_wrap(~year) +
    theme_bw() +
    labs(y = "count")
}

### Battle/Clear

#### Summary of the percent difference between data on EDI and data used for juvenile abundance model

p_diff_summary_plot(catch_compare_2, "battle creek")
