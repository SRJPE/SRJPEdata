#' Pull Detections Data Based on Study IDs
#'
#' Pulls detections data from a specified ERDDAP table based on a list of study IDs.
#'
#' @param study_id A character study IDs. For all ERDDAP valid study IDs see `?pull_study_ids_from_ERDDAP()`
#'
#' @return A dataframe containing detections data from the ERDDAP table.
#'
#' @details This function retrieves detections data from the 'FED_JSATS_detects' ERDDAP table based on the provided list of study IDs. It constructs a query to filter detections by the specified study IDs and fetches the corresponding data from the ERDDAP server.
#'
#' @examples
#' # Define a list of study IDs
#' study_id <- "study_id_1"
#' 
#' # Pull detections data based on study IDs
#' detections_data <- pull_detections_data(study_id)
#' 
#' @export
pull_detections_data_from_ERDDAP <- function(study_id) {
  data <- tabledap('FED_JSATS_detects',
                  url = "https://oceanview.pfeg.noaa.gov/erddap/", 
                  str2lang(noquote(paste0("'study_id=\"", study_id,"\"'"))))
  return(data)
}

#' Pull Receiver Data from ERDDAP
#'
#' Pulls receiver data from the FED_JSATS_receivers table.
#'
#' @return A dataframe containing receiver data from the ERDDAP table.
#'
#' @details This function retrieves receiver data from the 'FED_JSATS_receivers' ERDDAP table. It fetches the data from the specified ERDDAP server URL.
#'
#' @examples
#' # Pull receiver data from ERDDAP
#' receiver_data <- pull_receiver_data_from_ERDDAP()
#' 
#' @export
pull_reciever_data_from_ERDDAP <- function() {
  data <- tabledap('FED_JSATS_receivers',
                   url = "https://oceanview.pfeg.noaa.gov/erddap/")
  return(data)
}

#' Pull Study IDs from ERDDAP
#'
#' Pulls unique study IDs from a specified ERDDAP table.
#'
#' @return A character vector containing unique study IDs.
#'
#' @details This function retrieves unique study IDs from the 'FED_JSATS_detects' ERDDAP table. It fetches the data from the specified ERDDAP server URL and extracts the 'study_id' field, ensuring uniqueness of the study IDs.
#'
#' @examples
#' # Pull study IDs from ERDDAP
#' study_ids <- pull_study_ids_from_ERDDAP()
#' 
#' @export
pull_study_ids_from_ERDDAP <- function(){
  study_ids <- tabledap("FED_JSATS_detects",
                        fields = "study_id",
                        url = "https://oceanview.pfeg.noaa.gov/erddap/") |> 
    pull(study_id) |> 
    unique()
  study_ids
}

#' Pull Fish Data from ERDDAP
#'
#' Pulls tagged fish data from a specified ERDDAP table.
#'
#' @return A dataframe containing tagged fish data from the ERDDAP table.
#'
#' @details This function retrieves tagged fish data from the 'FED_JSATS_taggedfish' ERDDAP table. It fetches the data from the specified ERDDAP server URL and performs necessary data transformations, including converting date columns to POSIXct format and extracting fish ID prefixes.
#'
#' @examples
#' # Pull fish data from ERDDAP
#' fish_data <- pull_fish_data_from_ERDDAP()
#' 
#' @export
pull_fish_data_from_ERDDAP <- function() {
  data <- tabledap('FED_JSATS_taggedfish',
                  url = "https://oceanview.pfeg.noaa.gov/erddap/") |> 
    mutate(fish_release_date = as.POSIXct(fish_release_date, 
                                          format = "%m/%d/%Y %H:%M:%S", 
                                          tz = "Etc/GMT+8"),
           fish_date_tagged = as.POSIXct(fish_date_tagged, 
                                         format = "%m/%d/%Y %H:%M:%S", 
                                         tz = "Etc/GMT+8"),
           fish_id_prefix = substr(fish_id, start = 1, stop = (nchar(fish_id)-4))) 
  return(data)
}


