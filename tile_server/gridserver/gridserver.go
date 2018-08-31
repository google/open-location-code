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

	"github.com/golang/glog"
)

const (
	originHeader       = "Access-Control-Allow-Origin"
	contentTypeHeader  = "Content-Type"
	contentTypeGeoJSON = "application/vnd.geo+json"
	contentTypePNG     = "image/png"
	outputGeoJSON      = "json"
	outputPNG          = "png"
	tileNumberingWMS   = "wms"
	tileNumberingTMS   = "tms"
	lineColorOption    = "linecol"
	labelColorOption   = "labelcol"
	zoomAdjustOption   = "zoomadjust"
)

var (
	pathSpec = regexp.MustCompile(fmt.Sprintf(`^/grid/(%s|%s)/(\d+)/(\d+)/(\d+)\.(%s|%s)`, tileNumberingWMS, tileNumberingTMS, outputGeoJSON, outputPNG))
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

// Init reads in the font.
func Init() {
	if err := readImageFont(); err != nil {
		glog.Fatalf("Failed reading font: %v", err)
	}
}

// Handler processes a request for a single tile and writes either the GeoJSON or image as a response.
func Handler(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseForm(); err != nil {
		glog.Errorf("Bad request: %v: %v", r.URL, err)
		http.Error(w, err.Error(), 400)
		return
	}
	request, err := parseRequest(r)
	if err != nil {
		glog.Errorf("Bad request: %v: %v", r.URL, err)
		http.Error(w, err.Error(), 400)
		return
	}
	w.Header().Set(originHeader, "*")
	if request.format == jsonTile {
		if json, err := request.tile.GeoJSON(); err != nil {
			glog.Errorf("Error producing geojson tile: %v", err)
			http.Error(w, err.Error(), 500)
		} else if blob, err := json.MarshalJSON(); err != nil {
			glog.Errorf("Error marshaling geojson tile: %v", err)
			http.Error(w, err.Error(), 500)
		} else {
			w.Header().Set(contentTypeHeader, contentTypeGeoJSON)
			w.Write(blob)
		}
	}
	if request.format == imageTile {
		if blob, err := request.tile.Image(); err != nil {
			glog.Errorf("Error producing image tile: %v", err)
			http.Error(w, err.Error(), 500)
		} else {
			w.Header().Set(contentTypeHeader, contentTypePNG)
			w.Write(blob)
		}
	}
}

type tileFormat int

const (
	jsonTile  tileFormat = 0
	imageTile tileFormat = 1
)

type request struct {
	tile   *TileRef
	format tileFormat
}

func parseRequest(r *http.Request) (*request, error) {
	req := request{}
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
	if g[5] == outputGeoJSON {
		req.format = jsonTile
	} else if g[5] == outputPNG {
		req.format = imageTile
	} else {
		return nil, fmt.Errorf("Tile output type not specified: %v", g[5])
	}
	// Check for optional form values.
	opts := NewTileOptions()
	if r.FormValue(lineColorOption) != "" {
		if rgba, err := strconv.ParseUint(r.FormValue(lineColorOption), 0, 64); err == nil {
			opts.lineColor = int32ToRGBA(uint32(rgba))
		} else {
			glog.Warningf("Incorrect value for %s: %v", lineColorOption, r.FormValue(lineColorOption))
		}
	}
	if r.FormValue(labelColorOption) != "" {
		if rgba, err := strconv.ParseUint(r.FormValue(labelColorOption), 0, 64); err == nil {
			opts.labelColor = int32ToRGBA(uint32(rgba))
		} else {
			glog.Warningf("Incorrect value for %s: %v", labelColorOption, r.FormValue(labelColorOption))
		}
	}
	if r.FormValue(zoomAdjustOption) != "" {
		if za, err := strconv.ParseInt(r.FormValue(zoomAdjustOption), 0, 64); err == nil {
			opts.zoomAdjust = int(za)
		} else {
			glog.Warningf("Incorrect value for %s: %v", zoomAdjustOption, r.FormValue(zoomAdjustOption))
		}
	}
	// TODO: Add projection as an optional parameter.
	req.tile = MakeTileRef(x, y, z, opts)
	return &req, nil
}

// int32ToRGBA converts a 32-bit unsigned int into an RGBA color.
func int32ToRGBA(i uint32) color.RGBA {
	r := uint8((i >> 24) & 0xFF)
	g := uint8((i >> 16) & 0xFF)
	b := uint8((i >> 8) & 0xFF)
	a := uint8(i & 0xFF)
	return color.RGBA{r, g, b, a}
}
