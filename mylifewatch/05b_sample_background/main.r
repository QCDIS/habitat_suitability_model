##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-03-26
# Script Name: ~/habitat_suitability_model/code/05_sample_background.R
# Script Description: Sample the background based on the target-group background
# methodolody.
# SETUP ------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space

path = list(
  setup = "/mnt/inputs/01_setup.json",
  tempsal_filename = "/mnt/inputs/tempsal.nc",
  datasets_selection = "/mnt/inputs/datasets_selection.csv",
  thinned_m_file = "/mnt/inputs/thinned_m.RDS",
  thinned_d_file = "/mnt/inputs/thinned_d.RDS",
  target_group = "/mnt/inputs/target_group.RDS",
  study_area_file = "/mnt/inputs/study_area.RDS",
  pback_month = "/mnt/outputs/pback_month.RDS",
  pback_decade = "/mnt/outputs/pback_decade.RDS",
  thinned_tg_m = "/mnt/outputs/thinned_tg_m.RDS",
  thinned_tg_d = "/mnt/outputs/thinned_tg_d.RDS"
)


##################################################################################
##################################################################################

lapply(list.files("functions", full.names = TRUE),source)

lapply(list.files("/wrp/utils", full.names = TRUE, pattern = "\\.R$"), source)

args = args_parse(commandArgs(trailingOnly = TRUE))


# FUNCTIONS ---------------------------------------------------------------
#download_tg
#sample_background
#connect_eurobis

# INPUT -------------------------------------------------------------------
datasets_selection <- read.csv(file.path(path$datasets_selection))
tempsal <- terra::rast(file.path(path$tempsal_filename))
thinned_m <- readRDS(file.path(path$thinned_m_file))
thinned_d <- readRDS(file.path(path$thinned_d_file))
target_group <- readRDS(file.path(path$target_group))
study_area <- readRDS(path$study_area_file)
# WORKFLOW ----------------------------------------------------------------

# Thinning to one occurrence per pixel
thinned_tg_m <- thin_points(
  data = target_group,
  method = "grid",
  group_col = "month",
  raster_obj = tempsal[[1]],
  trials = 5,
  seed = 1234
)
thinned_tg_m <- thinned_tg_m[[1]]%>%dplyr::select(
  longitude = long,
  latitude = lat,
  occurrence_status,
  month,
  decade
)

thinned_tg_d <- thin_points(
  data = target_group,
  method = "grid",
  group_col = "decade",
  raster_obj = tempsal[[1]],
  trials = 5,
  seed = 1234
)
thinned_tg_d <- thinned_tg_d[[1]]%>%dplyr::select(
  longitude = long,
  latitude = lat,
  occurrence_status,
  month,
  decade
)

# Given a specific subsetting (e.g. monthly) of the presence data, sample a background for every subset
spatial_extent_proj <- st_transform(study_area, crs=25832)
#as.owin needs a projected CRS, not a geographic (latitude-longitude) CRS like WGS84.
#We need to reproject out object to a projected CRS, such as UTM, suitable for the analysis in meters.
#https://epsg.io/25832
win <- as.owin(spatial_extent_proj)
tgb_decade <- sample_background(target_group_data = thinned_tg_d,
                  grouping = "decade",
                  resample_layer = tempsal[[1]],
                  window = win,
                  n_multiplier = 5,
                  presence_data = thinned_d)

tgb_month <- sample_background(target_group_data = thinned_tg_m,
                               grouping = "month",
                               resample_layer = tempsal[[1]],
                               window = win,
                               n_multiplier = 5,
                               presence_data = thinned_m)
# OUTPUT -----------------------------------------------------------------
pback_month <- rbind(thinned_m%>%dplyr::select(-decade), tgb_month) #presence-background data monthly
saveRDS(pback_month, file = file.path(path$pback_month))
pback_decade <- rbind(thinned_d%>%dplyr::select(-month), tgb_decade)
saveRDS(pback_decade, file = file.path(path$pback_decade))
saveRDS(thinned_tg_m, file=file.path(path$thinned_tg_m))
saveRDS(thinned_tg_d, file=file.path(path$thinned_tg_d))



