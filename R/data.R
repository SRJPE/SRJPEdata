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
#'   \item \code{mean_fork_length}: Mean fork length of released efficiency trial fish 
#'   \item \code{number_released}: Number of efficiency trial fish released
#'   \item \code{number_recaptured}: Number of efficiency trial fish recaptured
#'   \item \code{hours_fished}: Hours fished on a stream 
#'   \item \code{flow_cfs}: Weekly mean gage flow in cubic feet per second (cfs)
#'   \item \code{life_stage}: Life stage of juvenile fish 
#'   \item \code{average_stream_effort}: Average hours fished on a given stream, used to standardize 
#'   \item \code{standardized_flow}: Flow standardized across years and sites 
#'   \item \code{run_year}: Run year 
#'   \item \code{catch_standardized_by_hours_fished}: Catch standardized by hours fished in a given week 
#'   \item \code{standardized_efficiency}: Efficiency standardized across years 
#'   \item \code{lgN_prior}: log normalized special prior abundance cap, for more info search `?SRJPEdata::btspasx_special_priors_data`
#'   }
#' @source Prepared using rotary screw trap catch data (see `?SRJPEdata::rst_catch` for more information on raw data sources), 
#'   environmental_data (see `?SRJPEdata::environmental_data`), hours fished information 
#'   (see `?SRJPEdata::weekly_hours_fished for more information`), and btspasx special priors (see `?SRJPEdata::btspasx_special_priors_data` for more information).
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
#' @source Special priors were developed by the lead SR JPE modeler, Josh Korman.
'btspasx_special_priors_data'

#' @title RST Catch Data 
#' @name rst_catch
#' @description Dataset containing rst catch monitoring data for all SR JPE tribuatary and mainstem monitoring programs. 
#' @format A dataframe with 511,961 rows and 14 columns 
#' \itemize{
#'   \item \code{date}: date 
#'   \item \code{stream}: Stream RST is located on  
#'   \item \code{site}: Site RST is located on   
#'   \item \code{subsite}: Specific trap site   
#'   \item \code{site_group}: Site group, used to separate traps within the same stream that have unique environmental conditions.
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
#' @source Raw datasets and original documentation of data processing and QC process can be found for each stream using the links below.
#'  \itemize{
#'   \item \strong{Battle Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1509.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/battle-creek/battle_creek_rst_catch_qc.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Butte Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1497.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/butte-creek/butte-creek-rst-qc-checklist.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Clear Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1509.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/clear-creek/clear_creek_rst_catch.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Deer Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1504.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/deer-creek/deer_creek_rst_data_qc.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Feather River}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1239.5}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/feather-river/feather-rst.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Mill Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1504.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/mill-creek/mill_creek_rst_qc.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Sacramento River}:
#'      \itemize{
#'          \item{Knights Landing}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1501.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/tree/main/data-raw/qc-markdowns/rst/lower-sac/knights_landing}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'          \item{Tisdale}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1499.2}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/tree/main/data-raw/qc-markdowns/rst/lower-sac/tisdale}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'          \item{Delta Entry}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1503.1}{Data on EDI}.
#'          }
#'   \item \strong{Yuba River}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1529.2}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/yuba-river/yuba-river-rst-qc-checklist.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   }
'rst_catch'

