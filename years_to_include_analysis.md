---
title: "Data to Include In JPE"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{years_to_include_analysis}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---



The Spring Run Juvenile Production Estimate is trained on historical Rotary Screw Trap and Adult Surveys. In order to improve model performance the modeling team worked with the stream teams to filter out data that is too incomplete to use for modeling. This article describes the process for selecting RST years to include and Adult years to include.

# RST Data - Years To Include in Model

The modeling team hosted a modeling windows workshop where we discussed approaches to determining modeling windows. At the workshop we decided to use the full sampling season of data for each tributary and year but to exclude years where we were concerned about data completeness. We came up with the following approach to determine excluded years:

1)  First exclude years with lots of missing data from cumulative catch curves. See `data-raw/years_to_exclude.csv` (exclusion_type = "really low sampling").
2)  Exclude yearlings from cumulative catch curves.
3)  Use updated cumulative catch curves to determine the critical window (average window over all historical years that captures 75 % percent of catch). See [heatmaps in shiny](https://flowwest.shinyapps.io/jpe-rst-workshop-shiny/) to view critical window.
4)  Remove additional years where there is no sampling for 4 consecutive weeks within critical window. See `data-raw/years_to_exclude.csv` (exclusion_type = "missing four consecutive weeks in critical window").

### Cumulative Catch Curves

