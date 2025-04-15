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

// Decode decodes an Open Location Code into the location coordinates.
// Returns a CodeArea object that includes the coordinates of the bounding
// box - the lower left, center and upper right.
//
// Longer codes are allowed, but only the first 15 is decoded.
func Decode(code string) (CodeArea, error) {
	var area CodeArea
	if err := CheckFull(code); err != nil {
		return area, err
	}
	// Strip out separator character, padding characters and convert to upper
	// case.
	code = StripCode(code)
	codeLen := len(code)
	if codeLen < 2 {
		return area, errors.New("code too short")
	}
	// lat and lng build up the integer values.
	var lat int64
	var lng int64
	// height and width build up integer values for the height and width of the
	// code area. They get set to 1 for the last digit and then multiplied by
	// each remaining place.
	var height int64 = 1
	var width int64 = 1
	// Decode the paired digits.
	for i := 0; i < pairCodeLen; i += 2 {
		lat *= encBase
		lng *= encBase
		height *= encBase
		if i < codeLen {
			lat += int64(strings.IndexByte(Alphabet, code[i]))
			lng += int64(strings.IndexByte(Alphabet, code[i+1]))
			height = 1
		}
	}
	// The paired section has the same resolution for height and width.
	width = height
	// Decode the grid section.
	for i := pairCodeLen; i < maxCodeLen; i++ {
		lat *= gridRows
		height *= gridRows
		lng *= gridCols
		width *= gridCols
		if i < codeLen {
			dval := int64(strings.IndexByte(Alphabet, code[i]))
			lat += dval / gridCols
			lng += dval % gridCols
			height = 1
			width = 1
		}
	}
	// Convert everything into degrees and return the code area.
	var latDegrees float64 = float64(lat-latMax*finalLatPrecision) / float64(finalLatPrecision)
	var lngDegrees float64 = float64(lng-lngMax*finalLngPrecision) / float64(finalLngPrecision)
	var heightDegrees float64 = float64(height) / float64(finalLatPrecision)
	var widthDegrees float64 = float64(width) / float64(finalLngPrecision)
	return CodeArea{
		LatLo: latDegrees,
		LngLo: lngDegrees,
		LatHi: latDegrees + heightDegrees,
		LngHi: lngDegrees + widthDegrees,
		Len:   codeLen,
	}, nil
}
