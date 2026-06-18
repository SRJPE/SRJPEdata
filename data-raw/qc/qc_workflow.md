# Annual QC Workflow

This document describes the planned annual QC workflow for the SRJPEdata package. QC covers RST catch and trap data, flow and temperature data, efficiency trial data, and genetics data. The workflow is designed to run once per year after the RST season ends (typically July), with automated issue detection and a manual review step.

---

## Directory Structure

```
data-raw/qc/
  qc_log.csv                # persistent issue log, tracked in git
  qc_helpers.R              # shared functions sourced by all QC reports
  rst_qc.qmd                # RST catch & trap QC report
  flow_qc.qmd               # flow & temperature QC report
  efficiency_qc.qmd         # efficiency trial QC report
  genetics_qc.qmd           # genetics QC report (stub until integrated)
  run_annual_qc.R           # orchestration script — run this annually
  reports/                  # rendered HTML reports, tracked in git
  fixes/
    rst_fixes.R             # in-memory data patches for RST
    flow_fixes.R            # in-memory data patches for flow/temp
    efficiency_fixes.R      # in-memory data patches for efficiency trials
    genetics_fixes.R        # in-memory data patches for genetics
```

---

## The QC Log (`qc_log.csv`)

Tracked in git. Issues are **auto-appended** by the QC reports. Reviewers **manually fill in** the review columns.

| column | populated by | description |
|---|---|---|
| `log_id` | auto | stable ID: paste of key fields, spaces → underscores |
| `date_identified` | auto | `Sys.Date()` when issue first flagged |
| `data_type` | auto | `rst`, `flow`, `efficiency`, `genetics` |
| `stream` | auto | stream name |
| `site` | auto | site or site_group |
| `run_year` | auto | run year of affected data |
| `issue_type` | auto | category (see below) |
| `field` | auto | which variable has the issue |
| `description` | auto | human-readable sentence describing the specific issue |
| `n_records` | auto | number of affected records |
| `severity` | auto | `critical`, `moderate`, `minor` (default by issue_type, reviewer can override) |
| `status` | **manual** | `open` → `reviewed_no_issue` / `fixed_in_patch` / `fixed_in_source` |
| `reviewer_notes` | **manual** | explanation of resolution or why it is not an issue |
| `date_resolved` | **manual** | date status changed from `open` |
| `fix_script` | **manual** | path + line reference to fix, if patched |

**Deduplication:** when a QC report runs, it checks existing log entries by the composite key `(data_type, stream, site, run_year, issue_type, field)`. Issues already present — regardless of status — are not re-added. This preserves reviewer notes and status across re-runs.

**Issue types and default severities:**

| issue_type | severity | meaning |
|---|---|---|
| `implausible_value` | critical | biologically or physically impossible value |
| `recaptures_exceed_releases` | critical | more fish recaptured than released in an efficiency trial |
| `extended_gap` | critical | >7 consecutive missing days during season |
| `high_na_rate` | moderate | >95% missing in a key field for a site/year |
| `low_sampling_effort` | moderate | <3 weeks sampled in BTSPAS window |
| `low_trial_coverage` | moderate | <3 efficiency trials in the BTSPAS window for a run_year |
| `gap` | moderate | any missing dates during RST season |
| `low_sample_count` | moderate | fewer samples than expected for site/year |
| `extreme_value` | minor | statistically unusual but not impossible — review needed |
| `low_release_count` | minor | fewer than 50 fish released in an efficiency trial |
| `zero_recaptures` | minor | efficiency trial with 0 recaptures |
| `run_assignment_mismatch` | minor | high rate of Sherlock vs. field disagreement |
| `missing_trap_record` | minor | catch dates with no corresponding trap visit |

---

## `qc_helpers.R`

Sourced at the top of every QC report. Contains:

- **`as_run_year(date)`** — converts a date to run year using the week >= 45 convention
- **`make_log_id(...)`** — pastes key fields into a readable stable ID
- **`log_issues(new_issues, log_path)`** — reads existing log, removes duplicates on key fields, appends only truly new issues, writes CSV
- **`qc_log_summary(log_path)`** — prints a count table of issues by data_type x status x severity (used at end of `run_annual_qc.R`)

---

## RST QC Report (`rst_qc.qmd`)

Works from `SRJPEdata::rst_catch`, `SRJPEdata::rst_trap`, and `SRJPEdata::weekly_juvenile_abundance_catch_data`.

