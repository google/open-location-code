// Package gridserver serves tiles with the plus codes grid.
// This parses the request, and generates either a GeoJSON or PNG image response.
package gridserver

import (
	"errors"
	"fmt"
	"image/color"
	"net/http"
	"regexp"
	"strconv"

	log "github.com/golang/glog"
)

const (
	outputJSON       = "json"
	outputPNG        = "png"
	tileNumberingWMS = "wms"
	tileNumberingTMS = "tms"
	lineColorOption  = "linecol"
	labelColorOption = "labelcol"
	zoomAdjustOption = "zoomadjust"
)

var (
	pathSpec = regexp.MustCompile(fmt.Sprintf(`^/grid/(%s|%s)/(\d+)/(\d+)/(\d+)\.(%s|%s)`, tileNumberingWMS, tileNumberingTMS, outputJSON, outputPNG))
)

// LatLng represents a latitude and longitude in degrees.
type LatLng struct {
	Lat float64 `json:"lat"`
	Lng float64 `json:"lng"`
}

// String returns the lat/lng formatted as a string.
func (l *LatLng) String() string {
	return fmt.Sprintf("%.6f,%.6f", l.Lat, l.Lng)
}

// Parse extracts information from an HTTP request.
func Parse(r *http.Request) (*TileRef, error) {
	g := pathSpec.FindStringSubmatch(r.URL.Path)
	if len(g) == 0 {
		return nil, errors.New("Request is not formatted correctly")
	}
	// The regex requires these values to be digits, so the conversions should succeed.
	// But we'll check for errors just in case someone messes with the regex.
	var err error
	z, err := strconv.Atoi(g[2])
	if err != nil {
		return nil, errors.New("zoom is not a number")
	}
	x, err := strconv.Atoi(g[3])
	if err != nil {
		return nil, errors.New("x is not a number")
	}
	y, err := strconv.Atoi(g[4])
	if err != nil {
		return nil, errors.New("y is not a number")
	}
	// The classes assume the Y coordinate is numbered according to the TMS standard (north to south).
	// If it uses the WMS standard (south to north) we need to modify the tile's Y coordinate.
	if g[1] == tileNumberingWMS {
		y = (1 << uint(z)) - y - 1
	}
	format := JSONTile // default
	if g[5] == outputJSON {
		format = JSONTile
	} else if g[5] == outputPNG {
		format = ImageTile
	} else {
		return nil, fmt.Errorf("Tile output type not specified: %v", g[5])
	}
	// Check for optional form values.
	opts := NewTileOptions()
	if r.FormValue(lineColorOption) != "" {
		if rgba, err := strconv.ParseUint(r.FormValue(lineColorOption), 0, 64); err == nil {
			opts.lineColor = int32ToRGBA(uint32(rgba))
		} else {
			log.Warningf("Incorrect value for %q: %v", lineColorOption, r.FormValue(lineColorOption))
		}
	}
	if r.FormValue(labelColorOption) != "" {
		if rgba, err := strconv.ParseUint(r.FormValue(labelColorOption), 0, 64); err == nil {
			opts.labelColor = int32ToRGBA(uint32(rgba))
		} else {
			log.Warningf("Incorrect value for %q: %v", labelColorOption, r.FormValue(labelColorOption))
		}
	}
	if r.FormValue(zoomAdjustOption) != "" {
		if za, err := strconv.ParseInt(r.FormValue(zoomAdjustOption), 0, 64); err == nil {
			opts.zoomAdjust = int(za)
		} else {
			log.Warningf("Incorrect value for %q: %v", zoomAdjustOption, r.FormValue(zoomAdjustOption))
		}
	}
	// TODO: Add projection as an optional parameter.
	return MakeTileRef(x, y, z, format, opts), nil
}

// int32ToRGBA converts a 32-bit unsigned int into an RGBA color.
func int32ToRGBA(i uint32) color.RGBA {
	r := uint8((i >> 24) & 0xFF)
	g := uint8((i >> 16) & 0xFF)
	b := uint8((i >> 8) & 0xFF)
	a := uint8(i & 0xFF)
	return color.RGBA{r, g, b, a}
}
