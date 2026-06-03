# Ingest data from GrandTab
# Jason Azat emails an excel file in June. The file mirrors the PDF which is the typical
# format and is challenging to use.

library(readxl)
library(tidyverse)

fall1 <- read_xls("data-raw/helper-tables/GrandTab.2025.06.09.xls", range = "C416:V491") |> 
  select(-c(SUM1, SUM2, Other)) |> 
  mutate(RunYear = as.numeric(gsub("\\[|\\]", "", RunYear)))

fall2 <- read_xls("data-raw/helper-tables/GrandTab.2025.06.09.xls", range = "C492:T567") |> 
  select(-c(SUM1, Other)) |> 
  mutate(RunYear = as.numeric(gsub("\\[|\\]", "", RunYear)))

fall3 <- read_xls("data-raw/helper-tables/GrandTab.2025.06.09.xls", range = "C568:N643") |> 
  select(-c(SUM1, SUM2)) |> 
  mutate(RunYear = as.numeric(gsub("\\[|\\]", "", RunYear)))

fall4 <- read_xls("data-raw/helper-tables/GrandTab.2025.06.09.xls", range = "C644:K719") |> 
  select(-c(SUM1)) |> 
  mutate(RunYear = as.numeric(gsub("\\[|\\]", "", RunYear)))

escapement_estimates_all_runs <- full_join(fall1, fall2) |> 
  full_join(fall3, by = "RunYear") |> 
  full_join(fall4, by = "RunYear") |> 
  filter(!is.na(RunYear)) |> 
  pivot_longer(2:48, names_to = "stream", values_to = "estimate") |> 
  mutate(run = "fall",
         species = "chinook salmon",
         data_type = "escapement estimate from grandtab",
         stream = tolower(stream)) |> 
  rename(run_year = RunYear) |> 
  filter(stream %in% c("battle","butte","clear","deer","feariv","mill","yuba")) |> 
  mutate(stream = case_when(stream == "feariv" ~ "feather river",
                            stream == "yuba" ~ "yuba river",
                            T ~ paste0(stream, " creek")))

usethis::use_data(escapement_estimates_all_runs, overwrite = T)
