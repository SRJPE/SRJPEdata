# TODO descide if we also want to export weekly summaries...probably not necessary, leaving in for now so I don't break something 
#' @title Passage to Spawner Model Covariates Standard
#' @name p2s_model_covariates_standard
#' @description The passage to spawner model covariates standard table contains environmental
#' covariates for use in the Passage to Spawner (P2S) model. The environmental variables are 
#' standardized within a column to center around 0. Selection and preparation of the 
#' covariates are detailed in \code{vignette("prep_environmental_covariates.Rmd", package = "SRJPEdata")}.
#' @format A tibble with 192 rows and 7 columns 
#' \itemize{
#'   \item \code{year}: year 
#'   \item \code{stream}: stream associated with covariate data
#'   \item \code{wy_type}: water year type, binary variable describing wet(1) or dry(0)
#'   \item \code{max_flow_std}: standardized maximum flow data for adult migration period (March - August) 
#'   \item \code{gdd_std}: standardized cumulative degree days above 20 degrees Celsius 
#'   for adult migration (Sacramento March - May) and holding (Tributaries May - August)
#'   \item \code{passage_index}: standardized total adult returns (not currently utilized by model)
#'   \item \code{median_passage_timing_std}: standardized median return week (not currently utilized by model)
#'   }
'p2s_model_covariates_standard'


#' @title Weekly BT-SPAS-X Model Data
#' @name weekly_juvenile_abundance_model_data
#' @description Weekly Rotary Screw Trap (RST) catch summaries, weekly RST effort effort, and weekly standardized flow, 
#' for spring run tributaries modeled in BT-SPAS-X. TODO - consider removing count, effort, and flow_cfs since we have somewhat duplicative columns 
#' @format A tibble with 9,457 rows and 17 columns 
#' \itemize{
#'   \item \code{year}: year 
#'   \week \code{week} : week 
#'   \item \code{stream}: rst stream 
#'   \item \code{site}: rst site 
#'   \item \code{count}: weekly count of number of 
#'   \item \code{mean_fork_length}:
#'   \item \code{number_released}: 
#'   \item \code{number_recaptured}: 
#'   \item \code{effort}: 
#'   \item \code{flow_cfs}: 
#'   \item \code{life_stage}: 
#'   \item \code{average_stream_effort}: 
#'   \item \code{standardized_flow}: 
#'   \item \code{run_year}: 
#'   \item \code{catch_standardized_by_effort}: 
#'   \item \code{standardized_efficiency}: 
#'   \item \code{lgN_prior}: 
#'   }
'weekly_juvenile_abundance_model_data'

#' @title Special Priors for BT-SPAS-X Abundance Model 
#' @name btspasx_special_priors_data
#' @description A dataframe containing special priors to fine tune model 
#' @format A dataframe with 71 rows and 4 columns 
#' \itemize{
#'   \item \code{site}: site
#'   \item \code{run_year}: run year
#'   \item \code{week}: week 
#'   \item \code{special_prior}: log normalized special prior abundance cap
#'   }
'btspasx_special_priors_data'

#' @title RST Catch Data 
#' @name rst_catch
#' @description Dataset containing rst catch monitoring data for all SR JPE tribuatary and mainstem monitoring programs 
#' @format A dataframe with 511,961 rows and 14 columns 
#' \itemize{
#'   \item \code{date}: date 
#'   \item \code{stream}: Stream RST is located on  
#'   \item \code{site}: Site RST is located on   
#'   \item \code{subsite}: Specific trap site   
#'   \item \code{site_group}: Site group    
#'   \item \code{count}: Number of fish caught  
#'   \item \code{run}: Run of catch  
#'   \item \code{life_stage}: Life Stage of catch  
#'   \item \code{adipose_clipped}: Boolean value describing if adipose is clipped on catch  
#'   \item \code{dead}: Mortality status of catch  
#'   \item \code{fork_length}: Fork length measure of catch in mm  
#'   \item \code{weight}: Weight of catch in grams  
#'   \item \code{actual_count}: Boolean Value describing if count is actual value or interpolated  
#'   \item \code{species}: Species of catch  
#'   }
'rst_catch'

#' @title RST Trap Data 
#' @name rst_trap
#' @description Dataset containing rst trap operations monitoring data for all SR JPE tribuatary and mainstem monitoring programs
#' @format 
#' \itemize{
#'   \item \code{year}: year 
#'   }
'rst_trap'

