package gridserver

import (
	"bytes"
	"testing"
)

func TestImage(t *testing.T) {
	var tests = []struct {
		x, y, z  int
		opts     *TileOptions
		testFile string
	}{
		{
			x: 17, y: 19, z: 5,
			testFile: testDataPath + "5_17_19.png",
		},
		{
			x: 17, y: 19, z: 5,
			opts:     &TileOptions{Format: ImageTile, LineColor: white, LabelColor: white, Projection: NewMercatorTMS(), ZoomAdjust: 2},
			testFile: testDataPath + "5_17_19_white_zoom_2.png",
		},
		{
			x: 1098232, y: 1362659, z: 21, testFile: testDataPath + "21_1098232_1362659.png",
		},
		{
			x: 1098232, y: 1362659, z: 21,
			opts:     &TileOptions{Format: ImageTile, LineColor: lineColor, LabelColor: labelColor, Projection: NewGeodeticTMS(), ZoomAdjust: 0},
			testFile: testDataPath + "21_1098232_1362659_geodetic.png",
		},
	}
	for n, td := range tests {
		want := readTestData(td.testFile)
		tr := MakeTileRef(td.x, td.y, td.z, td.opts)
		got, err := tr.Image()
		if err != nil {
			t.Errorf("Test %d: image failed: %v", n, err)
		}
		if !bytes.Equal(got, want) {
			t.Errorf("Test %d: got image != want image", n)
		}

	}
}
