library(tidyverse)
identifier = "1504"
version = "1"
# View existing tables on edi related to specific identifier and version 
httr::GET(url = paste0("https://pasta.lternet.edu/package/name/eml/edi/", identifier, "/", version), handle = httr::handle(""))

# pull existing tables using identifier, version, and table unique identifier
existing_catch <- httr::GET(
  url = paste0("https://pasta.lternet.edu/package/data/eml/edi/", identifier, "/", version, "/cd3a2416ee0cdf13bb6103a8ab46304a"),
  handle = httr::handle("")) |>
  httr::content() |>
  as_tibble() 

existing_trap <- httr::GET(
  url = paste0("https://pasta.lternet.edu/package/data/eml/edi/", identifier, "/", version, "/e87fdc6067fb46a770052b7570f66aa7"),
  handle = httr::handle("")) |>
  httr::content() |>
  as_tibble() 


existing_release <- httr::GET(
  url = paste0("https://pasta.lternet.edu/package/data/eml/edi/", identifier, "/", version, "/effc9a570ffc105c5a2a9a1737f38d48"),
  handle = httr::handle("")) |>
  httr::content() |>
  as_tibble() 

existing_recapture <- httr::GET(
  url = paste0("https://pasta.lternet.edu/package/data/eml/edi/", identifier, "/", version, "/9795dd81696a0fe61149aae2bf780669"),
  handle = httr::handle("")) |>
  httr::content() |>
  as_tibble() 

# clean up data/format same as database 
catch <- SRJPEdata::rst_catch |> summary()
existing_catch |> summary()
