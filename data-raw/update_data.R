# UPDATE SRJPE DATASETS
# This script provides within season and annual updates. 
# This script is automatically run every 2 weeks within the juvenile outmigration 
# season to provide near real time data for SRJPE models. At the end of the RST season, once 
# data has been QCd by stream teams we manually rerun the script to incorporate final RST data. 
# 
# This script is also run manually once annually to incorporate adult data updates in January. 
# ==============================================================================
# PULLING MONITORING DATA 
# (1) RST DATA PULL (Runs biweekly & manually at end of season)
# First source a script that pulls rst data from datatackle database, EDI, 
# and the SRJPE database and combines it
source("data-raw/pull_data_scripts/combine_database_pull_and_save.R")

# (2) COVARIATE DATA PULL (Runs biweekly & manually at end of season)
# First run a temp regression vignette to fill in temperature gaps 
knitr::knit("vignettes/temp_regression.Rmd") # ideally this will be phased out with better temp data
# Next pull environmental (flow & temp) data from CDEC, USGS, and misc spreadsheets
source("data-raw/pull_data_scripts/pull_flow_data.R")
source("data-raw/pull_data_scripts/pull_temperature_data.R")
# Create covariate datasets from raw flow and temp data
source("data-raw/process_data_scripts/build_covariates.R")

# (3) ADULT DATA PULL (Run manually once a year in January)
# Pulls adult data 
# Once automatic update in place, can change conditional to be based on if 
# is_automatic_update == FALSE or something like that
if(month(Sys.Date()) == 1) source("data-raw/pull_data_scripts/pull_adult_data.R") 

# (4) GENETICS DATA (Runs biweekly & manually at end of season)
# Pull genetics data from EDI 
source("data-raw/pull_data_scripts/pull_genetic_run_assignment_data.R")

# (5) SURVIVAL DATA (Run anually, month TBD)
# TODO - discuss timing of updated studies on ERDDAP with Flora (Update here and 
# in generate survival datasets below #10)
# Pull survival data from ERDDAP, confirm any new study ids are added
source("data-raw/pull_data_scripts/pull_acoustic_tagging_data.R")

# GENERATING HELPER AND MODELING DATASETS
# (6) TRAP EFFORT (Run biweekly & manually at end of season)
# Create weekly hours fished data object
devtools::load_all() # Need to load packages so vignette calls to SRJPEdata::rst_X are up to date
knitr::knit("vignettes/trap_effort.Rmd")
load("data/weekly_hours_fished.rda") # reload

# (7) MODELING YEARS (Run Annually at end of RST season and with adult update if needed)
source("data-raw/process_data_scripts/build_ruleset_tables.R")

# (8) GENERATE JUVENILE ABUNDANCE DATASETS (Run biweekly & manually at end of season)
# Take updated raw data and weekly effort table and compile into model datasets
source("data-raw/process_data_scripts/build_rst_model_datasets.R")

# (9) GENERATE STOCK RECRUIT DATASETS (Run annually with Adult data pull)
if(month(Sys.Date()) == 1) source("data-raw/process_data_scripts/build_sr_model_datasets.R")

# (10) GENERATE SURVIVAL DATASETS
# The combine_survival_datasets.R script sources generate data scripts for Feather, Butte, and Sacramento 
# and combines survival data into final data objects
# NOTE: some functions are site / system specific, may need to add new logic as new systems are added
source("data-raw/process_data_scripts/survival/combine_survival_datasets.R")

# TESTS
devtools::test() 

# AUTOMATIC UPDATES TO DOCS 
# TODO Update versioning and NEWS.md 
# add updated version number and description of updates into NEWS.md file, see
# https://docs.google.com/document/d/1HgDlOpBMK5BVcrNnuB3CbZWsO6PyYbpJZdfM5C6NfRQ/edit for our versioning procedures 
devtools::document()
pkgdown::build_site()

message("Update complete!")