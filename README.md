# Xver

[![Build Status](https://github.com/actforgood/xver/actions/workflows/build.yml/badge.svg)](https://github.com/actforgood/xver/actions/workflows/build.yml)
[![License](https://img.shields.io/badge/license-MIT-blue)](https://raw.githubusercontent.com/actforgood/xver/main/LICENSE)
[![Coverage Status](https://coveralls.io/repos/github/actforgood/xver/badge.svg?branch=main)](https://coveralls.io/github/actforgood/xver?branch=main)
[![Goreportcard](https://goreportcard.com/badge/github.com/actforgood/xver)](https://goreportcard.com/report/github.com/actforgood/xver)
[![Go Reference](https://pkg.go.dev/badge/github.com/actforgood/xver.svg)](https://pkg.go.dev/github.com/actforgood/xver)  

---
Package `xver` provides information about an application upon a JSON structure that looks like:
```go
{
  "app": {
    "name": "example",
    "version": "1.2.0"
  },
  "build": {
    "go": "1.24.3",
    "arch": "amd64",
    "os": "darwin",
    "commit": "a9139a022be172adb222e84eda2d8808fbeb01e0",
    "date": "2025-06-05T21:03:40Z"
  }
}
```
You can set the app name, app version, build date and commit with -X build flags like:
```shell
 go build -ldflags="-s -w -X 'github.com/actforgood/xver.name=example' -X 'github.com/actforgood/xver.version=1.2.0' -X 'github.com/actforgood/xver.date=2025-06-05T21:03:40Z' -X 'github.com/actforgood/xver.commit=a9139a0'" -o example /path/to/example-app/cmd/main.go
```


### Installation

```shell
$ go get github.com/actforgood/xver
```

### Example
A basic demo app can be setup with [./scripts/demoapp.sh](scripts/demoapp.sh) included in the repo, and different behaviors on what information is available by default using the different `build` / `run` / `install` commands can be observed.

<details>
<summary><b>Output</b></summary>

```
>>> Creating demoapp in /Users/JohnDoe/go/xver/scripts/../bin/demoapp/ 
>>> Initializing git repo for it and tagging to v1.2.3 

>>> 1. go build 
```
```json
{
  "app": {
    "name": "demoapp",
    "version": "1.2.3"
  },
  "build": {
    "go": "1.24.3",
    "arch": "amd64",
    "os": "darwin",
    "commit": "addaf89ed0461cdadbf74214e217899bfc04dcad",
    "date": "2025-06-06T08:33:53Z"
  }
}
```
```
>>> 2. go run main.go 
```
```json
{
  "app": {
    "name": "main",
    "version": ""
  },
  "build": {
    "go": "1.24.3",
    "arch": "amd64",
    "os": "darwin",
    "date": ""
  }
}
```
```
>>> 3. go install
```
```json
{
  "app": {
    "name": "demoapp",
    "version": "1.2.3"
  },
  "build": {
    "go": "1.24.3",
    "arch": "amd64",
    "os": "darwin",
    "commit": "addaf89ed0461cdadbf74214e217899bfc04dcad",
    "date": "2025-06-06T08:33:53Z"
  }
}
```
```
>>> 4. Creating a new file causing the repo to be dirty & go build 
```
```json
{
  "app": {
    "name": "demoapp",
    "version": "1.2.3+dirty"
  },
  "build": {
    "go": "1.24.3",
    "arch": "amd64",
    "os": "darwin",
    "commit": "addaf89ed0461cdadbf74214e217899bfc04dcad",
    "date": "2025-06-06T08:33:53Z"
  }
}
```
```
>>> 5. Setting information via flags 
>>> go build -ldflags="-s -w -X 'github.com/actforgood/xver.name=my-demo-app' -X 'github.com/actforgood/xver.version=9.8.7' -X 'github.com/actforgood/xver.date=2025-06-05T21:58:45Z' -X 'github.com/actforgood/xver.commit=a9139a0'" -o demoapp main.go
```
```json
{
  "app": {
    "name": "my-demo-app",
    "version": "9.8.7"
  },
  "build": {
    "go": "1.24.3",
    "arch": "amd64",
    "os": "darwin",
    "commit": "a9139a0",
    "date": "2025-06-05T21:58:45Z"
  }
}
```

</details>

---

<details>
<summary><b>Example of a little code snipped for printing version from cmd line arguments</b></summary>

```go
package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/actforgood/xver"
)

func main() {
	PrintVersion()
	// ...
}

func PrintVersion() {
	if len(os.Args) < 2 || os.Args[1] != "version" {
		return
	}

	info := xver.Information()

	var output string
	if len(os.Args) > 2 && os.Args[2] == "--json" {
		infoJSON, _ := json.Marshal(info)
		output = string(infoJSON)
	} else {
		output = fmt.Sprintf(
			"%s/%s (%s/%s)",
			info.App.Name, info.App.Version,
			info.Build.OS, info.Build.Arch,
		)
	}
	fmt.Println(output)

	os.Exit(0)
}

// Example of output for `./demoapp version`:
// demoapp/1.2.3 (darwin/amd64)
//
// Example of output for `./demoapp version --json`:
// {"app":{"name":"demoapp","version":"1.2.3"},"build":{"go":"1.24.3","arch":"amd64","os":"darwin","commit":"34091f1484780b4e8990df6e1d50f2bc6181430b","date":"2025-06-06T09:48:30Z"}}
```

</details>

---

<details>
<summary><b>Example of a little code snipped for printing web server information</b></summary>

```go
package main

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/actforgood/xver"
)

func main() {
	hdlr := http.NewServeMux()
	hdlr.HandleFunc("/info", InfoHandleFunc)
	// ...

	srv := &http.Server{
		Addr:    ":8080",
		Handler: hdlr,
	}
	log.Fatal(srv.ListenAndServe())
}

func InfoHandleFunc(w http.ResponseWriter, r *http.Request) {
	info := xver.Information()
	enc := json.NewEncoder(w)
	_ = enc.Encode(info)
}

// Example of output for `curl http://127.0.0.1:8080/info`:
// {"app":{"name":"demoapp","version":"1.2.3"},"build":{"go":"1.24.3","arch":"amd64","os":"darwin","commit":"34091f1484780b4e8990df6e1d50f2bc6181430b","date":"2025-06-06T09:48:30Z"}}`
```

</details>

### Misc 
Feel free to use this pkg if you like it and it fits your needs.   
As it is a light/lite pkg, you can also just copy-paste the code instead of importing it, keeping the license header.  


### License
This package is released under a MIT license. See [LICENSE](LICENSE).  
