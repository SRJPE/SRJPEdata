# QC Helpers ------------------------------------------------------------------
# Shared functions and constants for the annual QC workflow.
# Source this script at the top of each QC report.

library(readr)
library(dplyr)
library(lubridate)
library(glue)
library(stringr)
library(here)

QC_ERROR_LOG_PATH   <- here::here("data-raw", "qc", "qc_log_errors.csv")
QC_WARNING_LOG_PATH <- here::here("data-raw", "qc", "qc_log_warnings.csv")

# Maps an alert_level value to the log file it belongs in. Anything other
# than "error" is treated as a warning, so unrecognized/legacy alert_level
# values still land somewhere rather than being silently dropped.
qc_log_path_for_alert_level <- function(alert_level) {
  dplyr::if_else(alert_level == "error", QC_ERROR_LOG_PATH, QC_WARNING_LOG_PATH)
}

LOG_COLS <- c(
  "log_id", "date_identified", "data_type", "stream", "site", "run_year",
  "issue_type", "field", "description", "n_records", "severity", "alert_level",
  "status", "reviewer_notes", "date_resolved", "fix_script"
)

KEY_COLS <- c("data_type", "stream", "site", "run_year", "issue_type", "field")

SEVERITY_DEFAULTS <- c(
  "implausible_value"          = "critical",
  "recaptures_exceed_releases" = "critical",
  "extended_gap"               = "critical",
  "no_efficiency_trials"       = "critical",
  "high_na_rate"               = "moderate",
  "low_sampling_effort"        = "moderate",
  "low_trial_coverage"         = "moderate",
  "gap"                        = "moderate",
  "low_sample_count"           = "moderate",
  "extreme_value"              = "minor",
  "low_release_count"          = "minor",
  "zero_recaptures"            = "minor",
  "run_assignment_mismatch"    = "minor",
  "missing_trap_record"        = "minor"
)

# alert_level: "warning" checks surface things worth a look but that are
# frequently benign; "error" checks surface things that are very likely a
# real data problem (physically impossible values, complete data gaps).
ALERT_LEVEL_DEFAULTS <- c(
  "implausible_value"          = "error",
  "recaptures_exceed_releases" = "error",
  "extended_gap"               = "warning",
  "no_efficiency_trials"       = "error",
  "high_na_rate"               = "warning",
  "low_sampling_effort"        = "error",
  "low_trial_coverage"         = "warning",
  "gap"                        = "warning",
  "low_sample_count"           = "warning",
  "extreme_value"              = "error",
  "low_release_count"          = "warning",
  "zero_recaptures"            = "warning",
  "run_assignment_mismatch"    = "warning",
  "missing_trap_record"        = "warning"
)

