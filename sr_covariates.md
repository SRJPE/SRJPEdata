---
title: "Stock Recruit Covariates"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Stock Recruit Covariates}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---



There are multiple covariates used in SR JPE modeling that were developed through separate but related processes. There are currently two documents describing covariate selction and processing for different models: (1) Stock Recruit Covariates (this document) and (2) Adult Model Covariates.

The goal of this document is to process covariates for use in SR JPE stock recruitment modeling. 

## Selecting Stock Recruit Environmental Covariates

FlowWest conducted initial literature review and planning to outline covariates that are expected to be important based on past research. This work can be found [here](https://docs.google.com/spreadsheets/d/1Q4VUBE72KdPq0x65y_vUoDMj5dDHp8XwOyDNIyIJKpE/edit#gid=0). FlowWest reviewed covariates with the SR JPE Modeling Advisory Team to generate the following environmental covariates table to test within the SR model. 


*Table 1. Summary of covariates to include in stock recruit modeling based on preliminary literature review.*

<table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; margin-left: auto; margin-right: auto;'>
 <thead>
  <tr>
   <th style="text-align:left;"> Covariate Type </th>
   <th style="text-align:left;"> Structure </th>
   <th style="text-align:left;"> Rationale </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Temperature </td>
   <td style="text-align:left;"> Mean or median degree days </td>
   <td style="text-align:left;"> Influence growth rates of juvenile and affect survival </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Temperature </td>
   <td style="text-align:left;"> Day of year when 7DADM drops below or above 13 C </td>
   <td style="text-align:left;"> Production will be low if there are high water temperatures during the adult holding and spawning periods </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Temperature </td>
   <td style="text-align:left;"> Mean or median maximum weekly stream temperature </td>
   <td style="text-align:left;"> Temperatures above optimal or above a threshold negatively affect fertilization rates and embryo survival </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Temperature </td>
   <td style="text-align:left;"> Emergence date </td>
   <td style="text-align:left;"> Emergence date is correlated with temperature and will influence growth rates and survival </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Temperature </td>
   <td style="text-align:left;"> Degree days (20 threshold) upstream passage to spawning </td>
   <td style="text-align:left;"> Temperature negatively affects adults as they migrate upstream to spawn </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Hatchery </td>
   <td style="text-align:left;"> Proportion of hatchery on spawning grounds </td>
   <td style="text-align:left;"> Hatchery progeny are less fit </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Disaster </td>
   <td style="text-align:left;"> Affected by fire? (0/1) </td>
   <td style="text-align:left;"> Wildfire may have impacts on water quality; after a certain period of time or flow these effects may dissipate. Wildfire may also have negative impacts on habitat in terms of temperature. </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Water year type </td>
   <td style="text-align:left;"> Categorical water year type </td>
   <td style="text-align:left;"> System level impact on number of juveniles </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Streamflow </td>
   <td style="text-align:left;"> Mean precipitation </td>
   <td style="text-align:left;"> Rainfall affects juvenile growth by influencing foraging efficiency or habitat connectivity </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Streamflow </td>
   <td style="text-align:left;"> Maximum monthly precipitation </td>
   <td style="text-align:left;"> High rainfall negatively affects egg survival through streambed scour or sedimentation </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Fecundity </td>
   <td style="text-align:left;"> Adult length </td>
   <td style="text-align:left;"> Important for fecundity </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Thiamine deficiency </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Habitat </td>
   <td style="text-align:left;"> Off channel habitat </td>
   <td style="text-align:left;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Habitat </td>
   <td style="text-align:left;"> Restoration (0/1) </td>
   <td style="text-align:left;"> NA </td>
  </tr>
</tbody>
</table>



## Preparing Covariates 

This document focuses on preparing flow and temperature covariates for use in stock recruit modeling and exploratory analysis. 


### Temperature

Temperature has been found to influence spawning and rearing. Therefore it is expected to affect the translation from stock to recruit. Temperature can be included in multiple different formats which target different lifestages including:

- Number of degree days
- Day of year when 7DADM is above 13 C
- Maximum weekly stream temperature
- *In development: Emergence date (calculated from temperature and spawning date)*



#### Number of degree days

Degree days is defined here as the sum of the daily mean temperatures between August and December (spawning time period) by year and stream. 

*Note that for streams with multiple locations the max daily mean was selected. Clear Creek 2020 value is low which may be due to a few missing data points in December. This approach is vulnerable to missing data.*































