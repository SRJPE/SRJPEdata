library(DBI)
library(tidyverse)
library(lubridate)
library(SRJPEdata)
library("pins")
library(dplyr)
# config::get(file = "config.yml")
access_key <- Sys.getenv("aws_access_key_id")
secret_access_key <- Sys.getenv("secret_access_key_id")
session_token <- Sys.getenv("session_token_id")

#connecting to aws bucket (note that the access key, secret access key and session token expire every 24 hours so this needs to be updated when ran)
hrl_project_board <- pins::board_s3(
  bucket="healthy-rivers-landscapes",
  access_key= access_key,
  secret_access_key= secret_access_key,
  session_token= session_token
)
#checking it is reading bucket
print(hrl_project_board)
pins::pin_list(hrl_project_board)


#pull in tables

#catch
rst_catch_nosrjpe <- pins::pin_read(hrl_project_board, "catch") |> 
  glimpse()

#recapture
rst_recapture_nosrjpe <- pins::pin_read(hrl_project_board, "recapture") |> 
  glimpse()

#release
rst_release_nosrjpe <- pins::pin_read(hrl_project_board, "release") |> 
  glimpse()

#trap
rst_trap_nosrjpe <- pins::pin_read(hrl_project_board, "trap") |> #this table is empty since no trap data associated with Mokelumne or American River
  glimpse()


#save data to package

usethis::use_data(rst_catch_nosrjpe, overwrite = TRUE)

usethis::use_data(rst_recapture_nosrjpe, overwrite = TRUE)

usethis::use_data(rst_release_nosrjpe, overwrite = TRUE)

usethis::use_data(rst_trap_nosrjpe, overwrite = TRUE)
