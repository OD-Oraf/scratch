#!/bin/zsh

env="us-dev"
#git_tag="1.0.0"

#if [[
#  $env == "us-dev" ||
#  $env == "eu-dev"
#]]; then
#  echo "Dev deployment. TAG not needed"
#elif [[
#  (
#    $env != "us-dev" &&
#    $env != "eu-dev"
#  ) &&
#  -n "${git_tag}"
#]]; then
#  echo "Valid env and tag pair"
#else
#  echo "Tag Missing"
#fi

if [[ -z "" ]]; then
  echo "Variable does not exist"
else
  echo "variable exists"
fi
