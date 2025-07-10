##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-03-19
# Script Name: ~/habitat_suitability_model/code/0_1setup.R
# Script Description: A script to make the general folder structure and load the necessary packages.
# Also load custom functions and the given user inputs.
# SETUP ------------------------------------


##################################################################################
##################################################################################
path = list(
  setup = "/mnt/outputs/01_setup.json",
  study_area_file = "/mnt/outputs/study_area.RDS",
  temporal_extent_file = "/mnt/outputs/temporal_extent.RDS",
  spatial_layers = "/mnt/outputs/spatial_layers"
)


#Check for their existence, create if missing
if(!dir.exists(path$spatial_layers)){
    dir.create(path$spatial_layer,recursive = TRUE)
    cat("Folder created:", path$spatial_layer, "\n")
} else {
    cat("Folder already exists:", path$spatial_layer, "\n")
}




# FUNCTIONS ---------------------------------------------------------------
lapply(list.files("functions", full.names = TRUE),source)
sapply(list.files(path$code, full.names = T), source)
lapply(list.files("/wrp/utils", full.names = TRUE, pattern = "\\.R$"), source)
# INPUT -------------------------------------------------------------------

args = args_parse(commandArgs(trailingOnly = TRUE))
if (length(args) == 0) {
    stop("No arguments provided. Please provide the necessary arguments.")
}


# WORKFLOW ----------------------------------------------------------------

#Define user input choices
study_area <- load_ospar(c("II","III"), filepath = file.path(path$spatial_layers,"ospar_regions_2017_01_002.shp"))
# write   study_area as RDS file
saveRDS(study_area, file = file.path(path$study_area_file))

# Print study_area type
print(paste("Study area type:", class(study_area)))

bbox <- sf::st_bbox(study_area)
print(paste("bbox type:", class(bbox)))
date_start <- as.POSIXct(args$start_date)
date_end <- as.POSIXct(args$end_date)
temporal_extent <- lubridate::interval(date_start,date_end)
saveRDS(temporal_extent, file = file.path(path$temporal_extent_file))
# possible_aphiaids <- c(137117, 137084, 137094, 137111, 137101, 137087)
possible_aphiaids = args$possible_aphiaids
# Convert possible_aphiaids to numeric if they are not already
possible_aphiaids <- as.numeric(unlist(strsplit(possible_aphiaids, ",")))
aphiaid <- possible_aphiaids[1]

#Choosing the bounding box to assess the monthly trend
min_lon <- args$min_lon
max_lon <- args$max_lon
min_lat <- args$min_lat
max_lat <- args$max_lat

# OUTPUT ------------------------------------------------------------------
# Extract and format temporal_extent for JSON


# Save the user inputs as one json file
user_inputs <- list(
  possible_aphiaids = possible_aphiaids,
  aphiaid = aphiaid,
  min_lon = min_lon,
  max_lon = max_lon,
  min_lat = min_lat,
  max_lat = max_lat,
  datadir = datadir,
  mapsdir = mapsdir,
  modeldir = modeldir,
  figdir = figdir,
  envdir = envdir,
  occdir = occdir,
  spatdir = spatdir,
  study_area_file = path$study_area_file
)
jsonlite::write_json(user_inputs, file.path(path$setup), pretty = TRUE)