#' Get Receiver Sites Metadata for Given Detections Dataframe
#'
#' Get a list of all receiver sites and metadata for a given a detections dataframe.
#' Detections data can be pulled directly from ERDAP using `library(rerddap).` See `?pull_detections_data()` for more information.  
#'
#' @param all_detections A dataframe containing detections information.
#'
#' @return A dataframe of receiver sites along with River Kilometer (RKM), Latitude (Lat), Longitude (Lon), and receiver_region.
#'
#' @details This function processes the provided detections dataframe to extract unique receiver sites' metadata, including their River Kilometer (RKM), Latitude (Lat), Longitude (Lon), and Region. It calculates mean RKM, Lat, and Lon for each receiver site to handle potential discrepancies in the detections dataframe.
#'
#' @examples
#' # Load the detections dataframe
#' data <- read.csv("detections.csv")
#' 
#' # Get receiver sites metadata
#' receiver_metadata <- get_receiver_sites_metadata(data)
#' 
#' @export
get_receiver_sites_metadata <- function(all_detections) {
  # Get a list of all receiver sites and metadata for a given detections df
  #
  # Arguments:
  #  all_detections: detections df
  #
  # Return:
  #  df of receiver sites along with RKM, Lat, Lon, Region
  
  reach_metadata <- all_detections %>%
    bind_rows() %>%
    distinct(receiver_general_location, receiver_general_river_km, 
             receiver_general_latitude, receiver_general_longitude, receiver_region) %>%
    # Necessary because detections files shows differing RKM, Lat, Lon for some
    # receiver_general_locationsometimes
    group_by(receiver_general_location) %>%
    summarise(
      receiver_general_river_km = mean(as.numeric(receiver_general_river_km), na.rm = TRUE),
      receiver_general_latitude = mean(as.numeric(receiver_general_latitude), na.rm = TRUE),
      receiver_general_longitude = mean(as.numeric(receiver_general_longitude), na.rm = TRUE),
      receiver_region = first(receiver_region)
    ) %>%
    arrange(desc(receiver_general_river_km))
}