**Check 1 — Fork length: high NA rate**
- Group `rst_catch` by stream/site/run_year
- Flag if >95% of records have `NA` fork length AND total records >50
- Catches seasons where measurements were not recorded at all
- Visualization: heatmap of pct NA by site x run_year

**Check 2 — Fork length: implausible values**
- Flag any stream/site/run_year with records where `fork_length < 20` or `fork_length > 200`
- These are biologically implausible for juvenile chinook at an RST
- Visualization: dot plot of flagged values in context of full fork length distribution

**Check 3 — Catch: extreme annual totals**
- For each stream/site, compute total annual catch per run_year
- Flag run_years where total catch >4x the site median across all run_years (minimum 5 years of history required)
- Not necessarily an error — could be a real high-catch year — but always warrants review
- Visualization: time series of annual catch per site with flagged years highlighted

**Check 4 — Season coverage: low sampling effort**
- Use `weekly_juvenile_abundance_catch_data`, filter to BTSPAS window (weeks 45–53, 1–22)
- Flag all stream/site/run_years with <3 sampled weeks, including those already in `years_to_exclude_rst_data`, to provide a complete picture of data gaps
- Indicate in the description whether each flagged run_year is already excluded from modeling
- Visualization: tile plot of sampling coverage by site x run_year, with excluded years marked

---

## Flow QC Report (`flow_qc.qmd`)

Works from `SRJPEdata::environmental_data`.

**Check 1 — Stream coverage: expected streams present**
- For the most recent run_year, verify all 8 expected streams have flow data
- Expected streams: battle creek, butte creek, clear creek, deer creek, feather river, mill creek, sacramento river, yuba river
- Flag any stream missing from the current run_year entirely
- Visualization: table of stream x parameter x most recent date available

**Check 2 — Flow: gaps during RST season**
- For each stream/site_group/run_year, generate the expected daily date sequence Oct 1 – Jun 30
- Join with actual data, find missing dates (parameter = "flow", statistic = "mean")
- Flag: any gap >3 consecutive days (`issue_type = "gap"`); any gap >7 days (`issue_type = "extended_gap"`)
- Report the max gap length and start date in the description
- Visualization: calendar-style availability plot per stream

**Check 3 — Flow: zero or negative values**
- Flag stream/site_group/run_years with any flow value <= 0
- Zero flow at a salmon-bearing tributary during RST season is almost certainly a sensor or data issue
- Visualization: time series with flagged dates highlighted

---

## Efficiency Trial QC Report (`efficiency_qc.qmd`)

Works from `SRJPEdata::weekly_efficiency` (raw trial data) and `SRJPEdata::weekly_juvenile_abundance_efficiency_data` (model-ready data).

**Check 1 — Recaptures exceeding releases**
- Flag any trial in `weekly_efficiency` where `number_recaptured > number_released`
- These rows are already filtered out during the model data build in `build_rst_model_datasets.R`, but logging them creates a traceable record and prompts upstream correction
- Group by stream/site/run_year, report the number of affected trials and the max recapture/release ratio
- Visualization: scatter plot of number_released vs number_recaptured with flagged points

**Check 2 — Low release count**
- Flag trials in `weekly_efficiency` where `number_released < 50`
- Small releases produce high-variance efficiency estimates that reduce model reliability
- Group by stream/site/run_year, report the number of low-release trials and the minimum release count
- Visualization: histogram of release counts per site with threshold line

**Check 3 — Zero recaptures**
- Flag trials in `weekly_efficiency` where `number_recaptured == 0`
- Zero recaptures can be real (very low trap efficiency) but may also indicate a data entry issue
- Group by stream/site/run_year, report the number of zero-recapture trials
- Visualization: bar chart of recapture rates per run_year by site, with zero-recapture trials highlighted

**Check 4 — Trial coverage per run_year**
- Use `weekly_juvenile_abundance_efficiency_data`, filter to BTSPAS window (weeks 45–53, 1–22)
- Flag stream/site/run_years with fewer than 3 efficiency trials
- Sparse trial coverage limits the model's ability to estimate efficiency reliably
- Indicate whether flagged run_years are already in `years_to_exclude_rst_data`
- Visualization: tile plot of trial counts by site x run_year, with the minimum threshold marked

