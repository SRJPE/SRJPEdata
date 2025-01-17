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


``` r
# Note this is not the final dataset as lifestage is added below
standard_catch_unmarked_w_yearling <- rst_catch |> 
  filter(species %in% c("chinook", "chinook salmon")) |>  # filter for only chinook
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



|date       |stream           |site                    |subsite |site_group              | count|run    |life_stage |adipose_clipped |dead  | fork_length| weight| julian_week| julian_year|
|:----------|:----------------|:-----------------------|:-------|:-----------------------|-----:|:------|:----------|:---------------|:-----|-----------:|------:|-----------:|-----------:|
|2012-10-18 |sacramento river |red bluff diversion dam |gate 8  |red bluff diversion dam |     1|winter |smolt      |FALSE           |FALSE |          55|     NA|          42|        2012|
|2012-05-19 |sacramento river |red bluff diversion dam |gate 7  |red bluff diversion dam |     1|fall   |smolt      |FALSE           |FALSE |          54|     NA|          21|        2012|
|2012-11-08 |sacramento river |red bluff diversion dam |gate 7  |red bluff diversion dam |     5|winter |fry        |FALSE           |FALSE |          40|     NA|          45|        2012|
|2012-02-29 |sacramento river |red bluff diversion dam |gate 8  |red bluff diversion dam |    31|fall   |fry        |FALSE           |FALSE |          35|     NA|           9|        2012|
|2013-03-06 |sacramento river |red bluff diversion dam |gate 8  |red bluff diversion dam |    14|fall   |fry        |FALSE           |FALSE |          35|     NA|          10|        2013|
|2012-05-24 |sacramento river |red bluff diversion dam |gate 3  |red bluff diversion dam |     1|fall   |smolt      |FALSE           |FALSE |          83|     NA|          21|        2012|
|2012-02-28 |sacramento river |red bluff diversion dam |gate 6  |red bluff diversion dam |     2|fall   |fry        |FALSE           |TRUE  |          37|     NA|           9|        2012|
|2012-03-01 |sacramento river |red bluff diversion dam |gate 8  |red bluff diversion dam |     6|fall   |fry        |FALSE           |FALSE |          31|     NA|           9|        2012|
|2012-05-21 |sacramento river |red bluff diversion dam |gate 6  |red bluff diversion dam |     1|fall   |smolt      |FALSE           |FALSE |          63|     NA|          21|        2012|
|2012-02-13 |sacramento river |red bluff diversion dam |gate 6  |red bluff diversion dam |     1|winter |smolt      |TRUE            |FALSE |          84|     NA|           7|        2012|



### Determine year specific lifestage proportions

There are 68906 entries with missing lifestage due to missing fork length data. 



|date       |stream       |site |subsite |site_group   | count|run  |life_stage |adipose_clipped |dead | fork_length| weight| julian_week| julian_year|
|:----------|:------------|:----|:-------|:------------|-----:|:----|:----------|:---------------|:----|-----------:|------:|-----------:|-----------:|
|2002-03-13 |clear creek  |lcc  |lcc     |clear creek  |     1|fall |NA         |FALSE           |NA   |          NA|      0|          11|        2002|
|2002-01-01 |battle creek |lbc  |lbc     |battle creek |     7|fall |NA         |FALSE           |NA   |          NA|      0|           1|        2002|
|2002-01-01 |battle creek |lbc  |lbc     |battle creek |     3|fall |NA         |FALSE           |NA   |          NA|      0|           1|        2002|
|2002-01-01 |battle creek |lbc  |lbc     |battle creek |     6|fall |NA         |FALSE           |NA   |          NA|      0|           1|        2002|
|2002-01-06 |battle creek |lbc  |lbc     |battle creek |     1|NA   |NA         |FALSE           |NA   |          NA|      0|           1|        2002|
|2002-01-06 |battle creek |lbc  |lbc     |battle creek |     1|NA   |NA         |FALSE           |NA   |          NA|      0|           1|        2002|



The first step in filling in these missing lifestages was to find the proportion for each lifestage category for a given stream, site, week, and year. This information could then be used to fill in the lifestage for missing rows within a week.



| year| week|stream           |site                    | percent_fry| percent_smolt| percent_yearling|
|----:|----:|:----------------|:-----------------------|-----------:|-------------:|----------------:|
| 1992|   42|deer creek       |deer creek              |           0|             0|                1|
| 1992|   44|deer creek       |deer creek              |           0|             0|                1|
| 1992|   45|deer creek       |deer creek              |           0|             0|                1|
| 1992|   46|deer creek       |deer creek              |           0|             0|                1|
| 1992|   47|deer creek       |deer creek              |           0|             0|                1|
| 1992|   48|deer creek       |deer creek              |           0|             0|                1|
| 1992|   49|deer creek       |deer creek              |           0|             0|                1|
| 1994|   29|sacramento river |red bluff diversion dam |           0|             1|                0|
| 1994|   30|sacramento river |red bluff diversion dam |           0|             1|                0|
| 1994|   31|sacramento river |red bluff diversion dam |           0|             1|                0|



### Determine general weekly lifestage proportions

For weeks that had no fork length data in a given week, we calculated a general lifestage proportion across years. Calculating the proportion for each lifestage category for a given stream, site, and week. 



### Apply proportions to fill in missing values

We used these proportions to fill in missing lifestage values. See the final lifestage designations below. 



|date       |stream           |site                    |subsite |site_group              | count|run    |life_stage |adipose_clipped |dead  | fork_length| weight| julian_week| julian_year| week| year|model_lifestage_method   |
|:----------|:----------------|:-----------------------|:-------|:-----------------------|-----:|:------|:----------|:---------------|:-----|-----------:|------:|-----------:|-----------:|----:|----:|:------------------------|
|2012-10-18 |sacramento river |red bluff diversion dam |gate 8  |red bluff diversion dam |     1|winter |smolt      |FALSE           |FALSE |          55|     NA|          42|        2012|   42| 2012|assigned from fl cutoffs |
|2012-05-19 |sacramento river |red bluff diversion dam |gate 7  |red bluff diversion dam |     1|fall   |smolt      |FALSE           |FALSE |          54|     NA|          21|        2012|   21| 2012|assigned from fl cutoffs |
|2012-11-08 |sacramento river |red bluff diversion dam |gate 7  |red bluff diversion dam |     5|winter |fry        |FALSE           |FALSE |          40|     NA|          45|        2012|   45| 2012|assigned from fl cutoffs |
|2012-02-29 |sacramento river |red bluff diversion dam |gate 8  |red bluff diversion dam |    31|fall   |fry        |FALSE           |FALSE |          35|     NA|           9|        2012|    9| 2012|assigned from fl cutoffs |
|2013-03-06 |sacramento river |red bluff diversion dam |gate 8  |red bluff diversion dam |    14|fall   |fry        |FALSE           |FALSE |          35|     NA|          10|        2013|   10| 2013|assigned from fl cutoffs |
|2012-05-24 |sacramento river |red bluff diversion dam |gate 3  |red bluff diversion dam |     1|fall   |smolt      |FALSE           |FALSE |          83|     NA|          21|        2012|   21| 2012|assigned from fl cutoffs |
|2012-02-28 |sacramento river |red bluff diversion dam |gate 6  |red bluff diversion dam |     2|fall   |fry        |FALSE           |TRUE  |          37|     NA|           9|        2012|    9| 2012|assigned from fl cutoffs |
|2012-03-01 |sacramento river |red bluff diversion dam |gate 8  |red bluff diversion dam |     6|fall   |fry        |FALSE           |FALSE |          31|     NA|           9|        2012|    9| 2012|assigned from fl cutoffs |
|2012-05-21 |sacramento river |red bluff diversion dam |gate 6  |red bluff diversion dam |     1|fall   |smolt      |FALSE           |FALSE |          63|     NA|          21|        2012|   21| 2012|assigned from fl cutoffs |
|2012-02-13 |sacramento river |red bluff diversion dam |gate 6  |red bluff diversion dam |     1|winter |smolt      |TRUE            |FALSE |          84|     NA|           7|        2012|    7| 2012|assigned from fl cutoffs |



### Generate rows for when no fish of a lifestage are caught

In order to improve the usability of this dataset (particulary for modeling) we decided to add rows for when a lifestage was not caught. For instance, there may be only fry caught on a particular day and when running the model for smolt that day would not show up in the dataset.



### Review lifestage

The following plot shows the general patten in the lifestage field where fry are caught earlier in the year and smolt are caught later in the year.

**Battle Creek: 2011**

![plot of chunk unnamed-chunk-11](figure/unnamed-chunk-11-1.png)
