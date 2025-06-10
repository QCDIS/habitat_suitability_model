##################################################################################
##################################################################################

# Author: Nowé Jo-Hannes
# Email: johannes.nowe@vliz.be
# Date: 2025-04-01
# Script Name: ~/habitat_suitability_model/code/09_ensemble_month.R
# Script Description: Train the monthly model.
# SETUP ------------------------------------

path = list(
  code = "./code",
  env_month = "/mnt/inputs/env_month.RDS",
  thetao_avg_m = "/mnt/inputs/thetao_avg_m.nc",
  so_avg_m = "/mnt/inputs/so_avg_m.nc",
  npp_avg_m = "/mnt/inputs/npp_avg_m.nc",
  bathy = "/mnt/inputs/bathy.nc",
  modelling_monthly = "/mnt/outputs/modelling_monthly",
  ranger = "/mnt/outputs/modelling_monthly/ranger.RDS",
  randforest = "/mnt/outputs/modelling_monthly/randforest.RDS",
  gam = "/mnt/outputs/modelling_monthly/gam.RDS",
  mars = "/mnt/outputs/modelling_monthly/mars.RDS",
  maxent = "/mnt/outputs/modelling_monthly/maxent.RDS",
  xgb = "/mnt/outputs/modelling_monthly/xgb.RDS",
  stack_data = "/mnt/outputs/modelling_monthly/stack_data.RDS",
  stack_mod = "/mnt/outputs/modelling_monthly/stack_mod.RDS",
  stack_fit = "/mnt/outputs/modelling_monthly/stack_fit.RDS"
)

##################################################################################
##################################################################################


lapply(list.files("functions", full.names = TRUE),source)
sapply(list.files(path$code, full.names = T), source)
lapply(list.files("/wrp/utils", full.names = TRUE, pattern = "\\.R$"), source)

args = args_parse(commandArgs(trailingOnly = TRUE))


# FUNCTIONS ---------------------------------------------------------------
#tidymodels_preparation
#gam_fit
#mars_fit
#maxent_fit
#randforest_fit
#ranger_fit
#xgb_fit
#save_bundle
#knndm_fold

# INPUT -------------------------------------------------------------------
# load(file.path(path$env_month))
env_month <- readRDS(file.path(path$env_month))
thetao_avg_m <- terra::rast(file.path(path$thetao_avg_m))
so_avg_m <- terra::rast(file.path(path$so_avg_m))
npp_avg_m <- terra::rast(file.path(path$npp_avg_m))
bathy <- terra::rast(file.path(path$bathy))
bathy <-resample(bathy, thetao_avg_m)


# WORKFLOW ----------------------------------------------------------------

#Create a folder if it does not exist yet
cat("- Create a folder if it does not exist yet- \n")
ifelse(!dir.exists(file.path(path$modelling_monthly)), dir.create(file.path(path$modelling_monthly)), FALSE)


# Creating folds and preparing data

## Outer fold (stratified 4-fold CV)
### Stratified 4-fold CV based on presence-only
cat("- Outer fold (stratified 4-fold CV)- \n")
pres_month <- env_month[env_month$occurrence_status==1,]
outer_month <- vfold_cv(data = pres_month,
                        v = 4,
                        strata = "month")

### add background points to every fold
cat("- Add background points to every fold -\n")
indices <- list()
for(i in 1:nrow(outer_month)){
  manual_split <- c(outer_month$splits[[i]]$in_id,seq(from = nrow(pres_month)+1, to=nrow(env_month), by=1)) #background points at the end of this dataframe
  indices[[i]] <- list(analysis = as.integer(manual_split),
                       assessment = setdiff(1:nrow(env_month),manual_split)) #test set is presence points not used in a fold
}
splits <- lapply(indices, FUN=make_splits, data = env_month)
outer_month <- manual_rset(splits, c("Fold1", "Fold2","Fold3","Fold4"))

for( i in 1:nrow(outer_month)){
  train_month <- outer_month$splits[[i]]$data[outer_month$splits[[i]]$in_id,]
}

