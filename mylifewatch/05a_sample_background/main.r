##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-03-26
# Script Name: ~/habitat_suitability_model/code/05_sample_background.R
# Script Description: Sample the background based on the target-group background
# methodolody.
# SETUP ------------------------------------

##################################################################################
##################################################################################
path = list(
  setup = "/mnt/inputs/01_setup.json",
  tempsal_filename = "/mnt/inputs/tempsal.nc",
  datasets_selection = "/mnt/inputs/datasets_selection.csv",
  thinned_m_file = "/mnt/inputs/thinned_m.RDS",
  thinned_d_file = "/mnt/inputs/thinned_d.RDS",
  target_group = "/mnt/outputs/target_group.RDS",
  study_area_file = "/mnt/inputs/study_area.RDS",
  temporal_extent = "/mnt/inputs/temporal_extent.RDS"
)
setup <- jsonlite::read_json(path$setup)
aphiaid = as.integer(setup$aphiaid)

lapply(list.files("functions", full.names = TRUE),source)
sapply(list.files(path$code, full.names = T), source)
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
study_area <- readRDS(path$study_area_file)
bbox <- sf::st_bbox(study_area)
temporal_extent <- readRDS(path$temporal_extent)
# WORKFLOW ----------------------------------------------------------------

# Define the list of datasets that passed through the filtering
list_dasid <- datasets_selection$datasetid

# For a given species and lists of datasets, download the full target-group occurrences
print(aphiaid)
print(list_dasid)
print(bbox)
target_group <- download_tg(aphia_id = aphiaid,
                            list_dasid= list_dasid,
                            spatial_extent = bbox,
                            temporal_extent = temporal_extent)

target_group <- clean_presence(target_group, study_area, dataset_selection = datasets_selection)
saveRDS(target_group, file=file.path(path$target_group))