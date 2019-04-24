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
	"math/rand"
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
		length   int64
		code     string
	}

	decodingTest struct {
		code                                 string
		length                               int64
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
		for _, cols := range mustReadLines("validityTests.csv") {
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
		for _, cols := range append(
			mustReadLines("encoding.csv"),
			bytes.Split([]byte("-0.2820710399999935,36.07145996093760,15,6GFRP39C+5HG4QWR"), []byte(",")),
			bytes.Split([]byte("-0.2820710399999935,36.07145996093760,16,6GFRP39C+5HG4QWRV"), []byte(",")),
		) {
			encoding = append(encoding, encodingTest{
				lat:    mustFloat(cols[0]),
				lng:    mustFloat(cols[1]),
				length: mustInt(cols[2]),
				code:   string(cols[3]),
			})
		}
	}()

	go func() {
		defer wg.Done()
		for _, cols := range append(
			mustReadLines("decoding.csv"),
			bytes.Split([]byte("6GFRP39C+5HG4QWR,15,-0.2820710399999935,36.07145996093752,-0.2820709999999935,36.07146008300783"), []byte(",")),
			bytes.Split([]byte("6GFRP39C+5HG4QWRV,16,-0.2820710399999935,36.07145996093752,-0.2820709999999935,36.07146008300783"), []byte(",")),
		) {
			encoding = append(encoding, encodingTest{
				code:   string(cols[0]),
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
				code:  string(cols[0]),
				lat:   mustFloat(cols[1]),
				lng:   mustFloat(cols[2]),
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
	check := func(i int, code, name string, got, want float64) {
		if !closeEnough(got, want) {
			t.Errorf("%d. %q want %s=%f, got %f", i, code, name, want, got)
			t.FailNow()
		}
	}
	for i, elt := range decoding {
		got, err := Decode(elt.code)
		if err != nil {
			t.Errorf("%d. %q: %v", i, elt.code, err)
			continue
		}
		if got.codeLen != elt.length || !closeEnough(got.LatLo, elg.latLo) || !closeEnough(got.LatHi, elg.latHi) || !closeEnough(got.LngLo, elg.lngLo) || !closeEnough(got.LngHi, elg.lngHi) {
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

func mustReadLines(name string) [][][]byte {
	rows, err := readLines(filepath.Join("..", "test_data", name))
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

func mustInt(a []byte) float64 {
	f, err := strconv.ParseInt(string(a), 10, 64)
	if err != nil {
		panic(err)
	}
	return f
}

func TestPrecision(t *testing.T) {
	const c15 = "6GFRP39C+5HG4QWR"
	const c16 = "6GFRP39C+5HG4QWRV"
	want := CodeArea{
		LatLo: -0.2820710399999935, LatHi: -0.2820709999999935,
		LngLo: 36.07145996093752, LngHi: 36.07146008300783,
		Len: 15,
	}

	a15, err := Decode(c15)
	if err != nil {
		t.Errorf("%q Decode: %v", c15, err)
	}
	if a15 != want {
		t.Errorf("got %v, wanted %v", a15, want)
	}

	a16, err := Decode(c16)
	if err != nil {
		t.Errorf("%q Decode: %v", c16, err)
	}

	if a16 != a15 {
		t.Errorf("got %v, wanted %v", a15, a16)
	}

	t.Logf("15: %v, 16: %v", a15, a16)

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
		Encode(lat[i], lng[i], 16)
	}
}

func BenchmarkDecode(b *testing.B) {
	// Build random lat/lngs and encode them.
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	codes := make([]string, b.N)
	for i := 0; i < b.N; i++ {
		codes[i] = Encode(r.Float64()*180-90, r.Float64()*360-180, 16)
	}
	// Reset the timer and run the benchmark.
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		Decode(codes[i])
	}
}
