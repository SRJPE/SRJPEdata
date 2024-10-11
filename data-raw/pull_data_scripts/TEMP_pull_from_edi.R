# This is a temporary script to pull in data on EDI that have not yet been integrated
# into the database. This fix was implemented to make sure all data were available
# for modeling and not to hold up the modeling process. When these data are added
# to the database this script can be archived.
library(tidyverse)
library(EDIutils)

# Find max dates in SRJPEdata
dates <- SRJPEdata::rst_catch |> 
  group_by(stream, site) |> 
  summarize(min = min(date),
            max = max(date))

# Butte -------------------------------------------------------------------
res <- read_data_entity_names(packageId = "edi.1497.14")
raw <- read_data_entity(packageId = "edi.1497.14", entityId = res$entityId[1])
catch_edi <- read_csv(file = raw)
raw <- read_data_entity(packageId = "edi.1497.14", entityId = res$entityId[2])
recapture_edi <- read_csv(file = raw)
raw <- read_data_entity(packageId = "edi.1497.14", entityId = res$entityId[3])
release_edi <- read_csv(file = raw)
raw <- read_data_entity(packageId = "edi.1497.14", entityId = res$entityId[4])
trap_edi <- read_csv(file = raw)

butte_catch_edi <- catch_edi |> 
  mutate(commonName = tolower(commonName)) |> 
  filter(commonName == "chinook salmon") |> 
  mutate(stream = "butte creek",
         site_group = "butte creek",
         adipose_clipped = case_when(fishOrigin == "Natural" ~ F,
                                     fishOrigin == "Hatchery" ~ T,
                                     T ~ NA),
         dead = NA,
         weight = NA,
         species = "chinook",
         site = case_when(siteName %in% c("parrot-phelan", "Parrott-Phelan canal trap box","Okie RST","Parrot-Phelan RST") ~ "okie dam",
                          T ~ siteName),
         subsite = case_when(subSiteName %in% c("pp rst","Okie RST","PP RST") ~ "okie dam 1",
                             subSiteName == "canal trap box" ~ "okie dam fyke trap",
                             subSiteName == "pp rst 2" ~ "okie dam 2",
                             subSiteName == "adams dam" ~ "adams dam",
                             T ~ NA)) |> 
  rename(date = visitTime,
         count = n,
         run = finalRun,
         life_stage = lifeStage,
         fork_length = forkLength,
         actual_count = actualCount) |> 
  left_join(dates) |> 
  filter(date > max & year(date) > 2021) |> 
  select(date, stream, site, subsite, site_group, count, run, life_stage, adipose_clipped,
         dead, fork_length, weight, actual_count, species) 

butte_recapture_edi <- recapture_edi |> 
  mutate(stream = "butte creek",
         site_group = "butte creek",
         adipose_clipped = case_when(fishOrigin == "Natural" ~ F,
                                     fishOrigin == "Hatchery" ~ T,
                                     T ~ NA),
         dead = NA,
         weight = NA,
         species = "chinook",
         site = case_when(siteName %in% c("parrot-phelan", "Parrott-Phelan canal trap box","Okie RST","Parrot-Phelan RST") ~ "okie dam",
                          T ~ siteName),
         subsite = case_when(subSiteName %in% c("pp rst","Okie RST","PP RST") ~ "okie dam 1",
                             subSiteName == "canal trap box" ~ "okie dam fyke trap",
                             subSiteName == "pp rst 2" ~ "okie dam 2",
                             subSiteName == "adams dam" ~ "adams dam",
                             T ~ NA),
         release_id = as.character(releaseID)) |> 
  rename(date = visitTime,
         count = n,
         run = finalRun,
         life_stage = lifeStage,
         fork_length = forkLength) |> 
  left_join(dates) |> 
  filter(date > max & year(date) > 2021) |> 
  select(date, release_id, stream, site, subsite, site_group, count, run, life_stage, adipose_clipped,
         dead, fork_length, weight, species)

