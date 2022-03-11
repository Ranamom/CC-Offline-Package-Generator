#!/usr/bin/env bash
set -o errexit

color="$(tput bold; tput setaf 5)"
reset="$(tput sgr0)"

printf "${color}*** Checking for build prerequisites${reset}\n"

[[ -d "$(xcode-select -p)" ]]  || { echo "${color}Xcode tools are missing! Run build_prerequisites.sh first.${reset}\n" && exit 1; }

checkPrereqs=("python3" \
              "brew" \
              "platypus" \
              "create-dmg" \
              "pipenv")

for prereq in ${checkPrereqs[@]}; do
    command -v $prereq > /dev/null 2>&1  || { printf "${color}$prereq is missing! Run build_prerequisites.sh first.${reset}\n" && exit 1; }
done

[[ -z $VIRTUAL_ENV ]] && printf "${color}Run 'pipenv shell' first, as this build script needs to run in a virtual environment.${reset}\n" && exit 1

if [[ -d /Volumes/CC_Offline_Package_Generator/CC_Offline_Package_Generator.app ]]; then
    hdiutil detach /Volumes/CC_Offline_Package_Generator  || { printf  "${color}*** Ensure that Adobe_Offline_Package_Generator.dmg is unmounted!${reset}\n" && exit 1; }
fi

printf  "${color}*** cleaning up before build...${reset}\n"
rm -rf build/ dist/
[[ -f app/CC-Offline-Package-Generator ]] && rm app/CC-Offline-Package-Generator

printf  "${color}*** creating the binary python 'CC-Offline-Package-Generator' with pyinstaller...${reset}\n"
pipenv install
pyinstaller pyinstall.spec

{
date +"Date: %Y-%m-%d %H:%M"
printf "\n$ sw_vers -productVersion\n"
sw_vers -productVersion
printf "\n$ python -V\n"
python -V
printf "\n$ pipenv --version\n"
pipenv --version
printf "\n$ pipenv graph\n"
pipenv graph
printf "\n$ pip list\n"
pip list
printf "\n$ brew list --versions\n"
brew list --versions
} > app/build_env.txt

printf  "${color}*** creating the .app bundle with Platypus...${reset}\n"
mkdir -p dmg/createdmg
mv dist/CC-Offline-Package-Generator app/
cd app
rm -rf "../dmg/createdmg/CC_Offline_Package_Generator.app"
platypus -P app_bundle_config.platypus "../dmg/createdmg/CC_Offline_Package_Generator.app"

printf  "${color}*** creating the DMG installer with create-dmg...${reset}\n"
cd ../dmg
[[ -f "CC_Offline_Package_Generator.dmg" ]] && rm "CC_Offline_Package_Generator.dmg"
[[ -f "rw.CC_Offline_Package_Generator.dmg" ]] && rm "rw.CC_Offline_Package_Generator.dmg"

# Create a DMG installer
create-dmg \
  --volname "CC_Offline_Package_Generator" \
  --background "installer_background.png" \
  --window-pos 200 120 \
  --window-size 500 360 \
  --icon-size 80 \
  --icon "CC_Offline_Package_Generator.app" 120 155 \
  --hide-extension "CC_Offline_Package_Generator.app" \
  --app-drop-link 350 155 \
  "CC_Offline_Package_Generator.dmg" \
  "createdmg"

printf  "${color}*** The installer has been created in dmg/CC_Offline_Package_Generator.dmg${reset}\n"
