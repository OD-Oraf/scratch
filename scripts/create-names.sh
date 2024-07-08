#!/bin/bash

# Define the size of the file in bytes
size=1048576 # 1MB

# Name of the output file
fname="names.txt"

# Generate random printable strings and append them to the file until it reaches the desired size
while read -r line; do
    echo "${line}" >> "${fname}"
    fsize=$(du -b "${fname}" | awk '{print $1}')
    
    # Check if the file has reached the desired size
    if [ ${fsize} -gt ${size} ]; then
        # Truncate the file to the desired size
        truncate -s "${size}" "${fname}"
        break
    fi
done < /dev/urandom