butte_trap_edi <- trap_edi |> 
  arrange(subSiteName, visitTime) |>
  mutate(trap_start_date = ymd_hms(lag(visitTime)),
         trap_stop_date = ymd_hms(visitTime),
         stream = "butte creek",
         site_group = "butte creek",
         site = case_when(siteName %in% c("parrot-phelan", "Parrott-Phelan canal trap box","Okie RST","Parrot-Phelan RST") ~ "okie dam",
                          T ~ siteName),
         subsite = case_when(subSiteName %in% c("pp rst","Okie RST","PP RST") ~ "okie dam 1",
                             subSiteName == "canal trap box" ~ "okie dam fyke trap",
                             subSiteName == "pp rst 2" ~ "okie dam 2",
                             subSiteName == "adams dam" ~ "adams dam",
                             T ~ NA)) |> 
  rename(visit_type = visitType,
         trap_functioning = trapFunctioning,
         fish_processed = fishProcessed,
         total_revolutions = counterAtEnd,
         rpm_start = rpmRevolutionsAtStart,
         rpm_end = rpmRevolutionsAtEnd,
         include = includeCatch,
         water_velocity = waterVel,
         water_temp = waterTemp) |> 
  left_join(dates) |> 
  filter(trap_stop_date > max & year(trap_stop_date) > 2021) |> 
  select(trap_start_date, visit_type, trap_stop_date, stream, site, subsite,
         site_group, trap_functioning, fish_processed, rpm_start, rpm_end,
         total_revolutions, discharge, water_velocity, water_temp, turbidity,
         include)

butte_release_edi <- release_edi |> 
  mutate(stream = "butte creek",
         site_group = "butte creek",
         site = case_when(releaseSite == "Parrott-Phelan e-test release site" ~ "okie dam",
                          T ~ NA),
         subsite = NA,
         release_id = as.character(releaseID)) |> 
  rename(date_released = releaseTime,
         number_released = nReleased,
         run = markedRun,
         life_stage = markedLifeStage,
         origin = markedFishOrigin) |> 
  left_join(dates) |> 
  filter(date_released > max & year(date_released) > 2021) |> 
  select(date_released, release_id, stream, site, subsite, site_group,
         number_released, run, life_stage, origin)
# Battle/Clear ------------------------------------------------------------
res <- read_data_entity_names(packageId = "edi.1509.2")
raw <- read_data_entity(packageId = "edi.1509.2", entityId = res$entityId[1])
catch_edi <- read_csv(file = raw)
raw <- read_data_entity(packageId = "edi.1509.2", entityId = res$entityId[3])
recapture_edi <- read_csv(file = raw)
raw <- read_data_entity(packageId = "edi.1509.2", entityId = res$entityId[4])
release_edi <- read_csv(file = raw)
raw <- read_data_entity(packageId = "edi.1509.2", entityId = res$entityId[2])
trap_edi <- read_csv(file = raw)

battle_clear_catch_edi <- catch_edi |> 
  mutate(common_name = tolower(common_name)) |> 
  filter(common_name == "chinook salmon") |> 
  mutate(stream = case_when(grepl("clear creek", station_code) ~ "clear creek",
                            grepl("battle creek", station_code) ~ "battle creek"),
         site_group = stream,
         adipose_clipped = NA,
         dead = NA,
         species = "chinook",
         site = case_when(station_code == "lower battle creek" ~ "lbc",
                          station_code == "upper battle creek" ~ "ubc",
                          station_code == "lower clear creek" ~ "lcc",
                          station_code == "upper clear creek" ~ "ucc"),
         subsite = site,
         actual_count = NA) |> 
  rename(date = sample_date,
         run = fws_run) |> 
  left_join(dates) |> 
  filter(date > max & year(date) > 2021) |> 
  select(date, stream, site, subsite, site_group, count, run, life_stage, adipose_clipped,
         dead, fork_length, weight, actual_count, species) 

battle_clear_recapture_edi <- recapture_edi |> 
  mutate(stream = case_when(grepl("clear creek", site) ~ "clear creek",
                            grepl("battle creek", site) ~ "battle creek"),
         site_group = stream,
         dead = NA,
         species = "chinook",
         site = case_when(site == "lower battle creek" ~ "lbc",
                          site == "upper battle creek" ~ "ubc",
                          site == "lower clear creek" ~ "lcc",
                          site == "upper clear creek" ~ "ucc"),
         subsite = site,
         life_stage = NA,
         weight = NA) |> 
  rename(date = date_recaptured,
         run = fws_run,
         adipose_clipped = hatchery_origin,
         count = number_recaptured,
         fork_length = median_fork_length_recaptured) |> 
  left_join(dates) |> 
  filter(date > max & year(date)) |> 
  select(date, release_id, stream, site, subsite, site_group, count, run, life_stage, adipose_clipped,
         dead, fork_length, weight, species)