#' @title RST Trap Data 
#' @name rst_trap
#' @description Dataset containing rst trap operations monitoring data for all SR JPE tribuatary and mainstem monitoring programs
#' @format 
#' \itemize{
#'   \item \code{trap_start_date}: Date that trap was visited. This field is included because in some cases a visit will not have a start/stop time (e.g. if trap was cleaned/serviced or just checked)                
#'   \item \code{visit_type}:
#'   \item \code{trap_stop_date}: Date that trap was started prior to being sampled. trap_start_date and trap_stop_date are meant to describe the sampling period.
#'   \item \code{trap_start_time}: Time that trap was visited.
#'   \item \code{trap_stop_time}:  Time that trap was sampled.
#'   \item \code{stream}: Which stream the RST is located on                 
#'   \item \code{site}: Site name  
#'   \item \code{subsite}: Name of trap       
#'   \item \code{site_group}: Site group, used to seperate traps within the same stream that have unique environmental conditions.
#'   \item \code{trap_functioning}: Describes how well trap is functioning. Categories: trap functioning normally, trap stopped functioning, trap not in service, trap functioning but not normally. If trap_functioning not used, "not recorded" is entered. 
#'   \item \code{in_half_cone_configuration}: Boolean to describe if trap fished in half cone configuration. If not recorded, then assumed to be FALSE.
#'   \item \code{fish_processed}: Describes if fish were processed. Categories: processed fish; no fish caught; no catch data, fish released; no catch data, fish left in live box. If fish_processed not used, "not recorded" is entered.
#'   \item \code{rpm_start}: Revolutions per minute at the start of the trap visit before trap is cleaned. If not recorded, then NA.
#'   \item \code{rpm_end}:  Revolutions per minute at the end of the trap visit after trap is cleaned. If not recorded, then NA.
#'   \item \code{total_revolutions}: Total revolutions during sample period. If not recorded, then NA. 
#'   \item \code{debris_volume}: Volume of debris emptied from trap (gallons). If not recorded, then NA. 
#'   \item \code{discharge}: Flow at trap in cfs
#'   \item \code{water_velocity}: Velocity at trap in feet per second 
#'   \item \code{water_temp}: Temperature at trap in degrees C
#'   \item \code{include}: Boolean to describe if sample should be included in data for analysis. If false then data or visit is determined to be of poor quality by data steward and should not be included in analysis. If not recorded, then assumed to be TRUE.
#'   \item \code{turbidity}: Turbidity at trap in NTUs
#'   }
#' @source Raw datasets and original documentation of data processing and QC process can be found for each stream using the links below. 
#'  \itemize{
#'   \item \strong{Battle Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1509.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/battle-creek/battle_creek_rst_environmental_qc.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Butte Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1497.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/butte-creek/butte-creek-rst-qc-checklist.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Clear Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1509.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/clear-creek/clear_creek_rst_environmental.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Deer Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1504.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/deer-creek/deer_creek_rst_data_qc.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Feather River}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1239.5}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/feather-river/feather-rst-effort.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Mill Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1504.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/mill-creek/mill_creek_rst_qc.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Sacramento River}:
#'      \itemize{
#'          \item{Knights Landing}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1501.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/tree/main/data-raw/qc-markdowns/rst/lower-sac/knights_landing/}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'          \item{Tisdale}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1499.2}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/tree/main/data-raw/qc-markdowns/rst/lower-sac/tisdale}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'          \item{Delta Entry}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1503.1}{Data on EDI}.
#'          }
#'   \item \strong{Yuba River}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1529.2}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/yuba-river/yuba-river-rst-qc-checklist.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   }
'rst_trap'

