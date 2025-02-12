library(SRJPEdata)
library(tidyverse)

# Create lookup table of years with adult data and rst data by stream
# To match up the juvenile and adult data: add 1 to the adult year
# sr_year, adult_year, run_year, site, rst (T/F), redd (T/F), carcass (T/F), holding (T/F), passage (T/F)

# rst years to exclude are already applied
rst_data <- weekly_juvenile_abundance_catch_data |> 
  filter(!is.na(count)) |> 
  distinct(run_year, stream, site) |> 
  mutate(brood_year = run_year - 1,
         rst = T)
# adults years to exclude already applied
adult_data <- observed_adult_input |> 
  select(year, stream, data_type, count) |> 
  pivot_wider(id_cols = c(year, stream), names_from = "data_type", values_from = "count") |> 
  mutate(passage = ifelse(upstream_estimate == "NULL", F, T),
         redd = ifelse(redd_count == "NULL", F, T),
         holding = ifelse(holding_count == "NULL", F, T),
         carcass = ifelse(carcass_estimate == "NULL", F, T)) |> 
  select(year, stream, passage, redd, holding, carcass) |> 
  rename(brood_year = year)

stock_recruit_year_lookup <- full_join(rst_data, adult_data) |> 
  rowwise() |> 
  mutate(rst = ifelse(is.na(rst), FALSE, rst),
         adult = ifelse((is.na(carcass) & is.na(passage) & is.na(redd) & is.na(holding)), FALSE, TRUE), 
         sr_possible = ifelse((isTRUE(rst) & isTRUE(adult)), TRUE, FALSE)) |> 
  filter(sr_possible) |> 
  select(-sr_possible) |> # SHOULD REMOVE ALL OF SACRAMENTO
  # BATTLE CREEK
  filter(site != "lbc") |> # LBC not used in SR filter to only ubc, see site_overview vignette for why
  # BUTTE CREEK
  filter(site != "adams dam") |> # okie should be used in SR, see site_overview vignette for why
  # CLEAR CREEK
  filter(site != "ucc") |> # lcc should be used in SR, see site_overview vignette for why
  # FEATHER RIVER
  filter(site != "steep riffle", 
         site != "lower feather river", 
         site != "gateway riffle", 
         site != "eye riffle") |> # herringer riffle should be used all years in SR except in 2011 we use sunset pumps, filter all else out, see site_overview vignette for why
  # YUBA RIVER
  filter(site != "yuba river") |> 
  mutate(recommended_adult_data = case_when(stream %in% c("battle creek", "clear creek", "mill creek") ~ "redd", 
                                           stream == "deer creek" ~ "holding", 
                                           stream %in% c("butte creek", "feather river") ~ "carcass", 
                                           stream == "yuba river" ~ "passage")) |> 
  mutate(have_recommended_adult_data = case_when(stream %in% c("battle creek", "clear creek", "mill creek") & redd ~ TRUE, 
                                                 stream == "deer creek" & holding ~ TRUE, 
                                                 stream %in% c("butte creek", "feather river") & carcass ~ TRUE, 
                                                 stream == "yuba river" &  passage ~ TRUE,
                                                 TRUE ~ FALSE)) |> 
  glimpse()

# TODO update with site selections from markdown

View(stock_recruit_year_lookup)


usethis::use_data(stock_recruit_year_lookup, overwrite = TRUE)


# Combine the adult data and sr covariates

# Todo - fill in recent years for battle and clear
stock_recruit_model_inputs <- observed_adult_input |> 
  select(year, stream, data_type, count) |> 
  group_by(year, stream, data_type) |> 
  summarize(count = sum(count)) |> # clean this up, wherever duplicate is coming from
  pivot_wider(names_from = "data_type", values_from = "count") |> 
  rename(holding = holding_count,
         passage = upstream_estimate,
         carcass = carcass_estimate,
         redd = redd_count) |> 
  left_join(
    stock_recruit_covariates |>
      ungroup() |>
      select(-stream_site) |> # this isn't doing anything and is confusing so remove
      mutate(site_group = case_when(
        gage_number %in% c("UBC", "UCC", "LCC", "LBC") ~ tolower(gage_number),
        # for some clear/battle the upper/lower being noted in gage_agency
        is.na(site_group) ~ stream,
        T ~ site_group),
        lifestage = ifelse(lifestage == "spawning and incubation", "spawning", "rearing"),
        covariate_structure = paste0(lifestage, "_", covariate_structure)
      ) |>
      filter(
        site_group %in% c(
          "ubc",
          "battle creek",
          "butte creek",
          "clear creek",
          "lcc",
          "deer creek",
          "upper feather hfc",
          "feather river",
          "mill creek",
          "yuba river",
          "sacramento river"
        )
      ) |> # select for the locations chosen for stock recruit (see sites vignette)
      select(year, stream, covariate_structure, value) |>
      group_by(stream, year, covariate_structure) |>
      summarize(value = mean(value, na.rm = T)) |> # if there are multiple sources, take the mean for now - clean this up
      ungroup() |>
      group_by(stream, covariate_structure) |>
      mutate(standardized_value = as.vector(scale(value))) |>
      pivot_wider(
        id_cols = c(year, stream),
        names_from = "covariate_structure",
        values_from = "standardized_value"
      ))

usethis::use_data(stock_recruit_model_inputs, overwrite = TRUE)
