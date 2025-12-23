# inst/scripts/compare_data_files.R
# ============================================
# DATA FILE COMPARISON SCRIPT FOR R PACKAGES
# ============================================
# Compares new .rda/.RData files with existing versions on main branch
# Checks that previous values remain unchanged

library(dplyr)
library(yaml)

# ============================================
# CONFIGURATION FROM YAML FILE
# ============================================

# Path to YAML configuration file
CONFIG_FILE <- "inst/config/data_comparison_config.yml"

get_file_config <- function(file_path, config_file = CONFIG_FILE) {
  file_name <- basename(file_path)
  
  # Default configuration
  default_config <- list(
    id_columns = NULL,
    allowed_to_change = c("notes"),
    date_columns = c(),
    numeric_tolerance = 1e-6,
    check_attributes = TRUE,
    allowed_attribute_changes = c("class", "row.names")
  )
  
  # Check if config file exists
  if (!file.exists(config_file)) {
    warning(paste("Configuration file not found:", config_file, "- using defaults"))
    return(default_config)
  }
  
  # Load YAML configuration
  tryCatch({
    all_configs <- yaml::read_yaml(config_file)
    
    # Get file-specific config or use default from YAML
    if (file_name %in% names(all_configs)) {
      config_data <- all_configs[[file_name]]
      cat("Using configuration for:", file_name, "\n")
    } else if ("default" %in% names(all_configs)) {
      config_data <- all_configs[["default"]]
      warning(paste("No configuration found for", file_name, "- using default from YAML"))
    } else {
      warning(paste("No configuration found for", file_name, "- using built-in defaults"))
      return(default_config)
    }
    
    # Convert YAML structure to expected format
    config <- list(
      id_columns = if (is.null(config_data$id_columns)) NULL else unlist(config_data$id_columns),
      allowed_to_change = if (is.null(config_data$allowed_to_change)) c() else unlist(config_data$allowed_to_change),
      date_columns = if (is.null(config_data$date_columns)) c() else unlist(config_data$date_columns),
      numeric_tolerance = if (is.null(config_data$numeric_tolerance)) 1e-6 else config_data$numeric_tolerance,
      check_attributes = if (is.null(config_data$check_attributes)) TRUE else config_data$check_attributes,
      allowed_attribute_changes = if (is.null(config_data$allowed_attribute_changes)) {
        c("class", "row.names")
      } else {
        unlist(config_data$allowed_attribute_changes)
      }
    )
    
    return(config)
    
  }, error = function(e) {
    warning(paste("Error reading config file:", e$message, "- using defaults"))
    return(default_config)
  })
}

# ============================================
# HELPER FUNCTIONS
# ============================================

load_rda_file <- function(file_path) {
  # Load .rda file and return the object(s) it contains
  env <- new.env()
  obj_names <- load(file_path, envir = env)
  
  if (length(obj_names) == 0) {
    stop(paste("No objects found in", file_path))
  }
  
  if (length(obj_names) > 1) {
    warning(paste("Multiple objects in", file_path, "- using first:", obj_names[1]))
  }
  
  list(
    data = env[[obj_names[1]]],
    object_name = obj_names[1]
  )
}

compare_values <- function(old_val, new_val, col_name) {
  # Handle NA comparisons
  if (is.na(old_val) && is.na(new_val)) return(TRUE)
  if (is.na(old_val) || is.na(new_val)) return(FALSE)
  
  # Numeric comparison with tolerance
  if (is.numeric(old_val) && is.numeric(new_val)) {
    return(abs(old_val - new_val) < NUMERIC_TOLERANCE)
  }
  
  # Direct comparison for other types
  return(old_val == new_val)
}

create_row_id <- function(data, id_cols) {
  if (is.null(id_cols)) {
    # Use row numbers if no ID columns specified
    return(as.character(seq_len(nrow(data))))
  }
  
  if (length(id_cols) == 1) {
    return(as.character(data[[id_cols]]))
  }
  
  # Create composite key
  do.call(paste, c(data[id_cols], sep = "_"))
}

