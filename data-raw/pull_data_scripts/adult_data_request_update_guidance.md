# Adult Data Request & Update Process

This document summarizes the process for updating the annual adult data compiled in `pull_adult_data.R`. Most adult data are **not** pulled automatically from a database — they require reaching out to stream team contacts to obtain the new year of data, then manually adding that data to the appropriate helper-table CSV.

The script combines data from all streams and saves the result as the `annual_adult` data object.

---

## Overview of Data Sources by Stream

| Stream | Data Type(s) | Source Method | Contact |
|---|---|---|---|
| Battle Creek | Redd counts, upstream passage estimates | Manual CSV update | Natasha Wingerter (natasha_wingerter@fws.gov), Gabby Moreno (gabriella_moreno@fws.gov)|
| Clear Creek | Redd counts, upstream passage estimates | Manual CSV update | Natasha Wingerter (natasha_wingerter@fws.gov), Teresa Urrutia (teresa_urrutia@fws.gov) |
| Butte Creek | Carcass estimates | Manual CSV update | Grant Henley (grantton.henley@wildlife.ca.gov), Anna Allison (anna.allison@wildlife.ca.gov)|
| Deer Creek | Holding counts | Manual CSV update | Ryan Revnak (ryan.revnak@wildlife.ca.gov)|
| Mill Creek | Redd counts, upstream passage estimates | Manual CSV update | Ryan Revnak (ryan.revnak@wildlife.ca.gov)|
| Feather River | Broodstock tagging / estimated in-river spring-run | Manual CSV update | Kassie Heneley (kassie.henley@water.ca.gov), Casey Campos (casey.campos@water.ca.gov) |
| Yuba River | Upstream passage estimates (spring run) | Pulled automatically from EDI | N/A (EDI edi.1707) |

Data outreach should begin in November to remind contacts what data is requested. The sooner the data can be provided the better. The deadline is December 15 of each year. In some cases, the most recent year of data will not be ready and the SR JPE forecast will rely on alternate methods.

---

## Stream-by-Stream Details

### Battle Creek & Clear Creek

**Data types needed:**
- Annual redd count
- Annual upstream passage estimate

**Helper tables to update:**
- `data-raw/helper-tables/battle_clear_redd_historical.csv` — columns: `year`, `stream`, `count`, `data_type`
- `data-raw/helper-tables/battle_clear_passage_estimates_historical.csv` — columns: `year`, `stream`, `count`, `data_type`

**Update process:** When Battle Creek or Clear Creek provides updated values, open the appropriate CSV, add the new row(s), and save. These data are not yet published on EDI; the plan is to migrate to EDI once data are in the desired format.

---

### Butte Creek

**Data types needed:**
- Annual carcass estimate (point estimate; confidence bounds optional though preferred)

**Helper table to update:**
- `data-raw/helper-tables/butte_carcass_historical.csv` — columns: `stream`, `year`, `carcass_estimate`, `lower_bound_estimate`, `upper_bound_estimate`, `confidence_level`

**Update process:** When Butte Creek provides updated values, open the appropriate CSV, add the new row(s), and save. These data are not yet published on EDI; the plan is to migrate to EDI once data are in the desired format.

---

### Deer Creek

**Data types needed:**
- Annual holding count (peak count of spring-run Chinook salmon holding in the stream)

**Helper table to update:**
- `data-raw/helper-tables/mill_deer_adult_historical.csv` — columns: `year`, `count`, `data_type`, `stream`
  - `data_type` value for Deer Creek: `holding`

**Update process:** Data are published on EDI ([edi.1672](https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1672.1)), but as of May 2025, discrepancies were found in the EDI data. Until those are resolved, data are pulled from a spreadsheet provided by **Ryan Revnak**. Request the updated spreadsheet from Ryan and add new rows to the CSV.

---

### Mill Creek

**Data types needed:**
- Annual redd count
- Annual upstream passage estimate

**Helper table to update:**
- `data-raw/helper-tables/mill_deer_adult_historical.csv` — columns: `year`, `count`, `data_type`, `stream`
  - `data_type` values for Mill Creek: `redd`, `upstream_estimate`

**Update process:** Same EDI discrepancy issue as Deer Creek (see above). Request the updated spreadsheet from **Ryan** and add new rows to the CSV. Note: Mill Creek redd counts go through an interpolation step using `data-raw/analysis/mill_redd_fill_table.csv` to account for incomplete survey effort in historical years; years 2021 onward are assumed to be complete surveys (multiplier = 1). See `data-raw/analysis/mill-redd-analysis.Rmd` for methodology.

---

### Feather River

**Data types needed:**
- Annual broodstock tagging data from Feather River Hatchery, specifically:
  - Number of spring-run hallprint-tagged for broodstock
  - Number returning to the hatchery in the fall
  - Number released from the hatchery
  - FMS spring-run count (if available)
  - Over-summer mortality count
  - Estimated in-river spring-run (derived: tagged minus returned to hatchery minus over-summer mortality)

**Helper table to update:**
- `data-raw/helper-tables/feather_adult_data_for_stock_recruit_dec_2025.csv` — columns: `Year`, `Hallprint Tagged`, `Hallprint Returned to FRFH`, `Hallprint Released from FRFH`, `FMS spring-run Count`, `Over Summer Morts`, `Estimated in-river spring-run`

**Update process:** Contact **Casey Campos** to request the updated broodstock tagging table. Casey typically provides an updated CSV that can replace or be appended to the existing helper table. Note: this metric is an underestimate of the total in-river population because not all spring-run pass through the hatchery, but it is the best available consistent index. The estimated in-river spring-run value is what gets used in the model.

---

### Yuba River

**Data types needed:** None — data are pulled automatically from EDI.

**Update process:** Yuba River upstream passage data are published on EDI ([edi.1707](https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1707.1)). The script queries the newest revision automatically using the `EDIutils` package and downloads `yuba_daily_corrected_passage.csv`. Spring run (including early spring and late spring) is summed by biological year to produce the annual passage estimate. No manual steps are required unless the EDI package structure changes.

---


