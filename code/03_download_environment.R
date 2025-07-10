##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-03-19
# Script Name: ~/habitat_suitability_model/code/03_download_environment.R
# Script Description: Download the environmental variables from CMEMS using the
# CopernicuMarine toolbox via python.
# SETUP ------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
source("code/01_setup.R")

##################################################################################
##################################################################################


# FUNCTIONS ---------------------------------------------------------------

# INPUT -------------------------------------------------------------------
study_area <- readRDS(file.path(datadir,"study_area.RDS"))
date_start <- as_datetime("1999-01-01")
date_end <- as_datetime("2019-12-31")
# WORKFLOW ----------------------------------------------------------------
# Not surce if we use the python virtualenv
# library(reticulate) #reticulate package allows for python usage in R
# virtualenv_create("mbo-proj",force=FALSE) #create a virtual environment to install packages in
# py_install("copernicusmarine",envname = "mbo-proj") #the copernicusmarine package allows CMEMS downloads
# virtualenv_list() #Check the list of available environments
# use_virtualenv("mbo-proj") #Load the environment

# More information on the reticulate package on: https://rstudio.github.io/cheatsheets/reticulate.pdf
# 
# Overview of the functions can be found at: https://help.marine.copernicus.eu/en/collections/9080063-copernicus-marine-toolbox
# 
# How to configure the credentials can be found at: https://help.marine.copernicus.eu/en/articles/8185007-copernicus-marine-toolbox-credentials-configuration
# Works in the terminal. Needs to be done only once. 

bbox <-sf::st_bbox(study_area)
xmin <- bbox[[1]]
xmax <- bbox[[3]]
ymin <- bbox[[2]]
ymax<- bbox[[4]]


cm <- import("copernicusmarine")
#cm$login()
cm$subset(
  dataset_id="cmems_mod_glo_phy_my_0.083deg_P1M-m",
  variables=c("so", "thetao"),
  minimum_longitude=xmin,
  maximum_longitude=xmax,
  minimum_latitude=ymin,
  maximum_latitude=ymax,
  start_datetime=date_start,
  end_datetime=date_end,
  minimum_depth=0.49402499198913574,
  maximum_depth=0.49402499198913574,
  output_directory= envdir,
  output_filename="tempsal.nc",
  overwrite = TRUE)

cm$subset(
  dataset_id="cmems_mod_glo_bgc_my_0.083deg-lmtl_PT1D-i",
  variables=list("npp"),
  minimum_longitude=xmin,
  maximum_longitude=xmax,
  minimum_latitude=ymin,
  maximum_latitude=ymax,
  start_datetime=date_start,
  end_datetime=date_end,
  minimum_depth=0.5057600140571594,
  maximum_depth=0.5057600140571594,
  output_directory= envdir,
  output_filename="npp.nc",
  overwrite = TRUE)



# OUTPUT ------------------------------------------------------------------
#tempsal.nc
#npp.nc