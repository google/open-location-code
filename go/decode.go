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

// Decode decodes an Open Location Code into the location coordinates.
// Returns a CodeArea object that includes the coordinates of the bounding
// box - the lower left, center and upper right.
//
// To avoid underflow errors, the precision is limited to 15 digits.
// Longer codes are allowed, but only the first 15 is decoded.
func Decode(code string) (CodeArea, error) {
	var area CodeArea
	if err := CheckFull(code); err != nil {
		return area, err
	}
	// Strip out separator character (we've already established the code is
	// valid so the maximum is one), padding characters and convert to upper
	// case.
	code = StripCode(code)
	if len(code) < 2 {
		return area, errors.New("code too short")
	}
	// Initialise the values for each section. We work them out as integers and
	// convert them to floats at the end.
	normalLat := -latMax * pairPrecision
	normalLng := -lngMax * pairPrecision
	extraLat := 0
	extraLng := 0
	// How many digits do we have to process?
	digits := pairCodeLen
	if len(code) < digits {
		digits = len(code)
	}
	// Define the place value for the most significant pair.
	pv := pairFPV
	for i := 0; i < digits-1; i += 2 {
		normalLat += strings.IndexByte(Alphabet, code[i]) * pv
		normalLng += strings.IndexByte(Alphabet, code[i+1]) * pv
		if i < digits-2 {
			pv /= encBase
		}
	}
	// Convert the place value to a float in degrees.
	latPrecision := float64(pv) / pairPrecision
	lngPrecision := float64(pv) / pairPrecision
	// Process any extra precision digits.
	if len(code) > pairCodeLen {
		// Initialise the place values for the grid.
		rowpv := gridLatFPV
		colpv := gridLngFPV
		// How many digits do we have to process?
		digits = maxCodeLen
		if len(code) < maxCodeLen {
			digits = len(code)
		}
		for i := pairCodeLen; i < digits; i++ {
			dval := strings.IndexByte(Alphabet, code[i])
			row := dval / gridCols
			col := dval % gridCols
			extraLat += row * rowpv
			extraLng += col * colpv
			if i < digits-1 {
				rowpv /= gridRows
				colpv /= gridCols
			}
		}
		// Adjust the precisions from the integer values to degrees.
		latPrecision = float64(rowpv) / finalLatPrecision
		lngPrecision = float64(colpv) / finalLngPrecision
	}
	// Merge the values from the normal and extra precision parts of the code.
	// Everything is ints so they all need to be cast to floats.
	lat := float64(normalLat)/pairPrecision + float64(extraLat)/finalLatPrecision
	lng := float64(normalLng)/pairPrecision + float64(extraLng)/finalLngPrecision
	// Round everthing off to 14 places.
	return CodeArea{
		LatLo: math.Round(lat*1e14) / 1e14,
		LngLo: math.Round(lng*1e14) / 1e14,
		LatHi: math.Round((lat+latPrecision)*1e14) / 1e14,
		LngHi: math.Round((lng+lngPrecision)*1e14) / 1e14,
		Len:   len(code),
	}, nil
}
