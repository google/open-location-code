package gridserver

import (
	"bytes"
	"fmt"
	"image"
	"image/color"
	"image/png"
	"strings"

	"github.com/golang/freetype"
	"github.com/golang/freetype/truetype"
	log "github.com/golang/glog"
	"github.com/paulmach/orb/geojson"
	"golang.org/x/image/font/gofont/goregular"
)

const (
	tileSize = 256 // size of tiles in pixels. Accessed by other functions in this package.
	fontSize = 80
)

var (
	imageTileFont *truetype.Font

	white      = color.RGBA{255, 255, 255, 255}
	black      = color.RGBA{0, 0, 0, 255}
	grey       = color.RGBA{0, 0, 0, 128}
	lineColor  = black
	labelColor = grey
)

// Image returns the tile as a 256x256 pixel PNG image.
func (t *TileRef) Image() ([]byte, error) {
	log.Infof("Producing image for tile z/x/y %v/%v/%v (%s)", t.Z, t.X, t.Y, t.Path())
	gj, err := t.GeoJSON()
	if err != nil {
		return nil, err
	}
	// If the font hasn't been set, fallback to the default.
	if imageTileFont == nil {
		if err := SetImageFont(goregular.TTF); err != nil {
			return []byte{}, fmt.Errorf("Failed reading font: %v", err)
		}
	}
	img := image.NewRGBA(image.Rect(0, 0, tileSize, tileSize))
	// Create a context used for adding text to the image.
	ctx := freetype.NewContext()
	ctx.SetDst(img)
	ctx.SetClip(image.Rect(-tileSize, -tileSize, tileSize, tileSize))
	ctx.SetSrc(image.NewUniform(t.Options.LabelColor))
	ctx.SetFont(imageTileFont)

	// Create a colour for the sub-grid, using half-alpha of the label colour.
	r, g, b, a := t.Options.LabelColor.RGBA()
	a = a / 2
	gridCol := color.RGBA{
		uint8(min(r, a)),
		uint8(min(g, a)),
		uint8(min(b, a)),
		uint8(a),
	}
	// Draw and label each OLC grid cell that is returned in the geojson (i.e. feature).
	for _, ft := range gj.Features {
		cell := makeGridCell(ctx, t, ft)
		// Decide if we want to draw the sub-grid, depending on the code length and the pixel width.
		if len(ft.Properties["global_code"].(string)) <= 10 && cell.width > 200 {
			cell.drawGrid(t, img, gridCol, 20, 20)
		} else if len(ft.Properties["global_code"].(string)) > 10 && cell.width > 100 {
			cell.drawGrid(t, img, gridCol, 4, 5)
		}
		// Draw the cell outline.
		cell.drawRect(img, t.Options.LineColor)
		// Draw the label.
		cell.label(featureLabel(ft))
	}
	buf := new(bytes.Buffer)
	png.Encode(buf, img)
	return buf.Bytes(), nil
}

// gridCell represents an OLC grid cell.
type gridCell struct {
	ctx *freetype.Context
	// Latlng coordinates.
	latlo, lnglo, lathi, lnghi float64
	// Pixel coordinates.
	x1, y1, x2, y2 float64
	cx, cy, width  float64
}

// makeGridCell creates a gridCell structure.
func makeGridCell(ctx *freetype.Context, t *TileRef, f *geojson.Feature) *gridCell {
	o := &gridCell{ctx: ctx}
	// Get the bounds and create the pixel coordinates.
	o.latlo, o.lnglo, o.lathi, o.lnghi = bounds(f)
	// The pixels go from top to bottom so the y-coordinates are swapped.
	o.x1, o.y2 = t.LatLngToPixel(o.latlo, o.lnglo, tileSize)
	o.x2, o.y1 = t.LatLngToPixel(o.lathi, o.lnghi, tileSize)
	// Get the pixel center and the width.
	o.cx = (o.x1 + o.x2) / 2
	o.cy = (o.y1 + o.y2) / 2
	o.width = o.x2 - o.x1
	return o
}

// drawRect draws a rectangle around the cell.
func (c *gridCell) drawRect(img *image.RGBA, col color.Color) {
	c.drawHoriz(img, col, c.y1)
	c.drawHoriz(img, col, c.y2)
	c.drawVert(img, col, c.x1)
	c.drawVert(img, col, c.x2)
}

