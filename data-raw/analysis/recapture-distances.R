library(sf)

# helper: distance-from-start for a snapped POINT
chainage_m <- function(pt_sf) {
  xy <- st_coordinates(st_geometry(pt_sf)[[1]])[1, ]
  d <- sqrt((coords[,1] - xy[1])^2 + (coords[,2] - xy[2])^2)
  cumdist[which.min(d)]
}

# Constants ---------------------------------------------------------------
recapture_locations <- read_csv("data-raw/helper-tables/recapture_locations.csv")


step_m <- 50
crs_m <- 32610  # UTM 10N

knights_landing <- st_sfc(
  st_point(c(-121.704, 38.8021)),
  crs = 4326
) |>
  st_sf(name = "Knights Landing")

knight_marker <- st_transform(knights_landing, crs_m)

butte_creek_sac_conf <-  st_sfc(
  st_point(c(-121.936410, 39.195019)),
  crs = 4326
) |>
  st_sf(name = "Butte Creek Conf. with Sac")

battle_creek_sac_conf <-  st_sfc(
  st_point(c(-122.175151, 40.355493)),
  crs = 4326
) |>
  st_sf(name = "Battle Creek Conf. with Sac")


# Sacramento River Pts ----------------------------------------------------
sac_river <- sf::read_sf("../jpe-map-shiny/data-raw/hydrology/nhd_major_rivers_creeks_cv.shp") |>
  st_transform(4326) |>
  filter(gnis_name == "Sacramento River") |>
  st_zm(drop = TRUE, what = "ZM") |>
  summarise(geometry = st_union(geometry)) |>      
  st_cast("MULTILINESTRING") |>                    
  st_line_merge()                                  

# If it still results in MULTILINESTRING, keep the longest continuous line
if (any(st_geometry_type(sac_river) == "MULTILINESTRING")) {
  parts <- st_cast(sac_river, "LINESTRING")
  sac_river <- parts[which.max(as.numeric(st_length(parts))), ] |> st_as_sf()
}

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

# --- Project everything ---
river_m  <- st_transform(sac_river, crs_m)
recap_pts <- st_transform(sac_recapture_pts, crs_m)

# --- Dissolve river into single geometry ---
river_m <- river_m |>
  st_geometry() |>
  st_union() |>
  st_sfc(crs = crs_m) |>
  st_sf()

river_line <- st_geometry(river_m)[[1]]

L <- as.numeric(st_length(river_line))
n <- max(2, ceiling(L / step_m))
river_pts <- st_line_sample(river_line, n = n, type = "regular") |> 
  st_cast("POINT")
coords <- st_coordinates(river_pts)
dseg <- sqrt(diff(coords[,1])^2 + diff(coords[,2])^2)
cumdist <- c(0, cumsum(dseg))  # meters from start

d_marker <- chainage_m(knight_marker)

sac_distances <- data.frame()
# --- Loop through ALL recapture points ---
for (i in seq_len(nrow(recap_pts))) {
  
  green_i <- recap_pts[i, ]
  
  d_green <- chainage_m(green_i)
  
  dist_along_m  <- abs(d_green - d_marker)
  dist_along_mi <- dist_along_m / 1609.344
  
  sac_distances <- bind_rows(
    sac_distances,
    data.frame(
      release_location_name = recap_pts$release_location_name[i],  
      dist_along_mi = dist_along_mi
    )
  )
}

sac_distances

# Butte Creek Distances ---------------------------------------------------
butte_creek <- sf::read_sf("../jpe-map-shiny/data-raw/hydrology/nhd_major_rivers_creeks_cv.shp") |>
  st_transform(4326) |>
  filter(gnis_name == "Butte Creek") |>
  st_zm(drop = TRUE, what = "ZM") |>
  summarise(geometry = st_union(geometry)) |>      
  st_cast("MULTILINESTRING") |>                    
  st_line_merge()                                  

