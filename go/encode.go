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
	"math"
	"strings"
)

var (
	// ErrShort indicates the provided code was a short code.
	ErrShort = errors.New("short code")
	// ErrNotShort indicates the provided code was not a short code.
	ErrNotShort = errors.New("not short code")
)

const (
	minTrimmableCodeLen = 6
)

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
	} else if codeLen > maxCodeLen {
		codeLen = maxCodeLen
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
	var code [15]byte

	// Compute the code.
	// This approach converts each value to an integer after multiplying it by
	// the final precision. This allows us to use only integer operations, so
	// avoiding any accumulation of floating point representation errors.

	// Multiply values by their precision and convert to positive.
	// Note: Go requires rounding before truncating to ensure precision!
	var latVal int64 = int64(math.Round((lat+latMax)*finalLatPrecision*1e6) / 1e6)
	var lngVal int64 = int64(math.Round((lng+lngMax)*finalLngPrecision*1e6) / 1e6)

	pos := maxCodeLen - 1
	// Compute the grid part of the code if necessary.
	if codeLen > pairCodeLen {
		for i := 0; i < gridCodeLen; i++ {
			latDigit := latVal % int64(gridRows)
			lngDigit := lngVal % int64(gridCols)
			ndx := latDigit*gridCols + lngDigit
			code[pos] = Alphabet[ndx]
			pos -= 1
			latVal /= int64(gridRows)
			lngVal /= int64(gridCols)
		}
	} else {
		latVal /= 3125 // gridRows**gridCodeLength
		lngVal /= 1024 // gridCols**gridCodeLength
	}
	pos = pairCodeLen - 1
	// Compute the pair section of the code.
	for i := 0; i < pairCodeLen/2; i++ {
		latNdx := latVal % int64(encBase)
		lngNdx := lngVal % int64(encBase)
		code[pos] = Alphabet[lngNdx]
		pos -= 1
		code[pos] = Alphabet[latNdx]
		pos -= 1
		latVal /= int64(encBase)
		lngVal /= int64(encBase)
	}

	// If we don't need to pad the code, return the requested section.
	if codeLen >= sepPos {
		return string(code[:sepPos]) + string(Separator) + string(code[sepPos:codeLen])
	}
	// Pad and return the code.
	return string(code[:codeLen]) + strings.Repeat(string(Padding), sepPos-codeLen) + string(Separator)
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