battle_clear_trap_edi <- trap_edi |> 
  mutate(stream = case_when(grepl("clear creek", station_code) ~ "clear creek",
                            grepl("battle creek", station_code) ~ "battle creek"),
         site_group = stream,
         site = case_when(station_code == "lower battle creek" ~ "lbc",
                          station_code == "upper battle creek" ~ "ubc",
                          station_code == "lower clear creek" ~ "lcc",
                          station_code == "upper clear creek" ~ "ucc"),
         subsite = site) |> 
  rename(trap_stop_date = sample_date,
         trap_stop_time = sample_time,
         total_revolutions = end_counter,
         water_velocity = velocity) |> 
  left_join(dates) |> 
  filter(trap_stop_date > max & year(trap_stop_date)) |> 
  select(trap_start_date, trap_stop_date, stream, site, subsite,
         site_group, total_revolutions, water_velocity, turbidity)

battle_clear_release_edi <- release_edi |> 
  mutate(stream = case_when(grepl("clear creek", site) ~ "clear creek",
                            grepl("battle creek", site) ~ "battle creek"),
         site_group = stream,
         site = case_when(site == "lower battle creek" ~ "lbc",
                          site == "upper battle creek" ~ "ubc",
                          site == "lower clear creek" ~ "lcc",
                          site == "upper clear creek" ~ "ucc"),
         subsite = NA) |> 
  rename(origin = origin_released) |> 
  left_join(dates) |> 
  filter(date_released > max & year(date_released) > 2021) |> 
  select(date_released, release_id, stream, site, subsite, site_group,
         number_released, origin)

# Feather -----------------------------------------------------------------
# Note there was an issue pushing these files to EDI due to large file size
# Until this is resolved, reading in the files locally
# res <- read_data_entity_names(packageId = "edi.1239.13")
# raw <- read_data_entity(packageId = "edi.1239.13", entityId = res$entityId[1])
# catch_edi <- read_csv(file = raw)
# raw <- read_data_entity(packageId = "edi.1239.13", entityId = res$entityId[2])
# recapture_edi <- read_csv(file = raw)
# raw <- read_data_entity(packageId = "edi.1239.13", entityId = res$entityId[3])
# release_edi <- read_csv(file = raw)
# raw <- read_data_entity(packageId = "edi.1239.13", entityId = res$entityId[4])
# trap_edi <- read_csv(file = raw)

catch_edi <- readxl::read_xlsx("data-raw/TEMP_data/feather_catch.xlsx")
recapture_edi <- readxl::read_xlsx("data-raw/TEMP_data/feather_recapture.xlsx")
release_edi <- readxl::read_xlsx("data-raw/TEMP_data/feather_release.xlsx")
trap_edi <- readxl::read_xlsx("data-raw/TEMP_data/feather_trap.xlsx")

lfc <- c("eye riffle_north", "eye riffle_side channel", "gateway main 400' up river", "gateway_main1", "gateway_rootball", "gateway_rootball_river_left", "#steep riffle_rst", "steep riffle_10' ext", "steep side channel")
hfc <- c("herringer_east", "herringer_upper_west", "herringer_west", "live oak", "shawns_east", "shawns_west", "sunset east bank", "sunset west bank")

lfc_site <- c("eye riffle")
hfc_site <- c("live oak","shawn's beach","sunset pumps","herringer riffle")

feather_catch_edi <- catch_edi |> 
  mutate(commonName = tolower(commonName)) |> 
  filter(commonName == "chinook salmon") |> 
  mutate(stream = "feather river",
         adipose_clipped = case_when(fishOrigin == "Natural" ~ F,
                                     fishOrigin == "Hatchery" ~ T,
                                     T ~ NA),
         dead = NA,
         weight = NA,
         species = "chinook",
         site = tolower(siteName),
         subsite = tolower(subSiteName),
         site_group = case_when(subsite %in% lfc ~ "feather river lfc",
                                subsite %in% hfc ~ "feather river hfc",
                                T ~ NA)) |> 
  rename(date = visitTime,
         count = n,
         life_stage = lifeStage,
         fork_length = forkLength,
         actual_count = actualCount) |> 
  left_join(dates) |> 
  filter(date > max) |> 
  select(date, stream, site, subsite, site_group, count, run, life_stage, adipose_clipped,
         dead, fork_length, weight, actual_count, species) 

