#! /bin/bash


for f in /mnt/inputs/*.zip; do
  [ -e "$f" ] && echo "Unzipping $f" && unzip -o "$f" -d /mnt/inputs
done

cd /wrp

# Call main.r script with input arguments
Rscript --vanilla main.r "$@"

cd /mnt/outputs
for f in *; do
  [ -f "$f" ] && echo "Zipping $f" && zip "${f%.*}.zip" "$f"
  # If we have a folder zip it
  [ -d "$f" ] && echo "Zipping $f" && zip -r "${f%.*}.zip" "$f"
done

cd /wrp