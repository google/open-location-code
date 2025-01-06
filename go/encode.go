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
	codeLen = clipCodeLen(codeLen)
	// Clip the latitude. Normalise the longitude.
	lat, lng = clipLatitude(lat), normalizeLng(lng)
	// Latitude 90 needs to be adjusted to be just less, so the returned code
	// can also be decoded.
	if lat == latMax {
		lat = normalizeLat(lat - computeLatPrec(codeLen))
	}
	// Use a char array so we can build it up from the end digits, without having
	// to keep reallocating strings.
	var code [maxCodeLen + 1]byte

	// Compute the code.
	// This approach converts each value to an integer after multiplying it by
	// the final precision. This allows us to use only integer operations, so
	// avoiding any accumulation of floating point representation errors.
	latVal, lngVal := roundLatLngToInts(lat, lng)

	// Compute the grid part of the code if necessary.
	if codeLen > pairCodeLen {
		code[sepPos+7], latVal, lngVal = latLngGridStep(latVal, lngVal)
		code[sepPos+6], latVal, lngVal = latLngGridStep(latVal, lngVal)
		code[sepPos+5], latVal, lngVal = latLngGridStep(latVal, lngVal)
		code[sepPos+4], latVal, lngVal = latLngGridStep(latVal, lngVal)
		code[sepPos+3], latVal, lngVal = latLngGridStep(latVal, lngVal)
	} else {
		latVal /= gridLatFullValue
		lngVal /= gridLngFullValue
	}

	// Add the pair after the separator.
	latNdx := latVal % int64(encBase)
	lngNdx := lngVal % int64(encBase)
	code[sepPos+2] = Alphabet[lngNdx]
	code[sepPos+1] = Alphabet[latNdx]

	// Avoid the need for string concatenation by filling in the Separator manually.
	code[sepPos] = Separator

	// Compute the pair section of the code.
	// Even indices contain latitude and odd contain longitude.
	code[7], lngVal = pairIndexStep(lngVal)
	code[6], latVal = pairIndexStep(latVal)

	code[5], lngVal = pairIndexStep(lngVal)
	code[4], latVal = pairIndexStep(latVal)

	code[3], lngVal = pairIndexStep(lngVal)
	code[2], latVal = pairIndexStep(latVal)

	code[1], lngVal = pairIndexStep(lngVal)
	code[0], latVal = pairIndexStep(latVal)

	// If we don't need to pad the code, return the requested section.
	if codeLen >= sepPos {
		return string(code[:codeLen+1])
	}
	// Pad and return the code.
	return string(code[:codeLen]) + strings.Repeat(string(Padding), sepPos-codeLen) + string(Separator)
}

// roundLatLngToInts rounds the passed latitude and longitude to integral values
// representing a location within 1 centimetre of the passed coordinates.
func roundLatLngToInts(lat, lng float64) (int64, int64) {
	// To round, we:
	// 1) Offset latitude and longitude so that all values are positive.
	// 2) Multiply by the final precision before conversion to integer to preserve precision.
	// 3) Multiply by desired rounding precision and add 1.
	// 4) Bit shift to undo the multiply used for rounding.

	// Precision of rounding is equal to 2^roundPrecision.
	// A value of 20 corresponds to sub-centimetre precision.
	const roundPrecision = 20
	latVal := int64((lat+latMax)*finalLatPrecision*(1<<roundPrecision)+1) >> roundPrecision
	lngVal := int64((lng+lngMax)*finalLngPrecision*(1<<roundPrecision)+1) >> roundPrecision
	return latVal, lngVal
}

// clipCodeLen returns the smallest valid code length greater than or equal to
// the desired code length.
func clipCodeLen(codeLen int) int {
	if codeLen <= 0 {
		// Default to a full pair code if codeLen is the default or negative
		// value.
		return pairCodeLen
	} else if codeLen < pairCodeLen && codeLen%2 == 1 {
		// Codes only consisting of pairs must have an even length.
		return codeLen + 1
	} else if codeLen > maxCodeLen {
		return maxCodeLen
	}
	return codeLen
}

// latLngGridStep computes the next smallest grid code in sequence,
// followed by the remaining latitude and longitude values not yet converted
// to a grid code.
func latLngGridStep(latVal, lngVal int64) (byte, int64, int64) {
	latDigit := latVal % int64(gridRows)
	lngDigit := lngVal % int64(gridCols)
	ndx := latDigit*gridCols + lngDigit
	return Alphabet[ndx], latVal / int64(gridRows), lngVal / int64(gridCols)
}

// pairIndexStep computes the next smallest pair code in sequence,
// followed by the remaining integer not yet converted to a pair code.
func pairIndexStep(coordinate int64) (byte, int64) {
	coordinate /= int64(encBase)
	latNdx := coordinate % int64(encBase)
	return Alphabet[latNdx], coordinate
}

// computeLatPrec computes the precision value for a given code length.
// Lengths <= 10 have the same precision for latitude and longitude,
// but lengths > 10 have different precisions due to the grid method
// having fewer columns than rows.
func computeLatPrec(codeLen int) float64 {
	if codeLen <= pairCodeLen {
		return math.Pow(float64(encBase), math.Floor(float64(codeLen/-2+2)))
	}
	return math.Pow(float64(encBase), -3) / math.Pow(float64(gridRows), float64(codeLen-pairCodeLen))
}
