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


| year|stream        |   gdd_trib| gdd_sac| gdd_total|
|----:|:-------------|----------:|-------:|---------:|
| 2000|feather river |  42.509566|       0|     42.51|
| 2000|yuba river    | 274.358130|       0|    274.36|
| 2001|clear creek   |  17.078134|       0|     17.08|
| 2001|feather river |  48.726433|       0|     48.73|
| 2001|yuba river    | 312.092106|       0|    312.09|
| 2002|clear creek   |  22.628449|       0|     22.63|
| 2002|feather river |  71.238409|       0|     71.24|
| 2002|yuba river    | 313.502719|       0|    313.50|
| 2003|battle creek  |   1.101875|       0|      1.10|
| 2003|clear creek   |  10.009113|       0|     10.01|

The following plot is of the growing degree days above the 20 degree threshold over time for all tributaries:

![plot of chunk unnamed-chunk-3](figure/unnamed-chunk-3-1.png)

### Flow 

Maximum flow more effectively captures the high flow events that support migration speed and passage to upstream holding areas. Additionally, upon inspection of the data source across multiple years average maximum flow over the migratory and holding months (March-May and May-August, respectively) was more representative of the fluctuations in flow over the entire year. The resulting dataset is as follows:


```
## Error in `filter()`:
## ℹ In argument: `month(date) %in% migratory_and_holding_months`.
## Caused by error in `as.Date.default()`:
## ! do not know how to convert 'x' to class "Date"
```



|stream      | year| mean_flow| max_flow|
|:-----------|----:|---------:|--------:|
|butte creek | 1997|       NaN|      Inf|
|butte creek | 1998|       NaN|      Inf|
|butte creek | 1999|  500.3782|     7177|
|butte creek | 2000|  477.5862|     7592|
|butte creek | 2001|  288.0755|     1844|
|butte creek | 2002|  286.3508|     6129|
|butte creek | 2003|  604.8511|     4420|
|butte creek | 2004|  395.5383|     4730|
|butte creek | 2005|  542.8965|    21900|
|butte creek | 2006| 1032.4894|    29600|

The following plot is of max flow (cfs) over time for all tributaries:

![plot of chunk unnamed-chunk-5](figure/unnamed-chunk-5-1.png)

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


| year|stream       | wy_type| max_flow_std|    gdd_std| passage_index| median_passage_timing_std|
|----:|:------------|-------:|------------:|----------:|-------------:|-------------------------:|
| 1995|battle creek |      NA|           NA|         NA|    -0.6837483|                        NA|
| 1996|battle creek |      NA|           NA|         NA|    -0.8597315|                        NA|
| 1997|battle creek |      NA|           NA|         NA|    -0.4509963|                        NA|
| 1998|battle creek |       1|           NA|         NA|    -0.0479381|                 0.1381146|
| 1999|battle creek |       1|           NA|         NA|    -0.6440101|                 0.2900407|
| 2000|battle creek |       1|           NA|         NA|    -0.6156258|                 1.2015972|
| 2001|battle creek |       0|           NA|         NA|    -0.4282888|                -0.7734419|
| 2002|battle creek |       0|           NA|         NA|     0.2018445|                 0.8977450|
| 2003|battle creek |       1|           NA| -0.7069247|     0.1961676|                 3.0247102|
| 2004|battle creek |       0|           NA| -0.7400252|    -0.5475032|                -0.0138115|

The following plot is of standardized covariates (covariates are colored by type) over time for all tributaries:

![plot of chunk unnamed-chunk-11](figure/unnamed-chunk-11-1.png)

#### Save data object
Data object saved in `SRJPEdata` as `p2s_model_covariates_standard.rds`. To access documentation search `?SRJPEdata::p2s_model_covariates_standard.rds`.


