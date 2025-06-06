#!/usr/bin/env bash

#
# This makes some checks upon demoapp.
# Prerequisites:
#   - demoapp.sh must be run prior to running this script.
#   - jq command should be available
#
# Example of usage of this script:
# ./path/to/scripts/integration_test.sh
#

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")

# check prerequisites
DEMO_EXE="$SCRIPT_PATH/../bin/demoapp/demoapp"
if [ ! -x "$DEMO_EXE" ]; then \
    printf '\033[0;31m Prerequisite check failed \033[0m > %s executable was not found. Please run demoapp.sh first.' "$DEMO_EXE"
    exit 1
fi
JQ_EXE=$(which jq)
if [ ! -x "$JQ_EXE" ]; then \
    printf '\033[0;31m Prerequisite check failed \033[0m > Please install "jq" unix utility.'
    exit 1
fi

# arrange
buildOS=$(uname)
case $buildOS in # Note: common cases are covered, fill free to enrich this part
  'Linux')
    buildOS='linux'
    ;;
  'WindowsNT')
    buildOS='windows'
    ;;
  'Darwin') 
    buildOS='darwin'
    ;;
  *) ;;
esac
if  [[ $buildOS == MSYS* ]]; then \
    buildOS='windows' # github windows runners
fi

buildArch=$(uname -m)
case $buildArch in # Note: common cases are covered, fill free to enrich this part
  'x86_64')
    buildArch='amd64'
    ;;
  *) ;;
esac

goVer=$(go version | grep -Eo "[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+")

# act
DEMO_OUTPUT=$($DEMO_EXE)

# assert
actualAppJSON=$(echo "$DEMO_OUTPUT" | jq -c '.app')
expectedAppJSON="{\"name\":\"my-demo-app\",\"version\":\"9.8.7\"}"
if [ "$actualAppJSON" != "$expectedAppJSON" ]; then \
    printf '\033[0;31m Test failed \033[0m > expected %s, but got %s\n' "$expectedAppJSON" "$actualAppJSON"
    exit 1
fi

actualBuildJSON=$(echo "$DEMO_OUTPUT" | jq -c '.build')
expectedBuildJSON="{\"go\":\"$goVer\",\"arch\":\"$buildArch\",\"os\":\"$buildOS\",\"commit\":\"a9139a0\",\"date\":\"2025-06-05T21:58:45Z\"}"
if [ "$actualBuildJSON" != "$expectedBuildJSON" ]; then \
    printf '\033[0;31m Test failed \033[0m > expected %s, but got %s\n' "$expectedBuildJSON" "$actualBuildJSON"
    exit 1
fi

echo "[OK] Test passed."
