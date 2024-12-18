# The goal of this script is to test final model data objects 
# Test weekly_juvenile_abundance_catch_data
test_that("weekly_juvenile_abundance_catch_data data coverage at the tributary level has not changed", {
  current_coverage <- weekly_juvenile_abundance_catch_data$stream |> unique() |> sort()
  # TODO where is feather? 
  expected_coverage <- c("battle creek", "butte creek", "clear creek", "deer creek", 
                         "feather river", "mill creek", "sacramento river", "yuba river")
  expect_equal(current_coverage, expected_coverage)
})


# Test weekly_juvenile_abundance_efficency_data
test_that("weekly_juvenile_efficeincy_catch_data data coverage at the tributary level has not changed", {
  current_coverage <- weekly_juvenile_abundance_efficiency_data$stream |> unique() |> sort()
  # TODO where is feather? 
  # Where are mill and deer
  expected_coverage <- c("battle creek", "butte creek", "clear creek", "deer creek", 
                         "feather river", "mill creek", "sacramento river", "yuba river")
  expect_equal(current_coverage, expected_coverage)
})

# years to exclude are actually excluded
test_that("weekly_juvenile_abundance_catch_data has the appropriate run years are included", {
  current_site_year_raw <- weekly_juvenile_abundance_catch_data |> 
    #filter(life_stage != "yearling") |> 
    #filter(count > 0) |> 
    distinct(stream, site, run_year) |> 
    mutate(site_year = paste0(site, "-", run_year))
  current_site_year <- sort(current_site_year_raw$site_year)
  chosen_site_year_raw <- chosen_site_years_to_model |> 
    select(monitoring_year, stream, site) |> 
    rename(run_year = monitoring_year) |> 
    mutate(site_year = paste0(site, "-", run_year)) |> 
    filter(!(run_year == 2025)) # make sure to remove this next year!
  chosen_site_year <- sort(chosen_site_year_raw$site_year)
  expect_equal(current_site_year, chosen_site_year)
})

# no missing values when there is catch data (even if catch is 0)
# Currently fails, there are nas in flow, standard flow, fork length, lifestage, hours fished, catch standardized by hours fished
test_that("there is no missing values (hours fished...ect) when there is catch data (even if catch is 0)", {
  catch <- weekly_juvenile_abundance_catch_data |> 
    filter(count >= 0) 
  stream_na = anyNA(catch$stream)
  site_na = anyNA(catch$site)
  flow_na = anyNA(catch$flow_cfs)
  std_flow_na = anyNA(catch$standardized_flow)
  fl_na = anyNA(catch$mean_fork_length)
  ls_na = anyNA(catch$life_stage)
  hf_na = anyNA(catch$hours_fished)
  as_hf_na = anyNA(catch$average_stream_hours_fished)
  ry_na = anyNA(catch$run_year)
  cshf_na = anyNA(catch$catch_standardized_by_hours_fished)
  
  nas = c(stream_na, site_na, flow_na, 
          fl_na, ls_na, hf_na, as_hf_na, 
          ry_na, cshf_na)
  expect_equal(c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE), 
               nas)
})


# check no -INf 
# no missing values when there is catch data (even if catch is 0)
# # when there are missing sampling weeks we should still include hours_fished and flow variables (these should not be missing)
# Currently fails, there are nas in flow, standard flow, fork length, lifestage, hours fished, catch standardized by hours fished
test_that("there is no missing values (hours fished...ect) when there is catch data (even if catch is 0)", {
  catch <- weekly_juvenile_abundance_catch_data 
  flow_na = any(catch$flow_cfs  == -Inf)
  std_flow_na = any(catch$standardized_flow == -Inf)
  hf_na = any(catch$hours_fished == -Inf)
  as_hf_na = any(catch$average_stream_hours_fished == -Inf)
  cshf_na = any(catch$catch_standardized_by_hours_fished == -Inf)
  
  nas = c(flow_na, std_flow_na, 
          hf_na, as_hf_na, cshf_na)
  expect_equal(c(NA, NA, NA, FALSE, NA), 
               nas)
})
# check that there is data for each site week combo




# test_join <- current_site_year_raw |> 
#   rename(current_site_year = site_year) |> 
#   full_join(chosen_site_year_raw)

# no missing values where we have catch
#test_that("weekly_juvenile_abundance_data does not have missing values where we have catch")
# if data for one lifestage, count is not missing for others
# we have all weeks