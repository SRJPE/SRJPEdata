---
title: "Lifestage Ruleset"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Lifestage Ruleset}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---





## Generate Yearling Rulesets 

Raw catch from the trap does not consistently differentiate between yearling and young of year (YOY) Chinook. FlowWest presented a proposed methodology at a life history diversity (LHD) ruleset workshop (see [lhd shiny](https://flowwest.shinyapps.io/lhd-workshop-shiny/) for workshop materials) and worked with watershed experts to define a methodology to systematically determine life history for each tributary (described below).

**Approach**

1) Set weekly cutoff values: Use visual determination on fork length over time scatter plots to set weekly cutoff values of yearlings vs YOY. 
2) Generate daily cutoff values: Use linear interpolation to extrapolate weekly cutoffs into daily values. 
3) Review & update: Share proposed cutoff values with watershed experts to review. Update as needed. 
4) Apply cutoff to catch data: Use daily cutoff values to generate a yearling column in the catch data. 

### Set Weekly Cutoff Values & Generate daily cutoff values

FlowWest proposed weekly cutoff values and used these weekly cutoff values to generate daily values using a linear approximation function, `approxfun`. 

`generate_cutoff <- approxfun(date, fork_length_cutoff, rule = 2)`

The plot below shows the updated cutoff values with linear interpolation of weekly cutoffs for Deer Creek. 

