# Pull Data Scripts

This folder contains scripts for pulling RST (rotary screw trap) data (as well as adult data and environmental covariates) from multiple sources into a standardized format.

## Background

Data are loaded into `jpe-db` (Azure PostgreSQL) and updated regularly. Because existing records are identified and replaced by unique IDs, **data without unique identifiers cannot be loaded into jpe-db**. For those datasets, data are pulled from EDI (Environmental Data Initiative) or from legacy standard-format files instead.

---

## Scripts

### `pull_misfit_rst_data.R`

Pulls RST data that **cannot be loaded into jpe-db** due to missing unique identifiers. Sources include EDI and legacy standard-format files. Uses the `EDIutils` package.

| Stream | Data Types | Source | Years | Notes |
|---|---|---|---|---|
| Battle Creek | Recapture | EDI (edi.1509) | All | No unique ID; catch/trap/release pulled from jpe-db |
| Clear Creek | Recapture | EDI (edi.1509) | All | No unique ID; catch/trap/release pulled from jpe-db |
| Butte Creek | Catch, Trap | EDI (edi, version 28) | Pre-2015 | No unique IDs pre-2015; no mark-recapture data exist for this period |
| Deer Creek | Catch, Trap, Release, Recapture | EDI (edi.1504, version 3) | Historical | Historical data lack unique IDs; current data pulled from DataTackle |
| Mill Creek | Catch, Trap, Release, Recapture | EDI (edi.1504, version 3) | Historical | Historical data lack unique IDs; current data pulled from DataTackle |
| Knights Landing | Catch, Trap, Release, Recapture | Legacy standard-format files (Google Cloud Bucket) | Pre-2004 | Not yet on EDI; data provided by CDFW and cleaned in JPE-datasets |
| Yuba River | Catch, Trap | EDI (edi.1529, version 13) | Pre-2022 | No unique IDs pre-2022; no mark-recapture data exist for this period |

---

## Data Source Summary by Stream

| Stream | Catch & Trap | Release & Recapture |
|---|---|---|
| Battle Creek | jpe-db | Release: jpe-db / Recapture: EDI |
| Clear Creek | jpe-db | Release: jpe-db / Recapture: EDI |
| Butte Creek | jpe-db (2015+), EDI (pre-2015) | jpe-db (2015+), none pre-2015 |
| Deer Creek | DataTackle (current), EDI (historical) | DataTackle (current), none (historical) |
| Mill Creek | DataTackle (current), EDI (historical) | DataTackle (current), none (historical) |
| Knights Landing | jpe-db (2004+), legacy files (pre-2004) | jpe-db (2004+), legacy files (pre-2004) |
| Yuba River | jpe-db (2022+), EDI (pre-2022) | jpe-db (2022+), none pre-2022 |
