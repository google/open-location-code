package gridserver

import (
	"image/color"

	"github.com/golang/glog"
)

// TileRef represents a TMS tile reference, based on x/y/z values.
// It provides the tile bounding box, and a function to convert lat/lng into pixel references.
type TileRef struct {
	Z      int
	X      int
	Y      int
	opts   *TileOptions
	origin *origin
	SW     *LatLng
	NE     *LatLng
}

// origin gives the pixel coordinates of the tile origin.
type origin struct {
	top  float64
	left float64
}

// TileOptions are settings to adjust how the tiles are generated.
type TileOptions struct {
	lineColor  color.RGBA
	labelColor color.RGBA
	proj       Projection
	zoomAdjust int
}

// NewTileOptions returns a default set of options.
func NewTileOptions() *TileOptions {
	return &TileOptions{zoomAdjust: 0, lineColor: lineColor, labelColor: labelColor, proj: NewMercatorTMS()}
}

// MakeTileRef constructs the tile reference.
func MakeTileRef(x, y, z int, opts *TileOptions) *TileRef {
	t := TileRef{X: x, Y: y, Z: z}
	if opts == nil {
		t.opts = NewTileOptions()
	} else {
		t.opts = opts
	}
	latlo, lnglo, lathi, lnghi := opts.proj.TileLatLngBounds(x, y, z)
	t.SW = &LatLng{latlo, lnglo}
	t.NE = &LatLng{lathi, lnghi}
	// We need the coordinates of the top left of this tile so we can correct the absolute pixel values.
	t.origin = &origin{}
	t.origin.left, t.origin.top = opts.proj.TileOrigin(x, y, z)
	glog.Infof("tile z/x/y %v/%v/%v, tile origin %v,%v,  sw %s, ne %s", z, x, y, t.origin.left, t.origin.top, t.SW, t.NE)
	return &t
}

// LatLngToPixel converts a lat/lng pair in degrees to pixel values relative to the NW corner of the tile.
func (t *TileRef) LatLngToPixel(lat, lng float64, tileSize float64) (x float64, y float64) {
	x, y = t.opts.proj.LatLngToRaster(lat, lng, float64(t.Z))
	// Make the coordinates relative to the top left of the tile.
	x = x - t.origin.left
	y = y - t.origin.top
	return
}
