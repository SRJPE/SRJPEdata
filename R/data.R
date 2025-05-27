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


#' @title Weekly BT-SPAS-X Model Efficency Data
#' @name weekly_juvenile_abundance_efficiency_data
#' @description Weekly Rotary Screw Trap (RST) efficiency data and weekly standardized flow, 
#' for spring run tributaries modeled in BT-SPAS-X.
#' @format A tibble with 651 rows and 8 columns 
#' \itemize{
#'   \item \code{year}: year 
#'   \week \code{week} : week 
#'   \item \code{stream}: rst stream 
#'   \item \code{site}: rst site 
#'   \item \code{number_released}: Number of efficiency trial fish released
#'   \item \code{number_recaptured}: Number of efficiency trial fish recaptured
#'   \item \code{standardized_efficiency_flow}: Flow standardized across years and sites 
#'   \item \code{run_year}: Run year 
#'   }
#' @source Prepared using rotary screw trap catch data (see `?SRJPEdata::rst_catch` for more information on raw data sources), 
#'   environmental_data (see `?SRJPEdata::environmental_data`), hours fished information 
#'   (see `?SRJPEdata::weekly_hours_fished for more information`), and btspasx special priors (see `?SRJPEdata::btspasx_special_priors_data` for more information).
'weekly_juvenile_abundance_model_data'

#' @title Weekly BT-SPAS-X Catch Data
#' @name weekly_juvenile_abundance_catch_data
#' @description Weekly Rotary Screw Trap (RST) catch summaries, weekly RST effort effort, and weekly standardized flow, 
#' for spring run tributaries modeled in BT-SPAS-X.
#' @format A tibble with 10,890 rows and 14 columns 
#' \itemize{
#'   \item \code{year}: year 
#'   \week \code{week} : week 
#'   \item \code{stream}: rst stream 
#'   \item \code{site}: rst site 
#'   \item \code{count}: weekly count of number of 
#'   \item \code{mean_fork_length}: Mean fork length of released efficiency trial fish 
#'   \item \code{hours_fished}: Hours fished on a stream 
#'   \item \code{flow_cfs}: Weekly mean gage flow in cubic feet per second (cfs)
#'   \item \code{life_stage}: Life stage of juvenile fish 
#'   \item \code{average_stream_hours_fished}: Average hours fished on a given stream, used to standardize 
#'   \item \code{standardized_flow}: Flow standardized across years and sites 
#'   \item \code{run_year}: Run year 
#'   \item \code{catch_standardized_by_hours_fished}: Catch standardized by hours fished in a given week 
#'   \item \code{lgN_prior}: log normalized special prior abundance cap, for more info search `?SRJPEdata::btspasx_special_priors_data`
#'   }
#' @source Prepared using rotary screw trap catch data (see `?SRJPEdata::rst_catch` for more information on raw data sources), 
#'   environmental_data (see `?SRJPEdata::environmental_data`), hours fished information 
#'   (see `?SRJPEdata::weekly_hours_fished for more information`), and btspasx special priors (see `?SRJPEdata::btspasx_special_priors_data` for more information).
'weekly_juvenile_abundance_catch_data'

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
#'   \item \code{life_stage}: Life Stage of catch, standardized based on FL (fork lenght < 45mm = "fry", fork length > 45mm and < yearling cutoff == "smolt")  
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

#' @title RST efficiency trial releases
#' @name release
#' @description Dataset containing releases for efficiency monitoring  
#' @format 
#' \itemize{
#'   \item \code{date_released}: date 
#'   \item \code{release_id}: id associated with release trial 
#'   \item \code{stream}: Stream RST is located on  
#'   \item \code{site}: Site RST is located on   
#'   \item \code{subsite}: Specific trap site   
#'   \item \code{site_group}: Site group, used to separate traps within the same stream that have unique environmental conditions.
#'   \item \code{number_released}: Number of fish released 
#'   \item \code{run}: Run of released fish   
#'   \item \code{life_stage}: Life Stage of catch   
#'   \item \code{origin}: Origin of catch   
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
'release'

#' @title Annual adult estimates
#' @name upstream_passage_estimates
#' @description Annual adult estimates by data type provided by monitoring programs. 
#' @format 
#' \itemize{
#'   \item \code{year}: year data were collected (calendar year)
#'   \item \code{stream}: stream data were collected on 
#'   \item \code{count}: annual estimate
#'   \item \code{data_type}: type of data (redd, carcass estimate, holding, passage estimate)
#'   \item \code{lower_bound_estimate}: if confidence intervals are available, value for the lower bound estimate
#'   \item \code{upper_bound_estimate}: if confidence intervals are available, value for the upper bound estimate
#'   \item \code{confidence_level}: if confidence intervals are available, level of confidence provided
#'   }
#' @source Annual adult estimates were provided by monitoring programs. 
#' These data are currently being uploaded to EDI. 
'annual_adult'

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
#'   \item \code{year}: Year associated with environmental measure 
#'   \item \code{week}: Week associated with environmental measure 
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
#'   \item \code{ch}: Capture history of each fish describing detection at receiver location, 0 indicated not detected, 1 indicates detected 
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

#' @title Survival Model Data
#' @name survival_model_inputs
#' @description Acoustic tagging data used to model survival for the SR JPE 
#' @format
#' \itemize{
#'   \item \code{fish_id}: Unique identifier associated with each released fish 
#'   \item \code{ch}: Capture history of each fish describing detection at receiver location, 0 indicated not detected, 1 indicates detected 
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

#' @title Survival Model Data
#' @name survival_model_inputs
#' @description Acoustic tagging data used to model survival for the SR JPE 
#' @format
#' \itemize{
#'   \item \code{fish_id}: Unique identifier associated with each released fish 
#'   \item \code{ch}: Capture history of each fish describing detection at receiver location, 0 indicated not detected, 1 indicates detected 
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

#' @title Site Lookup
#' @name site_lookup
#' @description Site lookup table for linking subsite, sites, site_groups, and streams in the SR JPE 
#' @format
#' \itemize{
#'   \item \code{stream}: Stream RST is located on  
#'   \item \code{site}: Site RST is located on   
#'   \item \code{subsite}: Specific trap site   
#'   \item \code{site_group}: Site group, used to separate traps within the same stream that have unique environmental conditions.
'site_lookup'
