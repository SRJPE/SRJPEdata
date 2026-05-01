library(shiny)
library(shinythemes)
library(sf)
library(riverdist)
library(readr)
library(readxl)
library(dplyr)
library(leaflet)

# =============================================================================
# LOAD RIVER NETWORK (once, at startup)
# =============================================================================
#  there are two files associated with this analysis 
# 1 data-raw/analysis/riverdist_test.R
# 2 data-raw/helper-tables/cwt_data/streams_shapefile/
CV_rivers1 <- read_rds("data-raw/helper-tables/cwt_data/streams_shapefile/CV_rivers1")
CV_lines   <- st_read(
  "data-raw/helper-tables/cwt_data/streams_shapefile/CV_rivers_projected_WGS84_10N_DCC_closed_HORB_open_bypasses_closed_force_mainstems.shp",
  quiet = TRUE
)

crs_net        <- st_crs(CV_lines)
CV_lines_leaflet <- st_transform(CV_rivers1$sf_current, 4326)

# =============================================================================
# HELPERS
# =============================================================================

snap_to_network <- function(df, rivers, crs_network) {
  sf_pts <- st_as_sf(df, coords = c("Longitude", "Latitude"), crs = 4326)
  coords  <- st_coordinates(st_transform(sf_pts, crs = crs_network))
  snapped <- xy2segvert(x = coords[, "X"], y = coords[, "Y"], rivers = rivers)
  df |> mutate(
    x        = coords[, "X"],
    y        = coords[, "Y"],
    seg      = snapped[, "seg"],
    vert     = snapped[, "vert"],
    snapdist = snapped[, "snapdist"]
  )
}

# Build yellow route polylines between two snapped points (returns list of sf objects)
build_route_lines <- function(from_row, to_row, rivers) {
  connections <- rivers$connections
  lines       <- rivers$lines
  
  startseg <- from_row$seg
  startvert <- from_row$vert
  endseg   <- to_row$seg
  endvert  <- to_row$vert
  
  path <- tryCatch(
    detectroute(start = startseg, end = endseg, rivers = rivers),
    error = function(e) integer(0)
  )
  if (length(path) == 0) return(NULL)
  
  route_sfs <- list()
  
  make_line_sf <- function(coords_matrix) {
    st_transform(
      st_as_sf(as.data.frame(coords_matrix), coords = c("V1", "V2"), crs = crs_net) |>
        summarise(do_union = FALSE) |>
        st_cast("LINESTRING"),
      4326
    )
  }
  
  if (length(path) == 1) {
    min_v <- min(startvert, endvert)
    max_v <- max(startvert, endvert)
    if (min_v != max_v)
      route_sfs[[1]] <- make_line_sf(lines[[path[1]]][min_v:max_v, ])
    return(route_sfs)
  }
  
  # First segment (from start vertex toward next segment)
  if (any(connections[path[1], path[2]] == c(1, 2))) {
    if (startvert != 1)
      route_sfs[[length(route_sfs) + 1]] <- make_line_sf(lines[[path[1]]][1:startvert, ])
  } else {
    linelen <- nrow(lines[[path[1]]])
    if (linelen != startvert)
      route_sfs[[length(route_sfs) + 1]] <- make_line_sf(lines[[path[1]]][linelen:startvert, ])
  }
  
  # Middle segments (full)
  if (length(path) > 2) {
    for (i in path[2:(length(path) - 1)]) {
      route_sfs[[length(route_sfs) + 1]] <- make_line_sf(lines[[i]])
    }
  }
  
  # Last segment (up to end vertex)
  prev_seg <- path[length(path) - 1]
  if (any(connections[prev_seg, endseg] == c(1, 3))) {
    if (endvert != 1)
      route_sfs[[length(route_sfs) + 1]] <- make_line_sf(lines[[endseg]][1:endvert, ])
  } else {
    linelen <- nrow(lines[[endseg]])
    if (linelen != endvert)
      route_sfs[[length(route_sfs) + 1]] <- make_line_sf(lines[[endseg]][linelen:endvert, ])
  }
  
  route_sfs
}

