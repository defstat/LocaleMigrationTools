#!/bin/bash
PATH=$PATH:/usr/bin

# Get parameters
repo_folder=$1
base_locale=$2
default_locale_folder=$3

root_parent_folders=($(git -C $repo_folder ls-files "*/$base_locale*/*.po" | xargs dirname | xargs -n 1 dirname | sort | uniq))

declare -A parent_folder_array
declare -A file_name_array

for root_parent_folder in "${root_parent_folders[@]}"; do
  file_filenames=($(git -C "$repo_folder/$root_parent_folder" ls-files "$base_locale*/*.po" | xargs -n 1  basename | sort | uniq))

  for file_filename in "${file_filenames[@]}"; do
    folder_to_attach="$repo_folder/$root_parent_folder/"
    folder_filenames=($(git -C "$repo_folder/$root_parent_folder" ls-files "$base_locale*/$file_filename" | xargs -I {} echo "${folder_to_attach}{}" | sort | uniq))

    base_locale_folder="$folder_to_attach/$base_locale"
    if [ ! -d "$base_locale_folder" ]; then
        echo "mkdir "$base_locale_folder""
        mkdir "$base_locale_folder"
    fi

    if [ "${#folder_filenames[@]}" -gt 1 ]; then
      for folder_filename in "${folder_filenames[@]}"; do
        echo "msguniq --use-first $folder_filename -o $folder_filename"
        msguniq --use-first $folder_filename -o $folder_filename
      done

      default_file_name="$folder_to_attach/$default_locale_folder/$file_filename"
      if [[ " ${folder_filenames[@]} " =~ " ${default_file_name} " ]]; then
        # Remove the filename from the array
        folder_filenames=(${folder_filenames[@]/$default_file_name})

        echo "msgcat --use-first $default_file_name ${folder_filenames[@]} -o "$base_locale_folder/$file_filename""
        msgcat --use-first $default_file_name ${folder_filenames[@]} -o "$base_locale_folder/$file_filename"

        echo "rm $default_file_name"
        rm $default_file_name
      else
        echo "msgcat --use-first ${folder_filenames[@]} -o "$base_locale_folder/$file_filename""
        msgcat --use-first ${folder_filenames[@]} -o "$base_locale_folder/$file_filename"
      fi
      echo "rm ${folder_filenames[@]}"
      rm ${folder_filenames[@]}
    else
      only_file=${folder_filenames[0]}
      echo "mv $only_file "$base_locale_folder/$file_filename""
      mv $only_file "$base_locale_folder/$file_filename"
    fi
  done

  echo "find "$repo_folder/$root_parent_folder" -mindepth 1 -type d -name "$base_locale"_* -empty -delete"
  find "$repo_folder/$root_parent_folder" -mindepth 1 -type d -name "$base_locale"_* -empty -delete

  # Search for non empty locale folders and move the contents to the base locale folder
  
  # echo "find "$repo_folder/$root_parent_folder" -type d -name "$base_locale"_*"
  # remaining_locale_folders=$(find "$repo_folder/$root_parent_folder" -type d -name "$base_locale"_*)
  # for remaining_locale_folder in "${remaining_locale_folders[@]}"; do
  #   echo "mv $remaining_locale_folder/* $repo_folder/$root_parent_folder/$base_locale"
  #   mv "$remaining_locale_folder/*" "$repo_folder/$root_parent_folder/$base_locale"
  # done
done