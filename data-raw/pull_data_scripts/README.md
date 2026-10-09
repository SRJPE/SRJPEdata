# Pull Data Scripts

This folder contains scripts for pulling RST (rotary screw trap) data (as well as adult data and environmental covariates) from multiple sources into a standardized format.

## Background

Data are loaded into `jpe-db` (Azure PostgreSQL) and updated regularly. Because existing records are identified and replaced by unique IDs, **data without unique identifiers cannot be loaded into jpe-db**. For those datasets, data are pulled from EDI (Environmental Data Initiative) or from legacy standard-format files instead.

---

## Action Items - Misfit Data Sources to Revisit

Revisit data pulled in `pull_misfit_rst_data.R` - as we update temporary hardcoded scripts to pull from EDI or the SRJPE database, we can remove the temporary code in this script that pulls and processes misfit data. 

- [ ] **Butte Creek pre-2015 catch/trap is pulled from static file** These data do not have unique IDs and are not stored in the database. *This misfit data is not expected to change.*
- [ ] **Yuba pre-2022 (edi.1529) is pinned to version 13** Newer versions are published in zip format that the current `pull_edi()` helper can't parse. Investigate adding zip-file support so Yuba can move off the pinned version and pick up any upstream corrections. *Low priority*
- [ ] **Deer/Mill historical data (edi.1504) is pinned to version 3** ("Version is static" per the script comment) rather than pulling the latest. Confirm whether a newer version has been published and, if so, whether it's safe to unpin.
- [ ] **Battle/Clear recapture has a hard-coded data fix** (a recapture count of 1180 on 2018-02-15 is overridden to 11) because the source error on EDI hasn't been corrected upstream - flagged to USFWS contact Natasha as of 7/24/2025 and still unresolved as of the last check. Follow up and remove the override once EDI is corrected.
- [ ] **Battle/Clear 2026 efficiency** 2026 efficiency data is not yet on EDI so we currently pull from 2 xlsx sheets. Check EDI and update script once 2026 data is on EDI. 
- [ ] **Deer/Mill recapture has a hard-coded fix** for recapture dates mistakenly entered with year 2032 instead of 2023. Follow up and remove the override once corrected at the source.
- [ ] **Knights Landing pre-2004 data pulled from standard format csv** (`data-raw/helper-tables/google_bucket/knl_*_standard.csv`) pulled from the standard-format files in JPE-datasets/Google Cloud Bucket, on the assumption that this historical data "will not change." Confirm that's still true, and check whether CDFW has since published it to EDI, last checked August 2026. Starting in 2026 CDFW no longer operates this trap and Fish Bio has taken over. *This misfit data is not expected to change.*

---

## Scripts

### `pull_misfit_rst_data.R`

Pulls RST data that **cannot be loaded into jpe-db** due to missing unique identifiers. Sources include EDI and legacy standard-format files. Uses the `EDIutils` package.

| Stream | Data Types | Source | Years | Notes |
|---|---|---|---|---|
| Battle Creek | Recapture | EDI (edi.1509) | All | No unique ID; catch/trap/release pulled from jpe-db |
| Battle Creek | Recapture | XLSX sheet from Natasha | 2026 | Data not yet uploaded to EDI for 2026 season |
| Clear Creek | Recapture | EDI (edi.1509) | All | No unique ID; catch/trap/release pulled from jpe-db |
| Clear Creek | Recapture | XLSX sheet from Natasha | 2026 | Data not yet uploaded to EDI for 2026 season |
| Butte Creek | Catch, Trap | EDI (edi, version 28) | Pre-2015 | No unique IDs pre-2015; no mark-recapture data exist for this period |
| Deer Creek | Catch, Trap, Release, Recapture | EDI (edi.1504, version 3) | Historical | Historical data lack unique IDs; current data pulled from DataTackle |
| Mill Creek | Catch, Trap, Release, Recapture | EDI (edi.1504, version 3) | Historical | Historical data lack unique IDs; current data pulled from DataTackle |
| Knights Landing | Catch, Trap, Release, Recapture | Legacy standard-format files (Google Cloud Bucket) | Pre-2004 | Not yet on EDI; data provided by CDFW and cleaned in JPE-datasets |
| Yuba River | Catch, Trap | EDI (edi.1529, version 13) | Pre-2022 | No unique IDs pre-2022; no mark-recapture data exist for this period |

---

## Data Source Summary by Stream

| Stream | Catch & Trap | Release & Recapture |
|---|---|---|
| Battle Creek | jpe-db | Release: jpe-db & XLSX / Recapture: EDI & XLSX |
| Clear Creek | jpe-db | Release: jpe-db & XLSX / Recapture: EDI & XLSX |
| Butte Creek | jpe-db (2015+), EDI (pre-2015) | jpe-db (2015+), none pre-2015 |
| Deer Creek | DataTackle (current), EDI (historical) | DataTackle (current), none (historical) |
| Mill Creek | DataTackle (current), EDI (historical) | DataTackle (current), none (historical) |
| Knights Landing | jpe-db (2004+), legacy files (pre-2004) | jpe-db (2004+), legacy files (pre-2004) |
| Yuba River | jpe-db (2022+), EDI (pre-2022) | jpe-db (2022+), none pre-2022 |
