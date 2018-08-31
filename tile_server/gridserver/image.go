package gridserver

import (
	"bytes"
	"image"
	"image/color"
	"image/png"
	"math"
	"strings"

	"github.com/golang/freetype/truetype"
	"github.com/golang/glog"
	"github.com/llgcode/draw2d"
	"github.com/llgcode/draw2d/draw2dimg"
	geojson "github.com/paulmach/go.geojson"
	"golang.org/x/image/font/gofont/goregular"
)

const (
	tileSize = 256 // size of tiles in pixels. Accessed by other functions in this package.
	fontSize = 20
)

var (
	font       draw2d.FontData
	lineColor  = color.RGBA{0, 0, 0, 255}
	labelColor = color.RGBA{0, 0, 0, 128}
)

// Image returns the tile as a 256x256 pixel PNG image.
func (t *TileRef) Image() ([]byte, error) {
	glog.Infof("Producing image for tile z/x/y %v/%v/%v", t.Z, t.X, t.Y)
	gj, err := t.GeoJSON()
	if err != nil {
		return nil, err
	}
	img := image.NewRGBA(image.Rect(0, 0, tileSize, tileSize))
	gc := draw2dimg.NewGraphicContext(img)
	gc.SetLineWidth(1.0)
	gc.SetFontData(font)
	gc.SetFontSize(float64(fontSize))
	// Draw and label each feature that is returned in the geojson for this tile.
	for _, ft := range gj.Features {
		gc.SetFillColor(t.opts.lineColor)
		gc.SetStrokeColor(t.opts.lineColor)
		// Convert the grid cell vertices from lng/lat to pixels.
		var cp [][]float64
		for _, v := range ft.Geometry.Polygon[0] {
			vx, vy := t.LatLngToPixel(v[1], v[0], tileSize)
			cp = append(cp, []float64{vx, vy})
		}
		// Draw the cell lines.
		gc.MoveTo(cp[0][0], cp[0][1])
		gc.LineTo(cp[1][0], cp[1][1])
		gc.LineTo(cp[2][0], cp[2][1])
		gc.LineTo(cp[3][0], cp[3][1])
		gc.Close()
		gc.Stroke()
		// Add the label.
		if hasAreaLocalCode(ft) {
			t.centerText(gc, cp, ft.Properties["area_code"].(string), ft.Properties["local_code"].(string))
		} else {
			t.centerText(gc, cp, ft.Properties["name"].(string), "")
		}
	}
	buf := new(bytes.Buffer)
	png.Encode(buf, img)
	return buf.Bytes(), nil
}

// centerText draws a one or two-line label in the center of the cell - not tile, but grid cell.
// The font size is scaled for the longer label to fit.
// The pixel coordinates of the cell are in cellGeom.
func (t *TileRef) centerText(gc draw2d.GraphicContext, cellGeom [][]float64, label1, label2 string) {
	// Get the center of the cell and it's width.
	cx := (cellGeom[0][0] + cellGeom[2][0]) / 2
	cy := (cellGeom[0][1] + cellGeom[2][1]) / 2
	cw := cellGeom[2][0] - cellGeom[0][0]
	// Get the default dimensions of each label so we can work out how far to scale it.
	fs1, w1, h1 := labelDimension(gc, cw, label1)
	fs2, w2, h2 := labelDimension(gc, cw, label2)
	// Use the smaller fontsize, and the largest height.
	fs := math.Min(fs1, fs2)
	hMax := math.Max(h1, h2)
	// Scale the widths and height for the new fontsize.
	w1 = w1 * fs / fontSize
	w2 = w2 * fs / fontSize
	hMax = hMax * fs / fontSize
	gc.SetFontSize(fs)
	gc.SetFillColor(t.opts.labelColor)
	gc.SetStrokeColor(t.opts.labelColor)
	// Add the labels.
	if len(label2) == 0 {
		gc.FillStringAt(label1, cx-w1/2, cy+hMax/2)
	} else {
		gc.FillStringAt(label1, cx-w1/2, cy-hMax*0.8)
		gc.FillStringAt(label2, cx-w2/2, cy+hMax*0.8)
	}
}

// labelDimension returns the width and height of a label drawn with the default font size.
func labelDimension(gc draw2d.GraphicContext, cw float64, label string) (fs float64, width float64, height float64) {
	if len(label) == 0 {
		return 1000, 0, 0
	}
	gc.SetFontSize(fontSize)
	// Use Ms so all strings the same length will get the same fontsize.
	l, t, r, b := gc.GetStringBounds(strings.Repeat("M", len(label)))
	// Scale the font to make the label fit in the cell width.
	fs = (cw / (r - l)) * fontSize * 0.8
	l, t, r, b = gc.GetStringBounds(label)
	width = r - l
	height = b - t
	return
}

// hasAreaLocalCode returns true if the GeoJSON feature has area and local code properties.
func hasAreaLocalCode(f *geojson.Feature) bool {
	if _, ok := f.Properties["area_code"]; !ok {
		return false
	}
	if _, ok := f.Properties["local_code"]; !ok {
		return false
	}
	return true
}

// readImageFont reads in the font file and registers it for use.
func readImageFont() error {
	// Parse the truetype file.
	f, err := truetype.Parse(goregular.TTF)
	if err != nil {
		return err
	}
	// Create a new FontData struct for augmenting images and register true type font with draw2d.
	font = draw2d.FontData{Name: "goregular"}
	draw2d.RegisterFont(font, f)
	return nil
}
