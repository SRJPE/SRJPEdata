# Pull data from Azure Database 
library(DBI)
library(tidyverse)
library(lubridate)
library(SRJPEdata)
library(googleCloudStorageR)

gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
gcs_global_bucket(bucket = Sys.getenv("GCS_DEFAULT_BUCKET"))

# Note that I fixed a table and pulled in directly - this will be updated on db and then can be removed
# gcs_get_object(object_name = "model-db/catch.csv",
#               bucket = gcs_get_global_bucket(),
#               saveToDisk = "data-raw/database-tables/catch.csv",
#               overwrite = TRUE)
# rst_catch_raw <- read_csv("data-raw/database-tables/catch.csv")
# CONNECT TO DB & VIEW TABLES --------------------------------------------------
# Use DBI - dbConnect to connect to database - keep user id and password sectret
con <- DBI::dbConnect(drv = RPostgres::Postgres(),
                      host = "jpe-db.postgres.database.azure.com",
                      dbname = "jpedb-prod",
                      user = Sys.getenv("jpe_db_user_id"),
                      password = Sys.getenv("jpe_db_password"),
                      port = 5432)
 DBI::dbListTables(con)

# PULL IN HELPER TABLES 
 try(trap_location_query <- dbGetQuery(con, "SELECT *
                                       FROM trap_location"))
 
 try(if(!exists("trap_location_query"))
   rst_trap_locations <- SRJPEdata::rst_trap_locations
   else(rst_trap_locations <- trap_location_query))
 
 # try(if(nrow(trap_location_query) <= nrow(SRJPEdata::rst_trap_locations)) {
 #   rst_trap_locations <- SRJPEdata::rst_trap_locations
 #   warning(paste("No new rst locations added to the database."))
 # })
 site_lookup <- rst_trap_locations |>  
   select(stream, site, subsite, site_group) |> 
   distinct()
 usethis::use_data(site_lookup, overwrite = TRUE)
 
 run <- dbGetQuery(con, "SELECT * FROM run")
 lifestage <- dbGetQuery(con, "SELECT * FROM lifestage")
 survey_location <- dbGetQuery(con, "SELECT * FROM survey_location")
 
 # This can be removed after table is updated on db
 # rst_catch <- rst_catch_raw |>
 #   left_join(rst_trap_locations, by = c("trap_location_id" = "id")) |>
 #   left_join(run, by = c("run_id" = "id")) |>
 #   left_join(lifestage, by = c("lifestage_id" = "id")) |>
 #   select(date, stream, site, subsite, site_group, count, run = definition.x, life_stage = definition.y,
 #          adipose_clipped, dead, fork_length, weight, actual_count) |>
 #   mutate(species = "chinook",
 #          subsite = case_when(site == "yuba river" ~ "hal",
 #                     T ~ subsite),
 #          site = case_when(stream == "yuba river" ~ "hallwood",
 #                  T ~ site))
 
 # This can be removed after the adult data pull is finalized
gcs_get_object(object_name = "model-db/daily_redd.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = "data-raw/database-tables/redd.csv",
               overwrite = TRUE)
redd_raw <- read_csv("data-raw/database-tables/redd.csv")
redd <- redd_raw |> 
  left_join(survey_location, by = c("survey_location_id" = "id")) |> 
  left_join(run, by = c("run_id" = "id")) |> 
  select(date, stream, reach, latitude, longitude, run = definition, velocity, redd_id, age, redd_count)

# PULL IN RST DATA -------------------------------------------------------------
# Pull in Catch table
try(rst_catch_query <- dbGetQuery(con, "SELECT c.date, tl.stream, tl.site, tl.subsite, tl.site_group, 
                                       c.count, r.definition as run, ls.definition as life_stage, 
                                       c.adipose_clipped, c.dead, c.fork_length, c.weight, c.actual_count
                                       FROM catch c 
                                       left join trap_location tl on c.trap_location_id = tl.id 
                                       left join run r on c.run_id = r.id
                                       left join lifestage ls on c.lifestage_id = ls.id") |> 
      mutate(species = "chinook"))

try(if(!exists("rst_catch_query"))
  rst_catch <- SRJPEdata::rst_catch
  else(rst_catch <- rst_catch_query))

# try(if(nrow(rst_catch_query) <= nrow(SRJPEdata::rst_catch)) {
#   rst_catch <- SRJPEdata::rst_catch
#   warning(paste("No new rst catch datasets detected in the database. Maximum date of RST catch data is", max(SRJPEdata::rst_catch$date, na.rm = TRUE)))
# })

# Removes NA sites that come from battle, will change logic after discussing EDI package udpates with battle team
rst_catch <- rst_catch |> 
  filter(!is.na(site), !is.na(date))

# Pull in Trap table 
try(rst_trap_query <-  dbGetQuery(con, 
                                  "SELECT tv.trap_visit_time_start as trap_start_date, vt.definition as visit_type, tv.trap_visit_time_end as trap_stop_date, tl.stream, tl.site, tl.subsite, 
                                  tl.site_group, tf.definition as trap_functioning, tv.in_half_cone_configuration, fp.definition as fish_processed, tv.rpm_start, tv.rpm_end, tv.total_revolutions,
                                  tv.debris_volume, tv.discharge, tv.water_velocity, tv.water_temp, tv.turbidity, tv.include
                                  FROM trap_visit tv
                                  left join visit_type vt on tv.visit_type_id = vt.id
                                  left join trap_location tl on tv.trap_location_id = tl.id
                                  left join trap_functioning tf on tv.trap_functioning_id = tf.id
                                  left join fish_processed fp on tv.fish_processed_id = fp.id
                                  left join debris_level d on tv.debris_level_id = d.id") |> 
        mutate(trap_start_time = hms::as_hms(trap_start_date),
               trap_start_date = as_date(trap_start_date), 
               trap_stop_time = hms::as_hms(trap_stop_date),
               trap_stop_date = as_date(trap_stop_date)
               
  ))

try(if(!exists("rst_trap_query"))
  rst_trap <- SRJPEdata::rst_trap
  else(rst_trap <- rst_trap_query))

# try(if(nrow(rst_trap_query) <= nrow(SRJPEdata::rst_trap)) {
#   rst_trap <- SRJPEdata::rst_trap
#   warning(paste("No new rst trap datasets detected in the database. Maximum date of RST trap data is", max(SRJPEdata::rst_trap$trap_stop_date, na.rm = TRUE)))
# })
# Pull in efficiency data 
# release table 
 try(release_query <- dbGetQuery(con, "SELECT rs.date_released, rs.release_id, tl.stream, tl.site, 
                                                tl.subsite, tl.site_group, rs.number_released, r.definition as run, 
                                                rs.median_fork_length_released,
                                                ls.definition as life_stage, o.definition as origin
                                                FROM release rs 
                                                left join trap_location tl on rs.trap_location_id = tl.id 
                                                left join run r on rs.run_id = r.id
                                                left join lifestage ls on rs.lifestage_id = ls.id
                                                left join origin o on rs.origin_id = o.id"))
 try(if(!exists("release_query"))
   release <- SRJPEdata::release
   else(release <- release_query))
 
 # try(if(nrow(release_query) <= nrow(SRJPEdata::release)) {
 #   release <- SRJPEdata::release
 #   warning(paste("No new release datasets detected in the database. Maximum date of release datais", max(SRJPEdata::release$date_released, na.rm = TRUE)))
 # })

# Pull in release fish info, Fork length for release trials 
# TODO Update if we get data in release fish 
# release_fish <- dbGetQuery(con, "SELECT rf.release_id, tl.stream, tl.site, tl.subsite, tl.site_group, rf.fork_length
#                                  FROM released_fish rf 
#                                  left join trap_location tl on rf.trap_location_id = tl.id") 

# glimpse(release_fish)

# Pull Recaptures ---
try(recaptures_query <- dbGetQuery(con, "SELECT rf.date, rf.count, rf.release_id, tl.stream, tl.site, tl.subsite, tl.site_group, rf.fork_length, rf.dead, 
                                         rf.weight, r.definition as run, ls.definition as life_stage, rf.adipose_clipped
                                         FROM recaptured_fish rf 
                                         left join trap_location tl on rf.trap_location_id = tl.id 
                                         left join run r on rf.run_id = r.id
                                         left join lifestage ls on rf.lifestage_id = ls.id"))

try(if(!exists("recaptures_query"))
  recaptures <- SRJPEdata::recaptures
  else(recaptures <- recaptures_query))

# try(if(nrow(recaptures_query) <= nrow(SRJPEdata::recaptures)) {
#   recaptures <- SRJPEdata::recaptures
#   warning(paste("No new recaptures datasets detected in the database. Maximum date of recaptures data is", max(SRJPEdata::recaptures$date, na.rm = TRUE)))
# })



# PULL IN ADULT DATA -------------------------------------------------------------
# Pull in passage raw counts 
# TODO decide if we want more site information 
# TODO 14 records with NA stream and NA reach...figure out what is going on there (looks like it is probably battle creek)
# TODO filter out butte creek 
try(upstream_passage_query <- dbGetQuery(con, "SELECT p.date, sl.stream, sl.reach, p.count, p.adipose_clipped,  
                                              r.definition as run, s.definition as sex, d.definition as direction,
                                              p.hours_sampled
                                              FROM passage_counts p
                                              left join survey_location sl on p.survey_location_id = sl.id
                                              left join run r on p.run_id = r.id
                                              left join sex s on p.sex_id = s.id
                                              left join direction d on p.direction_id = d.id"))

try(if(!exists("upstream_passage_query"))
  upstream_passage <- SRJPEdata::upstream_passage
  else(upstream_passage <- upstream_passage_query))

try(if(nrow(upstream_passage_query) <= nrow(SRJPEdata::upstream_passage)) {
  upstream_passage <- SRJPEdata::upstream_passage
  warning(paste("No new upstream passage datasets detected in the database. Maximum year of upstream passage data is", max(SRJPEdata::upstream_passage$date, na.rm = TRUE)))
})

# Pull in passage estimates 
# TODO fix query, not returning anything 
try(upstream_passage_estimates_query <- dbGetQuery(con, "SELECT p.year, sl.stream, p.passage_estimate, p.adipose_clipped,  
                                                         r.definition as run, p.upper_bound_estimate, p.lower_bound_estimate,
                                                         p.confidence_level
                                                         FROM passage_estimates p
                                                         left join survey_location sl on p.survey_location_id = sl.id
                                                         left join run r on p.run_id = r.id"))

try(if(!exists("upstream_passage_estimates_query"))
  upstream_passage_estimates <- SRJPEdata::upstream_passage_estimates
  else(upstream_passage_estimates <- upstream_passage_estimates_query))

# Removed because of the filter that removes data from query
# try(if(nrow(upstream_passage_estimates_query) <= nrow(SRJPEdata::upstream_passage_estimates)) {
#   upstream_passage_estimates <- SRJPEdata::upstream_passage_estimates
#   warning(paste("No new upstream passage estimates datasets detected in the database. Maximum date of upstream passage estimates data is", max(SRJPEdata::upstream_passage_estimates$year, na.rm = TRUE)))
# })

# pull in holding data
try(holding_query <- dbGetQuery(con, "SELECT h.date, sl.stream, sl.reach, h.count, h.adipose_clipped,  
                                      r.definition as run, h.latitude, h.longitude
                                      FROM daily_holding h
                                      left join survey_location sl on h.survey_location_id = sl.id
                                      left join run r on h.run_id = r.id"))

try(if(!exists("holding_query"))
  holding <- SRJPEdata::holding
  else(holding <- holding_query))

try(if(nrow(holding_query) <= nrow(SRJPEdata::holding)) {
  holding <- SRJPEdata::holding
  warning(paste("No new holding datasets detected in the database. Holding data  is", Sys.Date()))
})

# We are not pulling in redd data from the database. Redd summary is generated in buld_adult_model_datasets
# Pull in redd data (just daily) 
# try(redd_query <- dbGetQuery(con, "SELECT r.date, sl.stream, sl.reach, r.latitude, r.longitude,
#                                    ru.definition as run, r.velocity, r.redd_id, r.age
#                                    FROM daily_redd r
#                                    left join survey_location sl on r.survey_location_id = sl.id
#                                    left join run ru on r.run_id = ru.id"))
# 
# 
# try(if(!exists("redd_query"))
#   redd <- SRJPEdata::redd
#   else(redd <- redd_query))
# 
# try(if(nrow(redd_query) <= nrow(SRJPEdata::redd)) {
#   redd <- SRJPEdata::redd
#   warning(paste("No new redd datasets detected in the database. Maximum date of redd data is", max(SRJPEdata::redd$date, na.rm = TRUE)))
# })

# Pull in raw carcass data 
# TODO not seeing this table in db, do we want it?

# Pull in carcass estimates 
try(carcass_estimates_query <- dbGetQuery(con, "SELECT c.year, sl.stream, sl.reach, c.carcass_estimate, c.adipose_clipped,  
                                               r.definition as run, c.upper_bound_estimate, c.lower_bound_estimate,
                                               c.confidence_level
                                               FROM carcass_estimates c
                                               left join survey_location sl on c.survey_location_id = sl.id
                                               left join run r on c.run_id = r.id"))
try(if(!exists("carcass_estimates_query"))
  carcass_estimates <- SRJPEdata::carcass_estimates
  else(carcass_estimates <- carcass_estimates_query))

try(if(nrow(carcass_estimates_query) <= nrow(SRJPEdata::carcass_estimates)) {
  carcass_estimates <- SRJPEdata::carcass_estimates
  warning(paste("No new carcass estimates datasets detected in the database. Maximum date of carcass estimate data is", max(SRJPEdata::carcass_estimates$year, na.rm = TRUE)))
})
