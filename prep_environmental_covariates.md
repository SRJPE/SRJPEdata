---
title: "Adult Model Covariates"
# output: html_document # to see tabset
output:
  html_document:
     code_folding: hide
     theme: flatly
# output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{prep_environmental_covariates}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---



There are multiple covariates used in SR JPE modeling that were developed through separate but related processes. There are currently two documents describing covariate selction and processing for different models: (1) Stock Recruit Covariates and (2) Adult Model Covariates (this document).

The Passage to Spawner (P2S) model relates spawner counts (from redd or holding surveys) to upstream passage counts obtained by video systems. This model is restricted to streams with reliable redd or holding surveys and reliable upstream passage counts. It is also restricted to years where the redd/holding and upstream passage datasets overlap. This vignette describes the process of pulling and processing environmental covariates for use in the P2S model.

## Selecting Adult Environmental Covariates

Potential environmental covariates hypothesized to influence prespawn mortality were proposed in meetings with the SR JPE Modeling Advisory Team (MAT). Five initial categories were identified: 

* temperature
* flow
* water year type
* passage timing
* total passage

There are many ways to summarize each of these categories and initial analyses helped identify collinearity and performance of each potential method by regressing prespawn mortality (calculated as `upstream_count / spawner_count`) against the environmental variable. When we were using redd counts as `spawner_count`, our model assumed a 50/50 sex ratio and modified that equation to be `upstream_count / (spawner_count * 0.5)`. Generally, one redd per female is a reasonable assumption although our model left the possibility open for more than one redd per female [(source)](https://www.researchgate.net/publication/233231658_The_Number_of_Redds_Constructed_per_Female_Spring_Chinook_Salmon_in_the_Wenatchee_River_Basin). Note that this covariate analysis and preparation does not include the Sacramento River mainstem as spring run do not spawn on the mainstem Sacramento.

## Preparing Covariates {.tabset}

### Temperature 

Several approaches were considered for summarizing temperature: 

1. Proportion of days where the temperature surpassed a threshold of 20 degrees Celsius [(source)](https://www.noaa.gov/sites/default/files/legacy/document/2020/Oct/07354626766.pdf) 
2. Growing degree days (GDD) with a base temperature of 0 degrees Celsius [(source)](https://www.researchgate.net/publication/279930331_Fish_growth_and_degree-days_I_Selecting_a_base_temperature_for_a_within-population_study and input from MAT team)  
3. Degree Day 20 (DD20), where cumulative degree days are calculated against a threshold of 20 degrees Celsius [(source)](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0204274) 

Following initial analyses and discussions, we focused on approach 3 because it showed the most consistent relationship with prespawn mortality across streams and accounts for cumulative stress. We calculated the metric for migration months (March - May) in the Sacramento River and holding months (May - August) in each tributary. The resulting dataset is as follows (note that DD less than 0 are set to 0):


```
## Error in `filter()`:
## ℹ In argument: `month(date) %in% migratory_months`.
## Caused by error in `as.POSIXlt.default()`:
## ! do not know how to convert 'x' to class "POSIXlt"
```

```
## Error in `filter()`:
## ℹ In argument: `month(date) %in% holding_months`.
## Caused by error in `as.POSIXlt.default()`:
## ! do not know how to convert 'x' to class "POSIXlt"
```

```
## Error in eval(expr, envir, enclos): object 'gdd_trib' not found
```

```
## Error in eval(expr, envir, enclos): object 'gdd' not found
```

The following plot is of the growing degree days above the 20 degree threshold over time for all tributaries:


```
## Error in eval(expr, envir, enclos): object 'gdd' not found
```

### Flow 

Maximum flow more effectively captures the high flow events that support migration speed and passage to upstream holding areas. Additionally, upon inspection of the data source across multiple years average maximum flow over the migratory and holding months (March-May and May-August, respectively) was more representative of the fluctuations in flow over the entire year. The resulting dataset is as follows:


```
## Error in `filter()`:
## ℹ In argument: `month(date) %in% migratory_and_holding_months`.
## Caused by error in `as.POSIXlt.default()`:
## ! do not know how to convert 'x' to class "POSIXlt"
```

```
## Error in eval(expr, envir, enclos): object 'flow_metrics' not found
```

The following plot is of max flow (cfs) over time for all tributaries:


```
## Error in eval(expr, envir, enclos): object 'flow_metrics' not found
```

### Water Year Type

To account for the influence of large scale interannual climate variability, we investigated water year type as a covariate as described by the [California Department of Water Resources](https://cdec.water.ca.gov/reportapp/javareports?name=WSIHIST) and available in the [waterYearType package in R](https://cloud.r-project.org/web/packages/waterYearType/index.html). 

We used the `waterYearType` package to pull water year assignments as a categorical covariate. Some streams had very few data points (i.e. for Mill Creek, only seven years were considered dependable), so we simplified all potential categories of water year type into either dry (`Dry`, `Below Normal`, `Critical`) or wet (`Wet`, `Above Normal`). The table below summarizes the number of dry and wet years that were included:


|Water Year Type | Count|
|:---------------|-----:|
|dry             |    60|
|wet             |    52|

### Passage Timing

Passage timing was considered; however, limited data reduced the sample size of the datasets for some tributaries so much as to remove them from candidacy for the model due to lack of statistical power. Passage timing was summarized as the mean, median, and min day of passage. The resulting dataset is as follows:


| year|stream       | median_passage_timing| mean_passage_timing| min_passage_timing|
|----:|:------------|---------------------:|-------------------:|------------------:|
| 1998|battle creek |                  24.5|            24.23333|                 22|
| 1999|battle creek |                  25.0|            24.73529|                 22|
| 2000|battle creek |                  28.0|            28.57895|                 21|
| 2001|battle creek |                  21.5|            23.50000|                 19|
| 2002|battle creek |                  27.0|            28.09091|                 22|
| 2003|battle creek |                  34.0|            32.18103|                 25|
| 2004|battle creek |                  24.0|            24.60870|                 23|
| 2005|battle creek |                  24.0|            24.90698|                 21|
| 2006|battle creek |                  26.0|            25.98750|                 25|
| 2007|battle creek |                  22.0|            23.08021|                 19|

The following plot is of median passage over time for all tributaries:

![plot of chunk unnamed-chunk-8](figure/unnamed-chunk-8-1.png)

### Total Passage as Index

We hypothesized that total annual passage might be an indicator of density because more adults in holding/spawning habitat could result in less available habitat and thus influence prespawn mortality. 


| year|stream       | passage_index|
|----:|:------------|-------------:|
| 1995|battle creek |            66|
| 1995|clear creek  |             2|
| 1996|battle creek |            35|
| 1997|battle creek |           107|
| 1998|battle creek |           178|
| 1998|clear creek  |            47|
| 1999|battle creek |            73|
| 1999|clear creek  |            35|
| 2000|battle creek |            78|
| 2000|clear creek  |             9|

![plot of chunk unnamed-chunk-9](figure/unnamed-chunk-9-1.png)

### Combine and Save Covariate Data 

Both continuous environmental variables (flow and temperature) were standardized and centered within streams before performing any analyses so that the scale of the data did not affect results. Water year type was coded as a binary variable as `1` for wet (wet, above normal) and `0` for dry (below normal, dry, critical). The resulting dataset is as follows (note that flow data has the longest time series available):


```
## Error in eval(expr, envir, enclos): object 'flow_metrics' not found
```



| year|stream       | wy_type| max_flow_std|    gdd_std| passage_index| median_passage_timing_std|
|----:|:------------|-------:|------------:|----------:|-------------:|-------------------------:|
| 1995|battle creek |       1|    3.0591938|         NA|    -0.6837483|                        NA|
| 1996|battle creek |       1|    0.0870719|         NA|    -0.8597315|                        NA|
| 1997|battle creek |       1|   -1.0024763|         NA|    -0.4509963|                        NA|
| 1998|battle creek |       1|    0.8456181|         NA|    -0.0479381|                -0.1057615|
| 1999|battle creek |       1|   -0.0715332|         NA|    -0.6440101|                 0.3595891|
| 2000|battle creek |       1|   -0.0301580|         NA|    -0.6156258|                 1.2902904|
| 2001|battle creek |       0|   -0.5956197|         NA|    -0.4282888|                -0.7262290|
| 2002|battle creek |       0|   -0.9493780|         NA|     0.2018445|                 0.9800567|
| 2003|battle creek |       1|    0.5146161| -0.5732839|     0.1961676|                 2.8414592|
| 2004|battle creek |       0|   -0.4301187| -0.5860987|    -0.5475032|                 0.0493554|

The following plot is of standardized covariates (covariates are colored by type) over time for all tributaries:

![plot of chunk unnamed-chunk-11](figure/unnamed-chunk-11-1.png)

#### Save data object
Data object saved in `SRJPEdata` as `p2s_model_covariates_standard.rds`. To access documentation search `?SRJPEdata::p2s_model_covariates_standard.rds`.


