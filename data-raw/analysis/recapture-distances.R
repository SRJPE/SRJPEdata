library(sf)
library(tidyverse)

# This script calculates the river miles for recapture points along the Sacramento River, 
# Battle Creek, and Butte Creek to Knights Landing
# 
# Battle Creek and Butte Creek are calculated by finding the RM distance from pt. to 
# confluence with Sac and confluence to knights landing

# functions ---------------------------------------------------------------
make_main_line <- function(shp, gnis) {
  x <- sf::read_sf(shp) |>
    st_transform(4326) |>
    filter(gnis_name == gnis) |>
    st_zm(drop = TRUE, what = "ZM") |>
    summarise(geometry = st_union(geometry)) |>
    st_cast("MULTILINESTRING") |>
    st_line_merge()
  
  # keep longest if still multi
  if (any(st_geometry_type(x) == "MULTILINESTRING")) {
    parts <- st_cast(x, "LINESTRING")
    x <- parts[which.max(as.numeric(st_length(parts))), ] |> st_as_sf()
  }
  x
}

make_chainage_engine <- function(river_sf, crs_m = 32610, step_m = 50) {
  river_m <- st_transform(river_sf, crs_m) |>
    st_geometry() |>
    st_union() |>
    st_sfc(crs = crs_m) |>
    st_sf()
  
  river_line <- st_geometry(river_m)[[1]]
  
  L <- as.numeric(st_length(river_line))
  n <- max(2, ceiling(L / step_m))
  
  river_pts <- st_line_sample(river_line, n = n, type = "regular") |> st_cast("POINT")
  coords <- st_coordinates(river_pts)
  
  dseg <- sqrt(diff(coords[,1])^2 + diff(coords[,2])^2)
  cumdist <- c(0, cumsum(dseg)) # meters from start
  
  chainage_m <- function(pt_sf_m) {
    xy <- st_coordinates(st_geometry(pt_sf_m)[[1]])[1, ]
    d <- sqrt((coords[,1] - xy[1])^2 + (coords[,2] - xy[2])^2)
    cumdist[which.min(d)]
  }
  
  list(
    crs_m = crs_m,
    river_m = river_m,
    chainage_m = chainage_m
  )
}

dist_from_marker <- function(engine, pts_sf_ll, marker_sf_ll, name_col = NULL) {
  pts_m    <- st_transform(pts_sf_ll, engine$crs_m)
  marker_m <- st_transform(marker_sf_ll, engine$crs_m)
  
  d_marker <- engine$chainage_m(marker_m)
  
  d_pts <- vapply(seq_len(nrow(pts_m)), function(i) engine$chainage_m(pts_m[i, ]), numeric(1))
  dist_mi <- abs(d_pts - d_marker) / 1609.344
  
  out <- data.frame(dist_along_mi = dist_mi)
  
  if (!is.null(name_col) && name_col %in% names(pts_sf_ll)) {
    out[[name_col]] <- pts_sf_ll[[name_col]]
    out <- out[, c(name_col, "dist_along_mi")]
  }
  out
}

# constants ---------------------------------------------------------------
recapture_locations <- read_csv("data-raw/helper-tables/recapture_locations.csv")

crs_m  <- 32610
step_m <- 50

knights_landing <- st_sfc(st_point(c(-121.704, 38.8021)), crs = 4326) |> st_sf(name="Knights Landing")

butte_creek_sac_conf  <- st_sfc(st_point(c(-121.936410, 39.195019)), crs = 4326) |> 
  st_sf(name="Butte Creek Conf. with Sac")
battle_creek_sac_conf <- st_sfc(st_point(c(-122.175151, 40.355493)), crs = 4326) |> 
  st_sf(name="Battle Creek Conf. with Sac")


# rivers ------------------------------------------------------------------
shp <- "../jpe-map-shiny/data-raw/hydrology/nhd_major_rivers_creeks_cv.shp"

