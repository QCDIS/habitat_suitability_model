#!/bin/bash

base_dir="$(pwd)"
dev_kit_dir="$HOME/workspace/mylifewatch-wrapper-development-kit"

copy_outputs_from_json() {
  local json_file="$1"
  local dest_dir="$2"
  jq -r '.outputs[].path' "$json_file" > output_paths.txt
  while read -r path; do
    path="${path//\/mnt\//data/}"
    if [ ! -f "$path" ]; then
      echo "Error input: $path does not exist."
      exit -1
    else
      echo "Copying output path: $path to $dest_dir"
      cp "$path" "$dest_dir/"
      ls "$dest_dir/"
    fi
  done < output_paths.txt
}

check_inputs() {
  echo "Checking inputs from JSON file in $(pwd)"
  local json_file="$1"
  local dest_dir="$2"
  jq -r '.inputs[].path' "$json_file" > inputs_paths.txt
  while read -r path; do
    # Replace '/mnt/' with 'data/' in the path
    path="${path//\/mnt\//data/}"
    echo "Checking input path: $path"
    if [ ! -f "$path" ]; then
      echo "Error input: $path does not exist."
      exit -1
    fi
  done < inputs_paths.txt
}

paths=("01_setup"
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

# Celan up the data/inputs and data/outputs directories
for ((i=0; i<${#paths[@]}; i++)); do
  sudo rm -rf data/inputs/* data/outputs/*
done

for ((i=0; i<${#paths[@]}; i++)); do
  current="${paths[$i]}"
  echo "---------------------------Running pipeline step: ${current}----------------------------"
  cd "$current"
  ${dev_kit_dir}/bin/build-image && ${dev_kit_dir}/bin/execute
  check_inputs "annotation.json"
  if (( i+1 < ${#paths[@]} )); then
    next_path="${paths[$((i+1))]}"
    copy_outputs_from_json "annotation.json" "../$next_path/data/inputs"
  fi
  cd ${base_dir}
done

