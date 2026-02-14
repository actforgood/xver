// Copyright The ActForGood Authors.
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://github.com/actforgood/xver/blob/main/LICENSE

package xver_test

import (
	"reflect"
	"runtime/debug"
	"testing"
	"testing/synctest"

	"github.com/actforgood/xver"
)

func TestInformation(t *testing.T) {
	t.Parallel()

	// arrange
	expected := xver.Info{}
	expected.App.Name = "xver.test"
	if goBuildInfo, available := debug.ReadBuildInfo(); available {
		expected.Build.Go = goBuildInfo.GoVersion[2:] // without the "go" prefix
		expected.App.Version = goBuildInfo.Main.Version
		for _, setting := range goBuildInfo.Settings {
			switch setting.Key {
			case "GOOS":
				expected.Build.OS = setting.Value
				if expected.Build.OS == "windows" {
					expected.App.Name += ".exe"
				}
			case "GOARCH":
				expected.Build.Arch = setting.Value
			}
		}
	}
	subject := xver.Information

	// act
	actual := subject()

	// assert
	if !reflect.DeepEqual(expected, actual) {
		t.Errorf(
			"\n\texpected \"%+v\" (%T),\n\tbut got \"%+v\" (%T)\n",
			expected, expected,
			actual, actual,
		)
	}
}

func TestInformation_concurrency(t *testing.T) {
	t.Parallel()

	// Note: this test does not expect much of a thing; it is meant to
	// see if something goes wrong in `test -race ...` context.

	synctest.Test(t, func(t *testing.T) {
		// arrange
		const goroutinesNo = 50
		subject := xver.Information

		// act
		for range goroutinesNo {
			go func() {
				actual := subject()

				// assert
				if len(actual.Build.Go) == 0 {
					t.Errorf("expected go version to be set")
				}
			}()
		}

		synctest.Wait()
	})
}
