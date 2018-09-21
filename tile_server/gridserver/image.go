package gridserver

import (
	"bytes"
	"fmt"
	"image"
	"image/color"
	"image/png"
	"math"
	"strings"

	"github.com/golang/freetype"
	"github.com/golang/freetype/truetype"
	log "github.com/golang/glog"
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
	ctx.SetSrc(image.NewUniform(t.opts.labelColor))
	ctx.SetFont(imageTileFont)
	// Draw and label each feature that is returned in the geojson for this tile.
	for _, ft := range gj.Features {
		// Convert the grid cell vertices from lng/lat to pixels.
		var cp [][]float64
		for _, v := range ft.Geometry.Polygon[0] {
			vx, vy := t.LatLngToPixel(v[1], v[0], tileSize)
			cp = append(cp, []float64{vx, vy})
		}
		// Draw the cell outline.
		drawRect(img, t.opts.lineColor, int(cp[0][0]), int(cp[2][1]), int(cp[2][0]), int(cp[0][1]))
		// Get the cell's center x and y, and the width.
		cx := (cp[0][0] + cp[2][0]) / 2
		cy := (cp[0][1] + cp[2][1]) / 2
		cw := cp[2][0] - cp[0][0]
		// Get and draw the labels.
		l1, l2 := featureLabels(ft)
		centerLabels(ctx, t.opts.labelColor, cx, cy, cw, l1, l2)
	}
	buf := new(bytes.Buffer)
	png.Encode(buf, img)
	return buf.Bytes(), nil
}

// drawHoriz draws a horizontal line
func drawHoriz(img *image.RGBA, c color.Color, x1, y, x2 int) {
	for ; x1 <= x2; x1++ {
		img.Set(x1, y, c)
	}
}

// drawVert draws a veritcal line
func drawVert(img *image.RGBA, c color.Color, x, y1, y2 int) {
	for ; y1 <= y2; y1++ {
		img.Set(x, y1, c)
	}
}

// drawRect draws a rectangle utilizing HLine() and VLine()
func drawRect(img *image.RGBA, c color.Color, x1, y1, x2, y2 int) {
	drawHoriz(img, c, x1, y1, x2)
	drawHoriz(img, c, x1, y2, x2)
	drawVert(img, c, x1, y1, y2)
	drawVert(img, c, x2, y1, y2)
}

// centerLabels draws a one or two-line label in the center of the cell - not tile, but grid cell.
// The font size is scaled for the longer label to fit.
func centerLabels(ctx *freetype.Context, c color.Color, cx, cy, cw float64, label1, label2 string) {
	// Get the smaller suitable font size for the two labels.
	fs := math.Min(
		scaleFontSize(ctx, cw, strings.Repeat("W", len(label1))),
		scaleFontSize(ctx, cw, strings.Repeat("W", len(label2))),
	)
	ctx.SetFontSize(fs)
	// Get the widths of each label with the current font size.
	w1 := getStringWidth(ctx, label1)
	w2 := getStringWidth(ctx, label2)
	// Add the labels.
	if len(label2) == 0 {
		if _, err := ctx.DrawString(label1, freetype.Pt(int(cx-w1/2), int(cy+fs/2))); err != nil {
			log.Errorf("Error drawing label1: %v", err)
		}
	} else {
		if _, err := ctx.DrawString(label1, freetype.Pt(int(cx-w1/2), int(cy-fs*0.8))); err != nil {
			log.Errorf("Error drawing label1: %v", err)
		}
		if _, err := ctx.DrawString(label2, freetype.Pt(int(cx-w2/2), int(cy+fs*0.8))); err != nil {
			log.Errorf("Error drawing label2: %v", err)
		}
	}
}

// scaleFontSize returns the scaled font size so the label fits within the cell width.
func scaleFontSize(ctx *freetype.Context, cw float64, label string) float64 {
	if len(label) == 0 {
		return 1000
	}
	// Start with the default font size.
	ctx.SetFontSize(fontSize)
	lw := getStringWidth(ctx, label)
	// Scale the font to make the label fit in the cell width.
	return (cw / lw) * fontSize * 0.9
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