# If it still results in MULTILINESTRING, keep the longest continuous line
if (any(st_geometry_type(butte_creek) == "MULTILINESTRING")) {
  parts <- st_cast(butte_creek, "LINESTRING")
  butte_creek <- parts[which.max(as.numeric(st_length(parts))), ] |> st_as_sf()
}

butte_recapture_pts <- recapture_locations |>
  filter(release_location_name == "BALDWIN CONST. YARD") |>
  mutate(
    geometry = st_sfc(lapply(seq_len(n()), \(i)
                             st_point(c(release_longitude[i], release_latitude[i]))
    ), crs = 4326)
  ) |>
  st_as_sf()

# --- Project everything ---
river_m  <- st_transform(butte_creek, crs_m)
recap_pts <- st_transform(butte_recapture_pts, crs_m)

# --- Dissolve river into single geometry ---
river_m <- river_m |>
  st_geometry() |>
  st_union() |>
  st_sfc(crs = crs_m) |>
  st_sf()

river_line <- st_geometry(river_m)[[1]]

# --- Sample river once (important for speed) ---
step_m <- 50
L <- as.numeric(st_length(river_line))
n <- max(2, ceiling(L / step_m))

river_pts <- st_line_sample(river_line, n = n, type = "regular") |> 
  st_cast("POINT")

coords <- st_coordinates(river_pts)

dseg <- sqrt(diff(coords[,1])^2 + diff(coords[,2])^2)
cumdist <- c(0, cumsum(dseg))  # meters from start

# --- Marker chainage (compute once) ---
d_marker <- chainage_m(knight_marker)
conf_marker_butte <- chainage_m(butte_creek_sac_conf)

butte_distances <- data.frame()

# First calculate the distance from butte creek to confluence with Sac 
green_i <- recap_pts
d_green <- chainage_m(green_i)
dist_along_m  <- abs(d_green - conf_marker_butte)
dist_along_mi <- dist_along_m / 1609.344
butte_distances <- bind_rows(
  butte_distances,
  data.frame(
    release_location_name = recap_pts$release_location_name,
    description = "distance from pt to conf. with Sac",
    dist_along_mi = dist_along_mi))

## Now calculate the distance from Butte Creek conf. to Knights landing 
river_m  <- st_transform(sac_river, crs_m)
recap_pts <- st_transform(butte_creek_sac_conf, crs_m)

# --- Dissolve river into single geometry ---
river_m <- river_m |>
  st_geometry() |>
  st_union() |>
  st_sfc(crs = crs_m) |>
  st_sf()

river_line <- st_geometry(river_m)[[1]]

L <- as.numeric(st_length(river_line))
n <- max(2, ceiling(L / step_m))

river_pts <- st_line_sample(river_line, n = n, type = "regular") |> 
  st_cast("POINT")

coords <- st_coordinates(river_pts)

dseg <- sqrt(diff(coords[,1])^2 + diff(coords[,2])^2)
cumdist <- c(0, cumsum(dseg))  # meters from start

d_marker <- chainage_m(knight_marker)

green_i <- recap_pts
d_green <- chainage_m(green_i)
dist_along_m  <- abs(d_green - d_marker)
dist_along_mi <- dist_along_m / 1609.344
butte_distances <- bind_rows(
  butte_distances,
  data.frame(
    release_location_name = recap_pts$name,
    description = "knights landing to conf",
    dist_along_mi = dist_along_mi))

butte_creek_total <- data.frame(
  release_location_name = "BALDWIN CONST. YARD",
  dist_along_mi = sum(butte_distances$dist_along_mi))


# Battle Creek ------------------------------------------------------------
battle_creek <- sf::read_sf("../jpe-map-shiny/data-raw/hydrology/nhd_major_rivers_creeks_cv.shp") |>
  st_transform(4326) |>
  filter(gnis_name == "Battle Creek") |>
  st_zm(drop = TRUE, what = "ZM") |>
  summarise(geometry = st_union(geometry)) |>      
  st_cast("MULTILINESTRING") |>                    
  st_line_merge()                                  