compare_attributes <- function(old_data, new_data) {
  issues <- list()
  
  old_attrs <- attributes(old_data)
  new_attrs <- attributes(new_data)
  
  # Remove allowed attribute changes
  old_attrs <- old_attrs[!names(old_attrs) %in% ALLOWED_ATTRIBUTE_CHANGES]
  new_attrs <- new_attrs[!names(new_attrs) %in% ALLOWED_ATTRIBUTE_CHANGES]
  
  # Check for missing attributes
  missing_attrs <- setdiff(names(old_attrs), names(new_attrs))
  if (length(missing_attrs) > 0) {
    issues[[length(issues) + 1]] <- list(
      type = "MISSING_ATTRIBUTES",
      message = paste("Attributes removed:", paste(missing_attrs, collapse = ", "))
    )
  }
  
  # Check for new attributes
  new_attrs_added <- setdiff(names(new_attrs), names(old_attrs))
  if (length(new_attrs_added) > 0) {
    issues[[length(issues) + 1]] <- list(
      type = "NEW_ATTRIBUTES",
      message = paste("Attributes added:", paste(new_attrs_added, collapse = ", "))
    )
  }
  
  # Check for changed attributes
  common_attrs <- intersect(names(old_attrs), names(new_attrs))
  for (attr_name in common_attrs) {
    if (!identical(old_attrs[[attr_name]], new_attrs[[attr_name]])) {
      issues[[length(issues) + 1]] <- list(
        type = "MODIFIED_ATTRIBUTE",
        attribute = attr_name,
        message = paste("Attribute", attr_name, "was modified")
      )
    }
  }
  
  return(issues)
}

