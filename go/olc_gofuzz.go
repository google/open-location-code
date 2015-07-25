// +build: gofuzz

// Copyright 2015 Tamás Gulácsi. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package olc

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/inconshreveable/log15.v2"
)

// Fuzz usage:
//   go get github.com/dvyukov/go-fuzz/...
//
//   go-fuzz-build github.com/google/open-location-code/go && go test -tags gofuzz && go-fuzz -bin=./olc-fuzz.zip -workdir=workdir

func Fuzz(data []byte) int {
	code := string(data)
	if err := Check(code); err != nil {
		return 0
	}
	area, err := Decode(code)
	if err != nil {
		return 2
	}
	if _, err = Decode(Encode(area.LatLo, area.LngLo, len(code))); err != nil {
		return 2
	}
	if _, err = Decode(Encode(area.LatHi, area.LngHi, len(code))); err != nil {
		return 2
	}

	return 1
}

func init() {
	dir := filepath.Join("workdir", "corpus")
	if _, err := os.Stat(filepath.Join(dir, "001.code.txt")); err == nil {
		return
	}
	Log.SetHandler(log15.StderrHandler)
	src := filepath.Join("..", "test_data")
	fis, err := ioutil.ReadDir(src)
	if err != nil {
		Log.Error("read test_data", "dir", src, "error", err)
		return
	}
	_ = os.MkdirAll(dir, 0755)
	n := 0
	for _, fi := range fis {
		if !strings.HasSuffix(fi.Name(), ".csv") {
			continue
		}
		fn := filepath.Join(src, fi.Name())
		data, err := ioutil.ReadFile(fn)
		if err != nil {
			Log.Error("read csv", "file", fn, "error", err)
			continue
		}
		for _, row := range bytes.Split(data, []byte{'\n'}) {
			if i := bytes.IndexByte(row, '#'); i >= 0 {
				row = row[:i]
			}
			// assume that the first field is the code
			if i := bytes.IndexByte(row, ','); i >= 0 {
				fn := filepath.Join(dir, fmt.Sprintf("%003d.code.txt", n))
				if err := ioutil.WriteFile(fn, row[:i], 0644); err != nil {
					Log.Error("Write", "file", fn, "error", err)
					continue
				}
				n++
			}
		}
	}
}
