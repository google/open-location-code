package gridserver

import (
	"bytes"
	"testing"
)

func TestMVT(t *testing.T) {
	var tests = []struct {
		x, y, z  int
		opts     *TileOptions
		testFile string
	}{
		{x: 17, y: 19, z: 5, testFile: testDataPath + "5_17_19.mvt"},
		{
			x: 17, y: 19, z: 5,
			opts:     &TileOptions{Format: VectorTile, LineColor: lineColor, LabelColor: labelColor, Projection: NewMercatorTMS(), ZoomAdjust: 2},
			testFile: testDataPath + "5_17_19_zoom_2.mvt",
		},
		{
			x: 1098232, y: 1362659, z: 21,
			opts:     &TileOptions{Format: VectorTile, LineColor: lineColor, LabelColor: labelColor, Projection: NewMercatorTMS(), ZoomAdjust: 0},
			testFile: testDataPath + "21_1098232_1362659.mvt",
		},
		{
			x: 17, y: 19, z: 5,
			opts:     &TileOptions{Format: VectorTile, LineColor: lineColor, LabelColor: labelColor, Projection: NewGeodeticTMS(), ZoomAdjust: 0},
			testFile: testDataPath + "5_17_19_geodetic.mvt",
		},
		{
			x: 1098232, y: 1362659, z: 21,
			opts:     &TileOptions{Format: VectorTile, LineColor: lineColor, LabelColor: labelColor, Projection: NewGeodeticTMS(), ZoomAdjust: 0},
			testFile: testDataPath + "21_1098232_1362659_geodetic.mvt",
		},
	}
	for n, td := range tests {
		want := readTestData(td.testFile)
		tr := MakeTileRef(td.x, td.y, td.z, td.opts)
		got, err := tr.MVT()
		if err != nil {
			t.Errorf("Test %d: MVT failed: %v", n, err)
		}
		if !bytes.Equal(got, want) {
			t.Errorf("Test %d: got MVT != want MVT", n)
		}
	}
}
