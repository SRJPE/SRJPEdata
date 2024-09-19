# Pull data from Azure Database 
library(DBI)
library(tidyverse)
library(lubridate)
library(SRJPEdata)

# CONNECT TO DB & VIEW TABLES --------------------------------------------------
# Use DBI - dbConnect to connect to database - keep user id and password sectret
con <- DBI::dbConnect(drv = RPostgres::Postgres(),
                      host = "rst-db-production-datatackle.postgres.database.azure.com",
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
                                        tl.site_name as site,
                                        t.commonname as species_common_name,
                                        r.definition as capture_run,
                                        cr.adipose_clipped, 
                                        cr.dead,
                                        ls.definition as life_stage,
                                        cr.fork_length,
                                        cr.weight,
                                        cr.num_fish_caught, 
                                        em.release_id,
                                        cr.plus_count,
                                        pcm.definition as plus_count_methodology,
                                        mt.definition as mark_type,
                                        mc.definition as mark_color,
                                        bp.definition as mark_position,
                                        p.stream_name as stream
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
                                        where (tv.program_id = 1 or tv.program_id = 2)") |> 
  mutate(date = as.Date(trap_visit_time_end),
         stream = tolower(stream),
         site = ifelse(tolower(site) == "mill creek rst", "mill creek", "deer creek"), # TODO update once queries are more complicated
         subsite = ifelse(tolower(trap_name) == "mill creek rst", "mill creek", "deer creek"),
         site_group = stream,
         count = num_fish_caught, 
         run = capture_run,
         species = tolower(species_common_name)) |> 
    filter(is.na(release_id)) |> 
    select(c("date", "stream", "site", "subsite", "site_group", "count", 
             "run", "life_stage", "adipose_clipped", "dead", "fork_length", 
             "weight", "species")))

# Data Checks 
rst_catch_query_pilot$adipose_clipped |> unique() #TODO I believe these should all be FALSE 
rst_catch_query_pilot$dead |> unique() #TODO lets make sure we are defaulting to FALSE on pilot, not NA

# TODO add tests 