#' @title RST Efficiency Summary Data
#' @name efficiency_summary
#' @description Dataset containing summarized efficiency monitoring data for all SR JPE tribuatary and mainstem monitoring programs
#' @format 
#' \itemize{
#'   \item \code{year}: year 
#'   }
'efficiency_summary'

#' @title RST Efficiency Trial Individual Fish Release Data
#' @name release_fish
#' @description Dataset containing individual fish releases for efficiency monitoring data for all SR JPE tribuatary and mainstem monitoring programs
#' @format Dataframe with __TODO EMPTY IN DATABASE CURRENTLY__ and 6 columns
#' \itemize{
#'   \item \code{release_id}: year 
#'   \item \code{stream}: stream where efficiency trial conducted
#'   \item \code{site}: site where efficiency trial conducted 
#'   \item \code{subsite}: subsite where efficiency trial conducted
#'   \item \code{site_group}: site group where efficiency trial conducted
#'   \item \code{fork_length}: fork length of released fish 
#'   }
'release_fish'

#' @title RST efficiency trial recaptures
#' @name recaptures
#' @description Dataset containing recapture for efficiency monitoring  
#' @format 
#' \itemize{
#'   \item \code{year}: year 
#'   }
'recaptures'

#' @title Adult Upstream passage monitoring estimates 
#' @name upstream_passage_estimates
#' @description Adult upstream passage estimates, Generalized Additive Model (GAM) 
#' used to generate passage estimates from raw passage data - TODO add source to show
#'  this / explain different status for different sites
#' @format 
#' \itemize{
#'   \item \code{year}: year data were collected
#'   \item \code{stream}: stream data were collected on 
#'   \item \code{passage_estimate}: yearly aggregated interpolated upstream passage estimate
#'   \item \code{run}: run of fish (if assigned)
#'   \item \code{adipose_clipped}: whether or not the adipose fin was clipped
#'   }
'upstream_passage_estimates'

#' @title Adult Upstream passage monitoring raw counts
#' @name standard_upstream
#' @description Raw adult upstream passage counts
#' @format 
#' \itemize{
#'   \item \code{year}: year data were collected
#'   \item \code{date}: date fish passage was observed
#'   \item \code{time}: time fish passage was observed
#'   \item \code{count}: count of fish observed passing the video system
#'   \item \code{run}: run of fish observed
#'   \item \code{adipose_clipped}: whether or not adipose fin was clipped
#'   \item \code{sex}: sex of fish
#'   \item \code{passage_direction}: direction of fish pasage (up or down)
#'   \item \code{viewing_condition}: viewing condition
#'   \item \code{spawning_condition}: description of spawning status based on coloration
#'   \item \code{jack_size}: Whether or not the fish is jack sized
#'   \item \code{ladder}: the ladder the fish was observed at
#'   \item \code{flow}: flow in cfs at the weir
#'   \item \code{temperature}: temperature in C at the weir
#'   \item \code{hours}: hours the camera was in operation #TODO confirm
#'   \item \code{comments}: comments
#'   }
'standard_upstream'


#' @title Carcass Survey CJS Estimates
#' @name carcass_estimates
#' @description Carcass Estimates produced by analyzing mark-recapture carcass surveys
#' with a Cormack-Jolly-Seber (CJS) model. Performed on the Yuba River, Feather River, and 
#' Butte Creek. Butte Creek uses the `escapeMR` package applied to raw count data.
#' TODO add source to show / explain specific sites we have this for 
#' @format 
#' \itemize{
#'   \item \code{year}: year data were collected
#'   \item \code{spawner_abundance_estimate}: estimated annual spawner abundance
#'   \item \code{stream}: stream data were collected on
#'   \item \code{lower}: lower confidence interval of abundance estimate
#'   \item \code{upper}: upper confidence interval of abundance estimate
#'   \item \code{confidence_interval}: confidence interval associated with lower and upper values
#'   }
'carcass_estimates'

