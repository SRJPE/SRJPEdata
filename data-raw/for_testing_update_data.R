# For the testing process, the update process will be run slightly differently
source("data-raw/pull_data_scripts/for_testing_combine_data.R")
source("data-raw/pull_data_scripts/pull_adult_data.R")

# temp regression vignette needs to come before the environmental data
#knitr::knit("vignettes/temp_regression.Rmd")
# Next source environmental data 
source("data-raw/pull_data_scripts/pull_environmental_data.R")
# in package (rebuild?)
devtools::load_all()
devtools::document()
# Incorporate new data in rule sets/covariates 
# Source all vignettes 
knitr::knit("vignettes/prep_environmental_covariates.Rmd")
knitr::knit("vignettes/trap_effort.Rmd")
#knitr::knit("vignettes/lifestage_ruleset.Rmd") # very slow but logic is a bit tricky, could be one to update to data.table
knitr::knit("vignettes/years_to_include_analysis.Rmd") # does not automatically exclude adults yet, so add that
knitr::knit("vignettes/sr_covariates.Rmd")
knitr::knit("vignettes/forecast_covariates.Rmd")
# rebuild site to save updated data objects in package
devtools::load_all()
detach(package:data.table)
# Source prep data scripts 
# source("data-raw/process_data_scripts/build_adult_model_datasets.R") 
source("data-raw/process_data_scripts/build_rst_model_datasets.R")
source("data-raw/process_data_scripts/build_sr_model_datasets.R")

devtools::document()
#pkgdown::build_site()
devtools::test() 
