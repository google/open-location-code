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
	encBase = len(Alphabet)

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

	// This algorithm starts with the least significant digits, and works it's way to the front of the code.
	// We generate either a max- or default length code, and then shorten/pad it at the end.
	code := ""
	if codeLen > pairCodeLen {
		// Multiply the decimal part of each coordinate by the final precision and round off to 1e-6 precision.
		// Convert to integers so the rest of the math is integer based.
		latPrecision := int(math.Round((lat-math.Floor(lat))*finalLatPrecision*1e6) / 1e6)
		lngPrecision := int(math.Round((lng-math.Floor(lng))*finalLngPrecision*1e6) / 1e6)
		for i := 0; i < gridCodeLen; i++ {
			code = string(Alphabet[(latPrecision%gridRows)*gridCols+int(lngPrecision%gridCols)]) + code
			latPrecision /= gridRows
			lngPrecision /= gridCols
		}
	}
	// Multiply each coordinate by the precision and round off to 1e-6 precision.
	// Convert to integers so the rest of the math is integer based.
	latPrecision := int(math.Round((lat+latMax)*pairPrecision*1e6) / 1e6)
	lngPrecision := int(math.Round((lng+lngMax)*pairPrecision*1e6) / 1e6)
	for i := 0; i < pairCodeLen/2; i++ {
		code = string(Alphabet[lngPrecision%encBase]) + code
		code = string(Alphabet[latPrecision%encBase]) + code
		latPrecision /= encBase
		lngPrecision /= encBase
		if i == 0 {
			code = string(Separator) + code
		}
	}
	// If we don't need to pad the code, return the requested section.
	if codeLen >= sepPos {
		return code[:codeLen+1]
	}
	// Pad and return the code.
	return code[:codeLen] + strings.Repeat(string(Padding), sepPos-codeLen) + string(Separator)
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