#' Aggregate Detections Data for Sacramento River Sites
#'
#' Replaces specific receiver locations in the detections dataframe with aggregated sites, updating their River Kilometer (RKM), Latitude (Lat), Longitude (Lon), and Region accordingly.
#'
#' @param detections A dataframe containing detections information.
#' @param replace_dict A list specifying receiver locations to aggregate and their corresponding aggregated names.
#' @param receiver_metadata A table containing metadata for general release sites. Created using `get_reciever_sites_metadata()`.
#'
#' @return A dataframe of detections with aggregated receiver sites and updated metadata.
#'
#' @details This function replaces specified receiver locations in the detections dataframe with aggregated sites according to the provided replace dictionary. It updates the River Kilometer (RKM), Latitude (Lat), Longitude (Lon), and Region for the aggregated sites. The function creates a new dataframe containing the aggregated receiver sites' metadata, reflecting the aggregation done.
#'
#' @examples
#' # Define replace dictionary
#' replace_dict <- list(replace_with = list(c("Releasepoint"),
#'                                          c("WoodsonBridge"),
#'                                          c("ButteBridge"),
#'                                          c("Sacramento"),
#'                                          c("Endpoint")),
#'                     replace_list = list(c("BattleCk_CNFH_Rel","RBDD_Rel","RBDD_Rel_Rec",
#'                                           "Altube Island","Abv_Altube1",
#'                                           "MillCk_RST_Rel","MillCk2_Rel","DeerCk_RST_Rel"),
#'                                         c("Mill_Ck_Conf","Abv_WoodsonBr","Blw_Woodson"),
#'                                         c("ButteBr","BlwButteBr"),
#'                                         c("TowerBridge","I80-50_Br",
#'                                           "ToeDrainBase","Hwy84Ferry"),
#'                                         c("BeniciaE","BeniciaW",
#'                                           "ChippsE","ChippsW")))
#'
#' # Aggregate detections data for Sacramento River sites
#' aggregated_detections <- aggregate_detections_sacramento(detections_data, replace_dict)
#'
#' @export
aggregate_detections_sacramento <- function(detections, receiver_metadata, 
                                            replace_dict = list(replace_with = list(c("Releasepoint"),
                                                                                    c("WoodsonBridge"),
                                                                                    c("ButteBridge"),
                                                                                    c("Sacramento"),
                                                                                    c("Endpoint")),
                                                                replace_list = list(c("BattleCk_CNFH_Rel","RBDD_Rel","RBDD_Rel_Rec",
                                                                                      "Altube Island","Abv_Altube1",
                                                                                      "MillCk_RST_Rel","MillCk2_Rel","DeerCk_RST_Rel"), 
                                                                                    c("Abv_WoodsonBr","Blw_Woodson"),
                                                                                    c("ButteBr","BlwButteBr","AbvButteBr"),
                                                                                    c("TowerBridge","I80-50_Br",
                                                                                      "ToeDrainBase","Hwy84Ferry"),
                                                                                    c("BeniciaE","BeniciaW",
                                                                                      "ChippsE","ChippsW"
                                                                                    ))),
                                            create_detection_history = FALSE) {
  
  # Make a copy of reach_meta (receiver metadata)
  reach_meta_aggregate <- receiver_metadata
  
  # Walk through each key/pair value
  for (i in 1:length(replace_dict$replace_with)) {
    # Unlist for easier to use format
    replace_list <- unlist(replace_dict[[2]][i])
    replace_with <- unlist(replace_dict[[1]][i])
    
    # Get the averaged replacement values
    replace <- receiver_metadata %>%
      select(receiver_general_location, receiver_general_river_km, receiver_general_latitude, receiver_general_longitude, receiver_region) %>%
      filter(receiver_general_location %in% c(replace_list, replace_with)) %>%
      distinct() %>%
      select(-receiver_general_location) %>%
      group_by(receiver_region) %>%
      summarise_all(mean)
    
    # Handle single or multiple regions
    if (nrow(replace) == 1) {
      replace_values <- replace
    } else {
      replace_values <- replace %>%
        ungroup() %>%
        summarise(
          receiver_general_river_km = mean(receiver_general_river_km),
          receiver_general_latitude = mean(receiver_general_latitude),
          receiver_general_longitude = mean(receiver_general_longitude),
          receiver_region = first(receiver_region)
        )
    }
    
    # Replace in detections - single mutate, check membership in replace_list
    detections <- detections %>%
      mutate(
        receiver_general_location = ifelse(receiver_general_location %in% replace_list, replace_with, receiver_general_location),
        receiver_general_river_km = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_river_km, receiver_general_river_km),
        receiver_general_latitude = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_latitude, receiver_general_latitude),
        receiver_general_longitude = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_longitude, receiver_general_longitude),
        receiver_region = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_region, receiver_region)
      )
    
    # This new df shows receiver metadata and reflects the aggregation done
    reach_meta_aggregate <- reach_meta_aggregate %>%
      mutate(
        receiver_general_location = ifelse(receiver_general_location %in% replace_list, replace_with, receiver_general_location),
        receiver_general_river_km = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_river_km, receiver_general_river_km),
        receiver_general_latitude = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_latitude, receiver_general_latitude),
        receiver_general_longitude = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_longitude, receiver_general_longitude),
        receiver_region = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_region, receiver_region)
      ) %>%
      distinct()

  }
  # TODO need something to catch where we have multiple detections
  if (create_detection_history == FALSE) {
    detections <- detections %>%
      filter(receiver_general_location %in% reach_meta_aggregate$receiver_general_location) %>%
      group_by(fish_id) %>%
      arrange(fish_id, desc(receiver_general_river_km)) %>%
      ungroup()
  } else if (create_detection_history == TRUE) {
    detections <- detections %>% 
      filter(receiver_general_location %in% reach_meta_aggregate$receiver_general_location) %>% 
      # TODO we were grouping by receiver_general_River_km - this was causing duplicates. We need to address this
      group_by(fish_id, receiver_general_location) %>% 
      summarise(min_time = min(time, na.rm = TRUE)) %>%
      arrange(fish_id, min_time) |> 
      ungroup()
  } 
  
  return(list(detections = detections, reach_meta_aggregate = reach_meta_aggregate))
}

