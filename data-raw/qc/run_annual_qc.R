# Annual QC Orchestration -----------------------------------------------------
# Run this script once per year after the RST season ends (typically July).
#
# Before running:
#   1. Rebuild the package data: run update_data.R first
#   2. Run devtools::load_all() in this session
#
# This script renders all four QC reports and prints a log summary.
# Rendered HTML files are saved to data-raw/qc/reports/ and tracked in git.

library(quarto)
library(here)
library(glue)

# Set the run year being reviewed (adjust as needed) --------------------------
review_run_year <- lubridate::year(Sys.Date())

# Paths -----------------------------------------------------------------------
qc_dir      <- here::here("data-raw", "qc")
reports_dir <- file.path(qc_dir, "reports")
if (!dir.exists(reports_dir)) dir.create(reports_dir, recursive = TRUE)

run_date <- format(Sys.Date(), "%Y-%m-%d")

render_report <- function(qmd_name, label) {
  message(glue("\nRendering {label} QC report..."))
  out_file <- paste0(tools::file_path_sans_ext(qmd_name), "_", run_date, ".html")
  quarto::quarto_render(
    input         = file.path(qc_dir, qmd_name),
    output_file   = out_file,
    execute_params = list(review_run_year = review_run_year)
  )
  rendered_path <- file.path(qc_dir, out_file)
  dest_path     <- file.path(reports_dir, out_file)
  if (file.exists(rendered_path)) file.rename(rendered_path, dest_path)
  message(glue("  -> {dest_path}"))
}

# Render all QC reports -------------------------------------------------------
render_report("rst_qc.qmd",        "RST")
render_report("flow_qc.qmd",       "Flow & Temperature")
render_report("efficiency_qc.qmd", "Efficiency Trials")
render_report("genetics_qc.qmd",   "Genetics")

# Print log summary -----------------------------------------------------------
source(file.path(qc_dir, "qc_helpers.R"))
qc_log_summary()

message("\nNext steps:")
message("  1. Open data-raw/qc/reports/ and review each HTML report")
message("  2. Open data-raw/qc/qc_log.csv and update 'status' and 'reviewer_notes' for each open issue")
message("     status options: reviewed_no_issue | fixed_in_patch | fixed_in_source")
message("  3. For fixed_in_patch: add a fix block to the relevant data-raw/qc/fixes/*.R script")
message("     and record the fix_script path in qc_log.csv")
message("  4. Commit qc_log.csv, reports/, and any fixes/ changes")
message("  5. Re-run update_data.R to rebuild data with patches applied")
