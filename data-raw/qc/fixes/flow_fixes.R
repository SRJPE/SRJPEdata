# Flow & Temperature Data Fixes -----------------------------------------------
# In-memory patches applied to environmental_data after the pull scripts
# but before usethis::use_data() saves .rda files.
#
# Each fix block references a log_id in data-raw/qc/qc_log.csv.
# When an issue is corrected in the source data:
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
# environmental_data <- environmental_data |>
#   filter(...) # or mutate(...)

# No fixes applied yet.
