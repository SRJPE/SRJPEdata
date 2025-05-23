# First source script that pulls rst, adult data from SRJPE database and rst from datatackle database
# Need DB permissions set
source("data-raw/pull_data_scripts/combine_database_pull_and_save.R")

# temp regression vignette needs to come before the environmental data
knitr::knit("vignettes/temp_regression.Rmd")
# Next source environmental data 
source("data-raw/pull_data_scripts/pull_environmental_data.R")

# And genetics data from DB
# Need config file 
# NOTE: missing field sheet data & 2023 data, should revisit after this is added to confirm that everything looks good
source("data-raw/pull_data_scripts/pull_genetic_run_assignment_data.R")

# in package (rebuild?)
devtools::load_all()
devtools::document()
# Incorporate new data in rule sets/covariates 
# Source all vignettes 
knitr::knit("vignettes/prep_environmental_covariates.Rmd")
knitr::knit("vignettes/trap_effort.Rmd")
knitr::knit("vignettes/lifestage_ruleset.Rmd") # very slow but logic is a bit tricky, could be one to update to data.table
knitr::knit("vignettes/years_to_include_analysis.Rmd") # does not automatically exclude adults yet, so add that
knitr::knit("vignettes/sr_covariates.Rmd")
knitr::knit("vignettes/forecast_covariates.Rmd")
# rebuild site to save updated data objects in package
devtools::load_all()

# Source prep data scripts 
source("data-raw/process_data_scripts/build_adult_model_datasets.R") #TODO, error here 
# Error because database pull for upstream passage returns empty table

source("data-raw/process_data_scripts/build_rst_model_datasets.R")
source("data-raw/process_data_scripts/build_sr_model_datasets.R")
# Then pull acoustic tagging data
# Note: We only pull specific JPE studies now, if we want to add more in, we must specify survey_id name in pull script
source("data-raw/pull_data_scripts/pull_acoustic_tagging_data.R")
# Note: some funcitons are site / system specific, may need to add new logic as new systems are added
source("data-raw/process_data_scripts/survival/combine_survival_datasets.R")

# Update versioning and NEWS.md 
# add updated version number and description of updates into NEWS.md file, see
# https://docs.google.com/document/d/1HgDlOpBMK5BVcrNnuB3CbZWsO6PyYbpJZdfM5C6NfRQ/edit for our versioning procedures 

# RUN IF DOCS UPDATE
devtools::document()
pkgdown::build_site()
#### DOCS html and .yml will be in gitignore. 
#### Make sure to update anyways if you have rebuilt the documentation site
devtools::test() 

# TODO Probably want to add some checks here to make sure no data is turning up empty
# or something 

# TADA, Data Update! 