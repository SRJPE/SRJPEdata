library(dplyr)
library(dataRetrieval)
library(lubridate)
library(tidyverse)

# Battle: 11376550
# Butte: 11390000
# Clear: 11372000
# Deer: 11383500
# Feather LFC: 11407000
# Feathe HFC: GRL, CDEC
# Mill: 11381500
# Yuba: 11421000
# Knights Landing: 11390500

gage_ids <- c(
  Battle = "11376550",
  Butte = "11390000",
  Clear = "11372000",
  Deer = "11383500",
  Feather_LFC = "11407000",
  Mill = "11381500",
  Yuba = "11421000",
  Knights_Landing = "11390500"
)

start_date <- format(Sys.Date() - 30*365, "%Y-%m-%d")  # ~30 years ago
end_date <- format(Sys.Date(), "%Y-%m-%d")

flow_list <- lapply(gage_ids, function(site) {
  readNWISdv(siteNumbers = site, parameterCd = "00060",
             startDate = start_date, endDate = end_date)
})

combined_flow <- bind_rows(
  lapply(names(flow_list), function(name) {
    flow_list[[name]] |>
      mutate(
        date = as.Date(Date),
        flow_cfs = X_00060_00003,
        site_name = name,
        month = month(date),
        year = year(date),
        water_year = ifelse(lubridate::month(date) >= 10,
                            lubridate::year(date) + 1,
                            lubridate::year(date))) |>
      select(site_name, date, flow_cfs, month, year, water_year)
  })
)
glimpse(combined_flow)


# separating per stream
battle <- combined_flow |> 
  filter(site_name == "Battle") |> 
  glimpse()

# write.csv(battle, "data-raw/usgs_flow_tables/battle.csv")


# calculating flow exceedence probability

battle_fep <- battle |>
  arrange(desc(flow_cfs)) |>
  mutate(M = row_number(),
         n = n(),  
         exceedance_probability = (M / (n + 1)) * 100) |> 
  glimpse()

ggplot(battle_fep, aes(x = exceedance_probability, y = flow_cfs)) +
  geom_line(color = "blue") +
  scale_y_log10() +
  labs(title = "Annual Flow Exceedence Graph",
       x = "Exceedance Probability (%)",
       y = "Average Daily Flow (cfs)") +
  theme_minimal()
