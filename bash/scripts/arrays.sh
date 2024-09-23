#!/bin/zsh

fruits=("apple" "banana" "orange")

fruits+=("watermelon")
echo "print all elements in array"
for i in "${fruits[@]}"; do
  echo "$i"
done