compare_data_files <- function(old_file, new_file) {
  
  # Get file-specific configuration
  config <- get_file_config(new_file)
  ID_COLUMNS <- config$id_columns
  ALLOWED_TO_CHANGE <- config$allowed_to_change
  DATE_COLUMNS <- config$date_columns
  NUMERIC_TOLERANCE <- config$numeric_tolerance
  CHECK_ATTRIBUTES <- config$check_attributes
  ALLOWED_ATTRIBUTE_CHANGES <- config$allowed_attribute_changes
  
  results <- list(
    file_name = basename(new_file),
    comparison_date = Sys.time(),
    status = "PASS",
    issues = list(),
    summary = list()
  )
  
  # Check if old file exists
  if (!file.exists(old_file)) {
    results$status <- "NEW_FILE"
    results$summary$message <- "This is a new file (no previous version to compare)"
    return(results)
  }
  
  # Load .rda files
  old_data <- NULL
  new_data <- NULL
  
  # Load new file
  tryCatch({
    new_loaded <- load_rda_file(new_file)
    new_data <- new_loaded$data
    results$summary$new_object_name <- new_loaded$object_name
  }, error = function(e) {
    results$status <- "ERROR"
    results$issues[[length(results$issues) + 1]] <- list(
      type = "LOAD_ERROR",
      message = paste("Error loading new file:", e$message)
    )
    return(results)
  })
  
  if (results$status == "ERROR") return(results)
  
  # Load old file
  tryCatch({
    old_loaded <- load_rda_file(old_file)
    old_data <- old_loaded$data
    results$summary$old_object_name <- old_loaded$object_name
    
    # Check if object names match
    if (old_loaded$object_name != new_loaded$object_name) {
      results$status <- "WARNING"
      results$issues[[length(results$issues) + 1]] <- list(
        type = "OBJECT_NAME_CHANGED",
        message = paste("Object name changed from", old_loaded$object_name, "to", new_loaded$object_name)
      )
    }
  }, error = function(e) {
    # Old file doesn't exist or can't be loaded - this is a new file
    cat("Note: Could not load old file (may be new file):", e$message, "\n")
    old_data <- NULL
  })
  
  # If old_data is NULL, this is a new file
  if (is.null(old_data)) {
    results$status <- "NEW_FILE"
    results$summary$message <- "This is a new file (no previous version to compare)"
    return(results)
  }
  
  # Check data types
  if (class(old_data)[1] != class(new_data)[1]) {
    results$status <- "ERROR"
    results$issues[[length(results$issues) + 1]] <- list(
      type = "TYPE_MISMATCH",
      message = paste("Data type changed from", class(old_data)[1], "to", class(new_data)[1])
    )
    return(results)
  }
  
  # Only compare data frames (most common case for data packages)
  if (!is.data.frame(old_data)) {
    results$status <- "WARNING"
    results$summary$message <- paste("Cannot compare non-data.frame objects of type:", class(old_data)[1])
    return(results)
  }
  
  # Compare attributes if enabled
  if (CHECK_ATTRIBUTES) {
    attr_issues <- compare_attributes(old_data, new_data)
    if (length(attr_issues) > 0) {
      results$issues <- c(results$issues, attr_issues)
    }
  }
  
  # Parse date columns
  for (date_col in DATE_COLUMNS) {
    if (date_col %in% names(old_data)) {
      old_data[[date_col]] <- as.Date(old_data[[date_col]])
    }
    if (date_col %in% names(new_data)) {
      new_data[[date_col]] <- as.Date(new_data[[date_col]])
    }
  }
  
  # Basic checks
  results$summary$old_rows <- nrow(old_data)
  results$summary$new_rows <- nrow(new_data)
  results$summary$old_cols <- ncol(old_data)
  results$summary$new_cols <- ncol(new_data)
  results$summary$rows_added <- nrow(new_data) - nrow(old_data)
  
  # Check for column changes
  old_cols <- names(old_data)
  new_cols <- names(new_data)
  
  removed_cols <- setdiff(old_cols, new_cols)
  if (length(removed_cols) > 0) {
    results$status <- "FAIL"
    results$issues[[length(results$issues) + 1]] <- list(
      type = "COLUMNS_REMOVED",
      message = paste("Columns removed:", paste(removed_cols, collapse = ", "))
    )
  }
  
  added_cols <- setdiff(new_cols, old_cols)
  if (length(added_cols) > 0) {
    results$summary$columns_added <- added_cols
  }
  
  # Check if ID columns exist
  if (!is.null(ID_COLUMNS)) {
    missing_id_cols <- setdiff(ID_COLUMNS, names(new_data))
    if (length(missing_id_cols) > 0) {
      results$status <- "ERROR"
      results$issues[[length(results$issues) + 1]] <- list(
        type = "MISSING_ID_COLUMNS",
        message = paste("ID columns missing in new data:", paste(missing_id_cols, collapse = ", "))
      )
      return(results)
    }
  }
  
  # Create row identifiers
  old_data$row_id <- create_row_id(old_data, ID_COLUMNS)
  new_data$row_id <- create_row_id(new_data, ID_COLUMNS)
  
  # Find matching rows
  matching_ids <- intersect(old_data$row_id, new_data$row_id)
  
  if (length(matching_ids) == 0) {
    results$summary$message <- "No matching rows found between old and new data"
    return(results)
  }
  
  results$summary$matching_rows <- length(matching_ids)
  
  # Get columns to check (exclude ID columns and allowed-to-change columns)
  cols_to_check <- setdiff(
    intersect(names(old_data), names(new_data)),
    c(ID_COLUMNS, ALLOWED_TO_CHANGE, "row_id")
  )
  
  # Compare matching rows
  modifications <- list()
  
  for (row_id in matching_ids) {
    old_row <- old_data[old_data$row_id == row_id, ]
    new_row <- new_data[new_data$row_id == row_id, ]
    
    for (col in cols_to_check) {
      old_val <- old_row[[col]]
      new_val <- new_row[[col]]
      
      if (!compare_values(old_val, new_val, col)) {
        modifications[[length(modifications) + 1]] <- list(
          row_id = row_id,
          column = col,
          old_value = old_val,
          new_value = new_val
        )
      }
    }
  }
  
  # Report modifications
  if (length(modifications) > 0) {
    results$status <- "FAIL"
    results$issues <- c(results$issues, modifications)
    results$summary$n_modifications <- length(modifications)
    results$summary$modified_columns <- unique(sapply(modifications, function(x) x$column))
  } else if (results$status == "PASS") {
    results$summary$message <- "All existing values match. No unauthorized modifications detected."
  }
  
  # Check for deleted rows
  deleted_ids <- setdiff(old_data$row_id, new_data$row_id)
  if (length(deleted_ids) > 0) {
    results$status <- "FAIL"
    results$summary$rows_deleted <- length(deleted_ids)
    results$issues[[length(results$issues) + 1]] <- list(
      type = "DELETED_ROWS",
      message = paste("Rows deleted:", length(deleted_ids)),
      row_ids = head(deleted_ids, 10)  # Show first 10
    )
  }
  
  # Check for new rows
  new_ids <- setdiff(new_data$row_id, old_data$row_id)
  if (length(new_ids) > 0) {
    results$summary$rows_added <- length(new_ids)
  }
  
  return(results)
}