The cumulative catch curve below shows cumulative catch throughout time for Battle Creek. This plot shows that in 2007 there was only sampling through mid January on Battle Creek. We used simmilar plots on each tributaries to exclude years where there is very limited sampling. See additional [cumulative catch curves in shiny](https://flowwest.shinyapps.io/jpe-rst-workshop-shiny/) for each tributary.


```
#> Error in loadNamespace(name): there is no package called 'webshot'
```

### Heat Map - All Streams

The below heat map shows all streams. It shows that sampling is more complete across traps from 2004 - 2009 and from mid November to July. Some traps have continued sampling throughout the season. Some years there are gaps within season for specific traps or across multiple traps.

See [heatmaps in shiny](https://flowwest.shinyapps.io/jpe-rst-workshop-shiny/) to view additional plots for each stream.


```
#> Error in loadNamespace(name): there is no package called 'webshot'
```

### Years to Exclude

We utilized above cumulative catch curves and heatmaps come up with a list of years to exclude from modeling. See a section of this years to exclude table below.

For ongoing data collection and more recent seasons, we applied an automatic check to determine if a year should be excluded. We use the following criteria to asses if a recent rst season should be excluded from analysis: 

* Missing 4 consecutive weeks in the critical window, OR 
* If 25% of the weeks are missing (this test is used in place of or origional criteria of "exclude years with lots of missing data from cumulative catch curves" )

We check this list against our original method annually after it is run to confirm that it is making the correct exclusion decisions.



|Stream       | Year|Exclusion Type                                    |Notes                    |
|:------------|----:|:-------------------------------------------------|:------------------------|
|battle creek | 2003|really low sampling                               |only a few weeks of data |
|battle creek | 2007|really low sampling                               |only 12 week of data     |
|battle creek | 2015|missing four consecutive weeks in critical window |NA                       |
|butte creek  | 2019|really low sampling                               |only 10 weeks of data    |
|butte creek  | 2005|really low sampling                               |only 6 weeks of data     |
|butte creek  | 1997|missing four consecutive weeks in critical window |NA                       |
|butte creek  | 2006|missing four consecutive weeks in critical window |NA                       |
|butte creek  | 1998|missing four consecutive weeks in critical window |NA                       |
|deer creek   | 1993|really low sampling                               |only 6 weeks of data     |
|deer creek   | 1994|really low sampling                               |only 6 weeks of data     |



*... with 15 more rows*


## Applying to modeling datasets

In order to apply the years to exclude information to the modeling datasets we did some additional analysis to create a table describing the Stream, Site, Year, Min Week, and Max Week that should be included in the SR JPE modeling.

The table below shows a section of this table:



| monitoring_year|stream           |site            |subsite            |min_date   | min_week|max_date   | max_week|
|---------------:|:----------------|:---------------|:------------------|:----------|--------:|:----------|--------:|
|            1995|deer creek       |deer creek      |deer creek         |1994-10-03 |       40|1995-06-18 |       25|
|            1996|butte creek      |okie dam        |okie dam 1         |1995-12-01 |       48|1996-04-29 |       18|
|            1996|butte creek      |okie dam        |okie dam fyke trap |1995-12-01 |       48|1996-04-29 |       18|
|            1996|butte creek      |okie dam        |NA                 |1995-12-06 |       49|1996-04-19 |       16|
|            1996|deer creek       |deer creek      |deer creek         |1995-11-29 |       48|1996-06-24 |       26|
|            1996|mill creek       |mill creek      |mill creek         |1995-12-09 |       49|1996-06-24 |       26|
|            1996|sacramento river |knights landing |8.3                |1995-12-18 |       51|1996-06-28 |       26|
|            1996|sacramento river |knights landing |8.4                |1995-11-21 |       47|1996-06-28 |       26|
|            1997|sacramento river |knights landing |8.3                |1996-09-30 |       40|1997-08-29 |       35|
|            1997|sacramento river |knights landing |8.4                |1996-09-30 |       40|1997-08-29 |       35|



*... with 259 more rows*

# Adult Data - Years To Include in Model

We treated Adult data a little differently to account for the two main types of adult data - adult survey data (holding, redd, carcass) and adult passage data (video passage).

Below are the methods we used for excluding years by adult data type:

**Survey data**

-   Exclude year if survey does not cover core reaches in a year or if less than 50% of reaches are sampled. 

    | Stream         | Core Reaches |
    |----------------|-------------------------------------------------------------------------------------------|
    | Battle Creek   | R1, R2, R3, R4 (R5, R6) |
    | Butte Creek    | A1, B1, C1, D1, E3          |
    | Clear Creek    | R1, R2, R3, R4, R5 (R5A, R5B, R5C) |
    | Deer Creek     | Lower Falls to A line, A line to Wilson Cove, Polk Springs to Murphy Trail, Murphy Trail to Ponderosa Way, Ponderosa Way to Trail 2E17, Trail 2E17 to Dillon Cove, Uper Falls to Potato Patch Camp, Potato Patch Camp to Highway 32 (Red Bridge)         |
    | Feather River  | 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38  |
    | Mill Creek     | Mccarthy Place To Savercool Place, Savercool Place To Black Rock, Black Rock To Below Ranch House, Below Ranch House To Above Avery, Above Avery To Pape Place, Pape Place to Buckhorn Gulch, Buckhorn Gulch To Upper Dam, Above Hwy 36,Hwy 36 To Little Hole In Ground, Hole In Ground To Ishi Trail Head, Ishi Trail Head To Big Bend, Big Bend to Canyon Camp, Canyon Camp To Sooner Place  |
    | Yuba River     | Yuba does not have core reaches with historical survyes, only samples section of river, not appropriate for use in JPE|

**Video data**

-   Exclude year if video out for more than 4 weeks in the sampling season
-   Exclude year if flows exceed a threshold value on each tributary (overpass weir etc..). Threshold determined by monitoring program. 

Additionally we conducted outreach to stream teams to review our list and highlight any other years that should be excluded.

## Video Data

### Cumulative Catch Curves

The cumulative catch curve below shows cumulative upstream passage throughout time for Battle Creek. We used similar plots on each tributaries to exclude years where there is very limited sampling. This plot shows that in 2019 and 2006, upstream passage monitoring started late in the season on Battle Creek. See additional [cumulative catch curves in shiny](https://flowwest.shinyapps.io/jpe-rst-workshop-shiny/) for each tributary.


```
#> Error in loadNamespace(name): there is no package called 'webshot'
```

### Heat Map - All Streams

The below heat map shows all streams. Some video passage systems have continued footage throughout the season. Some years there are gaps within season for specific systems.

See [heatmaps in shiny](https://flowwest.shinyapps.io/jpe-rst-workshop-shiny/) to view additional plots for each stream.


```
#> Error in loadNamespace(name): there is no package called 'webshot'
```

## Survey Data

The below heat map shows battle creek redd survey coverage. It shows decent coverage of redd surveys across reaches and years with some gaps in early years and more gaps post 2015. We excluded years where less than 50% of reaches were sampled. 

See [heatmaps in shiny](https://flowwest.shinyapps.io/jpe-rst-workshop-shiny/) to view additional plots for each stream.

```
#> Error in loadNamespace(name): there is no package called 'webshot'
```

### Years to Exclude

We utilized above cumulative catch curves and heatmaps to come up with a list of years to exclude from modeling for adult data. See a section of this years to exclude table below.



|Stream       | Year|Data Type        |Exclusion Type                                                                                                                                    |
|:------------|----:|:----------------|:-------------------------------------------------------------------------------------------------------------------------------------------------|
|clear creek  | 2018|upstream passage |Missing march/april                                                                                                                               |
|clear creek  | 2019|upstream passage |Missing march/april                                                                                                                               |
|clear creek  | 2023|upstream passage |Over a third of the year the weir was open due to high flows, data was deemed to be too poor to verify and enter in master database at this time. |
|battle creek | 2017|carcass          |Missing 50% or more of reach coverage                                                                                                             |
|battle creek | 2008|carcass          |Missing 50% or more of reach coverage                                                                                                             |
|battle creek | 2019|carcass          |Missing 50% or more of reach coverage                                                                                                             |
|butte creek  | 2015|carcass          |Very limited coverage on D-E reaches                                                                                                              |
|clear creek  | 2011|carcass          |Missing reach 3, 4, and some of reach 5                                                                                                           |
|clear creek  | 2016|carcass          |Missing reach 1, 3, 4, and some of reach 5                                                                                                        |
|clear creek  | 2017|carcass          |Missing reach 1, 2, 4, and some of reach 5                                                                                                        |



*... with 47 more rows*