# Pull in Trap table 
try(rst_trap_query_pilot <-  dbGetQuery(con, 
                                  "SELECT 
                                   p.program_name as program_name, 
                                   p.stream_name as stream,
                                   tl.trap_name as trap_name,
                                   tl.site_name as site,
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
                                   t.debris_volume_liters, 
                                   tve.measure_name, 
                                   tve.measure_value_numeric,
                                   tve.measure_value_text, 
                                   tve.measure_unit
                                   FROM trap_visit t
                                   left join program p on (t.program_id = p.id)
                                   left join fish_processed fp on (t.fish_processed = fp.id)
                                   left join why_fish_not_processed wfnp on (t.why_fish_not_processed = wfnp.id)
                                   left join trap_functionality tf on (t.trap_functioning = tf.id)
                                   left join trap_status_at_end tsae on (t.trap_status_at_end = tsae.id)
                                   left join trap_locations tl on (t.trap_location_id = tl.id) 
                                   left join trap_visit_environmental tve on (t.id = tve.trap_visit_id)
                                   where (t.program_id = 1 or t.program_id = 2)") |> 
      mutate(trap_start_time = hms::as_hms(trap_visit_time_start),
             trap_start_date = as_date(trap_visit_time_start), 
             trap_stop_time = hms::as_hms(trap_visit_time_end),
             trap_stop_date = as_date(trap_visit_time_end),
             stream = tolower(stream), 
             site = ifelse(tolower(site) == "mill creek rst", "mill creek", "deer creek"), # TODO update once queries are more complicated
             subsite = ifelse(tolower(trap_name) == "mill creek rst", "mill creek", "deer creek"),
             site_group = stream,
             rpm_start = rpm_at_start, 
             rpm_end = rpm_at_end, 
             debris_volume = debris_volume_liters) |> # TODO confirm units match up with rst_trap data 
      pivot_wider(names_from = measure_name, values_from = measure_value_numeric) |> 
      rename(discharge = `flow measure`,
             water_temp = `water temperature`) |> 
      select(c("trap_start_date", "trap_stop_date", "stream", 
               "site", "subsite", "site_group", "trap_functioning",  
               "fish_processed", "rpm_start", "rpm_end", "total_revolutions", 
               "debris_volume", "discharge", "water_temp",  "trap_start_time", "trap_stop_time")) )

  
# ENV variables we are missing 
# turbidity, velocity - mill and deer currently do not collect. 
# also missing visit_type but we intentionally don't collect that

# TODO update tests, needs a date component as well to make sure we are only taking datatackle 
# try(if(!exists("rst_trap_query_pilot"))
#   rst_trap_pilot <- SRJPEdata::rst_trap |> 
#     filter(stream %in% c("mill creek", "deer creek")) 
#   else(rst_trap_pilot <- rst_trap_query_pilot))


# Pull in efficiency data 
# release table 
# TODO this query only works for mill deer (release all hatchery, will need to be updated once we bring in other systems)
dbGetQuery(con, "SELECT * from release") 
try(release_query_pilot <- dbGetQuery(con, "SELECT 
                                       r.id as release_id,
                                       r.released_at as released_at, 
                                       p.program_name as program_name, 
                                       p.stream_name as stream,
                                       rs.release_site_name as release_site,
                                       rp.definition as release_purpose, 
                                       r.total_hatchery_fish_released as number_released
                                       FROM release r 
                                       left join program p on (r.program_id = p.id)
                                       left join release_site rs on (r.release_site_id = rs.id)
                                       left join release_purpose rp on (r.release_purpose_id = rp.id)") |> 
      mutate(date_released = as.Date(released_at), 
             origin = "hatchery", 
             stream = tolower(stream),
             site = stream,
             subsite = stream, 
             site_group = stream, 
             run = NA, 
             life_stage = NA) |> 
      select(c("date_released", "release_id", "stream", "site", "subsite", 
               "site_group", "number_released", "run", "life_stage", "origin"
      )))

# try(if(!exists("release_query_pilot"))
#   release <- SRJPEdata::release |> filter(stream %in% c("mill creek", "deer creek"))
#   else(release <- release_query_pilot))

# Pull Recaptures ---
try(recaptures_query_pilot <- dbGetQuery(con, "SELECT 
                                        tv.trap_visit_time_start, 
                                        tv.trap_visit_time_end, 
                                        tl.trap_name as trap_name,
                                        tl.site_name as site,
                                        t.commonname as species_common_name,
                                        r.definition as capture_run,
                                        cr.adipose_clipped, 
                                        cr.dead,
                                        ls.definition as life_stage,
                                        cr.fork_length,
                                        cr.weight,
                                        cr.num_fish_caught, 
                                        cr.plus_count,
                                        pcm.definition as plus_count_methodology,
                                        em.release_id,
                                        mt.definition as mark_type,
                                        mc.definition as mark_color,
                                        bp.definition as mark_position,
                                        p.stream_name as stream
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
                                        where (tv.program_id = 1 or tv.program_id = 2)") |> 
      mutate(date = as.Date(trap_visit_time_end),
             stream = tolower(stream),
             site = ifelse(tolower(site) == "mill creek rst", "mill creek", "deer creek"), # TODO update once queries are more complicated
             subsite = ifelse(tolower(trap_name) == "mill creek rst", "mill creek", "deer creek"),
             site_group = stream,
             count = num_fish_caught, 
             run = capture_run,
             species = tolower(species_common_name)) |> 
      filter(!is.na(release_id)) |> 
      select(c("date", "stream", "site", "subsite", "site_group", "count", 
               "run", "life_stage", "adipose_clipped", "dead", "fork_length", 
               "weight", "species", "release_id")))

# try(if(!exists("recaptures_query_pilot"))
#   recaptures <- SRJPEdata::recaptures |> filter(stream %in% c("mill creek", "deer creek"))
#   else(recaptures <- recaptures_query_pilot))

