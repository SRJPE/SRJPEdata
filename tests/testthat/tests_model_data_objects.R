
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


# no missing values when there is catch data (even if catch is 0)
# Currently fails, there are nas in flow, standard flow, fork length, lifestage, hours fished, catch standardized by hours fished
test_that("there is no missing values (hours fished...ect) when there is catch data (even if catch is 0)", {
  catch <- weekly_juvenile_abundance_catch_data |> 
    filter(!is.na(count)) 
  stream_na = anyNA(catch$stream)
  site_na = anyNA(catch$site) # note 2/14 fixing this in db update
  flow_na = anyNA(catch$flow_cfs) # note 2/14 there are only 15 with missing data
  std_flow_na = anyNA(catch$standardized_flow) # same as above
  hf_na = anyNA(catch$hours_fished)
  ry_na = anyNA(catch$run_year)
  
  nas = c(stream_na, site_na, flow_na, hf_na, ry_na)
  expect_equal(c(FALSE, FALSE, FALSE, FALSE, FALSE), 
               nas)
})

# still have flow and hours fished even if no catch
# Currently fails, there are nas in flow, standard flow, fork length, hours fished, catch standardized by hours fished
test_that("still have flow and hours fished even if no catch", {
  catch <- weekly_juvenile_abundance_catch_data |> 
    filter(is.na(count)) 
  stream_na = anyNA(catch$stream)
  site_na = anyNA(catch$site)
  flow_na = anyNA(catch$flow_cfs)
  std_flow_na = anyNA(catch$standardized_flow)
  ry_na = anyNA(catch$run_year)
  
  nas = c(stream_na, site_na, flow_na, std_flow_na,ry_na)
  expect_equal(c(FALSE, FALSE, FALSE, FALSE, FALSE), 
               nas)
})

# check no -INf 
# no missing values when there is catch data (even if catch is 0)
test_that("there is no -Inf values (hours fished...ect) when there is catch data (even if catch is 0)", {
  catch <- weekly_juvenile_abundance_catch_data 
  flow_na = any(catch$flow_cfs  == -Inf)
  std_flow_na = any(catch$standardized_flow == -Inf)
  hf_na = any(catch$hours_fished == -Inf) # will be NA because there are NA when count is NA
  
  nas = c(flow_na, std_flow_na, hf_na)
  expect_equal(c(FALSE, FALSE, NA), 
               nas)
})