# =============================================================================
# TAB 1 DATA: RST Sites → Destinations
# =============================================================================
# TODO note that the rst distances brom butte rst's are being traces from the bypass, not the main steam 
destinations <- tribble(
  ~locname,                 ~Latitude,  ~Longitude,
  "Delta Entry 1st Bridge", 38.586307, -121.506456,
  "Woodson Bridge release", 39.920099, -122.084473,
  "Butte Bridge",           39.456900, -121.995000,
  "knights landing",        38.802050, -121.698953,
  "tisdale",                39.024694, -121.822356
)

dest_snapped <- snap_to_network(destinations, CV_rivers1, crs_net)

sites_raw <- read_excel(
  "data-raw/helper-tables/cwt_data/rst_distances_rkm.xlsx",
  sheet = "rst_distances_rkm"
) |>
  rename(site_from = site, gis_rkm_distance = rkm_distance) |>
  select(stream, site_from, site_latitude, site_longitude, distance_to, gis_rkm_distance) |>
  rename(Latitude = site_latitude, Longitude = site_longitude)

unique_sites <- sites_raw |>
  distinct(stream, site_from, Latitude, Longitude) |>
  rename(locname = site_from)

sites_snapped <- snap_to_network(unique_sites, CV_rivers1, crs_net)

rst_results <- sites_raw |>
  left_join(
    sites_snapped |> select(stream, locname, seg, vert, snapdist, x, y),
    by = c("stream", "site_from" = "locname")
  ) |>
  left_join(
    dest_snapped |> select(locname, seg, vert, x, y) |>
      rename(dest_seg = seg, dest_vert = vert, dest_x = x, dest_y = y),
    by = c("distance_to" = "locname")
  ) |>
  rowwise() |>
  mutate(
    rkm_riverdist = tryCatch(
      riverdistancetofrom(
        seg1 = seg, vert1 = vert,
        seg2 = dest_seg, vert2 = dest_vert,
        rivers = CV_rivers1, ID1 = site_from
      ) / 1000,
      error = function(e) NA_real_
    )
  ) |>
  ungroup() |>
  mutate(
    difference = rkm_riverdist - gis_rkm_distance,
    abs_diff   = abs(difference),
    pct_diff   = difference / gis_rkm_distance * 100
  )

rst_site_choices <- rst_results |>
  mutate(label = paste0(site_from, " → ", distance_to)) |>
  pull(label)

# =============================================================================
# TAB 2 DATA: Release Locations → Knights Landing (CWT comparison)
# =============================================================================

kl_snapped <- snap_to_network(
  data.frame(locname = "knights_landing", Latitude = 38.802050, Longitude = -121.698953),
  CV_rivers1, crs_net
)

release_pts <- read_csv("data-raw/helper-tables/recapture_locations.csv") |>
  rename(locname = release_location_name,
         Latitude = release_latitude,
         Longitude = release_longitude)

release_snapped <- snap_to_network(release_pts, CV_rivers1, crs_net)

cwt_riverdist <- release_snapped |>
  rowwise() |>
  mutate(
    rkm_riverdist = tryCatch(
      riverdistancetofrom(
        seg1 = seg, vert1 = vert,
        seg2 = kl_snapped$seg, vert2 = kl_snapped$vert,
        rivers = CV_rivers1, ID1 = locname
      ) / 1000,
      error = function(e) NA_real_
    )
  ) |>
  ungroup()

existing_cwt <- read_csv("data-raw/helper-tables/knights_landing_cwt_distances.csv") |> 
  mutate(dist_river_km = dist_along_mi *  1.60934) |> 
  select(-dist_along_mi) 


cwt_comparison <- cwt_riverdist |>
  select(locname, Latitude, Longitude, seg, vert, snapdist, rkm_riverdist) |>
  left_join(existing_cwt, by = c("locname" = "release_location_name")) |>
  filter(!is.na(dist_river_km)) |>
  rename(rkm_existing = dist_river_km) |>
  mutate(
    difference = rkm_riverdist - rkm_existing,
    # abs_diff   = abs(difference),
    pct_diff   = difference / rkm_existing * 100
  ) 


cwt_site_choices <- cwt_comparison$locname

