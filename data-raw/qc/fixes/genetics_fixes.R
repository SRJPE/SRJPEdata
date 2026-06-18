# Genetics Data Fixes ---------------------------------------------------------
# In-memory patches applied to completed_genetic_samples after the database
# pull but before usethis::use_data() saves .rda files.
#
# Each fix block references a log_id in data-raw/qc/qc_log.csv.
# When an issue is corrected in the source database:
#   1. Remove the fix block below
#   2. Update status to "fixed_in_source" in qc_log.csv
#
# Fix block template:
#
# # FIX: <short description>
# # Log ID: <log_id from qc_log.csv>
# # Identified: <YYYY-MM-DD>
# # Source fix target: yes/no
# # Remove when: <condition>
# completed_genetic_samples <- completed_genetic_samples |>
#   filter(...) # or mutate(...)

# No fixes applied yet.