**Note: You can view all code used to generate plots and tables in this markdown [here.](https://github.com/SRJPE/SRJPEdata/blob/main/vignettes/lifestage_ruleset.Rmd)**

![plot of chunk unnamed-chunk-2](figure/unnamed-chunk-2-1.png)




### Review & Update

FlowWest shared above plot for each watershed and asked stream experts to review. We incorporated feedback and modified rulesets to better separate yearlings and YOY. 

### Apply Cutoff to Catch Data

FlowWest took the daily cutoff line (shown in plot above) and used it as a threshold to classify yearling vs YOY in historical catch data. We added an `is_yearling` column to the catch data and set `is_yearling = TRUE` for any fish with a fork length that exceeded the yearling cutoff on a given date. 

The following code is applied in the `weekly_data_summary` script. 


```r
# Note this is not the final dataset as lifestage is added below
standard_catch_unmarked_w_yearling <- rst_catch |> 
  filter(species == "chinook") |>  # filter for only chinook
  mutate(month = month(date), 
         day = day(date)) |> 
  left_join(daily_yearling_ruleset) |> 
  mutate(is_yearling = case_when((fork_length <= cutoff & !run %in% c("fall","late fall", "winter")) ~ F,
                                 (fork_length > cutoff & !run %in% c("fall","late fall", "winter")) ~ T,
                                 (run %in% c("fall","late fall", "winter")) ~ NA,
                                 T ~ NA)) 
```


## Fry and Smolt Designations

In addition to differentiating between yearling and YOY it is important for the SR JPE to differentiate between fry and smolt as there will likely be a separate SR JPE for each lifestage. Some monitoring programs assign lifestage based on visual determination or fork length though not all RST data included lifestage data. To ensure lifestage was assigned consistently across streams and was complete, FlowWest developed an approach for differentiating between fry and smolt.

**Approach**

1. Create `lifestage` based on forklength cutoff of 45mm (< 45 - fry, > 45 - smolt)
2. Determine year specific proportions for fry, smolt, yearling for each stream, site, week and year
3. Determine general week proportions for fry, smolt, yearling for each stream, week
4. Apply proportions to data to fill in missing lifestage
5. Generate rows for when no fish of a particular lifestage are caught

### Create lifestage variable

The first step was to apply a lifestage cutoff to catch records that had fork lengths recorded. These cutoffs are `fork_length < 45 = fry`, `fork_length > 45 = smolt`, `fork_length > yearling_cutoff = yearling`.

<table>
 <thead>
  <tr>
   <th style="text-align:left;"> date </th>
   <th style="text-align:left;"> stream </th>
   <th style="text-align:left;"> site </th>
   <th style="text-align:left;"> subsite </th>
   <th style="text-align:left;"> site_group </th>
   <th style="text-align:right;"> count </th>
   <th style="text-align:left;"> run </th>
   <th style="text-align:left;"> life_stage </th>
   <th style="text-align:left;"> adipose_clipped </th>
   <th style="text-align:left;"> dead </th>
   <th style="text-align:right;"> fork_length </th>
   <th style="text-align:right;"> weight </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1999-01-19 </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-19 </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 17100 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-20 </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-20 </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 38 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-20 </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 37 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-20 </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 38 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-20 </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 34 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-20 </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 36 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-20 </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 36 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-20 </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 37 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
</tbody>
</table>



### Determine year specific lifestage proportions

There are 44880 entries with missing lifestage due to missing fork length data. 

<table>
 <thead>
  <tr>
   <th style="text-align:left;"> date </th>
   <th style="text-align:left;"> stream </th>
   <th style="text-align:left;"> site </th>
   <th style="text-align:left;"> subsite </th>
   <th style="text-align:left;"> site_group </th>
   <th style="text-align:right;"> count </th>
   <th style="text-align:left;"> run </th>
   <th style="text-align:left;"> life_stage </th>
   <th style="text-align:left;"> adipose_clipped </th>
   <th style="text-align:left;"> dead </th>
   <th style="text-align:right;"> fork_length </th>
   <th style="text-align:right;"> weight </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2002-03-13 </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2002-01-01 </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2002-01-01 </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2002-01-01 </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2002-01-06 </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2002-01-06 </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
</tbody>
</table>



The first step in filling in these missing lifestages was to find the proportion for each lifestage category for a given stream, site, week, and year. This information could then be used to fill in the lifestage for missing rows within a week.

<table>
 <thead>
  <tr>
   <th style="text-align:right;"> year </th>
   <th style="text-align:right;"> week </th>
   <th style="text-align:left;"> stream </th>
   <th style="text-align:left;"> site </th>
   <th style="text-align:right;"> percent_fry </th>
   <th style="text-align:right;"> percent_smolt </th>
   <th style="text-align:right;"> percent_yearling </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 1992 </td>
   <td style="text-align:right;"> 42 </td>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:right;"> 0.0 </td>
   <td style="text-align:right;"> 0.0 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1992 </td>
   <td style="text-align:right;"> 44 </td>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:right;"> 0.0 </td>
   <td style="text-align:right;"> 0.0 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1992 </td>
   <td style="text-align:right;"> 45 </td>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:right;"> 0.0 </td>
   <td style="text-align:right;"> 0.0 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1992 </td>
   <td style="text-align:right;"> 46 </td>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:right;"> 0.0 </td>
   <td style="text-align:right;"> 0.0 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1992 </td>
   <td style="text-align:right;"> 48 </td>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:right;"> 0.0 </td>
   <td style="text-align:right;"> 0.0 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1992 </td>
   <td style="text-align:right;"> 49 </td>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:right;"> 0.0 </td>
   <td style="text-align:right;"> 0.0 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1994 </td>
   <td style="text-align:right;"> 29 </td>
   <td style="text-align:left;"> sacramento river </td>
   <td style="text-align:left;"> red bluff diversion dam </td>
   <td style="text-align:right;"> 0.0 </td>
   <td style="text-align:right;"> 1.0 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1994 </td>
   <td style="text-align:right;"> 30 </td>
   <td style="text-align:left;"> sacramento river </td>
   <td style="text-align:left;"> red bluff diversion dam </td>
   <td style="text-align:right;"> 0.0 </td>
   <td style="text-align:right;"> 1.0 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1994 </td>
   <td style="text-align:right;"> 31 </td>
   <td style="text-align:left;"> sacramento river </td>
   <td style="text-align:left;"> red bluff diversion dam </td>
   <td style="text-align:right;"> 0.0 </td>
   <td style="text-align:right;"> 1.0 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1994 </td>
   <td style="text-align:right;"> 32 </td>
   <td style="text-align:left;"> sacramento river </td>
   <td style="text-align:left;"> red bluff diversion dam </td>
   <td style="text-align:right;"> 0.1 </td>
   <td style="text-align:right;"> 0.9 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
</tbody>
</table>



### Determine general weekly lifestage proportions

For weeks that had no fork length data in a given week, we calculated a general lifestage proportion across years. Calculating the proportion for each lifestage category for a given stream, site, and week. 



### Apply proportions to fill in missing values

We used these proportions to fill in missing lifestage values. See the final lifestage designations below. 

<table>
 <thead>
  <tr>
   <th style="text-align:left;"> date </th>
   <th style="text-align:left;"> stream </th>
   <th style="text-align:left;"> site </th>
   <th style="text-align:left;"> subsite </th>
   <th style="text-align:left;"> site_group </th>
   <th style="text-align:right;"> count </th>
   <th style="text-align:left;"> run </th>
   <th style="text-align:left;"> life_stage </th>
   <th style="text-align:left;"> adipose_clipped </th>
   <th style="text-align:left;"> dead </th>
   <th style="text-align:right;"> fork_length </th>
   <th style="text-align:right;"> weight </th>
   <th style="text-align:right;"> week </th>
   <th style="text-align:right;"> year </th>
   <th style="text-align:left;"> model_lifestage_method </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1999-01-19 </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 1999 </td>
   <td style="text-align:left;"> assigned from fl cutoffs </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-19 </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 17100 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 1999 </td>
   <td style="text-align:left;"> assigned from fl cutoffs </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-20 </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 1999 </td>
   <td style="text-align:left;"> assigned from fl cutoffs </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-20 </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 38 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 1999 </td>
   <td style="text-align:left;"> assigned from fl cutoffs </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-20 </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 37 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 1999 </td>
   <td style="text-align:left;"> assigned from fl cutoffs </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-20 </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 38 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 1999 </td>
   <td style="text-align:left;"> assigned from fl cutoffs </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-20 </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 34 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 1999 </td>
   <td style="text-align:left;"> assigned from fl cutoffs </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-20 </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> lcc </td>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 36 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 1999 </td>
   <td style="text-align:left;"> assigned from fl cutoffs </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-20 </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 36 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 1999 </td>
   <td style="text-align:left;"> assigned from fl cutoffs </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1999-01-20 </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> lbc </td>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> fall </td>
   <td style="text-align:left;"> fry </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 37 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 1999 </td>
   <td style="text-align:left;"> assigned from fl cutoffs </td>
  </tr>
</tbody>
</table>



### Generate rows for when no fish of a lifestage are caught

In order to improve the usability of this dataset (particulary for modeling) we decided to add rows for when a lifestage was not caught. For instance, there may be only fry caught on a particular day and when running the model for smolt that day would not show up in the dataset.



### Review lifestage

The following plot shows the general patten in the lifestage field where fry are caught earlier in the year and smolt are caught later in the year.

**Battle Creek: 2011**

![plot of chunk unnamed-chunk-11](figure/unnamed-chunk-11-1.png)

## Save resulting data to package


