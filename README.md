# SRJPEdata

This data package contains Juvenile, Adult and environmental data for each of the watersheds within the Spring Run Juvenile Production Estimate (SRJPE) Forecast model. Historical data are used to train the model and seasonal updates are used to Forecast the JPE of a given season. 

This data has been compiled from monitoring programs and gages and is stored in the SRJPE model database on Microsoft Azure. Biweekly, automated scripts update the database, pulling new datasets from CDEC & USGS gages and from EDI monitoring data packages. RST data is updated biweekly throughout the trapping season and Adult data is updated annual at the end of the adult monitoring season. 

This data package will be updated in annually after adult datasets are finalized and then biweekly through the RST motioning season (Nov - June). 

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

## Data Sources 

#### Spring Run Monitoring Datasets 

Adult and Juvenile monitoring datasets from 7 systems are compiled within this data package. All data can be found on the [Environmental Data Initiatives Data Portal](https://portal.edirepository.org/nis/simpleSearch) by searching "SR JPE."

#### Acoustic Tagging Survival Data 

NOAA collects acoustic tagging data as part of the Central Valley Enhanced Acoustic Tagging Project. This data package queries tagging data from many studies using the ERDDAP data server. We processed data, aggregating detection sites into 3 distinct locations and processing fish detection data to create a capture history for each fish. 

#### Genetics Data

Genetics monitoring data is also included in this data package to prepare data inputs for a probabilistic length at date (PLAD) model. Genetics data is pulled directly from the SR JPE genetics database into this data package. 

## Explore datasets 

Explore model datasets on the SRJPEdashboard shiny app. (Add link)

