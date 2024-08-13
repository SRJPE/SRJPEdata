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

<table>
 <thead>
  <tr>
   <th style="text-align:left;"> Stream </th>
   <th style="text-align:right;"> Year </th>
   <th style="text-align:left;"> Exclusion Type </th>
   <th style="text-align:left;"> Notes </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 2003 </td>
   <td style="text-align:left;"> really low sampling </td>
   <td style="text-align:left;"> only a few weeks of data </td>
  </tr>
  <tr>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 2007 </td>
   <td style="text-align:left;"> really low sampling </td>
   <td style="text-align:left;"> only 12 week of data </td>
  </tr>
  <tr>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 2015 </td>
   <td style="text-align:left;"> missing four consecutive weeks in critical window </td>
   <td style="text-align:left;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> butte creek </td>
   <td style="text-align:right;"> 2019 </td>
   <td style="text-align:left;"> really low sampling </td>
   <td style="text-align:left;"> only 10 weeks of data </td>
  </tr>
  <tr>
   <td style="text-align:left;"> butte creek </td>
   <td style="text-align:right;"> 2005 </td>
   <td style="text-align:left;"> really low sampling </td>
   <td style="text-align:left;"> only 6 weeks of data </td>
  </tr>
  <tr>
   <td style="text-align:left;"> butte creek </td>
   <td style="text-align:right;"> 1997 </td>
   <td style="text-align:left;"> missing four consecutive weeks in critical window </td>
   <td style="text-align:left;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> butte creek </td>
   <td style="text-align:right;"> 2006 </td>
   <td style="text-align:left;"> missing four consecutive weeks in critical window </td>
   <td style="text-align:left;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> butte creek </td>
   <td style="text-align:right;"> 1998 </td>
   <td style="text-align:left;"> missing four consecutive weeks in critical window </td>
   <td style="text-align:left;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:right;"> 1993 </td>
   <td style="text-align:left;"> really low sampling </td>
   <td style="text-align:left;"> only 6 weeks of data </td>
  </tr>
  <tr>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:right;"> 1994 </td>
   <td style="text-align:left;"> really low sampling </td>
   <td style="text-align:left;"> only 6 weeks of data </td>
  </tr>
</tbody>
</table>



*... with 20 more rows*


### Applying to Modeling Datasets

In order to apply the years to exclude information to the modeling datasets we did some additional analysis to create a table describing the stream, site, year, min week, and max week that should be included in the SR JPE modeling.

The table below shows a section of this table:

