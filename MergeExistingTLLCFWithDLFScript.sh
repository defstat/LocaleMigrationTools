#!/bin/bash

PATH=$PATH:/usr/bin
msgcat=$(which msgcat)

folder_path=$1

root_locale_folder="$folder_path/locale"

if [ -d "$root_locale_folder" ]; then
  # Find all folders named "locale" in the root folder
  for locale_named_folder in $(find "$root_locale_folder" -type d -name "locale" -print); do
    # Find all folders that their name is two character (like "es", "en", "eo" etc)
    # for subfolder2 in $(find "$locale_named_folder" -type d -name "??" -print); do
    for two_character_name_folder in $(find "$locale_named_folder" -type d -name "??" -print); do
      # Take the two character name of the folder 
      two_character_subfolder_name=$(basename "$two_character_name_folder")

      # Take all folders that their name start from the two characters we found
      relevant_folders=$(find "$locale_named_folder" -type d -name "$two_character_subfolder_name"_* -print)
      two_character_subfolder_files=$(find "$two_character_name_folder" -type f ! -name "*_depr" ! -name "*_new");

      # for locale_file in "$two_character_name_folder"*; do
      for locale_file in $two_character_subfolder_files; do
        locale_file_name=$(basename "$locale_file");
        folders_with_file=()
        for other_folders in $relevant_folders; do
          if [ -f "$other_folders/$locale_file_name" ] && ! echo "${folders_with_file[@]}" | grep -q "$other_folders"; then
              folders_with_file+=("$other_folders/$locale_file_name")
          fi
        done
        
        if [ "${#folders_with_file[@]}" -gt 0 ]; then
          echo "Concatenating .po file $locale_file accross base $two_character_name_folder and the folders ${folders_with_file[@]}"

          # retu=$($msgcat "$two_character_name_folder/$locale_file_name" ${folders_with_file[@]} -o "$two_character_name_folder/$locale_file_name"_depr)
          retu=$($msgcat --use-first "$two_character_name_folder/$locale_file_name" ${folders_with_file[@]} -o "$two_character_name_folder/$locale_file_name"_new)

          # Remove the .po file from the locale two letter code derived folders
          for file in ${folders_with_file[@]}; do
              rm "$file"
          done
          
        else
          echo "The .po file $locale_file is found in the folder $two_character_name_folder but in no other folders with names deriving from the $two_character_name_folder name"
        fi
        
      done
    done
  done
else
  echo "$folder_path_locale is not a directory."
fi