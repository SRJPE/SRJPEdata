# script to pull genetics data from the run-id-database

# remotes::install_github("SRJPE/grunID")
library(grunID) 

con <- gr_db_connect()

complete_genetic_samples <- DBI::dbGetQuery(con, 
                                            "SELECT s.id AS sample_id, s.datetime_collected, se.first_sample_date, s.fork_length_mm, 
                                            rt.run_name AS sherlock_run_assignment, rt2.run_name AS field_run_assignment,
                                            sl.stream_name
                                            FROM sample AS s
                                            LEFT JOIN genetic_run_identification as gr ON gr.sample_id = s.id
                                            LEFT JOIN sample_status AS ss ON ss.sample_id = s.id
                                            LEFT JOIN run_type AS rt ON rt.id = gr.run_type_id
                                            LEFT JOIN run_type AS rt2 ON rt2.id = s.field_run_type_id
                                            LEFT JOIN sample_bin AS sb ON sb.id = s.sample_bin_id
                                            LEFT JOIN sample_event AS se ON sb.sample_event_id = se.id
                                            LEFT JOIN sample_location AS sl ON se.sample_location_id = sl.id
                                            WHERE ss.status_code_id = 11;")

usethis::use_data(complete_genetic_samples, overwrite = TRUE)
