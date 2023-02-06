#!/bin/bash
PATH=$PATH:/usr/bin

# Get parameters
repo_folder=$1
locale_folder_names=()


while [[ $# -gt 0 ]]; do
  case $1 in
    -l)
      shift
      locale_folder_names=("$@")
      break
      ;;
  esac
  shift
done

k=$(echo "${locale_folder_names[@]}" | tr ' ' '|')
echo $k

default_locale_folder=${locale_folder_names[0]}

# Get all the folder names that actually contain any .po files, and list their parent's parent folder.
echo "git -C $repo_folder ls-files --full-name | grep -E '($k)/[^/]+\.po$' | xargs dirname | xargs -n 1 dirname | sort | uniq"
root_parent_folders=($(git -C $repo_folder ls-files --full-name | grep -E "($k)/[^/]+\.po$" | xargs dirname | xargs -n 1 dirname | sort | uniq))

for root_parent_folder in "${root_parent_folders[@]}"; do
  actual_root_locale_folder_path="$repo_folder/$root_parent_folder"

  # Check if that folder actually exists
  if [ ! -d "$actual_root_locale_folder_path" ]; then
    echo "Not there $actual_root_locale_folder_path"
    continue
  fi

  # List all the base filenames (like admin.po, locale.po, submission.po, etc) from this root locale folder, that are contained into 
  # the searched locale code
  file_filenames=($(git -C $actual_root_locale_folder_path ls-files | grep -E "($k)/[^/]+\.po$" | xargs -n 1  basename | sort | uniq))

  for file_filename in "${file_filenames[@]}"; do
    folder_to_attach="$repo_folder/$root_parent_folder/"

    # Get all the .po files filenames that are contained to a locale folder with the specified locale code, and add the relative folder path to that.
    folder_filenames=($(git -C $actual_root_locale_folder_path ls-files | grep -E "($k)/$file_filename" | grep -v @ | xargs -I {} echo "${folder_to_attach}{}" | sort | uniq))

    # Declare the path that it would be the .po file name path in the default locale folder, which is declared as an input param ...
    default_file_name="$folder_to_attach/$default_locale_folder/$file_filename"

    if [ "${#folder_filenames[@]}" -gt 0 ]; then
      
      # if there are more than one .po files that are contained to a locale folder with the specified locale code
      if [ "${#folder_filenames[@]}" -gt 1 ]; then
        # Make sure that there are no dublicate translation keys in each .po file - remove them if there are
        for folder_filename in "${folder_filenames[@]}"; do
          echo "msguniq --use-first $folder_filename -o $folder_filename"
          msguniq --use-first $folder_filename -o $folder_filename
        done

        echo "msgcat --use-first ${folder_filenames[@]} -o "$default_file_name""
        msgcat --use-first ${folder_filenames[@]} -o "$default_file_name"

        echo "git add "$default_file_name""
        git add "$default_file_name"

        if [[ " ${folder_filenames[@]} " =~ " ${default_file_name} " ]]; then
          # If it is in then remove the default locale folder filename from the array, in order to handle it differently ...
          folder_filenames=(${folder_filenames[@]/$default_file_name})
        fi
        # Finally remove all the .po files that we have just merged.
        echo "rm ${folder_filenames[@]}"
        rm ${folder_filenames[@]}

        echo "git add -u ${folder_filenames[@]}"
        git add -u ${folder_filenames[@]}
      else
        # if there is only one .po files that are contained to a locale folder with the specified locale code ...
        only_file=${folder_filenames[0]}

        # ... just move it in the base locale folder
        echo "mv $only_file "$default_file_name""
        mv $only_file "$default_file_name"

        echo "git add "$default_file_name""
        git add "$default_file_name"

        echo "git add -u $only_file"
        git add -u $only_file
      fi
    fi
  done

  locale_folder_names_no_first=("${locale_folder_names[@]:1}")
  k_no_first=$(echo "${locale_folder_names_no_first[@]}" | tr ' ' '|')
  echo $k_no_first

  # Find and remove all locale folders that have no contents after the .po files merge
  # Search for non empty locale folders and move them to the base locale folder adding a _depr to their name
  finale_action_folders=($(git -C $actual_root_locale_folder_path ls-tree -r -d --name-only HEAD | xargs -n 1  basename | grep -E "($k_no_first)".* | grep -v @ | sort | uniq))
  
  for finale_action_folder in "${finale_action_folders[@]}"; do
    actual_finale_action_folder_path="$actual_root_locale_folder_path/$finale_action_folder"
    if [ -n "$(ls -A "$actual_finale_action_folder_path")" ]; then
      # Actions if the folder is not empty
      finale_action_folder_name=($(basename ${actual_finale_action_folder_path}))
      echo "mv $actual_finale_action_folder_path "$repo_folder/$root_parent_folder/$default_locale_folder/depr_$finale_action_folder_name"_depr"
      mv $actual_finale_action_folder_path "$repo_folder/$root_parent_folder/$default_locale_folder/depr_$finale_action_folder_name"_depr
      
      echo "git add "$repo_folder/$root_parent_folder/$default_locale_folder/depr_$finale_action_folder_name"_depr"
      git add "$repo_folder/$root_parent_folder/$default_locale_folder/depr_$finale_action_folder_name"_depr
    else
      # Actions id the folder is empty
      echo "rm -r $actual_finale_action_folder_path"
      rm -r $actual_finale_action_folder_path

      echo "git add -u $actual_finale_action_folder_path"
      git add -u $actual_finale_action_folder_path
    fi
  done
done