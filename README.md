# SRJPEdata

This data package contains Juvenile, Adult and environmental data for each of the watersheds within the Spring Run Juvenile Production Estimate (SRJPE) Forecast model. Historical data are used to train the model and seasonal updates are used to Forecast the JPE of a given season. 

This data has been compiled from monitoring programs and gages and is stored in the SRJPE model database on Microsoft Azure. Biweekly, automated scripts update the database, pulling new datasets from CDEC & USGS gages and from EDI monitoring data packages. RST data is updated biweekly throughout the trapping season and Adult data is updated annual at the end of the adult monitoring season. 

This data package will be updated in __ and then biweekly through the RST motioning season (Nov - June). 

## Installation

```
# install.packages("remotes")
remotes::install_github("SRJPE/SRJPEdata")
```

## Usage
This package provides datasets to the SRJPEmodelpackage.

```
# datasets within the package
data(package = 'SRJPEdata')

# explore package documentation 
?SRJPEdata
```

## Dependencies

## Explore datasets 

Explore model datasets on the SRJPEdashboard shiny app. (Add link)

