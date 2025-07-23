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