# =============================================================================
# UI
# =============================================================================

ui <- fluidPage(
  theme = shinytheme("united"),
  titlePanel(
    tagList(
      h2("River Kilometer Distance Comparison"),
      h5("riverdist calculations vs. GIS/chainage estimates")
    )
  ),
  
  tabsetPanel(
    
    # ---- TAB 1: RST Sites ----
    tabPanel("RST Sites → Destinations",
             br(),
             fluidRow(
               column(4,
                      selectInput("rst_site", "Select site → destination:",
                                  choices = rst_site_choices, width = "100%"),
                      hr(),
                      tableOutput("rst_single_table"),
                      hr(),
                      h5("All RST results"),
                      tableOutput("rst_full_table")
               ),
               column(8,
                      leafletOutput("rst_map", height = 600)
               )
             )
    ),
    
    # ---- TAB 2: CWT Release → Knights Landing ----
    tabPanel("CWT Releases → Knights Landing",
             br(),
             fluidRow(
               column(4,
                      selectInput("cwt_site", "Select release location:",
                                  choices = cwt_site_choices, width = "100%"),
                      hr(),
                      tableOutput("cwt_single_table"),
                      hr(),
                      h5("All CWT comparison results"),
                      tableOutput("cwt_full_table")
               ),
               column(8,
                      leafletOutput("cwt_map", height = 600)
               )
             )
    )
  )
)

# =============================================================================
# SERVER
# =============================================================================