# alert_level is per (issue_type, field) rather than per issue_type alone,
# since a few issue_types cover both warning- and error-tagged checks
# depending on field (e.g. implausible_value/fork_length is a warning check,
# implausible_value/hours_fished is an error check). Used by qc_summary.qmd
# to label checks it recomputes directly from source data, without having to
# duplicate each check's hardcoded alert_level/severity assignment.
CHECK_METADATA <- tibble::tribble(
  ~data_type,   ~issue_type,                   ~field,                     ~alert_level, ~severity,  ~description,
  "rst",        "high_na_rate",                "fork_length",              "warning",    "moderate", "% of RST catch records with missing fork length.",
  "rst",        "implausible_value",           "fork_length",              "warning",    "critical", "% of measured fork lengths that are biologically implausible (<20mm or >200mm).",
  "rst",        "extreme_value",               "count",                    "error",      "minor",    "% of stream-site-years where total annual catch exceeds 4x that site's median annual catch.",
  "rst",        "extreme_value",               "count_weekly",             "error",      "minor",    "% of weekly catch counts more than 2 SD above that site's mean weekly count.",
  "rst",        "low_sampling_effort",         "weeks_sampled",            "error",      "moderate", "% of (site x week) slots in the BTSPAS window (weeks 45-53, 1-22) without a sampled week.",
  "rst",        "implausible_value",           "hours_fished",             "error",      "critical", "% of weekly hours_fished values exceeding 168 (24x7) - physically impossible for a week.",
  "flow",       "gap",                         "stream_coverage",          "error",      "critical", "% of the 8 expected streams missing entirely from flow data for the run year.",
  "flow",       "gap",                         "week",                     "warning",    "moderate", "% of (stream x week) slots in the BTSPAS window with no flow reading.",
  "flow",       "extended_gap",                "week",                     "warning",    "critical", "Streams/site_groups with a gap of >7 consecutive missing days of flow during the RST season.",
  "flow",       "implausible_value",           "value",                    "error",      "critical", "% of flow readings in the BTSPAS window that are zero or negative.",
  "flow",       "implausible_value",           "temperature",              "warning",    "critical", "% of temperature readings outside a plausible range (-5C to 35C).",
  "efficiency", "recaptures_exceed_releases",  "number_recaptured",        "error",      "critical", "% of efficiency trials where recaptures exceed releases (physically impossible).",
  "efficiency", "low_release_count",           "number_released",          "warning",    "minor",    "% of efficiency trials releasing fewer than 50 fish.",
  "efficiency", "zero_recaptures",              "number_recaptured",       "warning",    "minor",    "% of efficiency trials with zero recaptured fish.",
  "efficiency", "low_trial_coverage",          "n_trials",                 "warning",    "moderate", "% of (site x BTSPAS-window trial slots) short of the 3-trial minimum for the run year.",
  "efficiency", "extreme_value",               "number_recaptured",        "error",      "minor",    "% of stream-site-years where mean trial efficiency exceeds 3 SD above that site's historical mean.",
  "efficiency", "no_efficiency_trials",        "number_released",          "error",      "critical", "% of actively-trapping stream-sites that logged zero efficiency trials anywhere that year.",
  "genetics",   "low_sample_count",            "sample_id",                "warning",    "moderate", "Sites/years with fewer genetic samples than expected.",
  "genetics",   "high_na_rate",                "fork_length_mm",           "warning",    "moderate", "% of genetic samples missing fork length.",
  "genetics",   "high_na_rate",                "sherlock_run_assignment",  "warning",    "moderate", "% of genetic samples missing a Sherlock run assignment.",
  "genetics",   "run_assignment_mismatch",     "sherlock_run_assignment",  "warning",    "minor",    "% of samples where Sherlock run assignment disagrees with the field-assigned run."
)

# Convert a date vector to run year (week >= 45 belongs to year + 1)
as_run_year <- function(date) {
  dplyr::if_else(lubridate::week(date) >= 45,
                 lubridate::year(date) + 1L,
                 lubridate::year(date))
}

# Build a stable, human-readable log ID from the key fields
make_log_id <- function(data_type, stream, site, run_year, issue_type, field) {
  stringr::str_replace_all(
    paste(data_type, stream, site, run_year, issue_type, field, sep = "__"),
    " ", "_"
  )
}

# Read a single QC log file (qc_log_errors.csv or qc_log_warnings.csv),
# dropping any fully-blank rows.
# Spreadsheet apps (Excel, Numbers, Google Sheets) often leave blank rows
# behind when a range of rows is cleared/deleted and the file is re-saved as
# CSV, rather than truly removing the lines. Every reader of the log routes
# through this function so those blank rows get dropped as soon as they're
# encountered, instead of being read back in and rewritten by log_issues()
# on every subsequent run (which would make them accumulate indefinitely).
read_qc_log <- function(log_path) {
  if (!file.exists(log_path) || file.info(log_path)$size < 50) {
    return(tibble::tibble())
  }
  log <- readr::read_csv(log_path, show_col_types = FALSE,
                         col_types = readr::cols(.default = "c"))
  log[rowSums(!is.na(log)) > 0, ]
}

