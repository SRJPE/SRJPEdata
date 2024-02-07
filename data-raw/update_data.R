# Script to be run on automatic biweekly update using GitHub Actions 
# First source database to pull in RST and adult datasets 
source("data-raw/pull_tables_from_database.R")

# Next source environmental data 
source("data-raw/pull_environmental_data.R")

# TODO any other things we should be sourcing?
# TODO figure out if we need to clean env/reset to make sure updates incoperated 
# in package (rebuild?)
devtools::build_site()

# Incoperate new data in rulesets/covariates 
# Source all vignettes 
source("vignettes/prep_environmental_covariates.Rmd")
source("vignettes/trap_effort.Rmd")
source("vignettes/yearling_ruleset.Rmd")
source("vignettes/years_to_include_analysis.Rmd")
# TODO add others as we finish developing 

# Source prep data scripts 
source("data-raw/build_adult_model_datasets.R")
source("data-raw/build_rst_model_datasets.R")

# TODO Probably want to add some checks here to make sure no data is turning up empty
# or something 

# TADA, Data Update! 