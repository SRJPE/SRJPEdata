# This script pulls functional flow data using the function flows calculator #
# https://github.com/ceff-tech/ffc_api_client
# https://ceff-tech.github.io/ffc_api_client/articles/getting_started.html

# Battle: 11376550
# Butte: 11390000
# Clear: 11372000
# Deer: 11383500
# Feather LFC: 11407000
# Feathe HFC: GRL, CDEC
# Mill: 11381500
# Yuba: 11421000
# Knights Landing: 11390500

# main ffc package
library(ffcAPIClient)

# packages
library(dplyr) # for data wrangling
library(purrr) # for iterating over lists and applying functions
library(glue) # good for pasting things together
library(fs) # for working with directories and files
library(tictoc) # timing stuff
library(here) # helps with setting home directory/path
library(stringr) # for working with strings

gage_list <- c("11376550", "11390000", "11372000", "11383500", "11407000", "11381500", "11421000", "11390500")
st_date <- "1986-01-01"
ffctoken <- set_token(Sys.getenv("EFLOWS_TOKEN"))
# helper functions --------------------------------------------------------

# these functions written by R. Peek 2020 to facilitate iteration

library(readr)
library(ffcAPIClient)
library(purrr)
library(glue)
library(fs)
library(here)

# write a function to pull the data
ffc_iter <- function(id, startDate, ffctoken=ffctoken, dirToSave="output/ffc", save=TRUE){
  
  # set save dir
  outDir <- glue::glue("{here()}/{dirToSave}")
  dir_create(glue("{outDir}"))
  
  # start ffc processor
  ffc <- FFCProcessor$new()
  # set special parameters for this run of the FFC
  ffc$gage_start_date = startDate
  ffc$fail_years_data = 10  # tell it to indicate a failure if we don't have at least 10 water years of data after doing quality checks
  ffc$warn_years_data = 12  # warn us if it has at least 10, but not more than 12 years of data - quality of results will be lower - default is 15
  # run the FFCProcessor's setup code, then run the FFC itself
  ffc$set_up(gage_id = id, token=ffctoken)
  ffc$run()
  
  if(save==TRUE){
    dir_create(glue("{outDir}"))
    # write out
    write_csv(ffc$alteration, file = glue::glue("{outDir}/{id}_alteration.csv"))
    write_csv(ffc$ffc_results, file = glue::glue("{outDir}/{id}_ffc_results.csv"))
    write_csv(ffc$ffc_percentiles, file=glue::glue("{outDir}/{id}_ffc_percentiles.csv"))
    write_csv(ffc$predicted_percentiles, file=glue::glue("{outDir}/{id}_predicted_percentiles.csv"))
  } else {
    return(ffc)
  }
}

# wrap in possibly to permit error catching
# see helpful post here: https://aosmith.rbind.io/2020/08/31/handling-errors/
ffc_possible <- possibly(.f = ffc_iter, otherwise = NA_character_)

library(fs)
library(purrr)

# need function to read in and collapse different ffc outputs
ffc_collapse <- function(datatype, fdir){
  datatype = datatype
  csv_list = fs::dir_ls(path = fdir, regexp = datatype)
  csv_names = fs::path_file(csv_list) %>% fs::path_ext_remove()
  gage_ids = str_extract(csv_names, '([0-9])+')
  # read in all
  df <- purrr::map(csv_list, ~read_csv(.x)) %>%
    map2_df(gage_ids, ~mutate(.x,gageid=.y))
}


# pull data individually ---------------------------------------------------------------

# Battle
ffc <- FFCProcessor$new()
ffc$set_up(gage_id = 11376550,
           token = ffctoken)
ffc$run()
battle_results <- ffc$ffc_results

# Butte
ffc <- FFCProcessor$new()
ffc$set_up(gage_id = 11390000,
           token = ffctoken)
ffc$run()
butte_results <- ffc$ffc_results

# pull multiple gages -----------------------------------------------------
# TODO - this code is not working right now. if can't get to work then just use
# individual

tic() # start time
ffcs <- map(gage_list, ~ffc_possible(.x, startDate = st_date, ffctoken=ffctoken, dirToSave="data-raw/helper-tables/output/ffc_run", save=TRUE)) %>%
  # add names to list
  set_names(x = ., nm=gage_list)
toc() # end time

# identify missing:
ffcs %>% keep(is.na(.)) %>% length()

# make a list of missing gages for future use
miss_gages <- ffcs %>% keep(is.na(.)) %>% names()
# which gages?
miss_gages

# save out missing to a file
write_lines(miss_gages, file = "data-raw/helper-tables/output/usgs_ffcs_gages_alt_missing_data.txt")

# set the data type we want to collapse
datatype="predicted_percentiles"

# Data Type options:
## alteration
## ffc_percentiles
## ffc_results
## predicted_percentiles

# set directory where the raw .csv's live
fdir=glue("{here::here()}data-raw/helper-tables/output/ffc_run/")

# run it!
df_ffc <- ffc_collapse(datatype, fdir)

# view how many gages
df_ffc %>% distinct(gageid) %>% count()
# how many FF metrics per gage?
df_ffc %>% group_by(gageid) %>% tally()

# save it
write_csv(df_ffc, file = glue("{here::here()}data-raw/helper-tables/output/usgs_alt_{datatype}_run_{Sys.Date()}.csv"))