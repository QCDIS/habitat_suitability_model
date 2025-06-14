download_tg <- function(aphia_id, list_dasid, spatial_extent, temporal_extent){
  
  #Define target species and target-group
  species <- worrms::wm_id2name(aphia_id)
  #name2id also works, can provide the option to choose
  classification <- worrms::wm_classification(aphia_id) 
  class <- which(classification[,2]=="Class")
  target_group <- classification[[class,3]]
  
  #Connect to eurobis database
  cat("Connecting to Eurobis...\n")
  eurobis <- connect_eurobis()
  cat("Connected to Eurobis\n")
  
  #Generate a list of all the distinct aphiaids over the datasets
  cat("Creating list of aphiaids...\n")
  aphiaid_list <- eurobis %>%
    filter(datasetid %in% list_dasid,
           longitude > spatial_extent[1], longitude < spatial_extent[3],
           latitude > spatial_extent[2], latitude < spatial_extent[4],
           observationdate >= int_start(temporal_extent),
           observationdate <= int_end(temporal_extent)) %>%
    dplyr::select(aphiaid) %>%
    dplyr::distinct()%>%
    dplyr::filter(!is.na(aphiaid))%>%
    dplyr::collect()
  
  #Check which of the aphiaids belong to the target group (+-5min)
  cat("Create dataframe of aphiaid class information...\n")
  target_aphiaids <- worrms::wm_classification_(aphiaid_list[[1]])%>%
    dplyr::filter(rank == "Class",
                  scientificname==target_group)%>%
    dplyr::select(aphiaid="id")%>%
    dplyr::mutate(aphiaid=as.numeric(aphiaid))

  #Download target group points from EurOBIS
  cat("Download Eurobis data...\n")
  eurobis <- connect_eurobis()
  target_group_occurrences <- eurobis %>%
    dplyr::filter(datasetid %in% list_dasid,
           aphiaidaccepted %in% target_aphiaids$aphiaid,
           longitude > spatial_extent[1], longitude < spatial_extent[3],
           latitude > spatial_extent[2], latitude < spatial_extent[4],
           observationdate >= int_start(temporal_extent),
           observationdate <= int_end(temporal_extent)) %>%
    dplyr::select(datasetid,
                  latitude,
                  longitude,
                  time=observationdate,
                  scientific_name = scientificname_accepted,
                  occurrence_id = occurrenceid) %>%
    dplyr::collect()
  
  return(target_group_occurrences)
}