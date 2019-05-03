package olc

import (
	"errors"
	"fmt"
	"math"
	"strings"
)

// MinTrimmableCodeLen is the minimum length of a code that is able to be shortened.
const MinTrimmableCodeLen = 6

var (
	pairResolutions = [...]float64{20.0, 1.0, .05, .0025, .000125}
)

// Shorten removes characters from the start of an OLC code.
//
// This uses a reference location to determine how many initial characters
// can be removed from the OLC code. The number of characters that can be
// removed depends on the distance between the code center and the reference
// location.
//
// The minimum number of characters that will be removed is four. At most eight
// characters will be removed.
//
// The reference location must be within 50% of the maximum range. This ensures
// that the shortened code will be able to be recovered using slightly different
// locations.
func Shorten(code string, lat, lng float64) (string, error) {
	if err := CheckFull(code); err != nil {
		return code, err
	}
	if strings.IndexByte(code, Padding) >= 0 {
		return code, errors.New("cannot shorten padded code")
	}
	code = strings.ToUpper(code)
	area, err := Decode(code)
	if err != nil {
		return code, err
	}
	if area.Len < MinTrimmableCodeLen {
		return code, fmt.Errorf("code length must be at least %d", MinTrimmableCodeLen)
	}

	lat, lng = clipLatitude(lat), normalizeLng(lng)

	// How close are the latitude and longitude to the code center.
	centerLat, centerLng := area.Center()
	distance := math.Max(math.Abs(centerLat-lat), math.Abs(centerLng-lng))

	for i := len(pairResolutions) - 2; i >= 1; i-- {
		// Check if we're close enough to shorten. The range must be less than 1/2
		// the resolution to shorten at all, and we want to allow some safety, so
		// use 0.3 instead of 0.5 as a multiplier.
		if distance < pairResolutions[i]*0.3 {
			// Trim it.
			return code[(i+1)*2:], nil
		}
	}
	return code, nil
}

// RecoverNearest recovers the nearest matching code to a specified location.
//
// Given a short Open Location Code with from four to eight digits missing,
// this recovers the nearest matching full code to the specified location.
func RecoverNearest(code string, lat, lng float64) (string, error) {
	// Return uppercased code if a full code was passed.
	if err := CheckFull(code); err == nil {
		return strings.ToUpper(code), nil
	}
	// Return error if not a short code
	if err := CheckShort(code); err != nil {
		return code, ErrNotShort
	}
	// Ensure that latitude and longitude are valid.
	lat, lng = clipLatitude(lat), normalizeLng(lng)

	// Clean up the passed code.
	code = strings.ToUpper(code)

	// Compute the number of digits we need to recover.
	padLen := sepPos - strings.IndexByte(code, Separator)

	// The resolution (height and width) of the padded area in degrees.
	resolution := math.Pow(20, float64(2-(padLen/2)))

	// Distance from the center to an edge (in degrees).
	halfRes := float64(resolution) / 2

	// Use the reference location to pad the supplied short code and decode it.
	area, err := Decode(Encode(lat, lng, 0)[:padLen] + code)
	if err != nil {
		return code, err
	}

	// How many degrees latitude is the code from the reference? If it is more
	// than half the resolution, we need to move it south or north but keep it
	// within -90 to 90 degrees.
	centerLat, centerLng := area.Center()
	if lat+halfRes < centerLat && centerLat-resolution >= -latMax {
		// If the proposed code is more than half a cell north of the reference location,
		// it's too far, and the best match will be one cell south.
		centerLat -= resolution
	} else if lat-halfRes > centerLat && centerLat+resolution <= latMax {
		// If the proposed code is more than half a cell south of the reference location,
		// it's too far, and the best match will be one cell north.
		centerLat += resolution
	}

	// How many degrees longitude is the code from the reference?
	if lng+halfRes < centerLng {
		centerLng -= resolution
	} else if lng-halfRes > centerLng {
		centerLng += resolution
	}

	return Encode(centerLat, centerLng, area.Len), nil
}