#' Aggregate Detections for Butte Region
#'
#' Replace receiver locations in the detections dataframe with aggregated locations for the Butte region.
#'
#' @param detections A dataframe containing detections information.
#' @param receiver_metadata A dataframe containing receiver metadata.
#' @param replace_dict A list specifying receiver locations to aggregate and their aggregated name.
#'
#' @return A list containing:
#'   - A dataframe of detections with replaced receiver locations.
#'   - A dataframe of aggregated receiver metadata.
#'
#' @details This function replaces receiver locations in the detections dataframe with aggregated locations for the Butte region according to the specified replacement dictionary. It aggregates receiver locations into one and calculates the mean River Kilometer (RKM), Latitude, Longitude, and Region for each aggregated location. The function also updates the receiver metadata accordingly.
#'
#' @examples
#' # Define replacement dictionary
#' replacement_dict <- list(replace_with = list(c("Releasepoint"),
#'                                              c("Sacramento"),
#'                                              c("Endpoint")),
#'                          replace_list = list(c("UpperButte_RST_Rel","UpperButte_RST","UpperButte_SKWY",
#'                                               "SutterBypass_Weir2_RST_Rel","SutterBypass Weir2 RST"),
#'                                             c("TowerBridge","I80-50_Br",
#'                                               "ToeDrainBase","Hwy84Ferry"),
#'                                             c("BeniciaE","BeniciaW",
#'                                               "ChippsE","ChippsW"
#'                                             )))
#' 
#' # Aggregate detections for Butte region
#' aggregated_data <- aggregate_detections_butte(detections_data, receiver_metadata, replace_dict = replacement_dict)
#' 
#' @export
aggregate_detections_butte <- function(detections, receiver_metadata,
                                replace_dict = list(replace_with = list(c("Releasepoint"),
                                                                        c("Sacramento"),
                                                                        c("Endpoint")),
                                                    replace_list = list(c("UpperButte_RST_Rel","UpperButte_RST","UpperButte_SKWY",
                                                                          "Butte_Blw_Sanborn_Rel","North_Weir_Rel","Sanborn_Slough_Rel","Laux Rd",
                                                                          "SutterBypass_Weir2_RST_Rel","SutterBypass Weir2 RST"),
                                                                        c("TowerBridge","I80-50_Br",
                                                                          "ToeDrainBase","Hwy84Ferry"),
                                                                        c("BeniciaE","BeniciaW",
                                                                          "ChippsE","ChippsW"
                                                                        ))),
                                create_detection_history = FALSE) {
  
  # Make a copy of reach_meta (receiver metadata)
  reach_meta_aggregate <- receiver_metadata
  
  # Walk through each key/pair value
  for (i in 1:length(replace_dict$replace_with)) {
    # Unlist for easier to use format
    replace_list <- unlist(replace_dict[[2]][i])
    replace_with <- unlist(replace_dict[[1]][i])
    
    # Get the averaged replacement values
    replace <- receiver_metadata %>%
      select(receiver_general_location, receiver_general_river_km, receiver_general_latitude, receiver_general_longitude, receiver_region) %>%
      filter(receiver_general_location %in% c(replace_list, replace_with)) %>%
      distinct() %>%
      select(-receiver_general_location) %>%
      group_by(receiver_region) %>%
      summarise_all(mean)
    
    # Handle single or multiple regions
    if (nrow(replace) == 1) {
      replace_values <- replace
    } else {
      replace_values <- replace %>%
        ungroup() %>%
        summarise(
          receiver_general_river_km = mean(receiver_general_river_km),
          receiver_general_latitude = mean(receiver_general_latitude),
          receiver_general_longitude = mean(receiver_general_longitude),
          receiver_region = first(receiver_region)
        )
    }
    
    # Replace in detections - single mutate, check membership in replace_list
    detections <- detections %>%
      mutate(
        receiver_general_location = ifelse(receiver_general_location %in% replace_list, replace_with, receiver_general_location),
        receiver_general_river_km = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_river_km, receiver_general_river_km),
        receiver_general_latitude = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_latitude, receiver_general_latitude),
        receiver_general_longitude = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_longitude, receiver_general_longitude),
        receiver_region = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_region, receiver_region)
      )
    
    # This new df shows receiver metadata and reflects the aggregation done
    reach_meta_aggregate <- reach_meta_aggregate %>%
      mutate(
        receiver_general_location = ifelse(receiver_general_location %in% replace_list, replace_with, receiver_general_location),
        receiver_general_river_km = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_river_km, receiver_general_river_km),
        receiver_general_latitude = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_latitude, receiver_general_latitude),
        receiver_general_longitude = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_longitude, receiver_general_longitude),
        receiver_region = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_region, receiver_region)
      ) %>%
      distinct()
    
  }
  # TODO need something to catch where we have multiple detections
  if (create_detection_history == FALSE) {
    detections <- detections %>%
      filter(receiver_general_location %in% reach_meta_aggregate$receiver_general_location) %>%
      group_by(fish_id) %>%
      arrange(fish_id, desc(receiver_general_river_km)) %>%
      ungroup()
  } else if (create_detection_history == TRUE) {
    detections <- detections %>% 
      filter(receiver_general_location %in% reach_meta_aggregate$receiver_general_location) %>% 
      # TODO we were grouping by receiver_general_River_km - this was causing duplicates. We need to address this
      group_by(fish_id, receiver_general_location) %>% 
      summarise(min_time = min(time, na.rm = TRUE)) %>%
      arrange(fish_id, min_time) |> 
      ungroup()
  } 
  
  return(list(detections = detections, reach_meta_aggregate = reach_meta_aggregate))
}

