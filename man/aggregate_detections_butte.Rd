% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/acoustic_tagging_processing_functions.R
\name{aggregate_detections_butte}
\alias{aggregate_detections_butte}
\title{Aggregate Detections for Butte Region}
\usage{
aggregate_detections_butte(
  detections,
  receiever_metadata,
  replace_dict = list(replace_with = list(c("Releasepoint"), c("Sacramento"),
    c("Endpoint")), replace_list = list(c("UpperButte_RST_Rel", "UpperButte_RST",
    "UpperButte_SKWY", "Butte_Blw_Sanborn_Rel", "North_Weir_Rel", "Sanborn_Slough_Rel",
    "Laux Rd", "SutterBypass_Weir2_RST_Rel", "SutterBypass Weir2 RST"), c("TowerBridge",
    "I80-50_Br", "ToeDrainBase", "Hwy84Ferry"), c("BeniciaE", "BeniciaW", "ChippsE",
    "ChippsW")))
)
}
\arguments{
\item{detections}{A dataframe containing detections information.}

\item{receiever_metadata}{A dataframe containing receiver metadata.}

\item{replace_dict}{A list specifying receiver locations to aggregate and their aggregated name.}
}
\value{
A list containing:
\itemize{
\item A dataframe of detections with replaced receiver locations.
\item A dataframe of aggregated receiver metadata.
}
}
\description{
Replace receiver locations in the detections dataframe with aggregated locations for the Butte region.
}
\details{
This function replaces receiver locations in the detections dataframe with aggregated locations for the Butte region according to the specified replacement dictionary. It aggregates receiver locations into one and calculates the mean River Kilometer (RKM), Latitude, Longitude, and Region for each aggregated location. The function also updates the receiver metadata accordingly.
}
\examples{
# Define replacement dictionary
replacement_dict <- list(replace_with = list(c("Releasepoint"),
                                             c("Sacramento"),
                                             c("Endpoint")),
                         replace_list = list(c("UpperButte_RST_Rel","UpperButte_RST","UpperButte_SKWY",
                                              "SutterBypass_Weir2_RST_Rel","SutterBypass Weir2 RST"),
                                            c("TowerBridge","I80-50_Br",
                                              "ToeDrainBase","Hwy84Ferry"),
                                            c("BeniciaE","BeniciaW",
                                              "ChippsE","ChippsW"
                                            )))

# Aggregate detections for Butte region
aggregated_data <- aggregate_detections_butte(detections_data, receiver_metadata, replace_dict = replacement_dict)

}