feather_recapture_edi <- recapture_edi |> 
  mutate(stream = "feather river",
         adipose_clipped = case_when(fishOrigin == "Natural" ~ F,
                                     fishOrigin == "Hatchery" ~ T,
                                     T ~ NA),
         dead = NA,
         weight = NA,
         species = "chinook",
         site = tolower(siteName),
         subsite = tolower(subSiteName),
         site_group = case_when(subsite %in% lfc ~ "feather river lfc",
                                subsite %in% hfc ~ "feather river hfc",
                                T ~ NA),
         release_id = as.character(releaseID)) |> 
  rename(date = visitTime,
         count = n,
         life_stage = lifeStage,
         fork_length = forkLength) |> 
  left_join(dates) |> 
  filter(date > max) |> 
  select(date, release_id, stream, site, subsite, site_group, count, run, life_stage, adipose_clipped,
         dead, fork_length, weight, species)

feather_trap_edi <- trap_edi |> 
  arrange(subSiteName, visitTime) |>
  mutate(trap_start_date = ymd_hms(lag(visitTime)),
         trap_stop_date = ymd_hms(visitTime),
         stream = "feather river",
         site = tolower(siteName),
         subsite = tolower(subSiteName),
         site_group = case_when(subsite %in% lfc ~ "feather river lfc",
                                subsite %in% hfc ~ "feather river hfc",
                                T ~ NA)) |> 
  rename(visit_type = visitType,
         trap_functioning = trapFunctioning,
         fish_processed = fishProcessed,
         total_revolutions = counterAtEnd,
         rpm_start = rpmRevolutionsAtStart,
         rpm_end = rpmRevolutionsAtEnd,
         include = includeCatch,
         water_temp = waterTemp) |> 
  left_join(dates) |> 
  filter(trap_stop_date > max) |> 
  select(trap_start_date, visit_type, trap_stop_date, stream, site, subsite,
         site_group, trap_functioning, fish_processed, rpm_start, rpm_end,
         total_revolutions, water_temp, include)

feather_release_edi <- release_edi |> 
  mutate(stream = "feather river",
         site = tolower(releaseSite),
         site = case_when(grepl("eye riffle", site) ~ "eye riffle",
                          grepl("live oak", site) ~ "live oak",
                          grepl("herringer", site) ~ "herringer riffle",
                          grepl("steep riffle", site) ~ "steep riffle",
                          grepl("sunset", site) ~ "sunset pumps",
                          grepl("gateway", site) ~ "gateway riffle",
                          T ~ "not recorded"),
         site_group = case_when(site %in% lfc_site ~ "feather river lfc",
                                site %in% hfc_site ~ "feather river hfc",
                                T ~ NA),
         subsite = NA,
         life_stage = NA,
         release_id = as.character(releaseID)) |> 
  rename(date_released = releaseTime,
         number_released = nReleased,
         run = markedRun,
         origin = markedFishOrigin) |> 
  left_join(dates) |> 
  filter(date_released > max) |> 
  select(date_released, release_id, stream, site, subsite, site_group,
         number_released, run, life_stage, origin)

# Yuba --------------------------------------------------------------------
res <- read_data_entity_names(packageId = "edi.1529.11")
raw <- read_data_entity(packageId = "edi.1529.11", entityId = res$entityId[1])
catch_edi <- read_csv(file = raw)
raw <- read_data_entity(packageId = "edi.1529.11", entityId = res$entityId[2])
recapture_edi <- read_csv(file = raw)
raw <- read_data_entity(packageId = "edi.1529.11", entityId = res$entityId[3])
release_edi <- read_csv(file = raw)
raw <- read_data_entity(packageId = "edi.1529.11", entityId = res$entityId[4])
trap_edi <- read_csv(file = raw)

