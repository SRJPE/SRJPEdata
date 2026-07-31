# Renders stream_team_review.Rmd once per stream, each with its
# own params (stream name, flow_gage, temp_gage, adult_used_in_SR). 
library(rmarkdown)
library(purrr)
library(tibble)

# TODO: DOUBLE CHECK THESE - ESPECIALLY Adult used in SR 
stream_config <- tribble(
  ~selected_stream,          ~flow_gage,                                                    ~temp_gage,                                       ~adult_used_in_SR,
  "battle creek",   "USGS-11376550",                                               "USFWS - UBC",                                    "redd",
  "butte creek",    "USGS-11390000",                                               "USGS-11390000",                                  "carcass",
  "clear creek",    "USGS-11372000",                                               "USFWS - UCC",                                    "redd",
  "deer creek",     "USGS-11383500",                                               "CDEC - DCV",                                     "holding",
  "feather river",  "USGS-11406930 (ORF) + USGS-11407000 (TFB) + USGS-11406920 (TAO) for HFC; ORF+TFB for LFC; CDEC-FSB for lower Feather", "CDEC-GRL (HFC, interpolated) / CDEC-FRA (LFC, interpolated)", "broodstock_tag",
  "mill creek",     "USGS-11381500",                                               "CDEC - MLM",                                     "redd",
  "yuba river",     "USGS-11421000",                                               "CDEC - YR7 (interpolated)",                      "passage"
  # SAC: flow gages are USGS-11390500 (Sac @ Wilkins Slough, used for both "tisdale" and "knights landing" site groups) 
  # and USGS-11377100 (Red Bluff Diversion Dam, RBDD). Temp gage is USGS-11390500 (same, used for tisdale/knights landing),
  # with knights landing temp gap-filled using RST-reported temperature. 
)

output_dir <- "data-raw/data-checks/stream_team_review/stream_team_reports"
dir.create(output_dir, showWarnings = FALSE)

pwalk(stream_config, function(stream, flow_gage, temp_gage, adult_used_in_SR) {
  render(
    input = "data-raw/data-checks/stream_team_review/stream_team_review.Rmd",
    output_file = paste0(gsub(" ", "_", stream), "_review.html"),
    output_dir = output_dir,
    params = list(
      selected_stream = selected_stream,
      flow_gage = flow_gage,
      temp_gage = temp_gage, 
      adult_used_in_SR
    ),
    envir = new.env()
  )
})
