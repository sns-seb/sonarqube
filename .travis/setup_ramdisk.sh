#!/bin/bash
set -euo pipefail

echo "current dir: $PWD"

RED='\033[0;31m'
NC='\033[0m' # No Color
MNT_POINT="$HOME/mnt_point"
GRADLE_CACHE="$HOME/.gradle"
NEW_GRADLE_CACHE="$MNT_POINT/.gradle"
NEW_TRAVIS_BUILD_DIR="$MNT_POINT/sonarqube"
SONAR_HOME="$HOME/.sonar"
NEW_SONAR_HOME="$MNT_POINT/.sonar"

if [ ! -d "$SONAR_HOME" ]; then
  mkdir "$SONAR_HOME"
fi

printf "${RED}SETUP RAMDISK${NC}\n"
printf "${RED}disk size before build${NC}\n"
df -h
du -sh $HOME
du -sh $GRADLE_CACHE
du -sh $TRAVIS_BUILD_DIR

printf "${RED}create ramdisk mount point${NC}\n"
sudo mkdir -p "$MNT_POINT"
printf "${RED}create ramdisk${NC}\n"
sudo mount -t tmpfs -o size=8192m tmps "$MNT_POINT"
printf "${RED}mv TRAVIS_BUILD_DIR to ramdisk${NC}\n"
time sudo mv $TRAVIS_BUILD_DIR "$NEW_TRAVIS_BUILD_DIR"
sudo ln -s "$NEW_TRAVIS_BUILD_DIR" $TRAVIS_BUILD_DIR
printf "${RED}mv gradle cache to ramdisk${NC}\n"
time sudo mv $GRADLE_CACHE "$NEW_GRADLE_CACHE"
sudo ln -s "$NEW_GRADLE_CACHE" $GRADLE_CACHE
printf "${RED}create sonar home in ramdisk${NC}\n"
time sudo mv "$SONAR_HOME" "$NEW_SONAR_HOME"
sudo ln -s "$NEW_SONAR_HOME" "$SONAR_HOME"

printf "${RED}give permissions to travis on new dirs in ramdisk and symlinks${NC}\n"
sudo chown -R travis:travis "$NEW_TRAVIS_BUILD_DIR"
sudo chown -R travis:travis "$NEW_GRADLE_CACHE"
sudo chown -R travis:travis "$NEW_SONAR_HOME"
sudo chown -h travis:travis $TRAVIS_BUILD_DIR
sudo chown -h travis:travis $GRADLE_CACHE
sudo chown -h travis:travis $SONAR_HOME

printf "${RED}disk size after mount${NC}\n"
df -h
du -sh $HOME
du -sh $GRADLE_CACHE
du -sh $TRAVIS_BUILD_DIR

ls -la $MNT_POINT
