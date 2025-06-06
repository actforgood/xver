// Copyright The ActForGood Authors.
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://github.com/actforgood/xver/blob/main/LICENSE

package xver

import (
	"os"
	"path/filepath"
	"regexp"
	"runtime/debug"
	"strings"
	"sync"
)

// Info holds basic build information about an application.
//
// Some information may not be available, by default.
//
// To set the app name / app version / build date you can use
// `-X` option when running `go build` cmd.
type Info struct {
	// App holds app info.
	App App `json:"app"`
	// Build holds build info.
	Build Build `json:"build"`
}

// App holds basic application information, like name and version.
type App struct {
	// Name holds the application name.
	// Defaults to executable name.
	//
	// You can set it during build time with -X 'github.com/actforgood/xver.name=<appName>'.
	Name string `json:"name"`
	// Version holds the application version.
	// Defaults to [debug.BuildInfo.Main.Version].
	//
	// You can set it during build time with -X 'github.com/actforgood/xver.version=<appVersion>'.
	//
	// Note from go1.24 release:
	// 	The go build command now sets the main module’s version in the compiled binary based on
	// 	the version control system tag and/or commit. A +dirty suffix will be appended if there
	// 	are uncommitted changes. Use the -buildvcs=false flag to omit version control information
	// 	from the binary.
	Version string `json:"version"`
}

// Build holds basic build information,
// like the go version used and application built time.
type Build struct {
	// Go holds the go version application was compiled with.
	//
	// It is taken from [debug.ReadBuildInfo], if available.
	Go string `json:"go"`
	// Arch is the architecture binary was build for.
	//
	// It is taken from [debug.ReadBuildInfo], if available.
	Arch string `json:"arch"`
	// OS is the operating system binary was build for.
	//
	// It is taken from [debug.ReadBuildInfo], if available.
	OS string `json:"os"`
	// Commit is the commit sha.
	//
	// It is taken from [debug.ReadBuildInfo], if available.
	//
	// You can set it during build time with -X 'github.com/actforgood/xver.commit=<gitCommit>'.
	Commit string `json:"commit,omitempty"`
	// Date is application build date.
	//
	// It is taken from [debug.ReadBuildInfo], if available.
	//
	// You can set it during build time with -X 'github.com/actforgood/xver.date=<buildDate>'.
	Date string `json:"date"`
}

var (
	once sync.Once
	info Info

	name    = ""
	version = ""
	date    = ""
	commit  = ""
)

// Information returns information about the application.
func Information() Info {
	once.Do(func() {
		if name != "" {
			info.App.Name = name
		} else {
			execPath, _ := os.Executable()
			info.App.Name = filepath.Base(execPath)
		}
		info.App.Version = version
		info.Build.Date = date
		info.Build.Commit = commit

		buildInfo, available := debug.ReadBuildInfo()
		if !available {
			return
		}
		info.Build.Go = strings.TrimPrefix(buildInfo.GoVersion, "go")
		if buildInfo.Main.Version != "" {
			regex := regexp.MustCompile(`^v[\d]+\.[\d]+\.[\d]+.*`)
			if regex.MatchString(buildInfo.Main.Version) { // remove "v" prefix
				info.App.Version = buildInfo.Main.Version[1:]
			} else {
				info.App.Version = buildInfo.Main.Version
			}
		}

		for _, setting := range buildInfo.Settings {
			switch setting.Key {
			case "vcs.time":
				if info.Build.Date == "" {
					info.Build.Date = setting.Value
				}
			case "vcs.revision":
				if info.Build.Commit == "" {
					info.Build.Commit = setting.Value
				}
			case "vcs.modified":
				if setting.Value == "true" && !strings.HasSuffix(info.App.Version, "+dirty") {
					info.App.Version += "+dirty"
				}
			case "GOOS":
				info.Build.OS = setting.Value
			case "GOARCH":
				info.Build.Arch = setting.Value
			}
		}
	})

	return info
}
