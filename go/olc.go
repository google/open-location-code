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

// Package olc implements Open Location Code.
//
// See https://github.com/google/open-location-code .
package olc

import (
	"errors"
	"fmt"
	"log"
	"math"
	"strings"
)

var (
	pairResolutions = [...]float64{20.0, 1.0, .05, .0025, .000125}

	// Debug governs the debug output.
	Debug = false
)

const (
	// Separator is the character that separates the two parts of location code.
	Separator = '+'
	// Padding is the optional (left) padding character.
	Padding = '0'

	// Alphabet is the set of valid encoding characters.
	Alphabet = "23456789CFGHJMPQRVWX"

	pairCodeLen     = 10
	gridCols        = 4
	gridRows        = 5
	gridSizeDegrees = 0.000125

	latMax = 90
	lngMax = 180
)

// CodeArea is the area represented by a location code.
type CodeArea struct {
	LatLo, LngLo, LatHi, LngHi float64
	Len                        int
}

// Center returns the (lat,lng) of the center of the area.
func (area CodeArea) Center() (lat, lng float64) {
	return math.Min(area.LatLo+(area.LatHi-area.LatLo)/2, latMax),
		math.Min(area.LngLo+(area.LngHi-area.LngLo)/2, lngMax)
}

// Check checks the code whether it is a valid code, or not.
func Check(code string) error {
	if code == "" || len(code) == 1 && code[0] == Separator {
		return errors.New("empty code")
	}
	n := len(code)
	firstSep, firstPad := -1, -1
	for i, r := range code {
		if firstPad != -1 {
			// Open Location Codes with less than eight digits can be suffixed with zeros with a "+" used as the final character. Zeros may not be followed by any other digit.
			switch r {
			case Padding:
				continue
			case Separator:
				if firstSep != -1 {
					return fmt.Errorf("extraneous separator @%d", i)
				}
				firstSep = i
				if n-1 == i {
					continue
				}
			}
			return fmt.Errorf("%c after zero @%d", r, i)
		}

		if '2' <= r && r <= '9' {
			continue
		}
		switch r {
		case 'C', 'F', 'G', 'H', 'J', 'M', 'P', 'Q', 'R', 'V', 'W', 'X',
			// Processing of Open Location Codes must be case insensitive.
			'c', 'f', 'g', 'h', 'j', 'm', 'p', 'q', 'r', 'v', 'w', 'x':
			continue
		case Separator:
			// In addition to the above characters, a full Open Location Code can include a single "+" as a separator after the eighth digit.
			if firstSep != -1 {
				return fmt.Errorf("extra separator seen @%d", i)
			}
			if i > sepPos || i%2 == 1 {
				return fmt.Errorf("separator in illegal position @%d", i)
			}
			firstSep = i
		case Padding:
			if i == 0 {
				return errors.New("shouldn't start with padding character")
			}
			firstPad = i
		default:
			return fmt.Errorf("invalid char %c @%d", r, i)
		}
	}
	if firstSep == -1 {
		return errors.New("missing separator")
	}
	if n-firstSep-1 == 1 {
		return fmt.Errorf("only one char (%q) after separator", code[firstSep+1:])
	}
	if firstPad != -1 {
		if len(code)-firstPad-1%2 == 1 {
			return errors.New("odd number of padding chars")
		}
	}
	return nil
}

// CheckShort checks the code whether it is a valid short code, or not.
// If it is a valid, but not short code, then it returns ErrNotShort.
func CheckShort(code string) error {
	if err := Check(code); err != nil {
		return err
	}
	if i := strings.IndexByte(code, Separator); i >= 0 && i < sepPos {
		return nil
	}
	return ErrNotShort
}

// CheckFull checks the code whether it is a valid full code.
// If it is short, it returns ErrShort.
func CheckFull(code string) error {
	if err := Check(code); err != nil {
		return err
	}
	if err := CheckShort(code); err == nil {
		return ErrShort
	}
	if firstLat := strings.IndexByte(Alphabet, upper(code[0])) * encBase; firstLat >= latMax*2 {
		return errors.New("latitude outside range")
	}
	if len(code) == 1 {
		return nil
	}
	if firstLong := strings.IndexByte(Alphabet, upper(code[1])) * encBase; firstLong >= lngMax*2 {
		return errors.New("longitude outside range")
	}
	return nil
}

func upper(b byte) byte {
	if 'c' <= b && b <= 'x' {
		return b + 'C' - 'c'
	}
	return b
}

// stripCode strips the padding and separator characters from the code.
func stripCode(code string) string {
	return strings.Map(
		func(r rune) rune {
			if r == Separator || r == Padding {
				return -1
			}
			return rune(upper(byte(r)))
		},
		code)
}

// Because the OLC codes are an area, they can't start at 180 degrees, because they would then have something > 180 as their upper bound.
// Basically, what you have to do is normalize the longitude - so you need to change 180 degrees to -180 degrees.
func normalize(value, max float64) float64 {
	for value < -max {
		value += 2 * max
	}
	for value >= max {
		value -= 2 * max
	}
	return value
}

func normalizeLat(value float64) float64 {
	return normalize(value, latMax)
}

func normalizeLng(value float64) float64 {
	return normalize(value, lngMax)
}

func debug(format string, args ...interface{}) {
	if Debug {
		log.Printf(format, args...)
	}
}
