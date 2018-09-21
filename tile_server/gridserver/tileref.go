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
	format     TileFormat
	lineColor  color.RGBA
	labelColor color.RGBA
	proj       Projection
	zoomAdjust int
}

// String returns a string representation of the options.
func (o TileOptions) String() string {
	line := fmt.Sprintf("#%02x%02x%02x%02x", o.lineColor.R, o.lineColor.G, o.lineColor.B, o.lineColor.A)
	label := fmt.Sprintf("#%02x%02x%02x%02x", o.labelColor.R, o.labelColor.G, o.labelColor.B, o.labelColor.A)
	return fmt.Sprintf("%s_%s_%s_%d", line, label, o.proj, o.zoomAdjust)
}

// LineColor sets the color to use for the lines.
func (o *TileOptions) LineColor(c color.RGBA) *TileOptions {
	o.lineColor = c
	return o
}

// LabelColor sets the color to use for the labels.
func (o *TileOptions) LabelColor(c color.RGBA) *TileOptions {
	o.labelColor = c
	return o
}

// Zoom sets the zoom adjust level.
func (o *TileOptions) Zoom(z int) *TileOptions {
	o.zoomAdjust = z
	return o
}

// Projection changes the projection.
func (o *TileOptions) Projection(p Projection) *TileOptions {
	o.proj = p
	return o
}

// Format changes the output format.
func (o *TileOptions) Format(f TileFormat) *TileOptions {
	o.format = f
	return o
}

// NewTileOptions returns a default set of options.
func NewTileOptions() *TileOptions {
	return &TileOptions{format: JSONTile, lineColor: lineColor, labelColor: labelColor, proj: NewMercatorTMS(), zoomAdjust: 0}
}

// MakeTileRef constructs the tile reference.
func MakeTileRef(x, y, z int, opts *TileOptions) *TileRef {
	if opts == nil {
		opts = NewTileOptions()
	}
	t := TileRef{X: x, Y: y, Z: z, opts: opts}
	latlo, lnglo, lathi, lnghi := t.opts.proj.TileLatLngBounds(x, y, z)
	t.SW = &LatLng{latlo, lnglo}
	t.NE = &LatLng{lathi, lnghi}
	// We need the coordinates of the top left of this tile so we can correct the absolute pixel values.
	t.origin = &origin{}
	t.origin.left, t.origin.top = t.opts.proj.TileOrigin(x, y, z)
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

// Path converts a tile reference into a file path using zoom/x/y/options
func (t *TileRef) Path() string {
	return fmt.Sprintf("%d/%d/%d/%d:%d:%d_%s", t.Z, t.X, t.Y, t.Z, t.X, t.Y, t.opts)
}

// Format returns the output format.
func (t *TileRef) Format() TileFormat {
	return t.opts.format
}
