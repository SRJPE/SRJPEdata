library(googleCloudStorageR)
library(tidyverse)

gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
gcs_global_bucket(bucket = Sys.getenv("GCS_DEFAULT_BUCKET"))

# Mark-Recapture Data for RST
# standard recapture data table
gcs_get_object(object_name = "standard-format-data/standard_recapture.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/standard-format-data/standard_recapture.csv",
               overwrite = TRUE)
standard_recapture <- read_csv("data/standard-format-data/standard_recapture.csv")
# standard release data table
gcs_get_object(object_name = "standard-format-data/standard_release.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/standard-format-data/standard_release.csv",
               overwrite = TRUE)
standard_release <- read_csv("data/standard-format-data/standard_release.csv")

# RST Monitoring Data
# standard rst catch data table
gcs_get_object(object_name = "standard-format-data/standard_rst_catch.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/standard-format-data/standard_catch.csv",
               overwrite = TRUE)
standard_catch <- read_csv("data/standard-format-data/standard_catch.csv")

# standard rst trap data table
gcs_get_object(object_name = "standard-format-data/standard_rst_trap.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/standard-format-data/standard_trap.csv",
               overwrite = TRUE)
standard_trap <- read_csv("data/standard-format-data/standard_trap.csv")

# standard effort table
gcs_get_object(object_name = "standard-format-data/standard_rst_effort.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/standard-format-data/standard_effort.csv",
               overwrite = TRUE)
standard_effort <- read_csv("data/standard-format-data/standard_effort.csv")

# standard environmental covariate data collected during RST monitoring
gcs_get_object(object_name = "standard-format-data/standard_RST_environmental.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/standard-format-data/standard_environmental.csv",
               overwrite = TRUE)
standard_environmental <- read_csv("data/standard-format-data/standard_environmental.csv")

# rst site data
gcs_get_object(object_name = "standard-format-data/rst_trap_locations.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/standard-format-data/rst_trap_locations.csv",
               overwrite = TRUE)
standard_sites <- read_csv("data/standard-format-data/rst_trap_locations.csv")

# Standard Environmental Covariate Data
# standard flow
gcs_get_object(object_name = "standard-format-data/standard_flow.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/standard-format-data/standard_flow.csv",
               overwrite = TRUE)
standard_flow <- read_csv("data/standard-format-data/standard_flow.csv")
# standard temp
gcs_get_object(object_name = "standard-format-data/standard_temperature.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/standard-format-data/standard_temperature.csv",
               overwrite = TRUE)
standard_temperature <- read_csv("data/standard-format-data/standard_temperature.csv")

# Adult Upstream Data
gcs_get_object(object_name = "standard-format-data/standard_adult_upstream_passage.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/standard-format-data/standard_adult_upstream.csv",
               overwrite = TRUE)
standard_upstream <- read_csv("data/standard-format-data/standard_adult_upstream.csv")

# Adult Holding Data
gcs_get_object(object_name = "standard-format-data/standard_holding.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/standard-format-data/standard_holding.csv",
               overwrite = TRUE)
standard_holding <- read_csv("data/standard-format-data/standard_holding.csv")

# Adult Redd Data
gcs_get_object(object_name = "standard-format-data/standard_annual_redd.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/standard-format-data/standard_annual_redd.csv",
               overwrite = TRUE)
standard_annual_redd <- read_csv("data/standard-format-data/standard_annual_redd.csv")

gcs_get_object(object_name = "standard-format-data/standard_daily_redd.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data/standard-format-data/standard_daily_redd.csv",
               overwrite = TRUE)
standard_daily_redd <- read_csv("data/standard-format-data/standard_daily_redd.csv")