#!/bin/bash

PATH=$PATH:/usr/bin
msgcat=$(which msgcat)

# Declare an associative array
declare -A files_collection

folder_path_in=$1

# Define the root locale folder to search in
root_folder="$folder_path_in/locale"

# Find all ".po" files recursively in the root folder
locale_po_files=$(find $root_folder -type f -name "*.po" -printf '%f\n' | sort -u)

for locale_file in $locale_po_files; do
  echo "==> File: $locale_file"  

  # Get the name of the file without the path
  locale_file_name=$(basename $locale_file)

  # Find all subfolders that contain a file with the same name
  folders_with_file=($(find $root_folder -name $locale_file_name -printf '%h\n' | sort -u))

  # Declare an associative array for keyed folders
  declare -A keyed_folders=()

  counter=0
  for folder_path_inner in "${folders_with_file[@]}"; do
  # while [ $counter -lt ${#folders_with_file[@]} ]; do
    #folder_path_inner=${folders_with_file[counter]}

    echo "==> FileFolder: $folder_path_inner"  
    # Get the folder name

    folder_name_inner=($(basename ${folder_path_inner}))
    # folder_name=$(basename $folder_path)
    # Get the first 2 letters of the folder name
    two_letters=${folder_name_inner:0:2}

    if [ -v keyed_folders[$two_letters] ]; then
      counter=$((counter+1))
      continue
    fi

    # Check if there is a folder that is named something like tl_TL (like es_ES)
    tlupper="${two_letters^^}"
    relevant_folder_base=$(find "$root_folder" -type d -name "$two_letters"_"$tlupper" -print)

    # Get all subfolders that starts with two_letters followed by "_"
    deriving_folders=($(find $root_folder -type d -name "$two_letters"_* ! -name "$two_letters"_"$tlupper"))

    folders_with_file_locale=()

    for folder_base in $relevant_folder_base; do
      folders_with_file_locale+=("$folder_base/$locale_file")
    done

    for folder_base in $deriving_folders; do
      folders_with_file_locale+=("$folder_base/$locale_file")
    done

    # Add the two_letters and its corresponding folders to the keyed_folders associative array
    keyed_folders["$two_letters"]=${folders_with_file_locale[@]}
    OLDIFS=$IFS
    IFS=' '; echo "FOLDERS: ${folders_with_file_locale[*]}"
    IFS=$OLDIFS

    # IFS=$'\n' read -rd '' -a folders_with_file <<< "$(comm -23 <(echo "${folders_with_file[@]}" | tr ' ' '\n' | sort) <(echo "${folders_with_file_locale[@]}" | tr ' ' '\n' | sort))"
    # folders_with_file=($(echo "${folders_with_file[@]}" | tr ' ' '\n' | grep -vxf <(echo "${folders_with_file_locale[@]}" | tr ' ' '\n' | sort | uniq -u)))
    # folders_with_file=($(echo ${folders_with_file[@]} ${folders_with_file_locale[@]} | tr ' ' '\n' | sort | uniq -u))
    counter=$((counter+1))
  done
  # Add the file name and its corresponding keyed_folders to the files_collection associative array
  files_collection[$locale_file_name]="$(declare -p keyed_folders)"
done

for file in "${!files_collection[@]}"; do
  # echo "~~ File: $file"
  keyLocaleFolders="${files_collection[$file]}"
  eval "declare -A keyLocaleFolders="${keyLocaleFolders#*=}""
  for keyLocale in "${!keyLocaleFolders[@]}"; do
    # value=${keyLocaleFolders[$keyLocale]}
    OLDIFS=$IFS
    IFS=' ' read -a value <<< "${keyLocaleFolders[$keyLocale]}"
    IFS=$OLDIFS
    # echo "~~ Locale Key: $keyLocale"
    # echo "~~ Folders: $value"

    base_locale_folder="$root_folder/$keyLocale"
    if [ ! -d "$base_locale_folder" ]; then
        # mkdir "$base_locale_folder"
        echo "mkdir "$base_locale_folder""
    fi

    # folder_specific_file=()
    # for folder_specific in "${value[@]}"; do
    #   folder_specific_file+=($folder_specific/$file)
    # done

    if [ "${#value[@]}" -gt 1 ]; then
      echo "$msgcat --use-first ${value[@]} -o "$base_locale_folder/$file"_new"
      echo "printf '%s\0' "${value[@]}" | xargs -0 rm -f"
    else
      only_file=${value[0]}
      echo "mv $only_file "$base_locale_folder/$file"_new"
    fi
    # retu=$($msgcat --use-first ${value[@]} -o "$base_locale_folder/$file"_new)
    echo "$msgcat --use-first ${value[@]} -o "$base_locale_folder/$file"_new"

    # printf '%s\0' "${value[@]}" | xargs -0 rm -f
    echo "printf '%s\0' "${value[@]}" | xargs -0 rm -f"
  done
done