#' @title RST Efficiency Summary Data
#' @name efficiency_summary
#' @description Dataset containing summarized efficiency monitoring data for all SR JPE tribuatary and mainstem monitoring programs
#' @format 
#' \itemize{
#'   \item \code{date_released}: Date that efficiency trial release occurs (format - %Y-%m-%d)
#'   \item \code{release_id}: The unique identifier for each release trial 
#'   \item \code{stream}: Which stream the RST is located on                 
#'   \item \code{site}: Site name  
#'   \item \code{subsite}: Name of trap       
#'   \item \code{site_group}: Site group, used to seperate traps within the same stream that have unique environmental conditions.
#'   \item \code{number_released}: Count of fish released       
#'   \item \code{number_recaptured}: Count of fish recaptured in RST on a specific recapture date, when NA trap is not fished
#'   \item \code{run}: Run of fish released
#'   \item \code{life_stage}: Lifestage of fish released
#'   \item \code{origin}: Fish origin (natural, hatchery, mixed, unknown, not recorded, or NA)   
#'   }
#' @source Raw datasets and original documentation of data processing and QC process can be found for each stream using the links below. Data is combined \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/standard-format-data-prep/mark_recapture_standard_format.Rmd}{here}
#'  \itemize{
#'   \item \strong{Battle Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1509.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/battle-creek/battle_creek_mark_recapture_data.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Butte Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1497.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/butte-creek/butte_mark_recapture.Rmd}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Clear Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1509.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/clear-creek/clear_creek_mark_recapture.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Deer Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1504.1}{Data on EDI}
#'   \item \strong{Feather River}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1239.5}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/feather-river/feather_mark_recapture.R}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Mill Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1504.1}{Data on EDI}
#'      \itemize{
#'          \item{Knights Landing}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1501.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/tree/main/data-raw/qc-markdowns/rst/lower-sac/knights_landing_mark_reacapture.R}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'          \item{Tisdale}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1499.2}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/tree/main/data-raw/qc-markdowns/rst/lower-sac/tisdale_efficiency.Rmd}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'          \item{Delta Entry}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1503.1}{Data on EDI}.
#'          }
#'   \item \strong{Yuba River}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1529.2}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/yuba-river/yuba-river-rst-qc-checklist.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
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
#'   \item \code{site_group}: Site group, used to separate traps within the same stream that have unique environmental conditions.
#'   \item \code{fork_length}: fork length of released fish 
#'   }
'release_fish'

#' @title RST efficiency trial recaptures
#' @name recaptures
#' @description Dataset containing recapture for efficiency monitoring  
#' @format 
#' \itemize{
#'   \item \code{date}: date 
#'   \item \code{stream}: Stream RST is located on  
#'   \item \code{site}: Site RST is located on   
#'   \item \code{subsite}: Specific trap site   
#'   \item \code{site_group}: Site group, used to separate traps within the same stream that have unique environmental conditions.
#'   \item \code{count}: Number of fish caught 
#'   \item \code{release_id}: The unique identifier for each release trial  
#'   \item \code{fork_length}: Fork length measure of catch in mm   
#'   \item \code{dead}: Mortality status of catch   
#'   \item \code{weight}: Weight of catch in grams   
#'   \item \code{run}: Run of catch   
#'   \item \code{life_stage}: Life Stage of catch   
#'   \item \code{adipose_clipped}: Boolean value describing if adipose is clipped on catch 
#'   }
#' @source Raw datasets and original documentation of data processing and QC process can be found for each stream using the links below. Data is combined \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/standard-format-data-prep/mark_recapture_standard_format.Rmd}{here}
#'  \itemize{
#'   \item \strong{Battle Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1509.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/battle-creek/battle_creek_mark_recapture_data.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Butte Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1497.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/butte-creek/butte_mark_recapture.Rmd}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Clear Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1509.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/clear-creek/clear_creek_mark_recapture.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Deer Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1504.1}{Data on EDI}
#'   \item \strong{Feather River}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1239.5}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/feather-river/feather_mark_recapture.R}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   \item \strong{Mill Creek}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1504.1}{Data on EDI}
#'      \itemize{
#'          \item{Knights Landing}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1501.1}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/tree/main/data-raw/qc-markdowns/rst/lower-sac/knights_landing_mark_reacapture.R}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'          \item{Tisdale}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1499.2}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/tree/main/data-raw/qc-markdowns/rst/lower-sac/tisdale_efficiency.Rmd}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'          \item{Delta Entry}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1503.1}{Data on EDI}.
#'          }
#'   \item \strong{Yuba River}: \href{https://portal.edirepository.org/nis/mapbrowse?packageid=edi.1529.2}{Data on EDI}, \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/rst/yuba-river/yuba-river-rst-qc-checklist.md}{Original Data Exploration Script}. Additional data exploration scripts are located in GitHub.
#'   }
'recaptures'