sac_river    <- make_main_line(shp, "Sacramento River")
butte_creek  <- make_main_line(shp, "Butte Creek")
battle_creek <- make_main_line(shp, "Battle Creek")


# Sacramento  -------------------------------------------------------------

sac_recapture_pts <- recapture_locations |>
  filter(!(release_location_name %in% c(
    "COLEMAN NFH", "BATTLE CREEK NFK WILDCAT", "BATTLE CREEK BELOW CNFH",
    "BALDWIN CONST. YARD"
  ))) |>
  mutate(
    geometry = st_sfc(lapply(seq_len(n()), \(i)
                             st_point(c(release_longitude[i], release_latitude[i]))
    ), crs = 4326)
  ) |>
  st_as_sf()

eng_sac <- make_chainage_engine(sac_river, crs_m = crs_m, step_m = step_m)

sac_distances <- dist_from_marker(
  engine = eng_sac,
  pts_sf_ll = sac_recapture_pts,
  marker_sf_ll = knights_landing,
  name_col = "release_location_name"
)


# Butte Creek -------------------------------------------------------------
butte_recapture_pts <- recapture_locations |>
  filter(release_location_name == "BALDWIN CONST. YARD") |>
  mutate(geometry = st_sfc(list(st_point(c(release_longitude[1], release_latitude[1]))), crs = 4326)) |>
  st_as_sf()

eng_butte <- make_chainage_engine(butte_creek, crs_m = crs_m, step_m = step_m)

# release -> butte confluence (ON BUTTE CREEK)
butte_leg1 <- dist_from_marker(eng_butte, butte_recapture_pts, butte_creek_sac_conf)$dist_along_mi[1]

# butte confluence -> knights (ON SACRAMENTO)
butte_leg2 <- dist_from_marker(eng_sac, butte_creek_sac_conf, knights_landing)$dist_along_mi[1]

butte_creek_total <- data.frame(
  release_location_name = "BALDWIN CONST. YARD",
  dist_along_mi = butte_leg1 + butte_leg2
)


# Battle Creek ------------------------------------------------------------

battle_recapture_pts <- recapture_locations |>
  filter(release_location_name %in% c("COLEMAN NFH", "BATTLE CREEK NFK WILDCAT", "BATTLE CREEK BELOW CNFH")) |>
  mutate(
    geometry = st_sfc(lapply(seq_len(n()), \(i)
                             st_point(c(release_longitude[i], release_latitude[i]))
    ), crs = 4326)
  ) |>
  st_as_sf()

eng_battle <- make_chainage_engine(battle_creek, crs_m = crs_m, step_m = step_m)

# each battle release -> battle confluence (ON BATTLE CREEK)
battle_leg1 <- dist_from_marker(
  eng_battle, battle_recapture_pts, battle_creek_sac_conf, name_col = "release_location_name"
) |>
  rename(dist_to_sac = dist_along_mi)

# battle confluence -> knights (ON SACRAMENTO)  ✅ this is where your bug was showing up
battle_leg2 <- dist_from_marker(eng_sac, battle_creek_sac_conf, knights_landing)$dist_along_mi[1]

battle_creek_total <- battle_leg1 |>
  mutate(dist_along_mi = dist_to_sac + battle_leg2) |>
  select(release_location_name, dist_along_mi)


# Combine -----------------------------------------------------------------

all_distances <- bind_rows(
  battle_creek_total,
  butte_creek_total,
  sac_distances
)


write_csv(all_distances, "data-raw/helper-tables/knights_landing_cwt_distances.csv")

# leaflet() |>
#   addTiles() |>
#   addPolylines(data = rivers) |>
#   addCircleMarkers(
#     data = release_pts,
#     lng = ~release_longitude,
#     lat = ~release_latitude,
#     radius = 4
#   ) |>
#   addCircleMarkers(
#     data = knights_landing,
#     radius = 6
#   )


