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

# test_join <- current_site_year_raw |> 
#   rename(current_site_year = site_year) |> 
#   full_join(chosen_site_year_raw)

# no missing values where we have catch
#test_that("weekly_juvenile_abundance_data does not have missing values where we have catch")
# if data for one lifestage, count is not missing for others
# we have all weeks