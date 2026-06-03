filter_params <- list(
  "battle creek" = list(
    list(site = "lbc", subsite = "lbc", start_date = as.Date("1998-10-08"), end_date = as.Date("2016-03-12")),
    list(site = "ubc", subsite = "ubc", start_date = as.Date("1998-08-31"), end_date = as.Date("2022-09-30")),
    list(site = NA, subsite = NA, start_date = as.Date("2005-10-16"), end_date = as.Date("2006-10-06"))
  ),
  "butte creek" = list(
    list(site = "okie dam", subsite = "okie dam fyke trap", start_date = as.Date("1995-12-01"), end_date = as.Date("2022-06-30")),
    list(site = "adams dam", subsite = "adams dam", start_date = as.Date("1997-01-18"), end_date = as.Date("1998-05-09")),
    list(site = "okie dam", subsite = "okie dam 1", start_date = as.Date("1995-12-01"), end_date = as.Date("2015-11-02")),
    list(site = "okie dam", subsite = "okie dam 2", start_date = as.Date("2004-01-15"), end_date = as.Date("2008-03-24")),
    list(site = "okie dam", subsite = "okie dam fyke trap", start_date = as.Date("1995-12-01"), end_date = as.Date("2015-11-02")),
    list(site = "okie dam", subsite = NA, start_date = as.Date("1995-12-06"), end_date = as.Date("2007-01-14"))
  ),
  "clear creek" = list(
    list(site = "lcc", subsite = "lcc", start_date = as.Date("1998-12-06"), end_date = as.Date("2022-06-30")),
    list(site = "ucc", subsite = "ucc", start_date = as.Date("2003-10-14"), end_date = as.Date("2022-06-30"))
  ),
  "deer creek" = list(
    list(site = "deer creek", subsite = "deer creek", start_date = as.Date("1992-10-14"), end_date = as.Date("2023-06-20"))
  ),
  "mill creek" = list(
    list(site = "mill creek", subsite = "mill creek", start_date = as.Date("1995-12-09"), end_date = as.Date("2023-12-13"))
  ),
  "sacramento river" = list(
    list(site = "knights landing", subsite = "8.3", start_date = as.Date("1995-12-18"), end_date = as.Date("2003-11-26")),
    list(site = "knights landing", subsite = "8.4", start_date = as.Date("1995-11-21"), end_date = as.Date("2003-11-26")),
    list(site = "knights landing", subsite = "knights landing", start_date = as.Date("2000-10-06"), end_date = as.Date("2006-06-30")),
    list(site = "red bluff diversion dam", subsite = "gate 1", start_date = as.Date("1994-08-19"), end_date = as.Date("2024-01-30")),
    list(site = "red bluff diversion dam", subsite = "gate 10", start_date = as.Date("1994-08-29"), end_date = as.Date("2011-08-28")),
    list(site = "red bluff diversion dam", subsite = "gate 11", start_date = as.Date("1994-07-18"), end_date = as.Date("2011-08-28")),
    list(site = "red bluff diversion dam", subsite = "gate 2", start_date = as.Date("1995-01-25"), end_date = as.Date("2019-04-17")),
    list(site = "red bluff diversion dam", subsite = "gate 3", start_date = as.Date("1994-10-18"), end_date = as.Date("2019-04-17")),
    list(site = "red bluff diversion dam", subsite = "gate 4", start_date = as.Date("1995-10-31"), end_date = as.Date("2016-03-23")),
    list(site = "red bluff diversion dam", subsite = "gate 5", start_date = as.Date("1994-09-22"), end_date = as.Date("2024-01-30")),
    list(site = "red bluff diversion dam", subsite = "gate 5 w", start_date = as.Date("2002-06-03"), end_date = as.Date("2002-09-11")),
    list(site = "red bluff diversion dam", subsite = "gate 6", start_date = as.Date("1999-10-18"), end_date = as.Date("2024-01-30")),
    list(site = "red bluff diversion dam", subsite = "gate 6 e", start_date = as.Date("2002-06-04"), end_date = as.Date("2002-09-11")),
    list(site = "red bluff diversion dam", subsite = "gate 6 w", start_date = as.Date("2002-05-24"), end_date = as.Date("2002-09-11")),
    list(site = "red bluff diversion dam", subsite = "gate 7", start_date = as.Date("1994-10-14"), end_date = as.Date("2024-01-30")),
    list(site = "red bluff diversion dam", subsite = "gate 7 e", start_date = as.Date("2002-05-23"), end_date = as.Date("2002-09-11")),
    list(site = "red bluff diversion dam", subsite = "gate 8", start_date = as.Date("1996-04-16"), end_date = as.Date("2024-01-30")),
    list(site = "red bluff diversion dam", subsite = "gate 9", start_date = as.Date("1994-09-22"), end_date = as.Date("2019-04-17"))
  ),
  "yuba river" = list(
    list(site = "hallwood", subsite = "hal", start_date = as.Date("2000-05-07"), end_date = as.Date("2009-08-07")),
    list(site = "hallwood", subsite = "hal2", start_date = as.Date("2005-04-26"), end_date = as.Date("2009-08-18")),
    list(site = "hallwood", subsite = "hal3", start_date = as.Date("2006-11-18"), end_date = as.Date("2009-08-15")),
    list(site = "yuba river", subsite = "yub", start_date = as.Date("1999-11-25"), end_date = as.Date("2008-05-21"))
  )
)
save(filter_params, file = "filter_params.RData")
