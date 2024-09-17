library(SRJPEdata)
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
  expect_equal(any(is.na(rst_trap$site)), FALSE)
  expect_equal(any(is.na(rst_trap$subsite)), FALSE)
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
  
  #TODO we seem to be missing mill, deer, & yuba release data
  expected_coverage <- c("battle creek", "butte creek", "clear creek", "deer creek", 
                         "feather river", "mill creek", "sacramento river")
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
                         "feather river", "mill creek", "sacramento river")
  expect_equal(current_coverage, expected_coverage)
})

test_that("No NA values in identifying recapture data variables", {
  expect_equal(any(is.na(recaptures$stream)), FALSE)
  expect_equal(any(is.na(recaptures$site)), FALSE)
  expect_equal(any(is.na(recaptures$subsite)), FALSE) 
  expect_equal(any(is.na(recaptures$site_group)), FALSE) # TODO there should not be NAs here right? 
  expect_equal(any(is.na(recaptures$date)), FALSE)
})


# Adult data tests -------------------------------------------------------------
# Passage Counts
test_that("Upstream passage counts data coverage at the tributary level has not changed", {
  current_coverage <- upstream_passage$stream |> unique() |> sort()
  
  expected_coverage <- c("battle creek", "clear creek", "deer creek", "mill creek", 
                         "yuba river")
  expect_equal(current_coverage, expected_coverage)
})

test_that("No NA values in identifying passage counts data variables", {
  expect_equal(any(is.na(upstream_passage$stream)), FALSE)
  expect_equal(any(is.na(upstream_passage$date)), FALSE)
})

# Passage Estimates
test_that("Upstream passage estimates data coverage at the tributary level has not changed", {
  current_coverage <- upstream_passage_estimates$stream |> unique() |> sort()
  
  expected_coverage <- c("battle creek", "clear creek", "deer creek", "mill creek", 
                         "yuba river")
  expect_equal(current_coverage, expected_coverage)
})

test_that("No NA values in identifying passage estimates data variables", {
  expect_equal(any(is.na(upstream_passage_estimates$stream)), FALSE)
  expect_equal(any(is.na(upstream_passage_estimates$year)), FALSE)
})

# Redd
test_that("Redd data coverage at the tributary level has not changed", {
  current_coverage <- redd$stream |> unique() |> sort()
  
  expected_coverage <- c("battle creek", "clear creek", "feather river", "mill creek", 
                         "yuba river")
  expect_equal(current_coverage, expected_coverage)
})

test_that("No NA values in identifying redd data variables", {
  expect_equal(any(is.na(redd$stream)), FALSE)
  expect_equal(any(is.na(redd$date)), FALSE)
})

# carcass
test_that("Carcass estinates data coverage at the tributary level has not changed", {
  current_coverage <- carcass_estimates$stream |> unique() |> sort()
  
  expected_coverage <- c("butte creek", "feather river", "yuba river")
  expect_equal(current_coverage, expected_coverage)
})

test_that("No NA values in identifying carcass data variables", {
  expect_equal(any(is.na(carcass_estimates$stream)), FALSE)
  expect_equal(any(is.na(carcass_estimates$year)), FALSE)
})

# holding
test_that("Holding data coverage at the tributary level has not changed", {
  current_coverage <- holding$stream |> unique() |> sort()
  
  expected_coverage <- c("battle creek", "butte creek", "clear creek", "deer creek")
  expect_equal(current_coverage, expected_coverage)
})

test_that("No NA values in identifying holding data variables", {
  expect_equal(any(is.na(holding$stream)), FALSE)
  expect_equal(any(is.na(holding$year)), FALSE)
})



