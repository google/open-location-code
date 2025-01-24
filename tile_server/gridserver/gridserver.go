// Package gridserver serves tiles with the Plus Codes grid.
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
	outputMVT        = "mvt"
	tileNumberingWMS = "wms"
	tileNumberingTMS = "tms"
	lineColorOption  = "linecol"
	labelColorOption = "labelcol"
	projectionOption = "projection"
	zoomAdjustOption = "zoomadjust"
)

var (
	pathSpec = regexp.MustCompile(fmt.Sprintf(`^/grid/(%s|%s)/(\d+)/(\d+)/(\d+)\.(%s|%s|%s)`, tileNumberingWMS, tileNumberingTMS, outputJSON, outputPNG, outputMVT))
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
	// Check for optional form values.
	opts := NewTileOptions()
	if g[5] == outputJSON {
		opts.Format = JSONTile
	} else if g[5] == outputPNG {
		opts.Format = ImageTile
	} else if g[5] == outputMVT {
		opts.Format = VectorTile
	} else {
		return nil, fmt.Errorf("Tile output type not specified: %v", g[5])
	}
	if o := r.FormValue(lineColorOption); o != "" {
		if rgba, err := strconv.ParseUint(o, 0, 64); err == nil {
			opts.LineColor = int32ToRGBA(uint32(rgba))
		} else {
			log.Warningf("Incorrect value for %q: %v", lineColorOption, o)
		}
	}
	if o := r.FormValue(labelColorOption); o != "" {
		if rgba, err := strconv.ParseUint(o, 0, 64); err == nil {
			opts.LabelColor = int32ToRGBA(uint32(rgba))
		} else {
			log.Warningf("Incorrect value for %q: %v", labelColorOption, o)
		}
	}
	if o := r.FormValue(zoomAdjustOption); o != "" {
		if za, err := strconv.ParseInt(o, 0, 64); err == nil {
			opts.ZoomAdjust = int(za)
		} else {
			log.Warningf("Incorrect value for %q: %v", zoomAdjustOption, o)
		}
	}
	if o := r.FormValue(projectionOption); o != "" {
		if o == "mercator" || o == "epsg:3857" {
			// Mercator was the default.
			opts.Projection = NewMercatorTMS()
		} else if o == "geodetic" || o == "epsg:4326" {
			opts.Projection = NewGeodeticTMS()
		} else {
			log.Warningf("Incorrect value for %q: %v", projectionOption, o)
			return nil, fmt.Errorf("%q is not a valid value for %q", o, projectionOption)
		}
	}
	return MakeTileRef(x, y, z, opts), nil
}

// int32ToRGBA converts a 32-bit unsigned int into an RGBA color.
func int32ToRGBA(i uint32) color.Color {
	r := uint8((i >> 24) & 0xFF)
	g := uint8((i >> 16) & 0xFF)
	b := uint8((i >> 8) & 0xFF)
	a := uint8(i & 0xFF)
	return color.NRGBA{r, g, b, a}
}