# Read and combine both the error and warning logs into one data frame.
# Use this wherever a report needs a full view across alert levels (e.g. the
# "all open issues" tables and the year-over-year summary), rather than
# reading qc_log_errors.csv / qc_log_warnings.csv directly.
read_full_qc_log <- function() {
  dplyr::bind_rows(
    read_qc_log(QC_ERROR_LOG_PATH),
    read_qc_log(QC_WARNING_LOG_PATH)
  )
}

# Append truly-new rows (already restricted to a single log file's worth of
# issues) to log_path, deduplicating on KEY_COLS against what's already there.
# Issues already present are skipped regardless of status, preserving any
# reviewer notes or status updates across re-runs. Returns the newly added
# rows invisibly.
append_to_qc_log <- function(new_issues, log_path) {
  existing <- read_qc_log(log_path)

  # Deduplicate on KEY_COLS
  make_key <- function(df) apply(df[, KEY_COLS, drop = FALSE], 1, paste, collapse = "|")
  new_issues_chr <- new_issues |> dplyr::mutate(dplyr::across(dplyr::everything(), as.character))

  if (nrow(existing) > 0) {
    truly_new <- new_issues_chr[!make_key(new_issues_chr) %in% make_key(existing), ]
  } else {
    truly_new <- new_issues_chr
  }

  n_new  <- nrow(truly_new)
  n_skip <- nrow(new_issues) - n_new

  if (n_new > 0) {
    combined <- dplyr::bind_rows(existing, truly_new)
    readr::write_csv(combined, log_path, na = "")
  }

  list(truly_new = truly_new, n_new = n_new, n_skip = n_skip)
}

# Log new issues, routing each row to qc_log_errors.csv or qc_log_warnings.csv
# based on its alert_level. Returns the newly added rows (across both files)
# invisibly.
log_issues <- function(new_issues) {
  if (nrow(new_issues) == 0) {
    message("  No issues detected for this check.")
    return(invisible(tibble::tibble()))
  }

  # Fill auto-populated columns
  new_issues <- new_issues |>
    dplyr::mutate(
      log_id          = make_log_id(data_type, stream, site, run_year, issue_type, field),
      date_identified = as.character(Sys.Date()),
      status          = "open",
      reviewer_notes  = NA_character_,
      date_resolved   = NA_character_,
      fix_script      = NA_character_
    )

  # Ensure all LOG_COLS present (fill missing with NA)
  for (col in setdiff(LOG_COLS, names(new_issues))) {
    new_issues[[col]] <- NA_character_
  }
  new_issues <- new_issues[, LOG_COLS]

  # Route each row to its log file by alert_level, and append separately so
  # errors and warnings dedup against (and land in) their own file.
  new_issues$log_path <- qc_log_path_for_alert_level(new_issues$alert_level)

  results <- lapply(split(new_issues, new_issues$log_path), function(issues_for_log) {
    log_path <- issues_for_log$log_path[[1]]
    append_to_qc_log(issues_for_log[, LOG_COLS], log_path)
  })

  n_new  <- sum(vapply(results, `[[`, integer(1), "n_new"))
  n_skip <- sum(vapply(results, `[[`, integer(1), "n_skip"))

  if (n_new > 0) {
    message(glue::glue("  + {n_new} new issue(s) logged. {n_skip} already in log."))
  } else {
    message(glue::glue("  All {nrow(new_issues)} issue(s) already in log."))
  }

  invisible(dplyr::bind_rows(lapply(results, `[[`, "truly_new")))
}

# Print a summary of the QC log (combined across errors and warnings) to the console
qc_log_summary <- function() {
  log <- read_full_qc_log()
  if (nrow(log) == 0) {
    message("QC log is empty.")
    return(invisible(NULL))
  }
  cat(glue::glue("\n=== QC Log Summary ({nrow(log)} total issues) ===\n\n"))
  log |>
    dplyr::count(data_type, alert_level, status, severity) |>
    dplyr::arrange(data_type, alert_level, status, severity) |>
    print(n = Inf)
  cat("\n")
}