// drawGrid draws a grid within the cell of xdiv horizontal and ydiv vertical divisions.
func (c *gridCell) drawGrid(t *TileRef, img *image.RGBA, col color.Color, xdiv, ydiv float64) {
	// Draw the horizontal sub grid. We need to use the lat/lng coordinates for the horizontal lines
	// because the divisions are regular in degrees but not pixels.
	s := (c.lathi - c.latlo) / ydiv
	for i := 1; i <= 19; i++ {
		_, y := t.LatLngToPixel(c.latlo+float64(i)*s, c.lnglo, tileSize)
		c.drawHoriz(img, col, y)
	}
	// Draw the vertical sub grid.
	s = (c.x2 - c.x1) / xdiv
	for i := 1; i <= 19; i++ {
		c.drawVert(img, col, c.x1+float64(i)*s)
	}
}

// drawHoriz draws a horizontal line across the cell.
func (c *gridCell) drawHoriz(img *image.RGBA, col color.Color, y float64) {
	for x := c.x1; x <= c.x2; x++ {
		img.Set(int(x), int(y), col)
	}
}

// drawVert draws a vertical line across the cell.
func (c *gridCell) drawVert(img *image.RGBA, col color.Color, x float64) {
	for y := c.y1; y <= c.y2; y++ {
		img.Set(int(x), int(y), col)
	}
}

// label draws a multi-line label in the center of the cell - not tile, but grid cell.
// The font size of each line is scaled to fit the cell width.
func (c *gridCell) label(label string) {
	// Split the label into it's lines and get the font sizes for each line.
	lines := strings.Split(label, "\n")
	fontSizes := make([]float64, len(lines))
	var total float64
	for n, l := range lines {
		// Get the font size for the label.
		var fs float64
		// If it's the first line, and there are more, then the font size is reduced.
		if n == 0 && len(lines) > 1 {
			fs = scaleFontSize(c.ctx, c.width, strings.Repeat("W", 5)) * 0.9
		} else {
			fs = scaleFontSize(c.ctx, c.width, strings.Repeat("W", len(l)))
		}
		fontSizes[n] = fs
		total += fs
	}
	// Work out the y coordinate for the _last_ line. The y coordinate is the bottom of the line,
	// measured from the top of the cell.
	y := c.cy + total/2
	// Draw the last line, and work backwards to the first line.
	for i := len(lines) - 1; i >= 0; i-- {
		c.ctx.SetFontSize(fontSizes[i])
		w := getStringWidth(c.ctx, lines[i]) / 2
		if _, err := c.ctx.DrawString(lines[i], freetype.Pt(int(c.cx-w), int(y))); err != nil {
			log.Errorf("Error drawing label: %v", err)
		}
		// Reduce the y coordinate by the font size.
		y -= fontSizes[i]
	}
}

// scaleFontSize returns the scaled font size to fit the label within the available width.
func scaleFontSize(ctx *freetype.Context, cw float64, label string) float64 {
	if len(label) == 0 {
		return 1000
	}
	// Start with the default font size.
	ctx.SetFontSize(fontSize)
	lw := getStringWidth(ctx, label)
	// Scale the font to make the label fit in the cell width.
	return (cw / lw) * fontSize
}

// SetImageFont parses a TTF font and uses it for the image labels.
func SetImageFont(ttf []byte) error {
	// Parse the truetype file.
	font, err := truetype.Parse(ttf)
	imageTileFont = font
	return err
}

// getStringWidth returns the width of the string in the current font and font size.
func getStringWidth(ctx *freetype.Context, s string) float64 {
	if len(s) == 0 {
		return 0
	}
	// Draw it somewhere off the tile.
	st := freetype.Pt(-1000, -1000)
	val, err := ctx.DrawString(s, st)
	if err != nil {
		log.Errorf("Failed drawing string to compute width: %v", err)
		return 0
	}
	w := float64(val.X.Round() - st.X.Round())
	return w
}

func min(a, b uint32) uint32 {
	if a < b {
		return a
	}
	return b
}
