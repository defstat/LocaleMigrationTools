#!/bin/bash
PATH=$PATH:/usr/bin

# Get parameters
input_repos=$1
input_locale_params=$2

declare -a repos
readarray -t repos < "$(echo "$input_repos" | tr -d '\r\n')"

declare -a locale_params
readarray -t locale_params < "$(echo "$input_locale_params" | tr -d '\r\n')"

# for repo in "${repos[@]}"; do
#   for locale_param in "${locale_params[@]}"; do
#     echo "/bin/bash ./FinalLocaleMigration.sh $repo $locale_param"
#     /bin/bash ./FinalLocaleMigration.sh $repo $locale_param
#   done
# done
current_dir=$(pwd)

for repo in "${repos[@]}"; do
  cd $repo
  for locale_param in "${locale_params[@]}"; do
    echo "/bin/bash $current_dir/FinalLocaleMigrationWithOptions.sh $current_dir ./ $locale_param"
    /bin/bash "$current_dir/FinalLocaleMigrationWithOptions.sh" $current_dir ./ $locale_param
  done
  cd $current_dir
done