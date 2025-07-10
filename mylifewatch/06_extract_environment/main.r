##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-03-28
# Script Name: ~/habitat_suitability_model/code/06_extract_environment.R
# Script Description: Script to couple the CMEMS and EMODnet environmental data to
# the presence-background points
# SETUP ------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
library(terra)
##################################################################################
##################################################################################

path = list(
  tempsal_filename = "/mnt/inputs/tempsal.nc",
  study_area_file = "/mnt/inputs/study_area.RDS",
  pback_month = "/mnt/inputs/pback_month.RDS",
  pback_decade = "/mnt/inputs/pback_decade.RDS",
  mean_npp = "/mnt/inputs/mean_npp.nc",
  npp_filename = "/mnt/inputs/npp.nc",
  bathy = "/mnt/outputs/bathy.nc",
  bathy_sliced = "/mnt/inputs/bathy_sliced",
  env_month = "/mnt/outputs/env_month.RDS",
  env_decade = "/mnt/outputs/env_decade.RDS",
  thetao_avg_m = "/mnt/outputs/thetao_avg_m.nc",
  so_avg_m = "/mnt/outputs/so_avg_m.nc",
  npp_avg_m = "/mnt/outputs/npp_avg_m.nc",
  thetao_avg_d = "/mnt/outputs/thetao_avg_d.nc",
  so_avg_d = "/mnt/outputs/so_avg_d.nc",
  npp_avg_d = "/mnt/outputs/npp_avg_d.nc"
)

# FUNCTIONS ---------------------------------------------------------------
#couple_env
#determine_tempres
#resample_tempres

# INPUT ------------------------------------------------------------------
lapply(list.files("functions", full.names = TRUE),source)
sapply(list.files(path$code, full.names = T), source)
lapply(list.files("/wrp/utils", full.names = TRUE, pattern = "\\.R$"), source)

args = args_parse(commandArgs(trailingOnly = TRUE))

# load(file.path(datadir,"pback_month.RData"))
pback_month <- readRDS(file.path(path$pback_month))
pback_decade <- readRDS(file.path(path$pback_decade))
# WORKFLOW ----------------------------------------------------------------

#Load in environmental layers

#Load temperature and salinity out of the same object
#Salinity is first and then temperature
tempsal <- terra::rast(file.path(path$tempsal_filename))
layer <- nlyr(tempsal)/2

splitlist <- c(rep(1,layer),rep(2,layer))
tempsal_dataset <- split(tempsal,splitlist)

so <- tempsal_dataset[[1]]
so
thetao <- tempsal_dataset[[2]]
thetao

# We also load NPP, this is daily so we need to take the mean ourselves, or just load the object
if(!file.exists(file.path(path$mean_npp))){
  npp <- terra::rast(file.path(path$npp_filename))
  npp
  timepoints <- time(npp)
  ym_time <- format(timepoints, "%Y-%m")
  ym_time <- factor(ym_time, levels = unique(ym_time), ordered = TRUE)
  splitlist <- as.numeric(ym_time)
  yearmon <- seq(from=timepoints[1],to=timepoints[length(timepoints)],by="months")
  npp_dataset <- split(npp,splitlist)
  npp_dataset
  mean_npp <- list()
  for(i in 1:length(npp_dataset)){
    mean_npp[[i]]<-  terra::app(npp_dataset[[i]],fun=mean)
  }
  mean_npp <-rast(mean_npp)
  terra::time(mean_npp)<- yearmon
  writeCDF(mean_npp,file.path(path$mean_npp))
  cat("Mean npp layer created")
} else {
  cat("Mean npp layer already exists")
  mean_npp <- terra::rast(file.path(path$mean_npp))
  mean_npp <- terra::resample(mean_npp, thetao)
}

# Bathymetry data is a bit different as it is coming from EMODnet
## general data handling
library(XML)
library(dplyr)
library(tidyr)
library(reshape2)
library(downloader)

library(raster)
library(sp)
library(mapdata)
library(maptools)
library(ncdf4)
library(tiff)

