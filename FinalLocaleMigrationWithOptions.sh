#!/bin/bash
PATH=$PATH:/usr/bin

current_dir=$1
repo_folder=$2

while [[ $# -gt 0 ]]; do
  case $1 in
    -l)
      shift
      list=("$@")
      break
      ;;
    -s|--switch)
      base_locale="$2"
      shift
      ;;
    -d|--switch)
      default_locale="$2"
      shift
      ;;
    *)
      # other options
      ;;
  esac
  shift
done

if [ -n "$base_locale" ]; then
  if [ -n "$default_locale" ]; then
    echo "/bin/bash $current_dir/FinalLocaleMigration.sh $repo_folder $base_locale $default_locale"
    /bin/bash $current_dir/FinalLocaleMigration.sh $repo_folder $base_locale $default_locale
  else 
    echo "You have to declare a default locale"
  fi
else
  # echo "$repo_folder + $base_locale + List of parameters after -l switch: ${list[@]} withOUT switch"
  echo "/bin/bash $current_dir/MergeListOfLocales.sh $repo_folder -l ${list[@]}"
  /bin/bash $current_dir/MergeListOfLocales.sh $repo_folder -l ${list[@]}
fi

