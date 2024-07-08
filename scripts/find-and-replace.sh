#!/bin/bash

set -x
# Specify search directory
search_dir="~/Documents/bash-practice/"

find "${search_dir}" type f -name "*.txt" -exec sed -i '' 's/error/warning/g' {} \;

echo "Text replacement completed"