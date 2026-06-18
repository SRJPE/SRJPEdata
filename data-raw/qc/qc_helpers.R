# QC Helpers ------------------------------------------------------------------
# Shared functions and constants for the annual QC workflow.
# Source this script at the top of each QC report.

library(readr)
library(dplyr)
library(lubridate)
library(glue)
library(stringr)
library(here)

QC_LOG_PATH <- here::here("data-raw", "qc", "qc_log.csv")

LOG_COLS <- c(
  "log_id", "date_identified", "data_type", "stream", "site", "run_year",
  "issue_type", "field", "description", "n_records", "severity", "status",
  "reviewer_notes", "date_resolved", "fix_script"
)

KEY_COLS <- c("data_type", "stream", "site", "run_year", "issue_type", "field")

SEVERITY_DEFAULTS <- c(
  "implausible_value"          = "critical",
  "recaptures_exceed_releases" = "critical",
  "extended_gap"               = "critical",
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

# Append new issues to qc_log.csv.
# Issues already present (matched on KEY_COLS) are skipped regardless of status,
# preserving any reviewer notes or status updates across re-runs.
# Returns the newly added rows invisibly.
log_issues <- function(new_issues, log_path = QC_LOG_PATH) {
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

  # Read existing log (all character for type safety)
  if (file.exists(log_path) && file.info(log_path)$size > 50) {
    existing <- readr::read_csv(log_path, show_col_types = FALSE,
                                col_types = readr::cols(.default = "c"))
  } else {
    existing <- tibble::tibble()
  }

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
    message(glue::glue("  + {n_new} new issue(s) logged. {n_skip} already in log."))
  } else {
    message(glue::glue("  All {nrow(new_issues)} issue(s) already in log."))
  }

  invisible(truly_new)
}

# Print a summary of the QC log to the console
qc_log_summary <- function(log_path = QC_LOG_PATH) {
  if (!file.exists(log_path) || file.info(log_path)$size < 50) {
    message("QC log is empty.")
    return(invisible(NULL))
  }
  log <- readr::read_csv(log_path, show_col_types = FALSE)
  cat(glue::glue("\n=== QC Log Summary ({nrow(log)} total issues) ===\n\n"))
  log |>
    dplyr::count(data_type, status, severity) |>
    dplyr::arrange(data_type, status, severity) |>
    print(n = Inf)
  cat("\n")
}