if(!file.exists(file.path(path$bathy))){

  ifelse(!dir.exists(file.path(path$bathy_sliced)), dir.create(file.path(path$bathy_sliced)), FALSE)
  #xmin etc are described in 3_1
  stepsize <- 0.8
  study_area <- readRDS(file.path(path$study_area_file))
  bbox <-sf::st_bbox(study_area)
  number_of_slices <- ceiling((bbox[[3]]-bbox[[1]])/stepsize)
  for(i in 1:number_of_slices){
    beginslice <- bbox[[1]] + (i-1)*stepsize
    endslice <- bbox[[1]] + i*stepsize
    #We get an error because the file is too big, will split up in horizontal slices, and then merge together later
    con <-paste0("https://ows.emodnet-bathymetry.eu/wcs?service=wcs&version=1.0.0&request=getcoverage&coverage=emodnet:mean&crs=EPSG:4326&BBOX=",beginslice,",",bbox[[2]],",",endslice,",",bbox[[4]],"&format=image/tiff&interpolation=nearest&resx=0.08333333&resy=0.08333333")
    nomfich <- file.path(path$bathy_sliced,paste0("/","slice_",i, "img_.tiff"))
    download(con, nomfich, quiet = TRUE, mode = "wb")

  }


  #merge them together
  bathyrasters <- list()
  for(file in list.files(file.path(path$bathy_sliced))){
    bathyrasters[[file]] <- terra::rast(file.path(path$bathy_sliced,paste0("/",file)))
  }
  #Put the different spatrasters together in a spatrastercollection
  bathy_coll <- sprc(bathyrasters)

  #Merge the spatrastercollection
  bathy <- merge(bathy_coll)
  bathy[bathy>0] <- NA
  names(bathy) <-"bathy"
  varnames(bathy) <- "bathy"
  bathy <- resample(bathy, tempsal[[1]])
  writeCDF(bathy,file.path(path$bathy))
} else{
  cat("Bathymetry layer already exists")
  bathy <- terra::rast(file.path(path$bathy))
  bathy <- resample(bathy,tempsal[[1]])
}


# Average layers per month ------------------------------------------------

monthly_averages <- resample_tempres(spatrasters = list(thetao, so, mean_npp), average_over="monthly")
thetao_avg_m <- monthly_averages[[1]]
so_avg_m <- monthly_averages[[2]]
npp_avg_m <- monthly_averages[[3]]


# Average layers per decade -----------------------------------------------

decade_averages <- resample_tempres(spatrasters = list(thetao, so, mean_npp), average_over = "decadely")
thetao_avg_d <- decade_averages[[1]]
so_avg_d <- decade_averages[[2]]
npp_avg_d <- decade_averages[[3]]

# Extraction of values related to occurrence points -----------------------

env_month <- couple_env(data = pback_month,
                        thetao_rast = thetao_avg_m,
                        npp_rast = npp_avg_m,
                        so_rast = so_avg_m,
                        bathy_rast = bathy,
                        timescale = "month")

env_decade <- couple_env(data = pback_decade,
                         thetao_rast = thetao_avg_d,
                         npp_rast = npp_avg_d,
                         so_rast = so_avg_d,
                         bathy_rast = bathy,
                         timescale = "decade")

# OUTPUT -------------------------------------------------------------

saveRDS(env_month,file=file.path(path$env_month))
saveRDS(env_decade,file=file.path(path$env_decade))
terra::writeCDF(thetao_avg_m,file.path(path$thetao_avg_m), overwrite=TRUE)
terra::writeCDF(so_avg_m, file = file.path(path$so_avg_m), overwrite = TRUE)
terra::writeCDF(npp_avg_m, file = file.path(path$npp_avg_m), overwrite = TRUE)
terra::writeCDF(thetao_avg_d,file.path(path$thetao_avg_d), overwrite=TRUE)
terra::writeCDF(so_avg_d, file = file.path(path$so_avg_d), overwrite = TRUE)
terra::writeCDF(npp_avg_d, file = file.path(path$npp_avg_d), overwrite = TRUE)