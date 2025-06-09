#! /bin/bash

# Helper function
throwError() { echo "ERROR: $@" 1>&2; exit 1; }

# Check input files
if [ ! -f /mnt/inputs/input.zip ]; then
    throwError "No inputs file found."
fi

# Unzip input files
unzip -q /mnt/inputs/input.zip -d /mnt/inputs/

Rscript --vanilla main.r

# Zip file in the output folder
zip -q -j /mnt/outputs/output.zip /mnt/outputs/*