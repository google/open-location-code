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
			opts:     NewTileOptions().Zoom(2).LineColor(white).LabelColor(white),
			testFile: testDataPath + "5_17_19_white_zoom_2.png",
		},
		{x: 1098232, y: 1362659, z: 21, testFile: testDataPath + "21_1098232_1362659.png"},
	}
	for n, td := range tests {
		want := readTestData(td.testFile)
		tr := MakeTileRef(td.x, td.y, td.z, ImageTile, td.opts)
		got, err := tr.Image()
		if err != nil {
			t.Errorf("Test %d: image failed: %v", n, err)
		}
		if !bytes.Equal(got, want) {
			t.Errorf("Test %d: got image != want image", n)
		}

	}
}
