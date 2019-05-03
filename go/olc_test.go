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
	"bufio"
	"encoding/csv"
	"math"
	"math/rand"
	"os"
	"path/filepath"
	"strconv"
	"sync"
	"testing"
	"time"
)

var (
	validity []validityTest
	encoding []encodingTest
	decoding []decodingTest
	shorten  []shortenTest
)

type (
	validityTest struct {
		code                     string
		isValid, isShort, isFull bool
	}

	encodingTest struct {
		lat, lng float64
		length   int
		code     string
	}

	decodingTest struct {
		code                                 string
		length                               int
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
	wg.Add(4)

	go func() {
		defer wg.Done()
		for _, cols := range mustReadLines("validityTests.csv") {
			validity = append(validity, validityTest{
				code:    cols[0],
				isValid: cols[1] == "true",
				isShort: cols[2] == "true",
				isFull:  cols[3] == "true",
			})
		}
	}()

	go func() {
		defer wg.Done()
		for _, cols := range append(
			mustReadLines("encoding.csv"),
		) {
			encoding = append(encoding, encodingTest{
				lat:    mustFloat(cols[0]),
				lng:    mustFloat(cols[1]),
				length: mustInt(cols[2]),
				code:   cols[3],
			})
		}
	}()

	go func() {
		defer wg.Done()
		for _, cols := range append(
			mustReadLines("decoding.csv"),
		) {
			decoding = append(decoding, decodingTest{
				code:   cols[0],
				length: mustInt(cols[1]),
				latLo:  mustFloat(cols[2]),
				lngLo:  mustFloat(cols[3]),
				latHi:  mustFloat(cols[4]),
				lngHi:  mustFloat(cols[5]),
			})
		}
	}()

	go func() {
		defer wg.Done()
		for _, cols := range mustReadLines("shortCodeTests.csv") {
			shorten = append(shorten, shortenTest{
				code:  cols[0],
				lat:   mustFloat(cols[1]),
				lng:   mustFloat(cols[2]),
				short: cols[3],
				tType: cols[4],
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
			t.Errorf("%d. %q validity is %t (err=%v), wanted %t.", i, elt.code, got, err, elt.isValid)
		}
	}
}

func TestEncode(t *testing.T) {
	for i, elt := range encoding {
		got := Encode(elt.lat, elt.lng, elt.length)
		if got != elt.code {
			t.Errorf("%d. got %q for (%v,%v,%d), wanted %q.", i, got, elt.lat, elt.lng, elt.length, elt.code)
			t.FailNow()
		}
	}
}

func TestDecode(t *testing.T) {
	for i, elt := range decoding {
		got, err := Decode(elt.code)
		if err != nil {
			t.Errorf("%d. %q: %v", i, elt.code, err)
			continue
		}
		if got.Len != elt.length || !closeEnough(got.LatLo, elt.latLo) || !closeEnough(got.LatHi, elt.latHi) || !closeEnough(got.LngLo, elt.lngLo) || !closeEnough(got.LngHi, elt.lngHi) {
			t.Errorf("%d: got (%v) wanted (%v)", i, got, elt)
		}
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

func mustReadLines(name string) [][]string {
	csvFile, err := os.Open(filepath.Join("..", "test_data", name))
	if err != nil {
		panic(err)
	}
	reader := csv.NewReader(bufio.NewReader(csvFile))
	reader.Comment = '#'
	if records, err := reader.ReadAll(); err != nil {
		panic(err)
	} else {
		return records
	}
}

func mustFloat(a string) float64 {
	f, err := strconv.ParseFloat(a, 64)
	if err != nil {
		panic(err)
	}
	return f
}

func mustInt(a string) int {
	f, err := strconv.Atoi(a)
	if err != nil {
		panic(err)
	}
	return f
}

func TestFuzzCrashers(t *testing.T) {
	for i, code := range []string{
		"975722X9+88X29qqX297" +
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
	} {
		if err := Check(code); err != nil {
			t.Logf("%d. %q Check: %v", i, code, err)
		}
		area, err := Decode(code)
		if err != nil {
			t.Errorf("%d. %q Decode: %v", i, code, err)
		}
		if _, err = Decode(Encode(area.LatLo, area.LngLo, len(code))); err != nil {
			t.Errorf("%d. Lo Decode(Encode(%q, %f, %f, %d))): %v", i, code, area.LatLo, area.LngLo, len(code), err)
		}
		if _, err = Decode(Encode(area.LatHi, area.LngHi, len(code))); err != nil {
			t.Errorf("%d. Hi Decode(Encode(%q, %f, %f, %d))): %v", i, code, area.LatHi, area.LngHi, len(code), err)
		}
	}
}

func BenchmarkEncode(b *testing.B) {
	// Build the random lat/lngs.
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	lat := make([]float64, b.N)
	lng := make([]float64, b.N)
	for i := 0; i < b.N; i++ {
		lat[i] = r.Float64()*180 - 90
		lng[i] = r.Float64()*360 - 180
	}
	// Reset the timer and run the benchmark.
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		Encode(lat[i], lng[i], maxCodeLen)
	}
}

func BenchmarkDecode(b *testing.B) {
	// Build random lat/lngs and encode them.
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	codes := make([]string, b.N)
	for i := 0; i < b.N; i++ {
		codes[i] = Encode(r.Float64()*180-90, r.Float64()*360-180, maxCodeLen)
	}
	// Reset the timer and run the benchmark.
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		Decode(codes[i])
	}
}
