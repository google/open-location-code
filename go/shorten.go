package olc

import (
	"errors"
	"fmt"
	"math"
	"strings"
)

// MinTrimmableCodeLen is the minimum length of a code that is able to be shortened.
const MinTrimmableCodeLen = 6

// Shorten removes characters from the start of an OLC code.
//
// This uses a reference location to determine how many initial characters
// can be removed from the OLC code. The number of characters that can be
// removed depends on the distance between the code center and the reference
// location.
// The minimum number of characters that will be removed is four. If more than
// four characters can be removed, the additional characters will be replaced
// with the padding character. At most eight characters will be removed.
// The reference location must be within 50% of the maximum range. This ensures
// that the shortened code will be able to be recovered using slightly different
// locations.
//
// * code: A full, valid code to shorten.
// * lat: A latitude, in signed decimal degrees, to use as the reference
//       point.
// * lng: A longitude, in signed decimal degrees, to use as the reference
//       point.
func Shorten(code string, lat, lng float64) (string, error) {
	if err := CheckFull(code); err != nil {
		return code, err
	}
	if strings.IndexByte(code, Padding) >= 0 {
		return code, errors.New("cannot shorten padded code")
	}
	code = strings.ToUpper(code)
	area, err := Decode(code)
	debug("Shorten(%s) area=%v error=%v", code, area, err)
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

	//debug("Shorten lat=%f lng=%f centerLat=%f centerLng=%f distance=%.10f", lat, lng, centerLat, centerLng, distance)
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
// Given a short Open Location Code of between four and seven characters,
// this recovers the nearest matching full code to the specified location.
// The number of characters that will be prepended to the short code, depends
// on the length of the short code and whether it starts with the separator.
// If it starts with the separator, four characters will be prepended. If it
// does not, the characters that will be prepended to the short code, where S
// is the supplied short code and R are the computed characters, are as
// follows:
//
// SSSS    -> RRRR.RRSSSS
// SSSSS   -> RRRR.RRSSSSS
// SSSSSS  -> RRRR.SSSSSS
// SSSSSSS -> RRRR.SSSSSSS
//
// Note that short codes with an odd number of characters will have their
// last character decoded using the grid refinement algorithm.
//
// * code: A valid short OLC character sequence.
// * lat, lng: The latitude and longitude (in signed decimal degrees)
//   to use to find the nearest matching full code.
//
// Returns:
//   The nearest full Open Location Code to the reference location that matches
//   the short code. Note that the returned code may not have the same
//   computed characters as the reference location. This is because it returns
//   the nearest match, not necessarily the match within the same cell. If the
//   passed code was not a valid short code, but was a valid full code, it is
//   returned unchanged.
func RecoverNearest(code string, lat, lng float64) (string, error) {
	if err := CheckShort(code); err != nil {
		if err = CheckFull(code); err == nil {
			return code, nil
		}
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
	if lat + halfRes < centerLat && centerLat - resolution >= -latMax {
		// If the proposed code is more than half a cell north of the reference location,
		// it's too far, and the best match will be one cell south.
		centerLat -= resolution
	} else if lat - halfRes > centerLat && centerLat + resolution <= latMax {
		// If the proposed code is more than half a cell south of the reference location,
		// it's too far, and the best match will be one cell north.
		centerLat += resolution
	}

	// How many degrees longitude is the code from the reference?
	if lng + halfRes < centerLng {
		centerLng -= resolution
	} else if lng - halfRes > centerLng {
		centerLng += resolution
	}

	return Encode(centerLat, centerLng, area.Len), nil
}
