package gridserver

import (
	"fmt"
	"image/color"
)

// TileFormat specifies the types of tiles to generate.
type TileFormat int

const (
	// JSONTile indicates the tile output should be GeoJSON.
	JSONTile TileFormat = 0
	// ImageTile indicates the tile output should be a PNG image.
	ImageTile TileFormat = 1
	// VectorTile indicates the tile output should be Mapbox Vector Tile.
	VectorTile TileFormat = 2
)

// TileRef represents a TMS tile reference, based on x/y/z values.
// It provides the tile bounding box, and a function to convert lat/lng into pixel references.
type TileRef struct {
	Z       int
	X       int
	Y       int
	Options *TileOptions
	origin  *origin
	SW      *LatLng
	NE      *LatLng
}

// origin gives the pixel coordinates of the tile origin.
type origin struct {
	top  float64
	left float64
}

// TileOptions are settings to adjust how the tiles are generated.
type TileOptions struct {
	Format     TileFormat
	LineColor  color.Color
	LabelColor color.Color
	Projection Projection
	ZoomAdjust int
}

// String returns a string representation of the options.
func (o TileOptions) String() string {
	if o.Format == JSONTile || o.Format == VectorTile {
		// Colour settings aren't used for JSON or Vector tiles - they just mess up the caching.
		return fmt.Sprintf("%s_%d", o.Projection, o.ZoomAdjust)
	}
	r, g, b, a := o.LineColor.RGBA()
	line := fmt.Sprintf("#%02x%02x%02x%02x", uint8(r), uint8(g), uint8(b), uint8(a))
	r, g, b, a = o.LabelColor.RGBA()
	label := fmt.Sprintf("#%02x%02x%02x%02x", uint8(r), uint8(g), uint8(b), uint8(a))
	return fmt.Sprintf("%s_%s_%s_%d", line, label, o.Projection, o.ZoomAdjust)
}

// NewTileOptions returns a default set of options.
func NewTileOptions() *TileOptions {
	return &TileOptions{Format: JSONTile, LineColor: lineColor, LabelColor: labelColor, Projection: NewMercatorTMS(), ZoomAdjust: 0}
}

// MakeTileRef constructs the tile reference.
func MakeTileRef(x, y, z int, opts *TileOptions) *TileRef {
	if opts == nil {
		opts = NewTileOptions()
	}
	t := TileRef{X: x, Y: y, Z: z, Options: opts}
	latlo, lnglo, lathi, lnghi := t.Options.Projection.TileLatLngBounds(x, y, z)
	t.SW = &LatLng{latlo, lnglo}
	t.NE = &LatLng{lathi, lnghi}
	// We need the coordinates of the top left of this tile so we can correct the absolute pixel values.
	t.origin = &origin{}
	t.origin.left, t.origin.top = t.Options.Projection.TileOrigin(x, y, z)
	return &t
}

// LatLngToPixel converts a lat/lng pair in degrees to pixel values relative to the NW corner of the tile.
func (t *TileRef) LatLngToPixel(lat, lng float64, tileSize float64) (x float64, y float64) {
	x, y = t.Options.Projection.LatLngToRaster(lat, lng, float64(t.Z))
	// Make the coordinates relative to the top left of the tile.
	x = x - t.origin.left
	y = y - t.origin.top
	return
}

// Path converts a tile reference into a file path using zoom/x/y/options
func (t *TileRef) Path() string {
	return fmt.Sprintf("%d/%d/%d/%d:%d:%d_%s", t.Z, t.X, t.Y, t.Z, t.X, t.Y, t.Options)
}