# If it still results in MULTILINESTRING, keep the longest continuous line
if (any(st_geometry_type(battle_creek) == "MULTILINESTRING")) {
  parts <- st_cast(battle_creek, "LINESTRING")
  battle_creek <- parts[which.max(as.numeric(st_length(parts))), ] |> st_as_sf()
}

battle_recapture_pts <- recapture_locations |>
  filter(release_location_name %in% c( "COLEMAN NFH", "BATTLE CREEK NFK WILDCAT", "BATTLE CREEK BELOW CNFH")) |>
  mutate(
    geometry = st_sfc(lapply(seq_len(n()), \(i)
                             st_point(c(release_longitude[i], release_latitude[i]))
    ), crs = 4326)
  ) |>
  st_as_sf()

# --- Project everything ---
river_m  <- st_transform(battle_creek, crs_m)
recap_pts <- st_transform(battle_recapture_pts, crs_m)

# --- Dissolve river into single geometry ---
river_m <- river_m |>
  st_geometry() |>
  st_union() |>
  st_sfc(crs = crs_m) |>
  st_sf()

river_line <- st_geometry(river_m)[[1]]

# --- Sample river once (important for speed) ---
L <- as.numeric(st_length(river_line))
n <- max(2, ceiling(L / step_m))

river_pts <- st_line_sample(river_line, n = n, type = "regular") |> 
  st_cast("POINT")

coords <- st_coordinates(river_pts)

dseg <- sqrt(diff(coords[,1])^2 + diff(coords[,2])^2)
cumdist <- c(0, cumsum(dseg))  # meters from start

# --- Marker chainage (compute once) ---
conf_marker_battle <- chainage_m(battle_creek_sac_conf)

battle_distances <- data.frame()
# First calculate the distance from battle creek to confluence with Sac 
for (i in seq_len(nrow(recap_pts))) {
  green_i <- recap_pts[i, ]
  
  d_green <- chainage_m(green_i)
  
  dist_along_m  <- abs(d_green - conf_marker_battle)
  dist_along_mi <- dist_along_m / 1609.344
  
  battle_distances <- bind_rows(
    battle_distances,
    data.frame(
      release_location_name = recap_pts$release_location_name[i],  
      description = "battle pts to conf with sac",
      dist_to_sac = dist_along_mi
    )
  )
}

## Now calculate the distance from Butte Creek conf. to Knights landing 
river_m  <- st_transform(sac_river, crs_m)
recap_pts <- st_transform(battle_creek_sac_conf, crs_m)

# --- Dissolve river into single geometry ---
river_m <- river_m |>
  st_geometry() |>
  st_union() |>
  st_sfc(crs = crs_m) |>
  st_sf()

river_line <- st_geometry(river_m)[[1]]

L <- as.numeric(st_length(river_line))
n <- max(2, ceiling(L / step_m))

river_pts <- st_line_sample(river_line, n = n, type = "regular") |> 
  st_cast("POINT")

coords <- st_coordinates(river_pts)

dseg <- sqrt(diff(coords[,1])^2 + diff(coords[,2])^2)
cumdist <- c(0, cumsum(dseg))  # meters from start

d_marker <- chainage_m(knight_marker)

green_i <- recap_pts
d_green <- chainage_m(green_i)
dist_along_m  <- abs(d_green - d_marker)
dist_along_mi <- dist_along_m / 1609.344

knight_to_battle_conf <- dist_along_mi

battle_creek_total <- battle_distances |> 
  mutate(dist_along_mi = dist_to_sac + knight_to_battle_conf) |> 
  select(-dist_to_sac, -description)

# final distance dataframe ------------------------------------------------
all_distances <- bind_rows(battle_creek_total, 
                           butte_creek_total,
                           sac_distances)


