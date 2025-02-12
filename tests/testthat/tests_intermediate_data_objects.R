# The goal of this script is to test intermediate data objects like `chosen_site_years_to_model`
# Test that `chosen_site_years_to_model` includes all streams
test_that("years_to_include_rst_data includes all streams", {
  current_coverage <- years_to_include_rst_data$stream |> unique() |> sort()
  expected_coverage <- c("battle creek", "butte creek", "clear creek", "deer creek", 
                         "feather river", "mill creek", "sacramento river", "yuba river")
  expect_equal(current_coverage, expected_coverage)
})
# Test that `chosen_site_years_to_model` includes all sites

test_that("years_to_include_rst_data includes all sites", {
  current_coverage <- years_to_include_rst_data$site |> unique() |> sort()
  # TODO confirm that we do not want adams dam in there at all
  expected_coverage <- c("deer creek", "eye riffle", "gateway riffle", 
                         "hallwood", "herringer riffle", "knights landing", "lbc", "lcc", 
                         "live oak", "lower feather river", "mill creek", "okie dam", 
                         "red bluff diversion dam", "steep riffle", "sunset pumps", 
                         "tisdale", "ubc", "ucc", "yuba river")
  expect_equal(current_coverage, expected_coverage)
})
