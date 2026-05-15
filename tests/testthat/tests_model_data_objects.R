
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

test_that("no rows have more recaptures than releases", {
  efficiency <- weekly_juvenile_abundance_efficiency_data |> 
    filter(number_recaptured > number_released) 
  erroneous_rows <- nrow(efficiency)
  
  expect_equal(erroneous_rows, 
               0)
})

# check no count values for no hours_fished
# no missing values when there is catch data (even if catch is 0)
test_that("there are no rows where we have count > 0 when there was no effort", {
  catch <- weekly_juvenile_abundance_catch_data |> 
    filter(is.na(hours_fished) | hours_fished == 0)
  count_na <- !anyNA(catch$count)
  
  nas = count_na
  expect_equal(FALSE, 
               nas)
})

# including a draft test for using simple expansion methods to check for high values. not in final form and not necessary for v1.0
# simple expanded catch values are in reasonable ranges (not too high)
test_that("count values are reasonable", {
  
  efficiency_summary <- weekly_juvenile_abundance_efficiency_data |>
    filter(!is.na(number_recaptured),
           !is.na(number_released)) |> 
    mutate(simple_eff = number_recaptured / number_released) |> 
    group_by(site) |> 
    summarise(mean_simple_eff = mean(simple_eff)) |> 
    ungroup()

  expanded_catch <- weekly_juvenile_abundance_catch_data |>
    filter(!is.na(count)) |> 
    left_join(efficiency_summary, by = "site") |> 
    mutate(simple_expansion = count / mean_simple_eff)
    
  expanded_catch_summary <- expanded_catch |> 
    group_by(site) |> 
    summarise(mean_simple_expansion = mean(simple_expansion),
              sd_simple_expansion = sd(simple_expansion)) |> 
    ungroup()
  
  expanded_catch_check <- expanded_catch |> 
    select(site, week, run_year, simple_expansion) |> 
    left_join(expanded_catch_summary, by = "site") |> 
    mutate(upper_limit = mean_simple_expansion + (2 * sd_simple_expansion),
           flag_upper = ifelse(simple_expansion > upper_limit, TRUE, FALSE))
  
  expect_true(all(expanded_catch_check$flag_upper))
})