#' Aggregate Detections for Feather River Region
#'
#' Replace receiver locations in the detections dataframe with aggregated locations for the Feather River region.
#'
#' @param detections A dataframe containing detections information.
#' @param receiver_metadata A dataframe containing receiver metadata.
#' @param replace_dict A list specifying receiver locations to aggregate and their aggregated name.
#'
#' @return A list containing:
#'   - A dataframe of detections with replaced receiver locations.
#'   - A dataframe of aggregated receiver metadata.
#'
#' @details This function replaces receiver locations in the detections dataframe with aggregated locations for the Feather River region according to the specified replacement dictionary. It aggregates receiver locations into one and calculates the mean River Kilometer (RKM), Latitude, Longitude, and Region for each aggregated location. The function also updates the receiver metadata accordingly.
#'
#' @examples
#' # Define replacement dictionary
#' replacement_dict <- list(replace_with = list(c("Releasepoint"),
#'                                              c("Sacramento"),
#'                                              c("Endpoint")),
#'                          replace_list = list(c("FR_Gridley_Rel","FR_Boyds_Rel","FR_Boyds_Rel_Rec"),
#'                                             c("TowerBridge","I80-50_Br", 
#'                                               "ToeDrainBase","Hwy84Ferry"),
#'                                             c("BeniciaE","BeniciaW", 
#'                                               "ChippsE","ChippsW" 
#'                                             )))
#'
#' # Aggregate detections for Feather River region
#' aggregated_data <- aggregate_detections_feather(detections_data, receiver_metadata, replace_dict = replacement_dict)
#'
#' @export
aggregate_detections_feather <- function(detections, receiver_metadata, 
                                         replace_dict = list(replace_with = list(c("Releasepoint"),
                                                                                c("Sacramento"),
                                                                                c("Endpoint")),
                                                            replace_list = list(c("FR_Gridley_Rel","FR_Boyds_Rel","FR_Boyds_Rel_Rec"),
                                                                               c("TowerBridge","I80-50_Br", 
                                                                                 "ToeDrainBase","Hwy84Ferry"),
                                                                               c("BeniciaE","BeniciaW", 
                                                                                 "ChippsE","ChippsW" 
                                                                               ))),
                                         create_detection_history = FALSE) {
  
  # Make a copy of reach_meta (receiver metadata)
  reach_meta_aggregate <- receiver_metadata
  
  # Walk through each key/pair value
  for (i in 1:length(replace_dict$replace_with)) {
    # Unlist for easier to use format
    replace_list <- unlist(replace_dict[[2]][i])
    replace_with <- unlist(replace_dict[[1]][i])
    
    # Get the averaged replacement values
    replace <- receiver_metadata %>%
      select(receiver_general_location, receiver_general_river_km, receiver_general_latitude, receiver_general_longitude, receiver_region) %>%
      filter(receiver_general_location %in% c(replace_list, replace_with)) %>%
      distinct() %>%
      select(-receiver_general_location) %>%
      group_by(receiver_region) %>%
      summarise_all(mean)
    
    # Handle single or multiple regions
    if (nrow(replace) == 1) {
      replace_values <- replace
    } else {
      replace_values <- replace %>%
        ungroup() %>%
        summarise(
          receiver_general_river_km = mean(receiver_general_river_km),
          receiver_general_latitude = mean(receiver_general_latitude),
          receiver_general_longitude = mean(receiver_general_longitude),
          receiver_region = first(receiver_region)
        )
    }
    
    # Replace in detections - single mutate, check membership in replace_list
    detections <- detections %>%
      mutate(
        receiver_general_location = ifelse(receiver_general_location %in% replace_list, replace_with, receiver_general_location),
        receiver_general_river_km = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_river_km, receiver_general_river_km),
        receiver_general_latitude = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_latitude, receiver_general_latitude),
        receiver_general_longitude = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_longitude, receiver_general_longitude),
        receiver_region = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_region, receiver_region)
      )
    
    # This new df shows receiver metadata and reflects the aggregation done
    reach_meta_aggregate <- reach_meta_aggregate %>%
      mutate(
        receiver_general_location = ifelse(receiver_general_location %in% replace_list, replace_with, receiver_general_location),
        receiver_general_river_km = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_river_km, receiver_general_river_km),
        receiver_general_latitude = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_latitude, receiver_general_latitude),
        receiver_general_longitude = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_general_longitude, receiver_general_longitude),
        receiver_region = ifelse(receiver_general_location %in% replace_list, replace_values$receiver_region, receiver_region)
      ) %>%
      distinct()
    
  }
  # TODO need something to catch where we have multiple detections
  if (create_detection_history == FALSE) {
    detections <- detections %>%
      filter(receiver_general_location %in% reach_meta_aggregate$receiver_general_location) %>%
      group_by(fish_id) %>%
      arrange(fish_id, desc(receiver_general_river_km)) %>%
      ungroup()
  } else if (create_detection_history == TRUE) {
    detections <- detections %>% 
      filter(receiver_general_location %in% reach_meta_aggregate$receiver_general_location) %>% 
      # TODO we were grouping by receiver_general_River_km - this was causing duplicates. We need to address this
      group_by(fish_id, receiver_general_location) %>% 
      summarise(min_time = min(time, na.rm = TRUE)) %>%
      arrange(fish_id, min_time) |> 
      ungroup()
  } 
  
  return(list(detections = detections, reach_meta_aggregate = reach_meta_aggregate))
}

