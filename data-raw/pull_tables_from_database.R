# Pull data from Azure Database 
library(DBI)
library(tidyverse)
library(lubridate)

# Use DBI - dbConnect to connect to database - keep user id and password sectret
con <- DBI::dbConnect(drv = RPostgres::Postgres(),
                      host = "jpe-db.postgres.database.azure.com",
                      dbname = "postgres",
                      user = Sys.getenv("jpe_db_user_id"),
                      password = Sys.getenv("jpe_db_password"),
                      port = 5432)
# DBI::dbListTables(con)


# Catch table missing is yearling 
catch <- dbGetQuery(con, 
                    "SELECT c.date, tl.stream, tl.site, tl.subsite, tl.site_group, c.count, r.definition as run, 
                    ls.definition as life_stage, c.adipose_clipped, c.dead, c.fork_length, c.weight, c.actual_count
                    FROM catch c 
                    left join trap_location tl on c.trap_location_id = tl.id 
                    left join run r on c.run_id = r.id
                    left join lifestage ls on c.lifestage_id = ls.id") |> 
  mutate(species = "chinook")

# glimpse(catch)

# Trap table 
trap <-  dbGetQuery(con, 
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
  )
# glimpse(trap)

# Efficiency Summary 
# Need med fork length released, med fork length at recapture, flow at release, ect. 
efficiency_summary <- dbGetQuery(con, 
                    "SELECT rs.date_released, rs.release_id, tl.stream, tl.site, tl.subsite, tl.site_group, rs.number_released, rs.number_recaptured, r.definition as run, 
                    ls.definition as life_stage, o.definition as origin
                    FROM release_summary rs 
                    left join trap_location tl on rs.trap_location_id = tl.id 
                    left join run r on rs.run_id = r.id
                    left join lifestage ls on rs.lifestage_id = ls.id
                    left join origin o on rs.origin_id = o.id") 

# glimpse(efficiency_summary)

# NO DATA IN RELEASE FISH - FIX
release_fish <- dbGetQuery(con, "SELECT rf.release_id, tl.stream, tl.site, tl.subsite, tl.site_group, rf.fork_length
                    FROM released_fish rf 
                    left join trap_location tl on rf.trap_location_id = tl.id") 

# glimpse(release_fish)


recaptured <- dbGetQuery(con, "SELECT rf.date, rf.count, rf.release_id, tl.stream, tl.site, tl.subsite, tl.site_group, rf.fork_length, rf.dead, 
                           rf.weight, r.definition as run, ls.definition as life_stage, rf.adipose_clipped
                           FROM recaptured_fish rf 
                           left join trap_location tl on rf.trap_location_id = tl.id 
                           left join run r on rf.run_id = r.id
                           left join lifestage ls on rf.lifestage_id = ls.id") 

glimpse(recaptured)
