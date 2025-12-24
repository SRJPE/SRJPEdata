# tests/testthat/helper-data.R
# Loads all data files before tests run
library(tidyverse)
load("../../data/rst_catch.rda")
load("../../data/rst_trap.rda")
load("../../data/release.rda")
load("../../data/recaptures.rda")
load("../../data/annual_adult.rda")
load("../../data/years_to_include_rst_data.rda")
load("../../data/weekly_juvenile_abundance_catch_data.rda")

