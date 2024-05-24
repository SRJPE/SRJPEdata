# Script to be run on automatic biweekly update using GitHub Actions 
# First source database to pull in RST and adult datasets 
# Need DB permissions set
source("data-raw/pull_data_scripts/pull_tables_from_database.R")

# Next source environmental data 
source("data-raw/pull_data_scripts/pull_environmental_data.R")

# And genetics data from DB
# Need config file 
source("data-raw/pull_data_scripts/pull_genetic_run_assignment_data.R")

# TODO figure out if we need to clean env/reset to make sure updates incorporated 
# in package (rebuild?)
devtools::build_site()

# Incorporate new data in rule sets/covariates 
# Source all vignettes 
knitr::knit("vignettes/prep_environmental_covariates.Rmd")
knitr::knit("vignettes/trap_effort.Rmd")
knitr::knit("vignettes/yearling_ruleset.Rmd")
knitr::knit("vignettes/years_to_include_analysis.Rmd") #TODO, review any automatic exclusions and confirm, 
# also does not automatically exclude adults yet, so add that

# rebuild site to save updated data objects in package
devtools::build_site()

# Source prep data scripts 
source("data-raw/process_data_scripts/build_adult_model_datasets.R")
source("data-raw/process_data_scripts/build_rst_model_datasets.R")

# Then pull acoustic tagging data
source("data-raw/pull_data_scripts/pull_acoustic_tagging_data.R")
source("data-raw/process_data_scripts/build_survival_model_datasets.R")

devtools::build_site()

# TODO Probably want to add some checks here to make sure no data is turning up empty
# or something 

# TADA, Data Update! 