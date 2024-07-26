library(tidyverse)
library(CDECRetrieve)
library(dataRetrieval)

# the purpose of this code is to figure out the minimum dates of all salmon data
# for each site, and use this as a reference of the starting date to pull environmental data

#checking for date ranges

## Battle Creek ----

#rst_catch

battle_catch <- rst_catch |> 
  filter(stream == "battle creek") |> 
  glimpse()

range(battle_catch$date)
#"1998-08-31" "2022-09-30"

#no battle in carcass_estimate

#holding
battle_holding <- holding |> 
  filter(stream == "battle creek") |> 
  glimpse()

range(battle_holding$date) #"2001-07-19" "2019-10-18"

#redd
battle_redd <- redd |> 
  filter(stream == "battle creek") |> 
  glimpse()

range(redd$date) # "1997-10-01" "2023-10-01"

#upstream_passage_estimates
battle_upstream_estimates <- upstream_passage_estimates |> 
  filter(stream == "battle creek") |> 
  glimpse()

range(battle_upstream_estimates$year) #1995 2021


### Clear Creek ---- 

#rst_catch
clear_catch <- rst_catch |> 
  filter(stream == "clear creek") |> 
  glimpse()

range(clear_catch$date) # "1998-12-06" "2022-06-30"

#no Clear Creek in carcass_estimate

#holding
clear_holding <- holding |> 
  filter(stream == "clear creek") |> 
  glimpse()

range(clear_holding$date) # "2008-06-02" "2019-10-10"

#redd
clear_redd <- redd |> 
  filter(stream == "clear creek") |> 
  glimpse()

range(clear_redd$date) # "2000-09-25" "2019-10-24"

#upstream_passage_estimates
clear_upstream_estimates <- upstream_passage_estimates |> 
  filter(stream == "clear creek") |> 
  glimpse()

range(clear_upstream_estimates$year) # 1995 2021


### Deer Creek ----
# salmon data min date is 1986, pull env is 1995 

#rst_catch

deer_catch <- rst_catch |> 
  filter(stream == "deer creek") |> 
  glimpse()

range(deer_catch$date, na.rm = TRUE)
#"1998-08-31" "2022-09-30"

#no deer in carcass_estimate

#holding
deer_holding <- holding |> 
  filter(stream == "deer creek") |> 
  glimpse()

range(deer_holding$date) #"1986-08-01" "2020-08-01"

#no redd for Deer Creek

#upstream_passage_estimates
deer_upstream_estimates <- upstream_passage_estimates |> 
  filter(stream == "deer creek") |> 
  glimpse()

range(deer_upstream_estimates$year) #2014 2020


### Feather River ----

#rst_catch
feather_catch <- rst_catch |> 
  filter(stream == "feather river") |> 
  glimpse()

range(feather_catch$date, na.rm = TRUE) #"1997-12-22" "2022-06-22"

#carcass_estimate
feather_carcass <- carcass_estimates |> 
  filter(stream == "feather river") |> 
  glimpse()

range(feather_carcass$year) #2012 2022

#no holding for Feather River

#redd
feather_redd <- redd |>
  filter(stream == "feather river") |> 
  glimpse()

range(feather_redd$date) #"2009-09-29" "2020-11-20"

#no upstream_passage_estimates for Feather River


### Mill Creek ----

#rst_catch
mill_catch <- rst_catch |> 
  filter(stream == "mill creek") |> 
  glimpse()

range(mill_catch$date, na.rm = TRUE) # "1995-12-09" "2010-06-18"

#no carcass_estimate for Mill Creek 

#no holding for Mill Creek 
mill_upstream_estimates <- upstream_passage_estimates |> 
  filter(stream == "mill creek") |> 
  glimpse()

range(mill_upstream_estimates$year) #2014 2020

#redd
mill_redd <- redd |> 
  filter(stream == "mill creek") |> 
  glimpse()

range(mill_redd$date) # "1997-10-01" "2023-10-01"

#upstream_passage_estimates
mill_upstream_estimates <- upstream_passage_estimates |> 
  filter(stream == "mill creek") |> 
  glimpse()

range(mill_upstream_estimates$year) # 2014 2020


### Sacramento River 

#rst_catch
sac_catch <- rst_catch |> 
  filter(stream == "sacramento river") |> 
  glimpse()

range(sac_catch$date, na.rm = TRUE) # "1994-07-18" "2023-07-31"

#no carcass_estimate for Sacramento River

#no redd for Sacramento River

#no upstream_passage_estimates for Sacramento River


### Yuba River 

#rst_catch
yuba_catch <- rst_catch |> 
  filter(stream == "yuba river") |> 
  glimpse()

range(yuba_catch$date, na.rm = TRUE) # "1999-11-25" "2009-08-18"

#carcass_estimates
yuba_carcass <- carcass_estimates |> 
  filter(stream == "yuba river") |> 
  glimpse()

range(yuba_carcass$year) # 2014 2020


# no holding for Yuba River 

#redd
yuba_redd <- redd |> 
  filter(stream == "yuba river") |> 
  glimpse()

range(yuba_redd$date) # "2011-09-19" "2021-04-20"

#upstream_passage_estimates
yuba_upstream_estimates<- upstream_passage_estimates |> 
  filter(stream == "yuba river") |> 
  glimpse()

range(yuba_upstream_estimates$year) # 2004 2021