yuba_catch_edi <- catch_edi |> 
  mutate(commonName = tolower(commonName)) |> 
  filter(commonName == "chinook salmon") |> 
  mutate(stream = "yuba river",
         adipose_clipped = case_when(fishOrigin == "Natural" ~ F,
                                     fishOrigin == "Hatchery" ~ T,
                                     T ~ NA),
         dead = NA,
         weight = NA,
         species = "chinook",
         site = tolower(siteName),
         subsite = case_when(subSiteName == "yuba river" ~ "yub",
                             subSiteName == "Hallwood 1 RR" ~ "hal",
                             subSiteName == "Hallwood 2 RL" ~ "hal2",
                             subSiteName == "Hallwood 3" ~ "hal3"),
         site_group = "yuba river") |> 
  rename(date = visitTime,
         count = n,
         life_stage = lifeStage,
         fork_length = forkLength,
         actual_count = actualCount) |> 
  left_join(dates) |> 
  filter(date > max & year(date)) |> 
  select(date, stream, site, subsite, site_group, count, run, life_stage, adipose_clipped,
         dead, fork_length, weight, actual_count, species)

yuba_recapture_edi <- recapture_edi |> 
  mutate(stream = "yuba river",
         adipose_clipped = case_when(fishOrigin == "Natural" ~ F,
                                     fishOrigin == "Hatchery" ~ T,
                                     T ~ NA),
         dead = NA,
         weight = NA,
         species = "chinook",
         site = tolower(siteName),
         subsite = case_when(subSiteName == "yuba river" ~ "yub",
                             subSiteName == "Hallwood 1 RR" ~ "hal",
                             subSiteName == "Hallwood 2 RL" ~ "hal2",
                             subSiteName == "Hallwood 3" ~ "hal3"),
         site_group = "yuba river",
         release_id = as.character(releaseID)) |> 
  rename(date = visitTime,
         count = n,
         life_stage = lifeStage,
         fork_length = forkLength) |> 
  left_join(dates) |> 
  filter(date > max & year(date)) |> 
  select(date, release_id, stream, site, subsite, site_group, count, run, life_stage, adipose_clipped,
         dead, fork_length, weight, species)

yuba_trap_edi <- trap_edi |> 
  arrange(subSiteName, visitTime) |>
  mutate(trap_start_date = ymd_hms(lag(visitTime)),
         trap_stop_date = ymd_hms(visitTime),
         stream = "yuba river",
         site = tolower(siteName),
         subsite = case_when(subSiteName == "yuba river" ~ "yub",
                             subSiteName == "Hallwood 1 RR" ~ "hal",
                             subSiteName == "Hallwood 2 RL" ~ "hal2",
                             subSiteName == "Hallwood 3" ~ "hal3"),
         site_group = "yuba river") |> 
  rename(visit_type = visitType,
         trap_functioning = trapFunctioning,
         fish_processed = fishProcessed,
         total_revolutions = counterAtEnd,
         rpm_start = rpmRevolutionsAtStart,
         rpm_end = rpmRevolutionsAtEnd,
         include = includeCatch,
         water_temp = waterTemp) |> 
  left_join(dates) |> 
  filter(trap_stop_date > max & year(trap_stop_date)) |> 
  select(trap_start_date, visit_type, trap_stop_date, stream, site, subsite,
         site_group, trap_functioning, fish_processed, rpm_start, rpm_end,
         total_revolutions, water_temp, turbidity, include)

yuba_release_edi <- release_edi |> 
  mutate(stream = "yuba river",
         site = case_when(releaseSite == "Hallwood Release Site" ~ "hallwood"),
         subsite = NA,
         site_group = "yuba river",
         life_stage = NA,
         release_id = as.character(releaseID)) |> 
  rename(date_released = releaseTime,
         number_released = nReleased,
         run = markedRun,
         origin = markedFishOrigin) |> 
  left_join(dates) |> 
  filter(date_released > max & year(date_released)) |> 
  select(date_released, release_id, stream, site, subsite, site_group,
         number_released, run, life_stage, origin)

# Knights Landing ---------------------------------------------------------
res <- read_data_entity_names(packageId = "edi.1501.2")
raw <- read_data_entity(packageId = "edi.1501.2", entityId = res$entityId[2])
catch_edi <- read_csv(file = raw)
raw <- read_data_entity(packageId = "edi.1501.2", entityId = res$entityId[3])
recapture_edi <- read_csv(file = raw)
raw <- read_data_entity(packageId = "edi.1501.2", entityId = res$entityId[5])
release_edi <- read_csv(file = raw)
raw <- read_data_entity(packageId = "edi.1501.2", entityId = res$entityId[1])
trap_edi <- read_csv(file = raw)

