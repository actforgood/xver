#!/usr/bin/env bash

#
# This script creates a demo project that uses this package
# and shows different usage scenarios.
#
# Example of usage of this script:
# ./path/to/scripts/demoapp.sh
#


SCRIPT_PATH=$(dirname "$(readlink -f "$0")")

WORKING_DIR="$SCRIPT_PATH/../bin/demoapp/"
rm -rf "$WORKING_DIR" > /dev/null 2>&1 && mkdir -p "$WORKING_DIR"
cd "$WORKING_DIR" || exit 1

printf "\033[0;34m>>> Creating demoapp in %s \033[0m\n" "$WORKING_DIR"

cat > "main.go" << EOM
package main

// Note: generated sample project that uses github.com/actforgood/xver

import (
	"encoding/json"
	"fmt"

	"github.com/actforgood/xver"
)

func main() {
	appInfo := xver.Information()
	appInfoJSON, _ := json.MarshalIndent(appInfo, "", "  ")
	fmt.Println(string(appInfoJSON))
}
EOM

cat > "go.mod" << EOM
module demoapp

go 1.26

replace github.com/actforgood/xver v1.0.0 => ../../

require github.com/actforgood/xver v1.0.0
EOM

cat > ".gitignore" << EOM
install/
demoapp
EOM

printf "\033[0;34m>>> Initializing git repo for it and tagging to v1.2.3 \033[0m\n"
git init > /dev/null 2>&1 && \
    git branch -m main > /dev/null 2>&1 && \
    git add main.go go.mod .gitignore > /dev/null 2>&1 && \
    git commit -m "Demo application that uses actforgood/xver" > /dev/null 2>&1 && \
    git tag -a v1.2.3 -m "v1.2.3" > /dev/null 2>&1

printf "\n"
printf "\033[0;34m>>> 1. go build \033[0m\n"
go build && ./demoapp

printf "\033[0;34m>>> 2. go run main.go \033[0m\n"
go run main.go

printf "\033[0;34m>>> 3. go install \033[0m\n"
GOPATH="${WORKING_DIR}install" go install && ./install/bin/demoapp

printf "\033[0;34m>>> 4. Creating a new file causing the repo to be dirty & go build \033[0m\n"
touch new_file.dirty && go build && ./demoapp && rm new_file.dirty

printf "\033[0;34m>>> 5. Setting information via flags \033[0m\n"
# UTC_DATETIME=$(date -u +'%Y-%m-%dT%H:%M:%SZ') # more realistic scenario
UTC_DATETIME="2025-06-05T21:58:45Z" # hardcoded for integration test
# COMMIT=$(git rev-parse --short HEAD) # more realistic scenario
COMMIT="a9139a0" # hardcoded for integration test
printf "\033[0;34m>>> go build -ldflags=\"-s -w -X 'github.com/actforgood/xver.name=my-demo-app' -X 'github.com/actforgood/xver.version=9.8.7' -X 'github.com/actforgood/xver.date=%s' -X 'github.com/actforgood/xver.commit=%s'\" -o demoapp main.go \033[0m\n" "$UTC_DATETIME" "$COMMIT"
go build \
	-ldflags=" \
		-s -w \
		-X 'github.com/actforgood/xver.name=my-demo-app' \
		-X 'github.com/actforgood/xver.version=9.8.7' \
		-X 'github.com/actforgood/xver.date=$UTC_DATETIME' \
		-X 'github.com/actforgood/xver.commit=$COMMIT' \
		
	" \
	-o demoapp main.go && ./demoapp
