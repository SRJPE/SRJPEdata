library(SRJPEdata)
library(tidyverse)

# Create lookup table of years with adult data and rst data by stream
# To match up the juvenile and adult data: add 1 to the adult year
# sr_year, adult_year, run_year, site, rst (T/F), redd (T/F), carcass (T/F), holding (T/F), passage (T/F)
rst_data <- weekly_juvenile_abundance_catch_data |> 
  filter(!is.na(count)) |> 
  distinct(run_year, stream) |> 
  mutate(year = run_year,
         rst = T)

adult_data <- observed_adult_input |> 
  select(year, stream, data_type, count) |> 
  pivot_wider(id_cols = c(year, stream), names_from = "data_type", values_from = "count") |> 
  mutate(passage = ifelse(upstream_estimate == "NULL", F, T),
         redd = ifelse(redd_count == "NULL", F, T),
         holding = ifelse(holding_count == "NULL", F, T),
         carcass = ifelse(carcass_estimate == "NULL", F, T)) |> 
  select(year, stream, passage, redd, holding, carcass) |> 
  rename(adult_year = year) |> 
  mutate(year =  adult_year + 1)

sr_year_lookup <- full_join(rst_data, adult_data) 

# Combine the adult data and sr covariates

# Todo - fill in recent years for battle and clear
sr_model_inputs <- stock_recruit_covariates |> 
  ungroup() |> 
  select(-stream_site) |> # this isn't doing anything and is confusing so remove
  mutate(site_group = case_when(gage_number %in% c("UBC","UCC","LCC","LBC") ~ tolower(gage_number), # for some clear/battle the upper/lower being noted in gage_agency
                                is.na(site_group) ~ stream,
                                T ~ site_group)) |> 
  filter(site_group %in% c("ubc", "battle creek","butte creek","clear creek","lcc", "deer creek", "upper feather hfc", "feather river",
                           "mill creek", "yuba river","sacramento river")) |> # select for the locations chosen for stock recruit (see sites vignette)
  select(year, stream, covariate_structure, value) |> 
  group_by(stream, year, covariate_structure) |> 
  summarize(value = mean(value, na.rm = T)) |> # if there are multiple sources, take the mean for now - clean this up
  pivot_wider(id_cols = c(year, stream), names_from = "covariate_structure", values_from = "value") |> 
  full_join(observed_adult_input |> 
              select(year, stream, data_type, count) |> 
              group_by(year, stream, data_type) |> 
              summarize(count = mean(count)) |> # clean this up, wherever duplicate is coming from
              pivot_wider(names_from = "data_type", values_from = "count")) |> 
  rename(holding = holding_count,
         passage = upstream_estimate,
         carcass = carcass_estimate,
         redd = redd_count)