#' Make Fish Encounter History
#'
#' Create an encounter history dataframe based on detections and aggregated receiver metadata.
#'
#' @param detections A dataframe containing detections information.
#' @param aggregated_receiver_metadata A dataframe containing aggregated receiver metadata.
#'
#' @return An encounter history dataframe. A matrix of every fish tagged for a given studyID
#' at every given receiver site (that is in reach.meta.aggregate) and whether it was present 1 or absent 0 in the detection dataframe.
#'
#' @details This function creates an encounter history dataframe, which is a matrix of every fish tagged for a given studyID at every given receiver site (that is in reach.meta.aggregate), indicating whether the fish was present (1) or absent (0) in the detection dataframe. It utilizes the earliest detection time for each fish at each receiver site to determine presence or absence.
#'
#' @examples
#' # Create encounter history dataframe
#' encounter_history <- make_fish_encounter_history(detections_data, aggregated_receiver_metadata)
#' 
#' @export
make_fish_encounter_history <- function(detections,
                                        aggregated_reciever_metadata,
                                        released_fish_table) {
  # Make an encounter history df
  
  # Arguments:
  #  detections: a detections df
  
  # Return:
  #  Encounter history df. A matrix of every fish tagged for a given studyID
  #  at every given receiver site (that is in reach.meta.aggregate) and whether
  #  it was present 1 or absent 0 in the detection df
  
  # Get earliest detection for each fish at each GEN
  min_detects <- detections %>% 
    filter(receiver_general_location %in% aggregated_reciever_metadata$receiver_general_location) %>% 
    group_by(fish_id, receiver_general_location, receiver_general_river_km) %>% 
    summarise(min_time = min(time, na.rm = TRUE)) %>%
    arrange(fish_id, min_time) |> 
    mutate(detect = 1) # Add col detect to min_detects, these fish get a 1

  # Get list of all tagged fish for the studyID
  fish <- released_fish_table %>%
    # filter(study_id == detections$study_id[1]) %>%
    arrange(fish_id) %>%
    pull(fish_id)
  
  # Create matrix of all combinations of fish and GEN
  encounter_history <- expand.grid(
    fish,
    aggregated_reciever_metadata$receiver_general_location, stringsAsFactors = FALSE)
  
  names(encounter_history) <- c('fish_id', 'receiver_general_location')
  
  # Join in detections to the matrix, fish detected a GEN will be given a 1
  # otherwise it will be given a 0
  encounter_history <- encounter_history %>% 
    left_join(min_detects %>%
                select(fish_id, receiver_general_location, detect), 
              by = c("fish_id", "receiver_general_location")) %>% 
    mutate_if(is.numeric, coalesce, 0) |> 
    pivot_wider(id_cols = "fish_id", names_from = receiver_general_location, values_from = detect) |> 
    mutate(Releasepoint = 1) |> # Manually make the release column a 1 because all fish were released there
    unite("ch", Releasepoint:Endpoint , sep ="") 
}