#' @title Adult Upstream passage monitoring estimates 
#' @name upstream_passage_estimates
#' @description Adult upstream passage estimates, Generalized Additive Model (GAM) 
#' used to generate passage estimates from raw passage data. Upstream passage estimates 
#' are available for: battle creek, clear creek, deer creek, mill creek, yuba river, butte creek. 
#' @format 
#' \itemize{
#'   \item \code{year}: year data were collected
#'   \item \code{stream}: stream data were collected on 
#'   \item \code{passage_estimate}: yearly aggregated interpolated upstream passage estimate
#'   \item \code{run}: run of fish (if assigned)
#'   \item \code{adipose_clipped}: whether or not the adipose fin was clipped
#'   }
#' @source Adult upstream passage estimates were provided by monitoring programs. 
#' These data are currently being uploaded to EDI. In the meantime you can find data exploration scripts 
#' for each tributary \href{https://github.com/SRJPE/JPE-datasets/tree/main/data-raw/qc-markdowns/adult-upstream-passage-monitoring}{here} and 
#' combined passage estimates \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/standard-format-data-prep/adult_passage_estimate_standard_format.Rmd}{here}.
'upstream_passage_estimates'

#' @title Adult Upstream passage monitoring raw counts
#' @name upstream_passage
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
#'   \item \code{hours}: hours the camera was in operation 
#'   \item \code{comments}: comments
#'   }
'upstream_passage'

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
#' @source Carcass survey CJS estimates were provided by monitoring programs. 
#' These data are currently being uploaded to EDI. In the meantime you can find data exploration scripts 
#' for each tributary \href{https://github.com/SRJPE/JPE-datasets/tree/main/data-raw/qc-markdowns/adult-holding-redd-and-carcass-surveys}{here} and 
#' combined carcass estimates \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/standard-format-data-prep/carcass_cjs_estimates_standard_format.Rmd}{here}.
'carcass_estimates'

#' @title Redd Survey Data 
#' @name redd
#' @description Raw redd survey monitoring data. Redd survey data is available 
#' for Battle Creek, Clear Creek, Feather River, Mill Creek, Yuba River. 
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
#' @source Redd data were provided by monitoring programs. 
#' These data are currently being uploaded to EDI. In the meantime you can find data exploration scripts 
#' for each tributary \href{https://github.com/SRJPE/JPE-datasets/tree/main/data-raw/qc-markdowns/adult-holding-redd-and-carcass-surveys}{here} and 
#' combined redd data \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/standard-format-data-prep/standard_adult_redd_data.Rmd}{here}.
'redd'

#' @title Holding Survey Data 
#' @name holding
#' @description Raw holding survey monitoring data. Holding survey data is available 
#' for Battle Creek, Butte Creek, Clear Creek, Deer Creek. 
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
#' @source Holding data were provided by monitoring programs. 
#' These data are currently being uploaded to EDI. In the meantime you can find data exploration scripts 
#' for each tributary \href{https://github.com/SRJPE/JPE-datasets/tree/main/data-raw/qc-markdowns/adult-holding-redd-and-carcass-surveys}{here} and 
#' combined holding data \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/standard-format-data-prep/holding_standard_format.Rmd}{here}.
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
#' @source Adult data packages are currently being added to EDI. 
#' Data in this table was pulled from holding, redd, carcass, and passage datasets.
#' See `?SRJPEdata::holding`, `?SRJPEdata::redd`, `?SRJPEdata::carcass_estimates`, 
#' and `?SRJPEdata::passage_estimates` for more details.
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
#'   \item \code{site_group}:Site group, used to separate traps within the same stream that have unique environmental conditions.
#'   \item \code{min_date} : Minimum date of sampling season to include 
#'   \item \code{min_week} : Minimum week of sampling season to include 
#'   \item \code{max_date} : Maximum date of sampling season to include  
#'   \item \code{max_week} : Maximum week of sampling season to include  
#'   }
#' @source Expert opinion. See \code{vignette("years_to_include_analysis", package = "SRJPEdata")} for more details.
'chosen_site_years_to_model'

