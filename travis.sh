#!/usr/bin/env bash
set -euo pipefail

# current directory is $TRAVIS_BUILD_DIR
# move out of it because it will be moved to RAM disk
#cd $HOME
ls -al $HOME
#$TRAVIS_BUILD_DIR/.travis/setup_ramdisk.sh
#ls -al $HOME

#cd $TRAVIS_BUILD_DIR

#
# Configure Maven settings and install some script utilities
#
configureTravis() {
  mkdir -p ~/.local
  curl -sSL https://github.com/SonarSource/travis-utils/tarball/v55 | tar zx --strip-components 1 -C ~/.local
  source ~/.local/bin/install
}
configureTravis

#
# Travis fails on timeout when build does not print logs
# during 10 minutes. This aims to bypass this
# behavior when building the slow sonar-server sub-project.
#
keep_alive() {
  while true; do
    echo -en "\a"
    sleep 60
  done
}
keep_alive &

print_gc_logs() {
  echo "=========="
  cat /home/travis/.gradle/daemon/5.6.1/gclogs.txt
  echo "=========="
}

print_gc_logs_daemon() {
  sleep 3300
  print_gc_logs
}
print_gc_logs_daemon &

# When a pull request is open on the branch, then the job related
# to the branch does not need to be executed and should be canceled.
# It does not book slaves for nothing.
# @TravisCI please provide the feature natively, like at AppVeyor or CircleCI ;-)
cancel_branch_build_with_pr || if [[ $? -eq 1 ]]; then exit 0; fi

case "$TARGET" in

BUILD)
  git fetch --unshallow
  ./gradlew build --info --no-daemon --console plain
  print_gc_logs

echo "disk size after build"
df -h
pwd
du -sh $HOME
du -sh $TRAVIS_BUILD_DIR

  # the '-' at the end is needed when using set -u (the 'nounset' flag)
  # see https://stackoverflow.com/a/9824943/641955
    ./gradlew jacocoTestReport sonarqube --no-daemon --info --console plain \
      -Dsonar.projectKey="sns-seb_sonarqube" \
      -Dsonar.organization="sns-seb-github" \
      -Dsonar.host.url=https://sonarcloud.io \
      -Dsonar.login="b97e5ead51428ea12676e4dc21b61d0c7c4f6477"
  print_gc_logs
  ;;

WEB_TESTS)
  ./gradlew :server:sonar-web:yarn :server:sonar-web:yarn_validate --no-daemon --console plain
  ;;
  
*)
  echo "Unexpected TARGET value: $TARGET"
  exit 1
  ;;

esac

