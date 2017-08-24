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
	"io/ioutil"
	"math"
	"path/filepath"
	"strconv"
	"sync"
	"testing"
)

var (
	validity []validityTest
	encoding []encodingTest
	shorten  []shortenTest
)

type (
	validityTest struct {
		code                     string
		isValid, isShort, isFull bool
	}

	encodingTest struct {
		code                                 string
		lat, lng, latLo, lngLo, latHi, lngHi float64
	}

	shortenTest struct {
		code     string
		lat, lng float64
		short    string
		tType    string
	}
)

func init() {
	var wg sync.WaitGroup
	wg.Add(3)

	go func() {
		defer wg.Done()
		for _, cols := range mustReadLines("validity") {
			validity = append(validity, validityTest{
				code:    string(cols[0]),
				isValid: cols[1][0] == 't',
				isShort: cols[2][0] == 't',
				isFull:  cols[3][0] == 't',
			})
		}
	}()

	go func() {
		defer wg.Done()
		for _, cols := range mustReadLines("encoding") {
			encoding = append(encoding, encodingTest{
				code: string(cols[0]),
				lat:  mustFloat(cols[1]), lng: mustFloat(cols[2]),
				latLo: mustFloat(cols[3]), lngLo: mustFloat(cols[4]),
				latHi: mustFloat(cols[5]), lngHi: mustFloat(cols[6]),
			})
		}
	}()

	go func() {
		defer wg.Done()
		for _, cols := range mustReadLines("shortCode") {
			shorten = append(shorten, shortenTest{
				code: string(cols[0]),
				lat:  mustFloat(cols[1]), lng: mustFloat(cols[2]),
				short: string(cols[3]),
				tType: string(cols[4]),
			})
		}
	}()
	wg.Wait()
}

func TestCheck(t *testing.T) {
	for i, elt := range validity {
		err := Check(elt.code)
		got := err == nil
		if got != elt.isValid {
			t.Errorf("%d. %q validity is %t (err=%v), awaited %t.", i, elt.code, got, err, elt.isValid)
		}
	}
}

func TestEncode(t *testing.T) {
	for i, elt := range encoding {
		n := len(stripCode(elt.code))
		code := Encode(elt.lat, elt.lng, n)
		if code != elt.code {
			t.Errorf("%d. got %q for (%v,%v,%d), awaited %q.", i, code, elt.lat, elt.lng, n, elt.code)
			t.FailNow()
		}
	}
}

func TestDecode(t *testing.T) {
	check := func(i int, code, name string, got, want float64) {
		if !closeEnough(got, want) {
			t.Errorf("%d. %q want %s=%f, got %f", i, code, name, want, got)
			t.FailNow()
		}
	}
	for i, elt := range encoding {
		area, err := Decode(elt.code)
		if err != nil {
			t.Errorf("%d. %q: %v", i, elt.code, err)
			continue
		}
		code := Encode(elt.lat, elt.lng, area.Len)
		if code != elt.code {
			t.Errorf("%d. encode (%f,%f) got %q, awaited %q", i, elt.lat, elt.lng, code, elt.code)
		}
		C := func(name string, got, want float64) {
			check(i, elt.code, name, got, want)
		}
		C("latLo", area.LatLo, elt.latLo)
		C("latHi", area.LatHi, elt.latHi)
		C("lngLo", area.LngLo, elt.lngLo)
		C("lngHi", area.LngHi, elt.lngHi)
	}
}

func TestShorten(t *testing.T) {
	for i, elt := range shorten {
		if elt.tType == "B" || elt.tType == "S" {
			got, err := Shorten(elt.code, elt.lat, elt.lng)
			if err != nil {
				t.Errorf("%d. shorten %q: %v", i, elt.code, err)
				t.FailNow()
			}
			if got != elt.short {
				t.Errorf("%d. shorten got %q, awaited %q.", i, got, elt.short)
				t.FailNow()
			}
		}

		if elt.tType == "B" || elt.tType == "R" {
			got, err := RecoverNearest(elt.short, elt.lat, elt.lng)
			if err != nil {
				t.Errorf("%d. nearest %q: %v", i, got, err)
				t.FailNow()
			}
			if got != elt.code {
				t.Errorf("%d. nearest got %q, awaited %q.", i, got, elt.code)
				t.FailNow()
			}
		}
	}
}

