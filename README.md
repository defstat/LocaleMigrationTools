# USAGE
 Could call for batch use
 
 > `./DriverScript.sh ./inputRepos.txt ./inputLocales.txt`
 
 At this case
 1. The `inputRepos.txt` should contain paths of the repositories that we need to migrate their locale
 2. The `inputLocales.txt` should contain rows like `es es_ES\nen en_US\nfr fr_FR`

There are such test files in the repo.

 Could call for individual repo use
 
 > `./FinalLocaleMigration.sh ../ojs-3-dev-main es es_ES`
 
 Where
 1. The first parameter is the repository pass
 2. The second parameter is the locale code we want to work on
 3. The third parameter is the default locale folder for the specified locale code

 # PENDING ISSUES
 1. the "..@something" locale folders should be considered
 2. Perhaps add more locale_folders to consider other than the ones that start from the locale code (for example eu_ES could be considered if es locale is migrating)
 3. Other contents of the locale folders should be considered (.xml files, other folders like `images` folder (in `en_US`)) 
 4. Could add support for different default locale folder for different repo. 

 # Other Notes
Should install **msgcat** 
`sudo apt install gettext`

TLLCF:  Two Letter Locale Code Folder (en, eo, es)
DLF:    Deriving Locale Folder (en_US, en_EN, ....etc)


locale/en_US folder remained because of an "image" folder

../MyWork/ojs-3-dev-main/lib/pkp/locale/pl_PL/common.po:2176: duplicate message definition...

 > `find ../MyWork/ojs-3-dev-main/lib/pkp/locale -mindepth 1 -type d -empty -delete`

 > `find ../ojs-3-dev-main -type d -name "es_*" -o -name "es" -exec sh -c 'find "$0" -name "*.po" -print' {} \; | grep -E "es" | sort | uniq`

**Check Existing Locale keys from code**
> grep -rhoE "__\('([^']*)'" ./ | sed "s/__('\|')//g" | sed "s/'//g" | sort | uniq

 # PLUGIN LOCALE MIGRATION
 1. Clone this repo in a folder.
 2. Navigate to the cloned folder.
 3. Create a txt file (like `inputRepos.txt`) in the cloned folder. if you want to run the migration only for one plugin, just put in the new txt file the relative path of the folder that the plugin is cloned into (for example add this line to the file `../ojs/plugins/general/paperbuzz`. Make sure the line endings are LF). Let's say you have named the txt file `paperBuzzMigration.txt`. 
 4. Make sure that the plugin is at the branch that you need to migrate.
 5. Execute `./DriverScript.sh ./paperBuzzMigration.txt ./inputLocales.txt` to migrate the locales 
 **OR** 
 5. Execute `./DriverScript.sh ./paperBuzzMigration.txt ./inputLocales.txt | tee -a outputProcessAll-paperBuzzMigration.txt` to migrate the locales and keep all script output to the file `outputProcessAll-paperBuzzMigration.txt` for possible review.
 6. Check the local plugin repo - It should have all the locale migration changes staged and ready to commit.
