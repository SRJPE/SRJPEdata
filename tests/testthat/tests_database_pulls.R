library(SRJPEdata)
library(tidyverse)
context('RST data')

# RST tests --------------------------------------------------------------------
# Catch 
# Stream consistant
test_that("RST catch data coverage at the tributary level has not changed", {
  current_coverage <- rst_catch$stream |> unique() |> sort()
    
  expected_coverage <- c("battle creek", "butte creek", "clear creek", "deer creek", 
                         "feather river", "mill creek", "sacramento river", "yuba river")
  expect_equal(current_coverage, expected_coverage)
})

# No NA stream, site, subsite, site group, date
test_that("No NA values in identifying catch data variables", {
  expect_equal(any(is.na(rst_catch$stream)), FALSE)
  expect_equal(any(is.na(rst_catch$site)), FALSE)
  expect_equal(any(is.na(rst_catch$subsite)), FALSE)
  expect_equal(any(is.na(rst_catch$site_group)), FALSE)
  expect_equal(any(is.na(rst_catch$date)), FALSE)
})

# Trap 
# stream consistant
test_that("RST trap data coverage at the tributary level has not changed", {
  current_coverage <- rst_trap$stream |> unique() |> sort()
  
  expected_coverage <- c("battle creek", "butte creek", "clear creek", "deer creek", 
                         "feather river", "mill creek", "sacramento river", "yuba river")
  expect_equal(current_coverage, expected_coverage)
})

# # No NA stream, site, subsite, site group
test_that("No NA values in identifying trap data variables", {
  expect_equal(any(is.na(rst_trap$stream)), FALSE)
  expect_equal(any(is.na(rst_trap$site)), FALSE) # this happens for battle creek
  expect_equal(any(is.na(rst_trap$subsite)), FALSE) # this happens for battle, butte, yuba
  expect_equal(any(is.na(rst_trap$site_group)), FALSE)
})

# test that at least one date value (start or stop)
test_that("Always one non NA value in trap date variables", {
  date_col <- rst_trap |> 
    mutate(date_exists = ifelse(is.na(trap_start_date) & is.na(trap_stop_date), FALSE, TRUE)) |> 
    pull(date_exists)
  expect_equal(any(isFALSE(date_col)), FALSE)
}) 

# Efficiency data tests 
# stream consistant
test_that("RST release data coverage at the tributary level has not changed", {
  current_coverage <- release$stream |> unique() |> sort()
  
  expected_coverage <- c("battle creek", "butte creek", "clear creek", "deer creek", 
                         "feather river", "mill creek", "sacramento river", "yuba river")
  expect_equal(current_coverage, expected_coverage)
})

test_that("No NA values in identifying release data variables", {
  expect_equal(any(is.na(release$stream)), FALSE)
  expect_equal(any(is.na(release$site)), FALSE)
  expect_equal(any(is.na(release$site_group)), FALSE)
  expect_equal(any(is.na(release$date_released)), FALSE)
  
})

test_that("RST recapture data coverage at the tributary level has not changed", {
  current_coverage <- recaptures$stream |> unique() |> sort()
  
  expected_coverage <- c("battle creek", "butte creek", "clear creek", "deer creek", 
                         "feather river", "mill creek", "sacramento river", "yuba river")
  expect_equal(current_coverage, expected_coverage)
})

test_that("No NA values in identifying recapture data variables", {
  expect_equal(any(is.na(recaptures$stream)), FALSE)
  expect_equal(any(is.na(recaptures$site)), FALSE)
  expect_equal(any(is.na(filter(recaptures, !site %in% c("knights landing", "tisdale"))$subsite)), FALSE) # this happens for knights and tisdale, NAs are left because recapture location is unknown
  expect_equal(any(is.na(recaptures$site_group)), FALSE)
  expect_equal(any(is.na(recaptures$date)), FALSE)
})


# Adult data tests -------------------------------------------------------------
# Annual counts
test_that("Annual adult counts data coverage at the tributary level has not changed", {
  current_coverage <- annual_adult$stream |> unique() |> sort()
  
  expected_coverage <- c("battle creek", "butte creek", "clear creek", "deer creek", "mill creek", 
                         "feather river", "yuba river")
  expect_equal(current_coverage, expected_coverage)
})

test_that("No NA values in identifying annual adult data variables", {
  expect_equal(any(is.na(annual_adult$stream)), FALSE)
  expect_equal(any(is.na(annual_adult$year)), FALSE)
})