func closeEnough(a, b float64) bool {
	return a == b || math.Abs(a-b) <= 0.0000000001
}

func mustReadLines(name string) [][][]byte {
	rows, err := readLines(filepath.Join("..", "test_data", name+"Tests.csv"))
	if err != nil {
		panic(err)
	}
	return rows
}

func readLines(path string) (rows [][][]byte, err error) {
	data, err := ioutil.ReadFile(path)
	if err != nil {
		return nil, err
	}
	for _, row := range bytes.Split(data, []byte{'\n'}) {
		if j := bytes.IndexByte(row, '#'); j >= 0 {
			row = row[:j]
		}
		row = bytes.TrimSpace(row)
		if len(row) == 0 {
			continue
		}
		rows = append(rows, bytes.Split(row, []byte{','}))
	}
	return rows, nil
}

func mustFloat(a []byte) float64 {
	f, err := strconv.ParseFloat(string(a), 64)
	if err != nil {
		panic(err)
	}
	return f
}

func TestFuzzCrashers(t *testing.T) {
	for i, code := range []string{
		"+975722X988X29qqX297" +
			"5722X888X2975722X888" +
			"X2975722X988X29qqX29" +
			"75722X888X2975722X88" +
			"8X2975722X988X29qqX2" +
			"975722X88qqX2975722X" +
			"888X2975722X888X2975" +
			"722X988X29qqX2975722" +
			"X888X2975722X888X297" +
			"5722X988X29qqX297572" +
			"2X888X2975722X888X29" +
			"75722X988X29qqX29757" +
			"22X88qqX2975722X888X" +
			"2975722X888X2975722X" +
			"988X29qqX2975722X888" +
			"X2975722X888X2975722" +
			"X988X29qqX2975722X88" +
			"8X2975722X888X297572" +
			"2X988X29qqX2975722X8" +
			"8qqX2975722X888X2975" +
			"722X888X2975722X988X" +
			"29qqX2975722X888X297" +
			"5722X888X2975722X988" +
			"X20",

		"+qqX2975722X888X2975" +
			"722X888X2975722X988X" +
			"29qqX2975722X888X297" +
			"5722X888X2975722X988" +
			"X29qqX2975722X888X29" +
			"75722X888X2975722X98" +
			"8X29qqX2975722X88qqX" +
			"2975722X888X2975722X" +
			"888X2975722X988X29qq" +
			"X2975722X888X2975722" +
			"X888X2975722X988X29q" +
			"qX2975722X888X297572" +
			"2X888X2975722X988X29" +
			"qqX2975722X88qqX2975" +
			"722X888X2975722X888X" +
			"2975722X988X29qqX297" +
			"5722X888X2975722X888" +
			"X2975722X988X29qqX29" +
			"75722X888X2975722X88" +
			"8X2975722X988X29qqX2" +
			"975722X88qqX2975722X" +
			"888X2975722X888X2975" +
			"722X988X29qqX2975722" +
			"X888X2975722X888X297" +
			"5722X988X29qqX297572" +
			"2X888X2975722X888X29" +
			"75722X988X29qqX29757" +
			"2",
	} {
		if err := Check(code); err != nil {
			t.Logf("%d. %q Check: %v", i, code, err)
		}
		area, err := Decode(code)
		if err != nil {
			t.Logf("%d. %q Decode: %v", i, code, err)
		}
		if _, err = Decode(Encode(area.LatLo, area.LngLo, len(code))); err != nil {
			t.Logf("%d. Lo Decode(Encode(%q, %f, %f, %d))): %v", i, code, area.LatLo, area.LngLo, len(code), err)
		}
		if _, err = Decode(Encode(area.LatHi, area.LngHi, len(code))); err != nil {
			t.Logf("%d. Hi Decode(Encode(%q, %f, %f, %d))): %v", i, code, area.LatHi, area.LngHi, len(code), err)
		}

	}
}
