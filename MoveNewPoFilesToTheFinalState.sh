#!/bin/bash

PATH=$PATH:/usr/bin
msgcat=$(which msgcat)

folder_path=$1

# Define the root locale folder to search in
root_folder="$folder_path/locale"

for locale_named_folder in $(find "$root_folder" -type d); do
  # Find all files that end with "_new"
  for locale_file in $(find $locale_named_folder -type f -name "*_new" -printf '%f\n' | sort -u); do
    first_file_name=$(basename "$locale_file")

    # Strip "_new" from file name
    base_file_name=${first_file_name%_new}

    base_files=($(find "$locale_named_folder" -type f -name "$base_file_name"))

    if [ "${#base_files[@]}" -gt 1 ]; then
      other_file=($(echo ${base_files[@]} $locale_file | tr ' ' '\n' | sort | uniq -u))
      echo "msgcat --use-first "$locale_named_folder/$locale_file $other_file" -o "$locale_named_folder/$base_file_name")"
    else 
      echo "mv "$locale_named_folder/$locale_file" "$locale_named_folder/$base_file_name""
    fi

    echo "rm "$locale_named_folder/$locale_file""
  done
done