server <- function(input, output, session) {
  
  # ---- RST: selected row ----
  rst_selected <- reactive({
    req(input$rst_site)
    rst_results |>
      mutate(label = paste0(site_from, " → ", distance_to)) |>
      filter(label == input$rst_site)
  })
  
  # ---- RST: map ----
  output$rst_map <- renderLeaflet({
    row   <- rst_selected()
    dest  <- dest_snapped |> filter(locname == row$distance_to)
    
    route_lines <- build_route_lines(
      from_row = list(seg = row$seg, vert = row$vert),
      to_row   = list(seg = dest$seg, vert = dest$vert),
      rivers   = CV_rivers1
    )
    
    m <- leaflet() |>
      addProviderTiles("Esri.WorldStreetMap", group = "Street Map") |>
      addProviderTiles("Esri.WorldImagery",   group = "Satellite") |>
      addProviderTiles("Esri.WorldShadedRelief", group = "Relief") |>
      addLayersControl(
        baseGroups = c("Street Map", "Satellite", "Relief"),
        options = layersControlOptions(collapsed = FALSE)
      ) |>
      addPolylines(data = CV_lines_leaflet, color = "blue", weight = 1.5, opacity = 0.6)
    
    # Draw route in yellow
    for (seg_line in route_lines) {
      m <- m |> addPolylines(data = seg_line, color = "gold", weight = 4, opacity = 0.9)
    }
    
    # Site marker
    m <- m |>
      addCircleMarkers(
        lng = row$Longitude, lat = row$Latitude,
        label = htmltools::HTML(paste0(
          "<b>", row$site_from, "</b><br>",
          "riverdist: ", round(row$rkm_riverdist, 2), " km<br>",
          "GIS: ", round(row$gis_rkm_distance, 2), " km<br>",
          "Diff: ", round(row$difference, 2), " km<br>",
          "Snap dist: ", round(row$snapdist, 0), " m"
        )),
        labelOptions = labelOptions(permanent = FALSE, direction = "top"),
        radius = 7, color = "red", fillOpacity = 0.9
      ) |>
      # Destination marker
      addCircleMarkers(
        lng = dest$Longitude, lat = dest$Latitude,
        label = dest$locname,
        radius = 7, color = "green", fillOpacity = 0.9
      ) |>
      fitBounds(
        lng1 = min(row$Longitude, dest$Longitude) - 0.05,
        lat1 = min(row$Latitude,  dest$Latitude)  - 0.05,
        lng2 = max(row$Longitude, dest$Longitude) + 0.05,
        lat2 = max(row$Latitude,  dest$Latitude)  + 0.05
      )
    m
  })
  
  # ---- RST: single row summary table ----
  output$rst_single_table <- renderTable({
    rst_selected() |>
      select(stream, site_from, distance_to,
             gis_rkm_distance, rkm_riverdist, difference, pct_diff, snapdist) |>
      rename(
        Stream         = stream,
        Site           = site_from,
        Destination    = distance_to,
        `GIS RKM`      = gis_rkm_distance,
        `riverdist RKM`= rkm_riverdist,
        `Diff (km)`    = difference,
        `Diff (%)`     = pct_diff,
        `Snap dist (m)`= snapdist
      )
  }, digits = 2)
  
  # ---- RST: full results table ----
  output$rst_full_table <- renderTable({
    rst_results |>
      select(stream, site_from, distance_to,
             gis_rkm_distance, rkm_riverdist, difference, snapdist) |>
      arrange(desc(abs(difference)))
  }, digits = 2)
  
  # ---- CWT: selected row ----
  cwt_selected <- reactive({
    req(input$cwt_site)
    cwt_comparison |> filter(locname == input$cwt_site)
  })
  
  # ---- CWT: map ----
  output$cwt_map <- renderLeaflet({
    row <- cwt_selected()
    
    route_lines <- build_route_lines(
      from_row = list(seg = row$seg, vert = row$vert),
      to_row   = list(seg = kl_snapped$seg, vert = kl_snapped$vert),
      rivers   = CV_rivers1
    )
    
    m <- leaflet() |>
      addProviderTiles("Esri.WorldStreetMap", group = "Street Map") |>
      addProviderTiles("Esri.WorldImagery",   group = "Satellite") |>
      addProviderTiles("Esri.WorldShadedRelief", group = "Relief") |>
      addLayersControl(
        baseGroups = c("Street Map", "Satellite", "Relief"),
        options = layersControlOptions(collapsed = FALSE)
      ) |>
      addPolylines(data = CV_lines_leaflet, color = "blue", weight = 1.5, opacity = 0.6)
    
    for (seg_line in route_lines) {
      m <- m |> addPolylines(data = seg_line, color = "gold", weight = 4, opacity = 0.9)
    }
    
    m <- m |>
      addCircleMarkers(
        lng = row$Longitude, lat = row$Latitude,
        label = htmltools::HTML(paste0(
          "<b>", row$locname, "</b><br>",
          "riverdist: ", round(row$rkm_riverdist, 2), " km<br>",
          "Existing: ",  round(row$rkm_existing, 2),  " km<br>",
          "Diff: ",      round(row$difference, 2),    " km<br>",
          "Snap dist: ", round(row$snapdist, 0),       " m"
        )),
        labelOptions = labelOptions(permanent = FALSE, direction = "top"),
        radius = 7, color = "red", fillOpacity = 0.9
      ) |>
      addCircleMarkers(
        lng = kl_snapped$Longitude, lat = kl_snapped$Latitude,
        label = "Knights Landing",
        radius = 7, color = "green", fillOpacity = 0.9
      ) |>
      fitBounds(
        lng1 = min(row$Longitude, kl_snapped$Longitude) - 0.05,
        lat1 = min(row$Latitude,  kl_snapped$Latitude)  - 0.05,
        lng2 = max(row$Longitude, kl_snapped$Longitude) + 0.05,
        lat2 = max(row$Latitude,  kl_snapped$Latitude)  + 0.05
      )
    m
  })
  
  # ---- CWT: single row summary table ----
  output$cwt_single_table <- renderTable({
    cwt_selected() |>
      select(locname, rkm_existing, rkm_riverdist, difference, pct_diff, snapdist) |>
      rename(
        Site            = locname,
        `Existing RKM`  = rkm_existing,
        `riverdist RKM` = rkm_riverdist,
        `Diff (km)`     = difference,
        `Diff (%)`      = pct_diff,
        `Snap dist (m)` = snapdist
      )
  }, digits = 2)
  
  # ---- CWT: full comparison table ----
  output$cwt_full_table <- renderTable({
    cwt_comparison |>
      select(locname, rkm_existing, rkm_riverdist, difference, pct_diff, snapdist) 
  }, digits = 2)
}

shinyApp(ui, server)
