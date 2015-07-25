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
func Decode(code string) (CodeArea, error) {
	var area CodeArea
	if err := CheckFull(code); err != nil {
		return area, err
	}
	// Strip out separator character (we've already established the code is
	// valid so the maximum is one), padding characters and convert to upper
	// case.
	code = stripCode(code)
	n := len(code)
	if n < 2 {
		return area, errors.New("code too short")
	}
	if n <= pairCodeLen {
		area = decodePairs(code)
		return area, nil
	}
	area = decodePairs(code[:pairCodeLen])
	grid := decodeGrid(code[pairCodeLen:])
	debug("Decode %s + %s area=%s grid=%s", code[:pairCodeLen], code[pairCodeLen:], area, grid)
	return CodeArea{
		LatLo: area.LatLo + grid.LatLo,
		LngLo: area.LngLo + grid.LngLo,
		LatHi: area.LatLo + grid.LatHi,
		LngHi: area.LngLo + grid.LngHi,
		Len:   area.Len + grid.Len,
	}, nil
}

// decodePairs decodes an OLC code made up of alternating latitude and longitude
// characters, encoded using base 20.
func decodePairs(code string) CodeArea {
	latLo, latHi := decodePairsSequence(code, 0)
	lngLo, lngHi := decodePairsSequence(code, 1)
	return CodeArea{
		LatLo: latLo - latMax, LatHi: latHi - latMax,
		LngLo: lngLo - lngMax, LngHi: lngHi - lngMax,
		Len: len(code),
	}
}

// This decodes the latitude or longitude sequence of a lat/lng pair encoding.
// Starting at the character at position offset, every second character is
// decoded and the value returned.
//
// Returns a pair of the low and high values.
// The low value comes from decoding the characters.
// The high value is the low value plus the resolution of the last position.
// Both values are offset into positive ranges and will need to be corrected
// before use.
func decodePairsSequence(code string, offset int) (lo, hi float64) {
	var value float64
	i := -1
	for j := offset; j < len(code); j += 2 {
		i++
		value += float64(strings.IndexByte(Alphabet, code[j])) * pairResolutions[i]
	}
	//debug("decodePairsSequence code=%s offset=%s i=%d value=%v pairRes=%f", code, offset, i, value, pairResolutions[i])
	return value, value + pairResolutions[i]
}

// decodeGrid decodes an OLC code using the grid refinement method.
// The code input argument shall be a valid OLC code sequence that is only
// the grid refinement portion!
//
// This is the portion of a code starting at position 11.
func decodeGrid(code string) CodeArea {
	var latLo, lngLo float64
	var latPlaceValue, lngPlaceValue float64 = gridSizeDegrees, gridSizeDegrees
	//debug("decodeGrid(%s)", code)
	fGridRows, fGridCols := float64(gridRows), float64(gridCols)
	for _, r := range code {
		i := strings.IndexByte(Alphabet, byte(r))
		row := i / gridCols
		col := i % gridCols
		latPlaceValue /= fGridRows
		lngPlaceValue /= fGridCols
		//debug("decodeGrid i=%d row=%d col=%d larVal=%f lngVal=%f lat=%.10f, lng=%.10f", i, row, col, latPlaceValue, lngPlaceValue, latLo, lngLo)
		latLo += float64(row) * latPlaceValue
		lngLo += float64(col) * lngPlaceValue
	}
	//Log.Debug("decodeGrid", "code", code, "latVal", fmt.Sprintf("%f", latPlaceValue), "lngVal", fmt.Sprintf("%f", lngPlaceValue), "lat", fmt.Sprintf("%.10f", latLo), "lng", fmt.Sprintf("%.10f", lngLo))
	return CodeArea{
		LatLo: latLo, LatHi: latLo + latPlaceValue,
		LngLo: lngLo, LngHi: lngLo + lngPlaceValue,
		Len: len(code),
	}
}