format_report <- function(results_list) {
  report_lines <- c()
  
  overall_status <- if (all(sapply(results_list, function(x) x$status %in% c("PASS", "NEW_FILE")))) {
    "✅ PASS"
  } else if (any(sapply(results_list, function(x) x$status == "FAIL"))) {
    "❌ FAIL"
  } else {
    "⚠️ WARNING"
  }
  
  report_lines <- c(
    paste("**Overall Status:**", overall_status),
    "",
    paste("**Files Compared:**", length(results_list)),
    ""
  )
  
  for (result in results_list) {
    status_emoji <- switch(result$status,
                           "PASS" = "✅",
                           "NEW_FILE" = "🆕",
                           "FAIL" = "❌",
                           "ERROR" = "⚠️",
                           "WARNING" = "⚠️",
                           "❓"
    )
    
    report_lines <- c(
      report_lines,
      paste0("### ", status_emoji, " ", result$file_name),
      ""
    )
    
    # Object info
    if (!is.null(result$summary$old_object_name)) {
      report_lines <- c(
        report_lines,
        paste("- **Object name:**", result$summary$new_object_name)
      )
    }
    
    # Summary info
    if (!is.null(result$summary$old_rows)) {
      report_lines <- c(
        report_lines,
        paste("- **Old version:**", result$summary$old_rows, "rows ×", result$summary$old_cols, "columns"),
        paste("- **New version:**", result$summary$new_rows, "rows ×", result$summary$new_cols, "columns")
      )
      
      if (!is.null(result$summary$rows_added) && result$summary$rows_added > 0) {
        report_lines <- c(report_lines, paste("- **New rows added:**", result$summary$rows_added))
      }
      
      if (!is.null(result$summary$rows_deleted) && result$summary$rows_deleted > 0) {
        report_lines <- c(report_lines, paste("- **Rows deleted:** ⚠️", result$summary$rows_deleted))
      }
      
      if (!is.null(result$summary$columns_added) && length(result$summary$columns_added) > 0) {
        report_lines <- c(report_lines, paste("- **Columns added:**", paste(result$summary$columns_added, collapse = ", ")))
      }
      
      if (!is.null(result$summary$matching_rows)) {
        report_lines <- c(report_lines, paste("- **Matching rows checked:**", result$summary$matching_rows))
      }
    }
    
    if (!is.null(result$summary$message)) {
      report_lines <- c(report_lines, paste("- ", result$summary$message))
    }
    
    # Issues
    if (length(result$issues) > 0 && result$status %in% c("FAIL", "WARNING")) {
      report_lines <- c(report_lines, "", "**⚠️ Issues Found:**", "")
      
      # Check for attribute issues
      attr_issues <- result$issues[sapply(result$issues, function(x) 
        !is.null(x$type) && x$type %in% c("MISSING_ATTRIBUTES", "NEW_ATTRIBUTES", "MODIFIED_ATTRIBUTE"))]
      
      if (length(attr_issues) > 0) {
        report_lines <- c(report_lines, "**Attribute changes:**", "")
        for (issue in attr_issues) {
          report_lines <- c(report_lines, paste("-", issue$message))
        }
        report_lines <- c(report_lines, "")
      }
      
      # Group modifications by column
      mods <- result$issues[sapply(result$issues, function(x) !is.null(x$column))]
      
      if (length(mods) > 0) {
        cols_modified <- unique(sapply(mods, function(x) x$column))
        
        report_lines <- c(
          report_lines,
          paste("**Modified columns:**", paste(cols_modified, collapse = ", ")),
          ""
        )
        
        # Show first 5 modifications
        n_show <- min(5, length(mods))
        report_lines <- c(report_lines, "**Sample modifications:**", "")
        
        for (i in 1:n_show) {
          mod <- mods[[i]]
          report_lines <- c(
            report_lines,
            paste0(i, ". Row `", mod$row_id, "`, Column `", mod$column, "`"),
            paste0("   - Old: `", mod$old_value, "`"),
            paste0("   - New: `", mod$new_value, "`"),
            ""
          )
        }
        
        if (length(mods) > 5) {
          report_lines <- c(report_lines, paste("... and", length(mods) - 5, "more modifications"))
        }
      }
      
      # Check for deleted rows issue
      deleted_issue <- result$issues[sapply(result$issues, function(x) !is.null(x$type) && x$type == "DELETED_ROWS")]
      if (length(deleted_issue) > 0) {
        issue <- deleted_issue[[1]]
        report_lines <- c(
          report_lines,
          "",
          paste("**Deleted rows:**", length(issue$row_ids), "rows were removed"),
          paste("Sample IDs:", paste(head(issue$row_ids, 5), collapse = ", "))
        )
      }
      
      # Check for other issues
      other_issues <- result$issues[sapply(result$issues, function(x) 
        !is.null(x$type) && x$type %in% c("OBJECT_NAME_CHANGED", "COLUMNS_REMOVED", "LOAD_ERROR", "TYPE_MISMATCH"))]
      
      if (length(other_issues) > 0) {
        report_lines <- c(report_lines, "")
        for (issue in other_issues) {
          report_lines <- c(report_lines, paste("-", issue$message))
        }
      }
    }
    
    report_lines <- c(report_lines, "", "---", "")
  }
  
  return(paste(report_lines, collapse = "\n"))
}