knights_catch_edi <- catch_edi |> 
  mutate(commonName = tolower(commonName)) |> 
  filter(commonName == "chinook salmon") |> 
  mutate(stream = "sacramento river",
         site = "knights landing",
         adipose_clipped = case_when(fishOrigin == "Natural" ~ F,
                                     fishOrigin == "Hatchery" ~ T,
                                     T ~ NA),
         dead = NA,
         species = "chinook",
         site_group = "knights landing",
         actual_count = NA,
         subsite = as.character(subSiteName)) |> 
  rename(date = visitTime,
         count = n,
         life_stage = lifeStage,
         fork_length = forkLength) |> 
  left_join(dates) |> 
  filter(date > max & year(date)) |> 
  select(date, stream, site, subsite, site_group, count, run, life_stage, adipose_clipped,
         dead, fork_length, weight, actual_count, species)

knights_recapture_edi <- recapture_edi |> 
  mutate(stream = "sacramento river",
         site = "knights landing",
         adipose_clipped = case_when(fishOrigin == "Natural" ~ F,
                                     fishOrigin == "Hatchery" ~ T,
                                     T ~ NA),
         dead = NA,
         species = "chinook",
         site_group = "knights landing",
         weight = NA,
         subsite = as.character(subSiteName),
         release_id = as.character(releaseID)) |> 
  rename(date = visitTime,
         count = n,
         life_stage = lifeStage,
         fork_length = forkLength) |> 
  left_join(dates) |> 
  filter(date > max & year(date)) |> 
  select(date, release_id, stream, site, subsite, site_group, count, run, life_stage, adipose_clipped,
         dead, fork_length, weight, species)

knights_trap_edi <- trap_edi |> 
  mutate(stream = "sacramento river",
         site = "knights landing",
         site_group = "knights landing",
         subsite = as.character(subSiteName)) |> 
  rename(visit_type = visitType,
         trap_functioning = trapFunctioning,
         fish_processed = fishProcessed,
         total_revolutions = counterAtEnd,
         rpm_start = rpmRevolutionsAtStart,
         rpm_end = rpmRevolutionsAtEnd,
         include = includeCatch,
         water_temp = waterTemp,
         water_velocity = waterVel,
         trap_stop_date = trap_end_date) |> 
  left_join(dates) |> 
  filter(trap_stop_date > max & year(trap_stop_date)) |> 
  select(trap_start_date, visit_type, trap_stop_date, stream, site, subsite,
         site_group, trap_functioning, fish_processed, rpm_start, rpm_end,
         total_revolutions, water_temp, water_velocity, discharge, turbidity, include)

knights_release_edi <- release_edi |> 
  mutate(stream = "sacramento river",
         site = "knights landing",
         site_group = "knights landing",
         subsite = NA,
         release_id = as.character(releaseID)) |> 
  rename(date_released = releaseTime,
         number_released = nReleased,
         run = markedRun,
         origin = markedFishOrigin,
         life_stage = markedLifeStage) |> 
  left_join(dates) |> 
  filter(date_released > max & year(date_released)) |> 
  select(date_released, release_id, stream, site, subsite, site_group,
         number_released, run, life_stage, origin)


# Join all temp data ------------------------------------------------------

temp_catch <- bind_rows(battle_clear_catch_edi,
                        butte_catch_edi,
                        feather_catch_edi,
                        yuba_catch_edi,
                        knights_catch_edi)
temp_recapture <- bind_rows(battle_clear_recapture_edi,
                            butte_recapture_edi,
                            feather_recapture_edi,
                            yuba_recapture_edi,
                            knights_recapture_edi)
temp_release <- bind_rows(battle_clear_release_edi,
                          butte_release_edi,
                          feather_release_edi,
                          yuba_release_edi,
                          knights_release_edi)
temp_trap <- bind_rows(battle_clear_trap_edi,
                       butte_trap_edi,
                       feather_trap_edi,
                       yuba_trap_edi,
                       knights_trap_edi)
