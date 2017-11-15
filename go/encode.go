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
	"errors"
	"fmt"
	"log"
	"math"
	"sync"
)

var (
	// ErrShort indicates the provided code was a short code.
	ErrShort = errors.New("short code")
	// ErrNotShort indicates the provided code was not a short code.
	ErrNotShort = errors.New("not short code")
)

const (
	sepPos  = 8
	encBase = len(Alphabet)

	minTrimmableCodeLen = 6
)

var codePool = sync.Pool{
	New: func() interface{} { return make([]byte, 0, pairCodeLen+1) },
}

// Encode a location into an Open Location Code.
//
// Produces a code of the specified codeLen, or the default length if
// codeLen < 8;
// if codeLen is odd, it is incremented to be even.
//
// latitude is signed decimal degrees. Will be clipped to the range -90 to 90.
// longitude is signed decimal degrees. Will be normalised to the range -180 to 180.
// The length determines the accuracy of the code. The default length is
// 10 characters, returning a code of approximately 13.5x13.5 meters. Longer
// codes represent smaller areas, but lengths > 14 are sub-centimetre and so
// 11 or 12 are probably the limit of useful codes.
func Encode(lat, lng float64, codeLen int) string {
	if codeLen <= 0 {
		codeLen = pairCodeLen
	} else if codeLen < 2 {
		codeLen = 2
	} else if codeLen < pairCodeLen && codeLen%2 == 1 {
		codeLen++
	}
	lat, lng = clipLatitude(lat), normalizeLng(lng)
	// Latitude 90 needs to be adjusted to be just less, so the returned code
	// can also be decoded.
	if lat == latMax {
		lat = normalizeLat(lat - computePrec(codeLen, false))
	}
	// The tests for lng=180 want 2,2 but without this we get W,2
	if lng == lngMax {
		lng = normalizeLng(lng + computePrec(codeLen+2, true))
	}
	debug("Encode lat=%f lng=%f", lat, lng)
	n := codeLen
	if n > pairCodeLen {
		n = pairCodeLen
	}
	code := codePool.Get().([]byte)
	code = encodePairs(code[:0], lat, lng, n)
	codeS := string(code)
	if codeLen > pairCodeLen {
		finerCode, err := encodeGrid(code, lat, lng, codeLen-pairCodeLen)
		if err != nil {
			log.Printf("encodeGrid(%q, %f, %f, %d): %v", code, lat, lng, codeLen-pairCodeLen, err)
		} else {
			codeS = string(finerCode)
		}
	}
	codePool.Put(code)
	return codeS
}

// encodePairs encode the location into a sequence of OLC lat/lng pairs.
//
// Appends to the given code byte slice!
//
// This uses pairs of characters (longitude and latitude in that order) to
// represent each step in a 20x20 grid. Each code, therefore, has 1/400th
// the area of the previous code.
func encodePairs(code []byte, lat, lng float64, codeLen int) []byte {
	lat += latMax
	lng += lngMax
	for digits := 0; digits < codeLen; {
		// value of digits in this place, in decimal degrees
		placeValue := pairResolutions[digits/2]

		digitValue := int(lat / placeValue)
		lat -= float64(digitValue) * placeValue
		code = append(code, Alphabet[digitValue])
		digits++

		digitValue = int(lng / placeValue)
		lng -= float64(digitValue) * placeValue
		code = append(code, Alphabet[digitValue])
		digits++

		if digits == sepPos && digits < codeLen {
			code = append(code, Separator)
		}
	}
	for len(code) < sepPos {
		code = append(code, Padding)
	}
	if len(code) == sepPos {
		code = append(code, Separator)
	}

	return code
}

// encodeGrid encodes a location using the grid refinement method into
// an OLC string.
//
// Appends to the given code byte slice!
//
// The grid refinement method divides the area into a grid of 4x5, and uses a
// single character to refine the area. This allows default accuracy OLC codes
// to be refined with just a single character.
func encodeGrid(code []byte, lat, lng float64, codeLen int) ([]byte, error) {
	// Adjust to positive ranges.
	lat += latMax
	lng += lngMax
	// To avoid problems with floating point, get rid of the degrees.
	lat = math.Remainder(lat, 1.0)
	lng = math.Remainder(lng, 1.0)
	latPlaceValue, lngPlaceValue := gridSizeDegrees, gridSizeDegrees
	lat = math.Remainder(lat, latPlaceValue)
	if lat < 0 {
		lat += latPlaceValue
	}
	lng = math.Remainder(lng, lngPlaceValue)
	if lng < 0 {
		lng += lngPlaceValue
	}
	for i := 0; i < codeLen; i++ {
		row := int(math.Floor(lat / (latPlaceValue / gridRows)))
		col := int(math.Floor(lng / (lngPlaceValue / gridCols)))
		pos := row*gridCols + col
		if !(0 <= pos && pos < len(Alphabet)) {
			return nil, fmt.Errorf("pos=%d is out of alphabet", pos)
		}
		code = append(code, Alphabet[pos])
		if i == codeLen-1 {
			break
		}

		latPlaceValue /= gridRows
		lngPlaceValue /= gridCols
		lat -= float64(row) * latPlaceValue
		lng -= float64(col) * lngPlaceValue
	}
	return code, nil
}

// computePrec computes the precision value for a given code length.
// Lengths <= 10 have the same precision for latitude and longitude,
// but lengths > 10 have different precisions due to the grid method
// having fewer columns than rows.
func computePrec(codeLen int, longitudal bool) float64 {
	if codeLen <= 10 {
		return math.Pow(20, math.Floor(float64(codeLen/-2+2)))
	}
	g := float64(gridRows)
	if longitudal {
		g = gridCols
	}
	return math.Pow(20, -3) / math.Pow(g, float64(codeLen-10))
}

func clipLatitude(lat float64) float64 {
	if lat > latMax {
		return latMax
	}
	if lat < -latMax {
		return -latMax
	}
	return lat
}
