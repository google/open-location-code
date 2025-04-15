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
	"strings"
)

var (
	// ErrShort indicates the provided code was a short code.
	ErrShort = errors.New("short code")
	// ErrNotShort indicates the provided code was not a short code.
	ErrNotShort = errors.New("not short code")
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
	// This approach converts each value to an integer after multiplying it by the final precision.
	// This allows us to use only integer operations, so avoiding any accumulation of floating point representation errors.
	latVal := latitudeAsInteger(lat)
	lngVal := longitudeAsInteger(lng)

	// Clip the code length to legal values.
	codeLen = clipCodeLen(codeLen)
	// Use a char array so we can build it up from the end digits, without having
	// to keep reallocating strings.
	var code [maxCodeLen + 1]byte

	// Compute the grid part of the code if necessary.
	if codeLen > pairCodeLen {
		for i := maxCodeLen - pairCodeLen; i >= 1; i-- {
			code[sepPos+2+i], latVal, lngVal = latLngGridStep(latVal, lngVal)
		}
	} else {
		latVal /= gridLatFullValue
		lngVal /= gridLngFullValue
	}

	// Add the pair after the separator.
	code[sepPos+2], lngVal = pairIndexStep(lngVal)
	code[sepPos+1], latVal = pairIndexStep(latVal)

	// Avoid the need for string concatenation by filling in the Separator manually.
	code[sepPos] = Separator

	// Compute the pair section of the code.
	// Even indices contain latitude and odd contain longitude.
	for pairStart := (pairCodeLen/2 + 1); pairStart >= 0; pairStart = pairStart - 2 {
		code[pairStart+1], lngVal = pairIndexStep(lngVal)
		code[pairStart], latVal = pairIndexStep(latVal)
	}
	// If we don't need to pad the code, return the requested section.
	if codeLen >= sepPos {
		return string(code[:codeLen+1])
	}
	// Pad and return the code.
	return string(code[:codeLen]) + strings.Repeat(string(Padding), sepPos-codeLen) + string(Separator)
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
	latNdx := coordinate % int64(encBase)
	coordinate /= int64(encBase)
	return Alphabet[latNdx], coordinate
}
