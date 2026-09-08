# Rename Okie Dam site to Butte Creek -----------------------------------------

# Run at end of update_data.R script 

library(dplyr)
library(stringr)

rda_files <- list.files("data", pattern = "\\.rda$", full.names = TRUE)

for (rda_path in rda_files) {
  obj_name <- tools::file_path_sans_ext(basename(rda_path))
  e <- new.env()
  load(rda_path, envir = e)
  obj <- get(obj_name, envir = e)

  if (!is.data.frame(obj) || !any(c("site", "subsite") %in% names(obj))) {
    next
  }

  n_site_renamed <- if ("site" %in% names(obj)) sum(obj$site == "okie dam", na.rm = TRUE) else 0
  n_subsite_renamed <- if ("subsite" %in% names(obj)) sum(str_starts(obj$subsite, "okie dam"), na.rm = TRUE) else 0

  if (n_site_renamed == 0 && n_subsite_renamed == 0) {
    next
  }

  if ("site" %in% names(obj)) {
    obj <- obj |>
      mutate(site = if_else(site == "okie dam", "butte creek", site))
  }
  if ("subsite" %in% names(obj)) {
    obj <- obj |>
      mutate(subsite = str_replace(subsite, "^okie dam", "butte creek"))
  }

  assign(obj_name, obj, envir = e)
  save(list = obj_name, envir = e, file = rda_path, compress = "bzip2", version = 3)

  message(glue::glue(
    "Renamed {n_site_renamed} 'okie dam' site value(s) and ",
    "{n_subsite_renamed} 'okie dam*' subsite value(s) to 'butte creek*' in {obj_name}"
  ))
}
