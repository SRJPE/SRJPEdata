# Pull data from Azure Database 
library(DBI)
library(tidyverse)
library(lubridate)
library(SRJPEdata)

# CONNECT TO DB & VIEW TABLES --------------------------------------------------
# Use DBI - dbConnect to connect to database - keep user id and password sectret
con <- DBI::dbConnect(drv = RPostgres::Postgres(),
                      host = "rst-db-production.postgres.database.azure.com",
                      dbname = "postgres",
                      user = Sys.getenv("pilot_db_user_id"),
                      password = Sys.getenv("pilot_db_password"),
                      port = 5432)
DBI::dbListTables(con)

# catch 
try(rst_catch_query_pilot <- dbGetQuery(con, "SELECT 
                                        tv.trap_visit_time_start, 
                                        tv.trap_visit_time_end, 
                                        tl.trap_name as trap_name,
                                        t.commonname as species_common_name,
                                        r.definition as capture_run,
                                        mt.definition as mark_type,
                                        cr.adipose_clipped, 
                                        cr.dead,
                                        ls.definition as life_stage,
                                        cr.fork_length,
                                        cr.weight,
                                        cr.num_fish_caught, 
                                        cr.plus_count,
                                        pcm.definition as plus_count_methodology,
                                        cr.release_id,
                                        mt.definition as mark_type,
                                        mc.definition as mark_color,
                                        bp.definition as mark_position
                                        FROM catch_raw cr 
                                        left join trap_visit tv on (cr.trap_visit_id = tv.id)
                                        left join trap_locations tl on (tv.trap_location_id = tl.id) 
                                        left join program p on (cr.program_id = p.id)
                                        left join run r on (cr.capture_run_class = r.id)
                                        left join taxon t on (cr.taxon_code = t.code)
                                        left join life_stage ls on (cr.life_stage = ls.id)
                                        left join plus_count_methodology pcm on (cr.plus_count_methodology = pcm.id)
                                        left join existing_marks em on (cr.id = em.catch_raw_id)
                                        left join mark_type mt on (em.mark_type_id = mt.id)
                                        left join mark_color mc on (em.mark_color_id  = mc.id)
                                        left join body_part bp on (em.mark_position_id  = bp.id)
                                        where (tv.program_id = 1 or tv.program_id = 2)"))
# TODO structure so that it matches with rst_trap


try(if(!exists("rst_catch_query_pilot"))
  rst_catch_pilot <- SRJPEdata::rst_catch |> filter(stream %in% c("mill creek", "deer creek"))
  else(rst_catch_pilot <- rst_catch_query_pilot))

try(if(nrow(rst_catch_query_pilot) <= nrow(SRJPEdata::rst_catch |> filter(stream %in% c("mill creek", "deer creek")))) {
  rst_catch_pilot <- SRJPEdata::rst_catch  |> filter(stream %in% c("mill creek", "deer creek"))
  warning(paste("No new rst catch datasets detected in the database. RST catch data not updated on", Sys.Date()))
})


# Pull in Trap table 
try(rst_trap_query_pilot <-  dbGetQuery(con, 
                                  "SELECT 
                                   p.program_name as program_name, 
                                   tl.trap_name as trap_name,
                                   t.is_paper_entry, 
                                   t.trap_visit_time_start, 
                                   t.trap_visit_time_end,
                                   fp.definition as fish_processed,
                                   wfnp.definition as why_fish_not_processed,
                                   t.cone_depth,
                                   tf.definition as trap_functioning,
                                   tsae.definition as trap_status_at_end, 
                                   t.total_revolutions, 
                                   t.rpm_at_start, 
                                   t.rpm_at_end, 
                                   t.debris_volume_liters 
                                   FROM trap_visit t
                                   left join program p on (t.program_id = p.id)
                                   left join fish_processed fp on (t.fish_processed = fp.id)
                                   left join why_fish_not_processed wfnp on (t.why_fish_not_processed = wfnp.id)
                                   left join trap_functionality tf on (t.trap_functioning = tf.id)
                                   left join trap_status_at_end tsae on (t.trap_status_at_end = tsae.id)
                                   left join trap_locations tl on (t.trap_location_id = tl.id) 
                                   where (t.program_id = 1 or t.program_id = 2)") |> 
      mutate(trap_start_time = hms::as_hms(trap_visit_time_start),
             trap_start_date = as_date(trap_visit_time_start), 
             trap_stop_time = hms::as_hms(trap_visit_time_end),
             trap_stop_date = as_date(trap_visit_time_end)
      ))
# TODO structure so that it matches with rst_trap


try(if(!exists("rst_trap_query_pilot"))
  rst_trap_pilot <- SRJPEdata::rst_trap |> filter(stream %in% c("mill creek", "deer creek"))
  else(rst_trap_pilot <- rst_trap_query))

try(if(nrow(rst_trap_query_pilot) <= nrow(SRJPEdata::rst_trap |> filter(stream %in% c("mill creek", "deer creek")))) {
  rst_trap_pilot <- SRJPEdata::rst_trap |> filter(stream %in% c("mill creek", "deer creek"))
  warning(paste("No new rst trap datasets detected in the database. RST trap data not updated on", Sys.Date()))
})
# Pull in efficiency data 
# release table 
try(release_query_pilot <- dbGetQuery(con, ""))
try(if(!exists("release_query_pilot"))
  release <- SRJPEdata::release |> filter(stream %in% c("mill creek", "deer creek"))
  else(release <- release_query_pilot))

try(if(nrow(release_query_pilot) <= nrow(SRJPEdata::release)) {
  release <- SRJPEdata::release |> filter(stream %in% c("mill creek", "deer creek"))
  warning(paste("No new release datasets detected in the database. Release data not updated on", Sys.Date()))
})

# TODO release fish section
# Pull in release fish info, Fork length for release trials 

# glimpse(release_fish)

# Pull Recaptures ---
try(recaptures_query_pilot <- dbGetQuery(con, ""))

try(if(!exists("recaptures_query_pilot"))
  recaptures <- SRJPEdata::recaptures |> filter(stream %in% c("mill creek", "deer creek"))
  else(recaptures <- recaptures_query_pilot))

try(if(nrow(recaptures_query_pilot) <= nrow(SRJPEdata::recaptures)) {
  recaptures <- SRJPEdata::recaptures |> filter(stream %in% c("mill creek", "deer creek"))
  warning(paste("No new recaptures datasets detected in the database. Recaptures data not updated on", Sys.Date()))
})