**Check 5 — Efficiency rate outliers**
- Compute simple efficiency (`number_recaptured / number_released`) for each trial in `weekly_efficiency`
- Flag stream/site/run_years where any trial has a simple efficiency >3 SD above the site's historical mean (minimum 5 years of history)
- Unusually high efficiency could indicate data entry error or atypical conditions
- Visualization: time series of mean annual simple efficiency per site with flagged years highlighted

---

## Genetics QC Report (`genetics_qc.qmd`)

Stub until `completed_genetic_samples` is fully integrated. Structure in place for the following checks:

**Check 1 — Sample count by stream/year**
- Flag stream/years with fewer samples than expected
- Expected counts to be defined based on monitoring program targets

**Check 2 — Missing key fields**
- Flag stream/years with high NA rates in `fork_length_mm`, `sherlock_run_assignment`, `datetime_collected`

**Check 3 — Run assignment mismatch rate**
- For records with both Sherlock and field assignment, compute mismatch rate by stream/year
- Flag stream/years where mismatch rate is notably higher than historical average

---

## Fix Scripts (`fixes/*.R`)

Fix scripts are sourced from `update_data.R` after all data has been pulled (RST, flow, and environmental data), but before `usethis::use_data()` saves the `.rda` files. This placement ensures fixes have access to all relevant in-memory objects. Note that `update_data.R` is currently under active development and the exact sourcing location will be finalized as that script is refactored.

Fixes are applied as in-memory patches each time the data is rebuilt. Over time, issues should be corrected in the source database and the corresponding patch block removed.

Each fix block follows this structure:

```r
# FIX: <short description of the issue>
# Log ID: <log_id from qc_log.csv>
# Identified: <date>
# Source fix target: <yes/no — whether this should eventually be corrected upstream>
# Remove when: <condition under which this patch is no longer needed>

rst_catch <- rst_catch |>
  filter(...) # or mutate(...)
```

When an issue is corrected in the source database, the patch block is removed and `status` in the log is updated to `fixed_in_source`.

---

## Orchestration (`run_annual_qc.R`)

```
1. Set review_run_year (the run year being QC'd)
2. devtools::load_all()  — ensure latest package data is loaded
3. quarto::quarto_render("rst_qc.qmd")        → reports/rst_qc_YYYY-MM-DD.html
4. quarto::quarto_render("flow_qc.qmd")       → reports/flow_qc_YYYY-MM-DD.html
5. quarto::quarto_render("efficiency_qc.qmd") → reports/efficiency_qc_YYYY-MM-DD.html
6. quarto::quarto_render("genetics_qc.qmd")   → reports/genetics_qc_YYYY-MM-DD.html
7. qc_log_summary()  — print count of open/resolved issues to console
8. message directing reviewer to qc_log.csv
```

Rendered HTML reports go to `data-raw/qc/reports/` and are tracked in git so they can be reviewed without re-running the QC scripts.

---

## Integration with `update_data.R`

Fix scripts are sourced in `update_data.R` after all data has been pulled and processed, before the final `usethis::use_data()` calls:

```r
# Apply documented data patches (see data-raw/qc/fixes/ for log references)
source("data-raw/qc/fixes/rst_fixes.R")
source("data-raw/qc/fixes/flow_fixes.R")
source("data-raw/qc/fixes/efficiency_fixes.R")
source("data-raw/qc/fixes/genetics_fixes.R")
```

Annual QC reminder also in `update_data.R`:

```r
# ANNUAL QC — run once per year after RST season ends (typically July)
# source("data-raw/qc/run_annual_qc.R")
```

---

## Annual Workflow Summary

1. RST season ends (~June/July)
2. Pull new data via `update_data.R`
3. Run `run_annual_qc.R` — generates HTML reports and auto-populates new issues in `qc_log.csv`
4. Reviewer opens the HTML reports and `qc_log.csv`
5. For each `open` issue, reviewer adds `reviewer_notes` and updates `status`:
   - `reviewed_no_issue` — flagged but not actually a problem (explain why in notes)
   - `fixed_in_patch` — add a fix block to the relevant `fixes/*.R` script, note `fix_script` column
   - `fixed_in_source` — upstream database corrected, patch not needed
6. Commit `qc_log.csv`, updated HTML reports, and any `fixes/*.R` changes
7. Re-run `update_data.R` to rebuild data with patches applied
8. On next annual QC run, only new issues not already in the log are added