<table>
 <thead>
  <tr>
   <th style="text-align:right;"> monitoring_year </th>
   <th style="text-align:left;"> stream </th>
   <th style="text-align:left;"> site </th>
   <th style="text-align:left;"> subsite </th>
   <th style="text-align:left;"> min_date </th>
   <th style="text-align:right;"> min_week </th>
   <th style="text-align:left;"> max_date </th>
   <th style="text-align:right;"> max_week </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 1994 </td>
   <td style="text-align:left;"> sacramento river </td>
   <td style="text-align:left;"> red bluff diversion dam </td>
   <td style="text-align:left;"> gate 1 </td>
   <td style="text-align:left;"> 1994-08-19 </td>
   <td style="text-align:right;"> 33 </td>
   <td style="text-align:left;"> 1994-08-31 </td>
   <td style="text-align:right;"> 35 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1994 </td>
   <td style="text-align:left;"> sacramento river </td>
   <td style="text-align:left;"> red bluff diversion dam </td>
   <td style="text-align:left;"> gate 10 </td>
   <td style="text-align:left;"> 1994-08-29 </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:left;"> 1994-08-31 </td>
   <td style="text-align:right;"> 35 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1994 </td>
   <td style="text-align:left;"> sacramento river </td>
   <td style="text-align:left;"> red bluff diversion dam </td>
   <td style="text-align:left;"> gate 11 </td>
   <td style="text-align:left;"> 1994-07-18 </td>
   <td style="text-align:right;"> 29 </td>
   <td style="text-align:left;"> 1994-08-24 </td>
   <td style="text-align:right;"> 34 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1995 </td>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:left;"> deer creek </td>
   <td style="text-align:left;"> 1994-10-03 </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> 1995-06-18 </td>
   <td style="text-align:right;"> 25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1995 </td>
   <td style="text-align:left;"> sacramento river </td>
   <td style="text-align:left;"> red bluff diversion dam </td>
   <td style="text-align:left;"> gate 1 </td>
   <td style="text-align:left;"> 1994-09-01 </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:left;"> 1995-08-31 </td>
   <td style="text-align:right;"> 35 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1995 </td>
   <td style="text-align:left;"> sacramento river </td>
   <td style="text-align:left;"> red bluff diversion dam </td>
   <td style="text-align:left;"> gate 10 </td>
   <td style="text-align:left;"> 1994-09-01 </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:left;"> 1995-08-31 </td>
   <td style="text-align:right;"> 35 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1995 </td>
   <td style="text-align:left;"> sacramento river </td>
   <td style="text-align:left;"> red bluff diversion dam </td>
   <td style="text-align:left;"> gate 11 </td>
   <td style="text-align:left;"> 1995-03-03 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:left;"> 1995-08-31 </td>
   <td style="text-align:right;"> 35 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1995 </td>
   <td style="text-align:left;"> sacramento river </td>
   <td style="text-align:left;"> red bluff diversion dam </td>
   <td style="text-align:left;"> gate 2 </td>
   <td style="text-align:left;"> 1995-01-25 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> 1995-05-04 </td>
   <td style="text-align:right;"> 18 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1995 </td>
   <td style="text-align:left;"> sacramento river </td>
   <td style="text-align:left;"> red bluff diversion dam </td>
   <td style="text-align:left;"> gate 3 </td>
   <td style="text-align:left;"> 1994-10-18 </td>
   <td style="text-align:right;"> 42 </td>
   <td style="text-align:left;"> 1995-08-31 </td>
   <td style="text-align:right;"> 35 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1995 </td>
   <td style="text-align:left;"> sacramento river </td>
   <td style="text-align:left;"> red bluff diversion dam </td>
   <td style="text-align:left;"> gate 5 </td>
   <td style="text-align:left;"> 1994-09-22 </td>
   <td style="text-align:right;"> 38 </td>
   <td style="text-align:left;"> 1995-04-27 </td>
   <td style="text-align:right;"> 17 </td>
  </tr>
</tbody>
</table>



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

<table>
 <thead>
  <tr>
   <th style="text-align:left;"> Stream </th>
   <th style="text-align:right;"> Year </th>
   <th style="text-align:left;"> Data Type </th>
   <th style="text-align:left;"> Exclusion Type </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 2018 </td>
   <td style="text-align:left;"> upstream passage </td>
   <td style="text-align:left;"> Missing march/april </td>
  </tr>
  <tr>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 2019 </td>
   <td style="text-align:left;"> upstream passage </td>
   <td style="text-align:left;"> Missing march/april </td>
  </tr>
  <tr>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 2023 </td>
   <td style="text-align:left;"> upstream passage </td>
   <td style="text-align:left;"> Over a third of the year the weir was open due to high flows, data was deemed to be too poor to verify and enter in master database at this time. </td>
  </tr>
  <tr>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:left;"> carcass </td>
   <td style="text-align:left;"> Missing 50% or more of reach coverage </td>
  </tr>
  <tr>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 2008 </td>
   <td style="text-align:left;"> carcass </td>
   <td style="text-align:left;"> Missing 50% or more of reach coverage </td>
  </tr>
  <tr>
   <td style="text-align:left;"> battle creek </td>
   <td style="text-align:right;"> 2019 </td>
   <td style="text-align:left;"> carcass </td>
   <td style="text-align:left;"> Missing 50% or more of reach coverage </td>
  </tr>
  <tr>
   <td style="text-align:left;"> butte creek </td>
   <td style="text-align:right;"> 2015 </td>
   <td style="text-align:left;"> carcass </td>
   <td style="text-align:left;"> Very limited coverage on D-E reaches </td>
  </tr>
  <tr>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 2011 </td>
   <td style="text-align:left;"> carcass </td>
   <td style="text-align:left;"> Missing reach 3, 4, and some of reach 5 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 2016 </td>
   <td style="text-align:left;"> carcass </td>
   <td style="text-align:left;"> Missing reach 1, 3, 4, and some of reach 5 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> clear creek </td>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:left;"> carcass </td>
   <td style="text-align:left;"> Missing reach 1, 2, 4, and some of reach 5 </td>
  </tr>
</tbody>
</table>



*... with 47 more rows*
