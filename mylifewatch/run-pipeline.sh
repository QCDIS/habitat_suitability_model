#!/bin/bash

base_dir="$(pwd)"
dev_kit_dir="$HOME/workspace/mylifewatch-wrapper-development-kit"

wrapper_paths=("01_setup"
        "02_download_presences"
        "03_download_environment"
        "04_preprocess_presences"
        "05a_sample_background"
        "05b_sample_background"
        "06_extract_environment"
        "07_PAExploration"
        "08_ensemble_decade"
        "09_ensemble_month"
        "10_mapping_predictions"
        "11_static_plot")


check_inputs() {
  echo "Checking inputs from JSON file in $(pwd)"
  local json_file="$1"
  local dest_dir="$2"
  jq -r '.inputs[].path' "$json_file" > inputs_wrapper_paths.txt
  while read -r path; do
    # Replace '/mnt/' with 'data/' in the path
    path="${path//\/mnt\//data/}"
    echo "Checking input path: $path"
    if [ ! -f "$path" ]; then
      echo "Error input: $path does not exist."
      exit -1
    fi
  done < inputs_wrapper_paths.txt
}

prestage_input_data(){
  jq -r '.outputs[].path' "annotation.json" > generated_generated_output_paths.txt
  while read -r generated_output_path; do
    local_generated_output_path="${generated_output_path//\/mnt\//data/}"
    echo "Looking for usage of output path: $generated_output_path"
    for ((i=0; i<${#wrapper_paths[@]}; i++)); do
      wrapper_path="${wrapper_paths[$i]}"
      jq -r '.inputs[].path' "../$wrapper_path/annotation.json" > requsted_input_pathsinput_paths.txt
      while read -r requsted_input_path; do
        generated_output_file_name=$(basename "$generated_output_path")
        requsted_input_file_name=$(basename "$requsted_input_path")
        if [[ "$generated_output_file_name" == "$requsted_input_file_name" ]]; then
          dest_dir="${requsted_input_path//\/mnt\//data/}"
          echo "Copying $local_generated_output_path to ../$wrapper_path/$dest_dir"
          cp "$local_generated_output_path" "../$wrapper_path/$dest_dir"
        fi
      done < requsted_input_pathsinput_paths.txt
    done
  done < generated_generated_output_paths.txt
}


# Celan up the data/inputs and data/outputs directories
for ((i=0; i<${#wrapper_paths[@]}; i++)); do
  sudo rm -rf data/inputs/* data/outputs/*
done

for ((i=0; i<${#wrapper_paths[@]}; i++)); do
  current="${wrapper_paths[$i]}"
  echo "---------------------------Running pipeline step: ${current}----------------------------"
  cd "$current"
  ${dev_kit_dir}/bin/build-image && ${dev_kit_dir}/bin/execute
  check_inputs "annotation.json"
  prestage_input_data
  cd ${base_dir}
done

echo "---------------------------Pipeline completed successfully----------------------------"

