#!/bin/bash

PATH=$PATH:/usr/bin
msgcat=$(which msgcat)

# Declare an associative array
declare -A files_collection

folder_path=$1

# Define the root locale folder to search in
root_folder="$folder_path/locale"

# Find all ".po" files recursively in the root folder
locale_po_files=$(find $root_folder -type f -name "*.po" -printf '%f\n' | sort -u);
for locale_file in $locale_po_files; do
  echo "==> File: $locale_file"  

  # Get the name of the file without the path
  locale_file_name=$(basename $locale_file)

  # Find all subfolders that contain a file with the same name
  folders_with_file=($(find $root_folder -name $locale_file_name -printf '%h\n' | sort -u))

  # Declare an associative array for keyed folders
  declare -A keyed_folders

  for folder_path in "${folders_with_file[@]}"; do
    # echo "==> FileFolder: $folder_path"  
    # Get the folder name
    folder_name=$(basename $folder_path)
    # Get the first 2 letters of the folder name
    two_letters=${folder_name:0:2}
    # Get all subfolders that starts with two_letters followed by "_"
    deriving_folders=($(find $root_folder -type d -name "$two_letters"_*))
    # Add the two_letters and its corresponding folders to the keyed_folders associative array
    keyed_folders["$two_letters"]=${deriving_folders[@]}

    folders_with_file=($(echo ${folders_with_file[@]} ${deriving_folders[@]} | tr ' ' '\n' | sort | uniq -u))
  done
  # Add the file name and its corresponding keyed_folders to the files_collection associative array
  files_collection[$locale_file_name]="$(declare -p keyed_folders)"

  for file in "${!files_collection[@]}"; do
    echo "File: $file"
    keyLocaleFolders="${files_collection[$file]}"
    eval "declare -A keyLocaleFolders="${keyLocaleFolders#*=}""
    for keyLocale in "${!keyLocaleFolders[@]}"; do
      # value=${keyLocaleFolders[$keyLocale]}
      IFS=' ' read -a value <<< "${keyLocaleFolders[$keyLocale]}"
      echo "Locale Key: $keyLocale"
      echo "Folders: $value"

      base_locale_folder="$root_folder/$keyLocale"
      if [ ! -d "$base_locale_folder" ]; then
          mkdir "$base_locale_folder"
      fi

      folder_specific_file=()
      for folder_specific in "${value[@]}"; do
        folder_specific_file+=($folder_specific/$file)
      done

      # retu=$($msgcat ${folder_specific_file[@]} -o "$base_locale_folder/$file"_depr)
      retu=$($msgcat --use-first ${folder_specific_file[@]} -o "$base_locale_folder/$file"_new)

      printf '%s\0' "${folder_specific_file[@]}" | xargs -0 rm -f

    done
  done
done