#!/bin/bash

PATH=$PATH:/usr/bin
msgcat=$(which msgcat)

folder_path=$1

root_locale_folder="$folder_path/locale"

if [ -d "$root_locale_folder" ]; then
  # Find all folders that are named "locale" within the root (or list of roots?)
  locale_named_folders=$(find "$root_locale_folder" -type d -name "locale" -print);

  # Find all folders named "locale" in the root folder
  for locale_named_folder in $locale_named_folders; do
    # Find all folders that their name is two character (like "es", "en", "eo" etc)
    # for subfolder2 in $(find "$locale_named_folder" -type d -name "??" -print); do
    for two_character_name_folder in $(find "$locale_named_folder" -type d -name "??" -print); do
      # Take the two character name of the folder 
      two_character_subfolder_name=$(basename "$two_character_name_folder")

      # Check if there is a folder that is named something like tl_TL (like es_ES)
      tlupper="${two_character_subfolder_name^^}"
      relevant_folder_base=$(find "$locale_named_folder" -type d -name "$two_character_subfolder_name"_"$tlupper" -print)

      # Take all folders that their name start from the two characters we found
      relevant_folders=$(find "$locale_named_folder" -type d -name "$two_character_subfolder_name"_* ! -name "$two_character_subfolder_name"_"$tlupper" -print)
      two_character_subfolder_files=$(find "$two_character_name_folder" -type f ! -name "*_depr" ! -name "*_new");

      # for locale_file in "$two_character_name_folder"*; do
      for locale_file in $two_character_subfolder_files; do
        locale_file_name=$(basename "$locale_file");
        folders_with_file=()

        for folder_base in $relevant_folder_base; do
          folders_with_file+=("$folder_base/$locale_file_name")
        done

        for other_folders in $relevant_folders; do
          if [ -f "$other_folders/$locale_file_name" ] && ! echo "${folders_with_file[@]}" | grep -q "$other_folders"; then
              folders_with_file+=("$other_folders/$locale_file_name")
          fi
        done

        folders_with_file+=("$two_character_name_folder/$locale_file_name")
        
        if [ "${#folders_with_file[@]}" -gt 1 ]; then
          echo "Concatenating .po file $locale_file accross base $two_character_name_folder and the folders ${folders_with_file[@]}"

          # echo "$msgcat --use-first ${folders_with_file[@]} -o "$two_character_name_folder/$locale_file_name"_new"
          retu=$($msgcat --use-first ${folders_with_file[@]} -o "$two_character_name_folder/$locale_file_name"_new)

          # Remove the .po file from the locale two letter code derived folders
          for file in ${folders_with_file[@]}; do
              # echo "rm "$file""
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