# ============================================
# MAIN EXECUTION
# ============================================

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  stop("No files provided for comparison")
}

# Parse changed files
changed_files <- strsplit(args[1], " ")[[1]]

cat("Changed files:", paste(changed_files, collapse = ", "), "\n")

# Compare each file
results_list <- list()

for (new_file in changed_files) {
  cat("\nComparing:", new_file, "\n")
  
  # Get the old version from main branch
  old_file <- paste0("main_", basename(new_file))
  
  # Checkout the file from main branch
  git_command <- paste0("git show main:", new_file, " > ", old_file)
  git_result <- system(git_command, ignore.stderr = FALSE, intern = FALSE)
  
  # Check if git command succeeded
  if (git_result != 0 || !file.exists(old_file) || file.info(old_file)$size == 0) {
    cat("Note: Could not retrieve old version from main branch (may be new file)\n")
    # Create empty marker file so compare_data_files knows it's new
    if (file.exists(old_file)) {
      file.remove(old_file)
    }
  }
  
  # Compare
  result <- compare_data_files(old_file, new_file)
  results_list[[length(results_list) + 1]] <- result
  
  # Clean up
  if (file.exists(old_file)) {
    file.remove(old_file)
  }
}

# Generate report
report <- format_report(results_list)

# Save report
writeLines(report, "comparison_report.txt")

cat("\n=== COMPARISON REPORT ===\n")
cat(report)
cat("\n=========================\n")

# Exit with error if any comparisons failed
if (any(sapply(results_list, function(x) x$status == "FAIL"))) {
  cat("\n❌ Comparison FAILED: Unauthorized modifications detected\n")
  quit(status = 1)
} else if (any(sapply(results_list, function(x) x$status == "WARNING"))) {
  cat("\n⚠️ Comparison completed with warnings\n")
  quit(status = 0)
} else {
  cat("\n✅ Comparison PASSED: No unauthorized modifications\n")
  quit(status = 0)
}