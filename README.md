Should install **msgcat** 
`sudo apt install gettext`

TLLCF:  Two Letter Locale Code Folder (en, eo, es)
DLF:    Deriving Locale Folder (en_US, en_EN, ....etc)


locale/en_US folder remained because of an "image" folder

../MyWork/ojs-3-dev-main/lib/pkp/locale/pl_PL/common.po:2176: duplicate message definition...

 find ../MyWork/ojs-3-dev-main/lib/pkp/locale -mindepth 1 -type d -empty -delete

 find ../ojs-3-dev-main -type d -name "es_*" -o -name "es" -exec sh -c 'find "$0" -name "*.po" -print' {} \; | grep -E "es" | sort | uniq

 **USAGE**
 Could call `./DriverScript.sh ./inputRepos.txt ./inputLocales.txt`
 
 At this case
 1. The `inputRepos.txt` should contain paths of the repositories that we need to migrate their locale
 2. The `inputLocales.txt` should contain rows like `es es_ES\nen en_US\nfr fr_FR`

 Could call `./FinalLocaleMigration.sh ../ojs-3-dev-main es es_ES`
 Where
 1. The first parameter is the repository pass
 2. The second parameter is the locale code we want to work on
 3. The third parameter is the default locale folder for the specified locale code

 **PENDING ISSUES**
 1. the "..@something" locale folders should be considered
 2. Perhaps add more locale_folders to consider other than the ones that start from the locale code (for example eu_ES could be considered if es locale is migrating)
 3. Other contents of the locale folders should be considered (.xml files, other folders like `images` folder (in `en_US`)) 
