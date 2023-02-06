#!/bin/bash
PATH=$PATH:/usr/bin

# Get parameters
repo_folder=$1
base_locale=$2
default_locale_folder=$3

# Get all the folder names that actually contain any .po files, and list their parent's parent folder.
root_parent_folders=($(git -C $repo_folder ls-files "*/$base_locale*/*.po" | xargs dirname | xargs -n 1 dirname | sort | uniq))
at_root_parent_folders=($(git -C $repo_folder ls-files "*/$base_locale*/*.po" | grep @))

has_at_folders=0
if [ "${#at_root_parent_folders[@]}" -gt 0 ]; then
  has_at_folders=1
fi

for root_parent_folder in "${root_parent_folders[@]}"; do
  actual_root_locale_folder_path="$repo_folder/$root_parent_folder"

  # Check if that folder actually exists
  if [ ! -d "$actual_root_locale_folder_path" ]; then
    echo "Not there $actual_root_locale_folder_path"
    continue
  fi

  # List all the base filenames (like admin.po, locale.po, submission.po, etc) fron this root locale folder, that are contained into 
  # the searched locale code
  file_filenames=($(git -C $actual_root_locale_folder_path ls-files "$base_locale*/*.po" | xargs -n 1  basename | sort | uniq))

  for file_filename in "${file_filenames[@]}"; do
    folder_to_attach="$repo_folder/$root_parent_folder/"

    # Get all the .po files filenames that are contained to a locale folder with the specified locale code, and add the relative folder path to that.
    folder_filenames=($(git -C $actual_root_locale_folder_path ls-files "$base_locale*/$file_filename" | grep -v @ | xargs -I {} echo "${folder_to_attach}{}" | sort | uniq))

    if [ $has_at_folders == 1 ]; then
      folder_with_at_char_in_filenames=($(git -C $actual_root_locale_folder_path ls-files "$base_locale*/$file_filename" | grep @ | xargs -I {} echo "${folder_to_attach}{}" | sort | uniq))

      if [ "${#folder_with_at_char_in_filenames[@]}" -gt 0 ]; then
        at_strings=()
        for folder_with_at_char_in_filename in "${folder_with_at_char_in_filenames[@]}"; do
          parent_dir=$(dirname "$folder_with_at_char_in_filename")
          
          # Get the part before the '@' character
          before_at=${parent_dir%@*}
          # Get the part after the '@' character
          after_at=${parent_dir#*@}

          if ! [[ " ${at_strings[*]} " =~ " ${after_at} " ]]; then
              at_strings+=("$after_at")
          fi
        done
        for at_string in "${at_strings[@]}"; do
          echo "git -C $actual_root_locale_folder_path ls-files "$base_locale*@$at_string/$file_filename" | xargs -I {} echo "${folder_to_attach}{}" | sort | uniq" 
          specific_folder_with_at_filenames=($(git -C $actual_root_locale_folder_path ls-files "$base_locale*@$at_string/$file_filename" | xargs -I {} echo "${folder_to_attach}{}" | sort | uniq))

          if [ "${#specific_folder_with_at_filenames[@]}" -gt 0 ]; then
            base_locale_at_folder="$folder_to_attach/$base_locale@$at_string"

            # .. and create it if it does not exist
            if [ ! -d "$base_locale_at_folder" ]; then
                echo "mkdir "$base_locale_at_folder""
                mkdir "$base_locale_at_folder"
            fi

            if [ "${#specific_folder_with_at_filenames[@]}" -gt 1 ]; then
              # Make sure that there are no dublicate translation keys in each .po file - remove them if there are
              for specific_folder_with_at_filename in "${specific_folder_with_at_filenames[@]}"; do
                echo "msguniq --use-first $specific_folder_with_at_filename -o $specific_folder_with_at_filename"
                msguniq --use-first $specific_folder_with_at_filename -o $specific_folder_with_at_filename
              done

              # Declare the path that it would be the .po file name path in the default locale folder, which is declared as an input param ...
              default_at_file_name="$folder_to_attach/$default_locale_folder@$at_string/$file_filename"

              # ... and check if that file actually exists in the .po files that we are examining.
              if [[ " ${specific_folder_with_at_filenames[@]} " =~ " ${default_at_file_name} " ]]; then
                # If it is in then remove the default locale folder filename from the array, in order to handle it differently ...
                at_folder_filenames=(${specific_folder_with_at_filenames[@]/$default_at_file_name})

                # ... and add it first to the msgcat command
                # the output (locale merged) file will go right in the base locale folder
                echo "msgcat --use-first $default_at_file_name ${specific_folder_with_at_filenames[@]} -o "$base_locale_at_folder/$file_filename""
                msgcat --use-first $default_at_file_name ${specific_folder_with_at_filenames[@]} -o "$base_locale_at_folder/$file_filename"

                echo "git add "$base_locale_at_folder/$file_filename""
                git add "$base_locale_at_folder/$file_filename"

                # Remove the default locale folder filename (the others will be removed afterwards)
                echo "rm $default_at_file_name"
                rm $default_at_file_name

                echo "git add -u $default_at_file_name"
                git add -u $default_at_file_name
              else
                # If it is not in just call the msgcat, no matter the .po files order order
                # the output (locale merged) file will go right in the base locale folder
                echo "msgcat --use-first ${specific_folder_with_at_filenames[@]} -o "$base_locale_at_folder/$file_filename""
                msgcat --use-first ${specific_folder_with_at_filenames[@]} -o "$base_locale_at_folder/$file_filename"

                echo "git add "$base_locale_at_folder/$file_filename""
                git add "$base_locale_at_folder/$file_filename"
              fi

              # Finally remove all the .po files that we have just merged.
              echo "rm ${specific_folder_with_at_filenames[@]}"
              rm ${specific_folder_with_at_filenames[@]}
            else
              # if there is only one .po files that are contained to a locale folder with the specified locale code ...
              at_only_file=${specific_folder_with_at_filenames[0]}

              # ... just move it in the base locale folder
              echo "mv $at_only_file "$base_locale_at_folder/$file_filename""
              mv $at_only_file "$base_locale_at_folder/$file_filename"

              echo "git add "$base_locale_at_folder/$file_filename""
              git add "$base_locale_at_folder/$file_filename"

              echo "git add -u $at_only_file"
              git add -u $at_only_file
            fi
          fi
        done
      fi
    fi

    if [ "${#folder_filenames[@]}" -gt 0 ]; then
      # Declare the base locale folder (like the folder "/locale/en") 
      base_locale_folder="$folder_to_attach/$base_locale"

      # .. and create it if it does not exist
      if [ ! -d "$base_locale_folder" ]; then
          echo "mkdir "$base_locale_folder""
          mkdir "$base_locale_folder"
      fi

      # if there are more than one .po files that are contained to a locale folder with the specified locale code
      if [ "${#folder_filenames[@]}" -gt 1 ]; then
        # Make sure that there are no dublicate translation keys in each .po file - remove them if there are
        for folder_filename in "${folder_filenames[@]}"; do
          echo "msguniq --use-first $folder_filename -o $folder_filename"
          msguniq --use-first $folder_filename -o $folder_filename
        done

        # Declare the path that it would be the .po file name path in the default locale folder, which is declared as an input param ...
        default_file_name="$folder_to_attach/$default_locale_folder/$file_filename"

        # ... and check if that file actually exists in the .po files that we are examining.
        if [[ " ${folder_filenames[@]} " =~ " ${default_file_name} " ]]; then
          # If it is in then remove the default locale folder filename from the array, in order to handle it differently ...
          folder_filenames=(${folder_filenames[@]/$default_file_name})

          # ... and add it first to the msgcat command
          # the output (locale merged) file will go right in the base locale folder
          echo "msgcat --use-first $default_file_name ${folder_filenames[@]} -o "$base_locale_folder/$file_filename""
          msgcat --use-first $default_file_name ${folder_filenames[@]} -o "$base_locale_folder/$file_filename"

          echo "git add "$base_locale_folder/$file_filename""
          git add "$base_locale_folder/$file_filename"

          # Remove the default locale folder filename (the others will be removed afterwards)
          echo "rm $default_file_name"
          rm $default_file_name

          echo "git add -u $default_file_name"
          git add -u $default_file_name
        else
          # If it is not in just call the msgcat, no matter the .po files order order
          # the output (locale merged) file will go right in the base locale folder
          echo "msgcat --use-first ${folder_filenames[@]} -o "$base_locale_folder/$file_filename""
          msgcat --use-first ${folder_filenames[@]} -o "$base_locale_folder/$file_filename"

          echo "git add "$base_locale_folder/$file_filename""
          git add "$base_locale_folder/$file_filename"
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
        echo "mv $only_file "$base_locale_folder/$file_filename""
        mv $only_file "$base_locale_folder/$file_filename"

        echo "git add "$base_locale_folder/$file_filename""
        git add "$base_locale_folder/$file_filename"

        echo "git add -u $only_file"
        git add -u $only_file
      fi
    fi
  done

  # Find and remove all locale folders that have no contents after the .po files merge
  # Search for non empty locale folders and move them to the base locale folder adding a _depr to their name
  finale_action_folders=($(git -C $actual_root_locale_folder_path ls-tree -r -d --name-only HEAD | xargs -n 1  basename | grep -E "$base_locale"_.* | grep -v @ | sort | uniq))
  
  for finale_action_folder in "${finale_action_folders[@]}"; do
    actual_finale_action_folder_path="$actual_root_locale_folder_path/$finale_action_folder"
    if [ -n "$(ls -A "$actual_finale_action_folder_path")" ]; then
      # Actions id the folder is not empty
      finale_action_folder_name=($(basename ${actual_finale_action_folder_path}))
      echo "mv $actual_finale_action_folder_path "$repo_folder/$root_parent_folder/$base_locale/depr_$finale_action_folder_name"_depr"
      mv $actual_finale_action_folder_path "$repo_folder/$root_parent_folder/$base_locale/depr_$finale_action_folder_name"_depr
      
      echo "git add "$repo_folder/$root_parent_folder/$base_locale/depr_$finale_action_folder_name"_depr"
      git add "$repo_folder/$root_parent_folder/$base_locale/depr_$finale_action_folder_name"_depr
    else
      # Actions id the folder is empty
      echo "rm -r $actual_finale_action_folder_path"
      rm -r $actual_finale_action_folder_path

      echo "git add -u $actual_finale_action_folder_path"
      git add -u $actual_finale_action_folder_path
    fi
  done


  if [ $has_at_folders == 1 ]; then
    # Find and remove all locale folders that have no contents after the .po files merge
    # Search for non empty locale folders and move them to the base locale folder adding a _depr to their name
    at_finale_action_folders=($(git -C $actual_root_locale_folder_path ls-tree -r -d --name-only HEAD | xargs -n 1  basename | grep -E "$base_locale"_.* | grep @ | sort | uniq))
    
    for at_finale_action_folder in "${at_finale_action_folders[@]}"; do
      at_actual_finale_action_folder_path="$actual_root_locale_folder_path/$at_finale_action_folder"

      if [ -n "$(ls -A "$at_actual_finale_action_folder_path")" ]; then
        # Actions id the folder is not empty
        at_finale_action_folder_name=($(basename ${at_actual_finale_action_folder_path}))
        finale_after_at=${at_finale_action_folder_name#*@}
        echo "mv $at_actual_finale_action_folder_path "$repo_folder/$root_parent_folder/$base_locale@$finale_after_at/depr_$at_finale_action_folder_name"_depr"
        mv $at_actual_finale_action_folder_path "$repo_folder/$root_parent_folder/$base_locale@$finale_after_at/depr_$at_finale_action_folder_name"_depr
        
      else
        # Actions id the folder is empty
        echo "rm -r $at_actual_finale_action_folder_path"
        rm -r $at_actual_finale_action_folder_path

        echo "git add -u $at_actual_finale_action_folder_path"
        git add -u $at_actual_finale_action_folder_path
      fi
    done
  fi
done