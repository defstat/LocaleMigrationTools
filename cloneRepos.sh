#!/bin/bash

root="$PWD"
input_folder=$1

while read -r line; do
  IFS=' ' read -r -a values <<< "$line"
  f1="${values[0]}"
  f2="${values[1]}"
  f3="${values[2]}"

  # Check if the folder root/$f1 exists, create it if it doesn't
  if [ ! -d "$input_folder/$f1" ]; then
    mkdir "$input_folder/$f1"
  fi

  # Check if the folder root/$f1/$f2 exists, create it if it doesn't
  if [ ! -d "$input_folder/$f1/$f2" ]; then
    mkdir "$input_folder/$f1/$f2"
    # Clone the repo from $f3
    git clone "$f3" "$input_folder/$f1/$f2"
    cd "$input_folder/$f1/$f2"
    git checkout main
    cd "$root"
  else
    # Pull the main branch from the $f3
    cd "$input_folder/$f1/$f2"
    git checkout main
    git pull main
    cd "$root"
  fi
done < "$2"