# Pull genetics data
# Data are on the Azure database and on EDI
# Proposed strategy is to pull directly from EDI
# and have EDI be updated through pulls from database
# on a regular schedule

library(tidyverse)
library(grunID)
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

# plot
# completed_genetic_samples |>
#   filter(!is.na(datetime_collected)) |>
#   mutate(fake_year = ifelse(month(datetime_collected) %in% 10:12, 1970, 1971),
#          fake_date = as.Date(paste0(fake_year, "-", month(datetime_collected), "-", day(datetime_collected))),
#          season = as.factor(paste0("Season: 20", substr(sample_id, 4, 5)))) |>
#   ggplot(aes(x = fake_date, fill = final_run_designation)) +
#   geom_density(alpha = 0.5) +
#   facet_wrap(~season) +
#   theme_minimal() +
#   labs(x = "Datetime collected") +
#   theme(legend.position = "bottom")

# code for pulling from db - will migrate this to the EDI package

# edi_seasons <- completed_genetic_samples |>
#   mutate(season = as.numeric(substr(sample_id, 4, 5))) |>
#   distinct(season) |>
#   pull(season)
# con_prod <- gr_db_connect() # make sure you have production in your .yaml
# db_genetic_results <- generate_final_run_assignment(con_prod)$results |> 
#   mutate(season = as.numeric(substr(sample_id, 4, 5)),
#          coleman_f = as.numeric(coleman_f)) |> 
#   filter(!season %in% edi_seasons) |> 
#   select(-season)
# 
# 
# # combine and save
# genetic_run_assignment <- bind_rows(completed_genetic_samples,
#                                     db_genetic_results)


