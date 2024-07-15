---
title: "Years to Include"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Years to Include}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---



The Spring Run Juvenile Production Estimate uses historical rotary screw trap and adult survey data. In order to improve model performance the modeling team worked with the stream teams to filter out data that is too incomplete to use for modeling. This article describes the process for selecting RST years to include and adult years to include.

## RST Data - Years to Include in Model

The modeling team hosted a modeling windows workshop where we discussed approaches to defining the time window that should be included in the juvenile abundance model. At the workshop we decided to use the full sampling season of data for each tributary and year but to exclude years where we were concerned about data completeness. We came up with the following approach to determine excluded years:

1)  First exclude years with lots of missing data from cumulative catch curves. See `data-raw/years_to_exclude.csv` (exclusion_type = "really low sampling").
2)  Exclude yearlings from cumulative catch curves.
3)  Use updated cumulative catch curves to determine the critical window (average window over all historical years that captures 75% percent of catch).
4)  Remove additional years where there is no sampling for 4 consecutive weeks within the critical window. See `data-raw/years_to_exclude.csv` (exclusion_type = "missing four consecutive weeks in critical window").

### Cumulative catch curves

The cumulative catch curve below shows cumulative catch over time for Battle Creek. This plot shows that in 2007 there was only sampling through mid January on Battle Creek. We used similar plots for each tributary to exclude years where there is very limited sampling. 


```
#> Error in path.expand(path): invalid 'path' argument
```

### Heat map of all tributaries

The heat map below shows when sampling occurs for all streams. It shows that sampling is more complete across traps from 2004 - 2009 and from mid November to July. Some traps have continued sampling throughout the season. Some years there are gaps within season for specific traps or across multiple traps.


```
#> Error in path.expand(path): invalid 'path' argument
```

### Years to exclude

We utilized the above cumulative catch curves and heatmaps to come up with a list of years to exclude from modeling. See a section of the "years to exclude" table below.

For ongoing data collection and more recent seasons, we applied an automatic check to determine if a year should be excluded. We use the following criteria to asses if a recent RST season should be excluded from analysis: 

* Missing 4 consecutive weeks in the critical window, OR 
* If 25% of the weeks are missing (this test is used in place of the original criteria of "exclude years with lots of missing data from cumulative catch curves")

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


### Applying to Modeling Datasets

In order to apply the years to exclude information to the modeling datasets we did some additional analysis to create a table describing the stream, site, year, min week, and max week that should be included in the SR JPE modeling.

The table below shows a section of this table:



| monitoring_year|stream           |site                    |subsite    |min_date   | min_week|max_date   | max_week|
|---------------:|:----------------|:-----------------------|:----------|:----------|--------:|:----------|--------:|
|            1994|sacramento river |red bluff diversion dam |gate 1     |1994-08-19 |       33|1994-08-31 |       35|
|            1994|sacramento river |red bluff diversion dam |gate 10    |1994-08-29 |       35|1994-08-31 |       35|
|            1994|sacramento river |red bluff diversion dam |gate 11    |1994-07-18 |       29|1994-08-24 |       34|
|            1995|deer creek       |deer creek              |deer creek |1994-10-03 |       40|1995-06-18 |       25|
|            1995|sacramento river |red bluff diversion dam |gate 1     |1994-09-01 |       35|1995-08-31 |       35|
|            1995|sacramento river |red bluff diversion dam |gate 10    |1994-09-01 |       35|1995-08-31 |       35|
|            1995|sacramento river |red bluff diversion dam |gate 11    |1995-03-03 |        9|1995-08-31 |       35|
|            1995|sacramento river |red bluff diversion dam |gate 2     |1995-01-25 |        4|1995-05-04 |       18|
|            1995|sacramento river |red bluff diversion dam |gate 3     |1994-10-18 |       42|1995-08-31 |       35|
|            1995|sacramento river |red bluff diversion dam |gate 5     |1994-09-22 |       38|1995-04-27 |       17|



*... with 470 more rows*

## Adult Data - Years to Include in Model

We treated adult data a little differently to account for the two main types of adult data - adult survey data (holding, redd, carcass) and adult passage data (video passage).

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

-   Exclude year if video is out for more than 4 weeks in the sampling season
-   Exclude year if flows exceed a threshold value on each tributary (overpass weir etc..). Threshold determined by monitoring program. 

Additionally we conducted outreach to stream teams to review our list and highlight any other years that should be excluded.

### Video Data

#### Cumulative catch curves

The cumulative catch curve below shows cumulative upstream passage over time for Battle Creek. We used similar plots for each tributary with video data to exclude years where there is very limited sampling. This plot shows that in 2006 and 2019, upstream passage monitoring started late in the season on Battle Creek. 


```
#> Error in path.expand(path): invalid 'path' argument
```

#### Heat map of all tributaries

The heat map below shows when video monitoring occurs for all streams. Some video passage systems have continued footage throughout the season. Some years there are gaps within season for specific systems.


```
#> Error in path.expand(path): invalid 'path' argument
```

### Survey Data

The below heat map shows Battle Creek redd survey coverage. It shows decent coverage of redd surveys across reaches and years with some gaps in early years and more gaps post 2015. We excluded years where less than 50% of reaches were sampled. 


```
#> Error in path.expand(path): invalid 'path' argument
```

### Years to exclude

We utilized above cumulative catch curves and heatmaps to come up with a list of years to exclude from modeling for adult data. See a section of the "years to exclude" table below.



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
