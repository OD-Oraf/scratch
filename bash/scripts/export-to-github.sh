#!/bin/bash

folder_path="$1"
file_path="$2"

if [[ -d "$folder_path" ]]; then
  echo "Folder '$folder_path' already exists"
else
  mkdir "$folder_path"
  echo "Folder '$folder_path' has been created"
fi

if [[ -f "$file_path" ]]; then
  echo "'$file_path' already exists"
else
  touch "$file_path"
  echo "'$file_path' has been created"
fi

