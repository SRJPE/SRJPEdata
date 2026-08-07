# Renders stream_team_review.Rmd once per stream, each with its
# own params (stream name, flow_gage, temp_gage, adult_used_in_SR).
# For each stream, creates a folder containing the rendered .html report
# and a data/ subfolder with the filtered tables saved as csvs.
library(rmarkdown)
library(purrr)
library(tibble)
library(dplyr)
library(readr)
library(SRJPEdata)

# TODO: DOUBLE CHECK THESE - ESPECIALLY Adult used in SR
# Sacramento River has no stream-wide gage config - it is reviewed one site at a
# time (see sac_site_config below), so it is intentionally absent from this table.
stream_config <- tribble(
  ~selected_stream,          ~flow_gage,                                                    ~temp_gage,                                       ~adult_used_in_SR,
  "battle creek",   "USGS-11376550",                                               "USFWS - UBC",                                    "redd OR upstream passage",
  "butte creek",    "USGS-11390000",                                               "USGS-11390000",                                  "carcass",
  "clear creek",    "USGS-11372000",                                               "USFWS - UCC",                                    "redd OR upstream passage",
  "deer creek",     "USGS-11383500",                                               "CDEC - DCV",                                     "holding",
  "feather river",  "USGS-11406930 (ORF) + USGS-11407000 (TFB) + USGS-11406920 (TAO) for HFC; ORF+TFB for LFC", "CDEC-GRL (HFC, interpolated) / CDEC-FRA (LFC, interpolated)", "broodstock_tag",
  "mill creek",     "USGS-11381500",                                               "CDEC - MLM",                                     "redd",
  "yuba river",     "USGS-11421000",                                               "CDEC - YR7 (interpolated)",                      "passage"
)

# TODO just filter years to exclude adult to datatype we are using. 
# TODO similarly, specify RST site we are using (ex. UBC) and filter exclude table to only show UBC.For plots throughout, only show sites we are using.  
# FEATHER - REMOVE LIVE OAK AND SUNSET PUMPS 
# BATTLE 
# BUTTE - DONT USE ADAMS DAM 
# TODO get rid of line for 100 % efficency 
# TODO remove points from flow plot and just have colored lines 
# TODO filter flow and temperature data objectcs to 1990 
# TODO check on temperature data plot to see what is happening in january 1st disconnect
# TODO color efficiency plot by site
# TODO remove lower feather river flows
# TODO in catch plots use dashed line or gray to show which ones are excluded 
# TODO add note if interpolated temps

# Sacramento River is reviewed per-site rather than per-stream: RST, catch, and
# efficiency data are only collected at these sites, and there is no stream-wide
# adult data to report, so the adult data section is omitted for these reports.
sac_site_config <- tribble(
  ~selected_site,      ~flow_gage,       ~temp_gage,
  "tisdale",           "USGS-11390500",  "USGS-11390500",
  "knights landing",   "USGS-11390500",  "USGS-11390500 (gap-filled with RST-reported temperature)"
)

# TABLES TO INCLUDE ------------------------------------------------------------
# Returns a named list of tables, each filtered down to `selected_stream`
# (and to `selected_site` when reviewing a single Sacramento River site).
# Each entry is written out as its own csv alongside the rendered report.
build_stream_tables <- function(selected_stream, selected_site = NA) {
  if (is.na(selected_site)) {
    list(
      adult_data = annual_adult |>
        filter(stream == selected_stream),

      excluded_rst_years = rst_model_years |>
        filter(stream == selected_stream, exclude),

      excluded_adult_years = adult_model_years |>
        filter(stream == selected_stream, exclude),

      weekly_catch = weekly_juvenile_abundance_catch_data |>
        filter(stream == selected_stream) |>
        select(-average_hours_fished_during_efficiency_trials,
               -standardized_flow),

      weekly_eff = weekly_juvenile_abundance_efficiency_data |>
        filter(stream == selected_stream) |>
        select(-average_hours_fished_during_efficiency_trials,
               -standardized_efficiency_flow,
               -flow_cfs,
               -hours_fished),

      flow_data = flow_data |>
        filter(stream == selected_stream),

      temperature_data = temperature_data |>
        filter(stream == selected_stream)
    )
  } else {
    list(
      excluded_rst_years = rst_model_years |>
        filter(stream == selected_stream, site == selected_site, exclude),

      weekly_catch = weekly_juvenile_abundance_catch_data |>
        filter(stream == selected_stream, site == selected_site) |>
        select(-average_hours_fished_during_efficiency_trials,
               -standardized_flow),

      weekly_eff = weekly_juvenile_abundance_efficiency_data |>
        filter(stream == selected_stream, site == selected_site) |>
        select(-average_hours_fished_during_efficiency_trials,
               -standardized_efficiency_flow,
               -flow_cfs,
               -hours_fished),

      flow_data = flow_data |>
        filter(stream == selected_stream, site_group == selected_site),

      temperature_data = temperature_data |>
        filter(stream == selected_stream, site_group == selected_site)
    )
  }
}

output_dir <- "data-raw/data-checks/stream_team_review/stream_team_reports"
dir.create(output_dir, showWarnings = FALSE)

render_review <- function(selected_stream, selected_site, flow_gage, temp_gage, adult_used_in_SR) {
  stream_slug <- gsub(" ", "_", selected_stream)
  slug <- if (is.na(selected_site)) stream_slug else paste0(stream_slug, "_", gsub(" ", "_", selected_site))
  stream_dir <- file.path(output_dir, slug)
  data_dir <- file.path(stream_dir, "data")
  dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

  render(
    input = "data-raw/data-checks/stream_team_review/stream_team_review.Rmd",
    output_file = paste0(slug, "_review.html"),
    output_dir = stream_dir,
    params = list(
      selected_stream = selected_stream,
      selected_site = selected_site,
      flow_gage = flow_gage,
      temp_gage = temp_gage,
      adult_used_in_SR = adult_used_in_SR
    ),
    envir = new.env()
  )

  stream_tables <- build_stream_tables(selected_stream, selected_site)
  iwalk(stream_tables, function(tbl, tbl_name) {
    write_csv(tbl, file.path(data_dir, paste0(tbl_name, ".csv")))
  })
}

pwalk(stream_config, function(selected_stream, flow_gage, temp_gage, adult_used_in_SR) {
  render_review(selected_stream, NA, flow_gage, temp_gage, adult_used_in_SR)
})

# Sacramento River: render one report per site instead of one for the whole stream.
pwalk(sac_site_config, function(selected_site, flow_gage, temp_gage) {
  render_review("sacramento river", selected_site, flow_gage, temp_gage, NA)
})