#' @title Daily Yearling Rulesets 
#' @name daily_yearling_ruleset
#' @description Datasets containing the daily yearling rulesets. 
#' See \code{vignette("yearling_ruleset", package = "SRJPEdata")} for more details.
#' @format Dataframe with 2,565 rows and 4 columns (stream, month, day, cutoff)
#' \itemize{
#'   \item \code{stream}: Stream RST is located on   
#'   \item \code{month}: Month to apply yearling ruleset to 
#'   \item \code{day}: Day to apply yearling ruleset to  
#'   \item \code{cutoff}: Fork length cutoff value in mm 
#'   }
#' @source Expert opinion. See \code{vignette("yearling_ruleset", package = "SRJPEdata")} for more details.
'daily_yearling_ruleset'

#' @title Weekly Hours Fished
#' @name weekly_hours_fished
#' @description Datasets containing the hours fished for each stream, site, and week. 
#' See \code{vignette("trap_effort", package = "SRJPEdata")} for more details.
#' @format Dataframe containing 7 columns (stream, site, subsite, site_group, week, year, hours_fished)
#' \itemize{
#'  \item \code{year}: year 
#'   \item \code{stream}: Stream RST is located on  
#'   \item \code{site}: Site RST is located on   
#'   \item \code{site_group}: Site group, used to separate traps within the same stream that have unique environmental conditions.
#'   \item \code{week}: Week 
#'   \item \code{hours_fished}: Number of hours that a trap was operated in a given week. Capped at 168. 
#'   }
'weekly_hours_fished'

#' @title Environmental Gage Data
#' @name environmental_data
#' @description Environmental gage data for each tributary in the SR JPE.
#' @format
#' \itemize{
#'   \item \code{date}: Date associated with environmental measure 
#'   \item \code{statistic}: Summary static used to summarize flow and temperature measures into a single daily reccord (min, mean, max)
#'   \item \code{value}: Flow or temperature measurements 
#'   \item \code{stream}: Stream environmental data is collected on  
#'   \item \code{gage_agency}: Agency providing flow or temperature data, most data pulled from CDEC or USGS
#'   \item \code{gage_number}: Unique identifier of gage used to query flow and temperature data
#'   \item \code{parameter}: Parameter measured, includes "flow" and "temperature"
#'   \item \code{site_group}: Site group, used to separate traps within the same stream that have unique environmental conditions.
#'   }
#'   @source USGS/CDEC/FWS. See `data-raw/pull_environmental_data.R` for more details.
'environmental_data'

#' @title Survival Model Data
#' @name survival_model_inputs
#' @description Acoustic tagging data used to model survival for the SR JPE 
#' @format
#' \itemize{
#'   \item \code{fish_id}: Unique identifier associated with each released fish 
#'   \item \code{ch}: Capture history of each fish describing detection at reciever location, 0 indicated not detected, 1 indicates detected 
#'   \item \code{study_id}: Unique identifier associated with each release group 
#'   \item \code{fish_length}: Fork length of fish in mm 
#'   \item \code{fish_weight}: Weight of fish in grams 
#'   \item \code{fish_type}: Type of fish used in release trial, typically indicated where that fish came from and species of fish 
#'   \item \code{fish_release_date}: Date of release 
#'   \item \code{release_location}: Location of release 
#'   \item \code{year}: Year of release 
#'   }
#'   @source Central Valley Enhanced Acoustic Tagging Project. 
#'   This data package queries tagging data from many studies using the ERDDAP data server.
#'   See `data-raw/pull_acoustic_tagging_data.R` for more details.
'survival_model_inputs'
