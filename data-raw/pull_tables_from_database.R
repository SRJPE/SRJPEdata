# Pull data from Azure Database 
library(DBI)
library(tidyverse)
library(lubridate)
library(SRJPEdata)

# CONNECT TO DB & VIEW TABLES --------------------------------------------------
# Use DBI - dbConnect to connect to database - keep user id and password sectret
con <- DBI::dbConnect(drv = RPostgres::Postgres(),
                      host = "jpe-db.postgres.database.azure.com",
                      dbname = "postgres",
                      user = Sys.getenv("jpe_db_user_id"),
                      password = Sys.getenv("jpe_db_password"),
                      port = 5432)
# DBI::dbListTables(con)

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

try(if(nrow(rst_catch_query) <= nrow(SRJPEdata::rst_catch)) {
  rst_catch <- SRJPEdata::rst_catch
  warning(paste("No new rst catch datasets detected in the database. RST catch data not updated on", Sys.Date()))
})


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

try(if(nrow(rst_trap_query) <= nrow(SRJPEdata::rst_trap)) {
  rst_trap <- SRJPEdata::rst_trap
  warning(paste("No new rst trap datasets detected in the database. RST trap data not updated on", Sys.Date()))
})

# Pull in efficiency Summary 
# Need med fork length released, med fork length at recapture, flow at release, ect. 
try(efficiency_summary_query <- dbGetQuery(con, "SELECT rs.date_released, rs.release_id, tl.stream, tl.site, 
                                                tl.subsite, tl.site_group, rs.number_released, rs.number_recaptured, r.definition as run, 
                                                ls.definition as life_stage, o.definition as origin
                                                FROM release_summary rs 
                                                left join trap_location tl on rs.trap_location_id = tl.id 
                                                left join run r on rs.run_id = r.id
                                                left join lifestage ls on rs.lifestage_id = ls.id
                                                left join origin o on rs.origin_id = o.id"))

try(if(!exists("efficiency_summary_query"))
  efficiency_summary <- SRJPEdata::efficiency_summary
  else(efficiency_summary <- efficiency_summary_query))

try(if(nrow(efficiency_summary_query) <= nrow(SRJPEdata::efficiency_summary)) {
  efficiency_summary <- SRJPEdata::efficiency_summary
  warning(paste("No new efficiency summary datasets detected in the database. Efficency summary data not updated on", Sys.Date()))
})


# Pull in release fish info, Fork length for release trials 
# TODO NO DATA IN RELEASE FISH - FIX
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

try(if(nrow(recaptures_query) <= nrow(SRJPEdata::recaptures)) {
  recaptures <- SRJPEdata::recaptures
  warning(paste("No new recaptures datasets detected in the database. Recaptures data not updated on", Sys.Date()))
})


## SAVE TO DATA PACKAGE ---
usethis::use_data(rst_catch, overwrite = TRUE)
usethis::use_data(rst_trap, overwrite = TRUE)
usethis::use_data(efficiency_summary, overwrite = TRUE)
# usethis::use_data(release_fish, overwrite = TRUE)
usethis::use_data(recaptures, overwrite = TRUE)

# glimpse(recaptured)


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
  warning(paste("No new upstream passage datasets detected in the database. Upstream passage data not updated on", Sys.Date()))
})

# Pull in passage estimates 
try(upstream_passage_estimates_query <- dbGetQuery(con, "SELECT p.year, sl.stream, sl.reach, p.passage_estimate, p.adipose_clipped,  
                                                         r.definition as run, p.upper_bound_estimate, p.lower_bound_estimate,
                                                         p.confidence_level
                                                         FROM passage_estimates p
                                                         left join survey_location sl on p.survey_location_id = sl.id
                                                         left join run r on p.run_id = r.id") |> 
      filter(stream != "butte creek"))

try(if(!exists("upstream_passage_estimates_query"))
  upstream_passage_estimates <- SRJPEdata::upstream_passage_estimates
  else(upstream_passage_estimates <- upstream_passage_estimates_query))

try(if(nrow(upstream_passage_estimates_query) <= nrow(SRJPEdata::upstream_passage_estimates)) {
  upstream_passage_estimates <- SRJPEdata::upstream_passage_estimates
  warning(paste("No new upstream passage estimates datasets detected in the database. Upstream passage estimates data not updated on", Sys.Date()))
})

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
  warning(paste("No new holding datasets detected in the database. Holding data not updated on", Sys.Date()))
})

# Pull in redd data (just daily)
try(redd_query <- dbGetQuery(con, "SELECT r.date, sl.stream, sl.reach, r.latitude, r.longitude,
                                   ru.definition as run, r.velocity, r.redd_id, r.age
                                   FROM daily_redd r
                                   left join survey_location sl on r.survey_location_id = sl.id
                                   left join run ru on r.run_id = ru.id"))


try(if(!exists("redd_query"))
  redd <- SRJPEdata::redd
  else(redd <- redd_query))

try(if(nrow(redd_query) <= nrow(SRJPEdata::redd)) {
  redd <- SRJPEdata::redd
  warning(paste("No new redd datasets detected in the database. Redd data not updated on", Sys.Date()))
})

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
  warning(paste("No new carcass estimates datasets detected in the database. Carcass estimate data not updated on", Sys.Date()))
})

## SAVE TO DATA PACKAGE ---
usethis::use_data(upstream_passage, overwrite = TRUE)
usethis::use_data(upstream_passage_estimates, overwrite = TRUE)
usethis::use_data(holding, overwrite = TRUE)
usethis::use_data(redd, overwrite = TRUE)
usethis::use_data(carcass_estimates, overwrite = TRUE)

