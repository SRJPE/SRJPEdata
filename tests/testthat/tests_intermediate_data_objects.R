# The goal of this script is to test intermediate data objects like `chosen_site_years_to_model`
# Test that `chosen_site_years_to_model` includes all streams
test_that("chosen_site_years_to_model includes all streams", {
  current_coverage <- chosen_site_years_to_model$stream |> unique() |> sort()
  # TODO where is feather? 
  expected_coverage <- c("battle creek", "butte creek", "clear creek", "deer creek", 
                         "feather river", "mill creek", "sacramento river", "yuba river")
  expect_equal(current_coverage, expected_coverage)
})
# Test that `chosen_site_years_to_model` includes all sites

test_that("chosen_site_years_to_model includes all sites", {
  current_coverage <- chosen_site_years_to_model$site |> unique() |> sort()
  # TODO where is feather? 
  expected_coverage <- c("adams dam", "deer creek", "eye riffle", "gateway riffle", 
                         "hallwood", "herringer riffle", "knights landing", "lbc", "lcc", 
                         "live oak", "lower feather river", "mill creek", "okie dam", 
                         "red bluff diversion dam", "shawn's beach", "steep riffle", "sunset pumps", 
                         "tisdale", "ubc", "ucc", "yuba river")
  expect_equal(current_coverage, expected_coverage)
})

test_that("chosen_site_years_to_model includes all sites_groups", {
  current_coverage <- chosen_site_years_to_model$site_group |> unique() |> sort()
  # TODO missing feather site groups
  expected_coverage <- c("battle creek", "butte creek", "clear creek", "deer creek", 
                         "knights landing", "lower feather river", "mill creek", "red bluff diversion dam", 
                         "tisdale", "upper feather hfc", "upper feather lfc", "yuba river")
  expect_equal(current_coverage, expected_coverage)
})
