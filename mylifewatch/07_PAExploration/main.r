##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-03-28
# Script Name: ~/habitat_suitability_model/code/07_PAExploration.R
# Script Description: Make plots to assess the input data of the model
# SETUP ------------------------------------
cat("\014")                 # Clears the console
rm(list = ls())             # Remove all variables of the work space
path = list(
  setup = "/mnt/inputs/01_setup.json",
  cleaned_data = "/mnt/inputs/cleaned_data.RDS",
  study_area_file = "/mnt/inputs/study_area.RDS"
)

##################################################################################
##################################################################################


# FUNCTIONS ---------------------------------------------------------------
#plot_spatial

lapply(list.files("functions", full.names = TRUE),source)

lapply(list.files("/wrp/utils", full.names = TRUE, pattern = "\\.R$"), source)

args = args_parse(commandArgs(trailingOnly = TRUE))


setup <- jsonlite::read_json(path$setup)

# INPUT -------------------------------------------------------------------
cleaned_data <- readRDS(file.path(path$cleaned_data))
aphiaid = as.integer(setup$aphiaid)

# Create dir '/mnt/outputs/png/' if it does not exist
figdir <- "/mnt/outputs/png"
if (!dir.exists(figdir)) {
  dir.create(figdir, recursive = TRUE)
}

# Append to path list the output directory
path <- append(path, list("/mnt/outputs/png/spatial_decade",aphiaid,".png"))
path <- append(path, list("/mnt/outputs/png/temporal_decade",aphiaid,".png"))
path <- append(path, list("/mnt/outputs/png/spatial_month",aphiaid,".png"))
path <- append(path, list("/mnt/outputs/png/temporal_month",aphiaid,".png"))


study_area <- readRDS(file.path(path$study_area_file))
bbox <-sf::st_bbox(study_area)

# WORKFLOW ----------------------------------------------------------------

spatial_decade <- plot_spatial(study_area, presence_data = cleaned_data, timescale= "decade", bbox)

temporal_decade <- ggplot(data = cleaned_data, aes(x = decade)) +
  stat_count()+
  theme(plot.title = element_text(size=14), axis.title= element_text(size = 12),
        text = element_text(size = 12))+
  labs(title = paste("decadal occurrence records AphiaID",aphiaid))

spatial_month <- plot_spatial(study_area, presence_data = cleaned_data, timescale= "month", bbox)

temporal_month <- ggplot(data = cleaned_data, aes(x = as.factor(month))) +
  stat_count()+
  theme(plot.title = element_text(size=14), axis.title= element_text(size = 12),
        text = element_text(size = 12))+
  labs(title = paste("monthly occurrence records AphiaID",aphiaid))


# OUTPUT ------------------------------------------------------------------

ggsave(filename = paste0("spatial_decade",aphiaid,".png"), plot = spatial_decade, path = figdir, width = 6, height = 4, dpi = 300)
ggsave(filename = paste0("temporal_decade",aphiaid,".png"), plot = temporal_decade, path = figdir, width = 6, height = 4, dpi = 300)
ggsave(filename = paste0("spatial_month",aphiaid,".png"), plot = spatial_month, path = figdir, width = 6, height = 4, dpi = 300)
ggsave(filename = paste0("temporal_month",aphiaid,".png"), plot = temporal_month, path = figdir, width = 6, height = 4, dpi = 300)

