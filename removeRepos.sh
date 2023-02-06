#!/bin/bash

root="$PWD"
input_folder=$1

while read -r line; do
  IFS=' ' read -r -a values <<< "$line"
  f1="${values[0]}"
  f2="${values[1]}"
  f3="${values[2]}"

  # Check if the folder root/$f1/$f2 exists, create it if it doesn't
  if [ -d "$input_folder/$f1/$f2" ]; then
    echo "rm -rf "$input_folder/$f1/$f2""
    rm -rf "$input_folder/$f1/$f2"
  fi
done < "$2"