# Pull genetics data
# Data are on the Azure database and on EDI
# This script pulls genetics data directly from EDI
# The EDI package will be updated every 2 weeks 

library(tidyverse)
library(EDIutils)

# edi package (seasons 2022-2025) [as of May 2026]
# Set the scope for script to use API to download data from EDI
scope <- "edi"
identifier <- "2335"
revision <- list_data_package_revisions(scope, identifier, filter = "newest")
package_id <- paste(scope, identifier, revision, sep = ".")

# List data entities of the data package
res <- read_data_entity_names(package_id)
name <- "genetic_identification_data.csv"
entity_id <- res$entityId[res$entityName == name]
# download data from 2022-2025
raw <- read_data_entity(package_id, entity_id)
completed_genetic_samples <- read_csv(file = raw)

usethis::use_data(completed_genetic_samples, overwrite = TRUE)