##Inner-fold based on the knndm CAST R package
cat("- Inner-fold based on the knndm CAST R package -\n")
monthly_prep <- tidymodels_prep(train_month)
train_data_m <- monthly_prep$training_data
ctrl_grid_m <- monthly_prep$ctrl_grid
ctrl_res_m <- monthly_prep$ctrl_res
recipe_m <- monthly_prep$recipe

cat("- prediction_layers -\n")
prediction_layers <- terra::sds(thetao_avg_m, so_avg_m, npp_avg_m, bathy)
names(prediction_layers) <- c("thetao", "so", "npp", "bathy")
# Print prediction_layers type
cat("- prediction_layers type -\n")
print(class(prediction_layers))

start_time <- Sys.time()
cat('- Create monthly folds -\n')
samplesize <- as.numeric(args$samplesize)
monthly_folds <- knndm_fold(train_data_m, prediction_layers = prediction_layers, samplesize = samplesize)
cat('- start_time -\n')
print(Sys.time() - start_time)
cat('- Get  inner_month -\n')
inner_month <- monthly_folds$rsample_folds
cat('- Get  monthly_prep -\n')
monthly_prep$folds <- inner_month

# Model training
cat("Model training\n")
plan(multisession, workers = 6) #Use multisession for parallel processing
registerDoFuture()
fitted_ranger <- ranger_fit(folds = inner_month,
                            ensemble_ctrl = ctrl_grid_m,
                            recipe = recipe_m)
#here save output already
cat("Save fitted ranger model\n")
save_bundle(fitted_ranger, file = file.path(path$ranger))
fitted_randforest <- randforest_fit(folds = inner_month,
                                    ensemble_ctrl = ctrl_res_m,
                                    recipe = recipe_m)
cat("Save fitted randforest model\n")
save_bundle(fitted_randforest, file = file.path(path$randforest))
fitted_gam <- gam_fit(folds = inner_month,
                      ensemble_ctrl = ctrl_grid_m,
                      recipe = recipe_m)
cat("Save fitted gam model\n")
save_bundle(fitted_gam, file = file.path(path$gam))
fitted_mars <- mars_fit(folds = inner_month,
                        ensemble_ctrl = ctrl_grid_m,
                        recipe = recipe_m)
cat("Save fitted mars model\n")
save_bundle(fitted_mars, file = file.path(path$mars))
fitted_maxent <- maxent_fit(folds = inner_month,
                            ensemble_ctrl = ctrl_grid_m,
                            recipe = recipe_m)
cat("Save fitted maxent model\n")
save_bundle(fitted_maxent, file = file.path(path$maxent))
fitted_xgb <- xgb_fit(folds = inner_month,
                            ensemble_ctrl = ctrl_grid_m,
                            recipe = recipe_m)
cat("Save fitted xgb model\n")
save_bundle(fitted_xgb, file = file.path(path$xgb))

cat("Return to sequential processing\n")
plan(sequential) #Return to sequential processing
stack_data <-
  stacks() %>%
  add_candidates(fitted_ranger) %>%
  add_candidates(fitted_randforest)%>%
  add_candidates(fitted_gam)%>%
  add_candidates(fitted_mars)%>%
  add_candidates(fitted_maxent)%>%
  add_candidates(fitted_xgb)

stack_data
cat("Save stack data\n")
saveRDS(stack_data, file = file.path(path$stack_data))

cat("Blend predictions\n")
stack_mod <-
  blend_predictions(stack_data, metric= yardstick::metric_set(boyce_cont))
saveRDS(stack_mod, file = file.path(path$stack_mod))

cat("Fit ensemble model\n")
stack_fit <-
  stack_mod %>%
  fit_members()
save_bundle(stack_fit, file = file.path(path$stack_fit))


# OUTPUT ------------------------------------------------------------------
#fitted_ranger
#fitted_randforest
# fitted_gam
# fitted_mars
# fitted_maxent
# fitted_xgb
# stack_data
# stack_mod
# stack_fit

