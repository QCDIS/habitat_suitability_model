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


check_inputs_outputs() {
  local type="$1"  # "inputs" or "outputs"
  echo "Checking $type from JSON file in $(pwd)"
  jq -r ".${type}[].path" "annotation.json" > wrapper_paths.txt
  while read -r path; do
    # Replace '/mnt/' with 'data/' in the path
    path="${path//\/mnt\//data/}"
    echo "Checking path: $path"
    if [ ! -f "$path" ]; then
      echo "Error: $path does not exist."
      exit 1
    fi
  done < wrapper_paths.txt
}

prestage_input_data(){
  jq -r '.outputs[].path' "annotation.json" > generated_output_paths.txt

  while read -r generated_output_path; do
    local_generated_output_path="${generated_output_path//\/mnt\//data/}"
    echo "Looking for usage of output path: $generated_output_path"
    for wrapper_path in "${wrapper_paths[@]}"
    do
      jq -r '.inputs[].path' "../$wrapper_path/annotation.json" > requsted_input_paths.txt
      while read -r requsted_input_path; do
        generated_output_file_name=$(basename "$generated_output_path")
        requsted_input_file_name=$(basename "$requsted_input_path")
        echo "Checking if $generated_output_file_name is used in $wrapper_path $requsted_input_file_name"
        if [[ "$generated_output_file_name" == "$requsted_input_file_name" ]]; then
          dest_dir="${requsted_input_path//\/mnt\//data/}"
          echo "Copying $local_generated_output_path to ../$wrapper_path/$dest_dir"
          cp "$local_generated_output_path" "../$wrapper_path/$dest_dir"
        fi
      done < requsted_input_paths.txt
    done
  done < generated_output_paths.txt
}


#for i in "${wrapper_paths[@]}"
#do
#	echo $i
#	sudo rm -rf data/inputs/* data/outputs/*
#done

for wrapper_path in "${wrapper_paths[@]}"
do
  echo "---------------------------Running pipeline step: ${wrapper_path}----------------------------"
  cd "$wrapper_path"
  check_inputs_outputs "inputs"
#  ${dev_kit_dir}/bin/build-image && ${dev_kit_dir}/bin/execute
  check_inputs_outputs "outputs"
  prestage_input_data
  cd ${base_dir}
done

echo "---------------------------Pipeline completed successfully----------------------------"