#' @title Redd Survey Data 
#' @name redd
#' @description Raw redd survey monitoring data 
#' TODO link to vignette on age_index when available 
#' @format 
#' \itemize{
#'   \item \code{date}: year data were collected
#'   \item \code{latitude}: latitude of redd location
#'   \item \code{longitude}: longitude of redd location
#'   \item \code{reach}: survey reach where data were collected
#'   \item \code{river_mile}: river mile of redd location
#'   \item \code{redd_id}: unique identifier of redd
#'   \item \code{fish_guarding}: whether or not fish were observed guarding the redd
#'   \item \code{redd_measured}: whether or not the redd was measured
#'   \item \code{redd_width}: widdth of redd (m)
#'   \item \code{redd_length}: length of redd (m)
#'   \item \code{velocity}: measured stream velocity (ft/s)
#'   \item \code{age}: age of redd
#'   \item \code{age_index}: number of times a unique redd was aged If 0, the redd was surveyed but not aged.
#'   \item \code{redd_count}: number of redds surveyed
#'   \item \code{stream}: stream data were collected on
#'   \item \code{year}: year data were collected
#'   \item \code{survey_method}: surveying method
#'   \item \code{run}: run of fish associated with redd
#'   \item \code{species}: species of fish associated with redd
#'   \item \code{depth_m}: depth of water (m)
#'   \item \code{starting_elevation_ft}: starting elevation (ft)
#'   \item \code{num_of_fish_on_redd}: number of fish observed on redd
#'   \item \code{redd_substrate_class}: size class of substrate determined by millimeter size
#'   \item \code{tail_substrate_class}: size class of tail substrate determined by millimeter size
#'   \item \code{pre_redd_substrate_class}: size class of substrate pre-redd determined by millimeter size
#'   }
'redd'

#' @title Holding Survey Data 
#' @name holding
#' @description Raw holding survey monitoring data 
#' @format 
#' \itemize{
#'   \item \code{date}: date data were collected
#'   \item \code{reach}: survey reach where data were collected
#'   \item \code{river_mile}: river mile where holding fish were observed
#'   \item \code{count}: count of fish observed
#'   \item \code{jacks}: number of jacks observed
#'   \item \code{latitude}: latitude where fish were observed
#'   \item \code{longitude}: latitude where fish were observed
#'   \item \code{stream}: stream where data were collected
#'   \item \code{year}: year data were collected
#'   \item \code{survey_intent}: purpose of the survey conducted
#'   \item \code{picket_weir_location_rm}: location of the picket weir in river miles
#'   \item \code{picket_weir_relate}: where the fish were observed relative to the picket weir
#'   }
'holding'

#' @title Combined Adult Survey and Passage Counts
#' @name observed_adult_input
#' @description Contains all adult holding and redd survey counts, CJS estimates,
#' and interpolated upstream passage estimates aggregated by year. Includes all 
#' available years for all streams for each data type. This can be used as input for 
#' the Passage to Spawner model.
#' @format 
#' \itemize{
#'   \item \code{year}: year data were collected
#'   \item \code{stream}: stream data were collected on
#'   \item \code{data_type}: type of adult data (either `upstream_estimate`, 
#'   `redd_count`, `holding_count`, or `carcass_estimate`)
#'   \item \code{count}: aggregated yearly count of fish
#'   }
'observed_adult_input'

#' @title Years to Include in Modeling 
#' @name chosen_site_years_to_model
#' @description Datasets containing the chosen sites and years of monitoring data to include in model. 
#' See \code{vignette("years_to_include_analysis", package = "SRJPEdata")} for more details
#' @format Dataframe with 186 rows and 8 columns 
#' \itemize{
#'   \item \code{monitoring_year} : year 
#'   \item \code{stream}: Stream RST is located on  
#'   \item \code{site}: Site RST is located on   
#'   \item \code{site_group}: Site group    
#'   \item \code{min_date} : Minimum date of sampling season to include 
#'   \item \code{min_week} : Minimum week of sampling season to include 
#'   \item \code{max_date} : Maximum date of sampling season to include  
#'   \item \code{max_week} : Maximum week of sampling season to include  
#'   }
'chosen_site_years_to_model'

#' @title Daily Yearling Rulesets 
#' @name daily_yearling_ruleset
#' @description Datasets containing the daily yearling rulesets. 
#' See \code{vignette("yearling_ruleset", package = "SRJPEdata")} for more details.
#' @format Dataframe...
#' \itemize{
#'   \item \code{monitoring_year} : year 
#'   }
'daily_yearling_ruleset'

# TODO - get env data figured out 
# #' @title Environmental Gage Data
# #' @name environmental_data
# #' @description Environmental gage data for each tributary in the SR JPE. 
# #' TODO add gage is in list format to make explicit or link to source vignette 
# #' @format 
# #' \itemize{
# #'   \item \code{col 1}:col 1  
# #'   }
# environmental_data'