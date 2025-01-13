package gridserver

import (
	"encoding/json"
	"os"
	"testing"

	log "github.com/golang/glog"
	"github.com/google/go-cmp/cmp"
	"github.com/paulmach/orb/geojson"
)

const (
	testDataPath = "./testdata/"
)

func readTestData(p string) []byte {
	d, err := os.ReadFile(p)
	if err != nil {
		log.Fatal(err)
	}
	return d
}

func TestGeoJSON(t *testing.T) {
	var tests = []struct {
		x, y, z  int
		opts     *TileOptions
		testFile string
	}{
		{x: 17, y: 19, z: 5, testFile: testDataPath + "5_17_19.json"},
		{
			x: 17, y: 19, z: 5,
			opts:     &TileOptions{Format: JSONTile, LineColor: lineColor, LabelColor: labelColor, Projection: NewMercatorTMS(), ZoomAdjust: 2},
			testFile: testDataPath + "5_17_19_zoom_2.json",
		},
		{
			x: 1098232, y: 1362659, z: 21,
			opts:     &TileOptions{Format: JSONTile, LineColor: lineColor, LabelColor: labelColor, Projection: NewMercatorTMS(), ZoomAdjust: 0},
			testFile: testDataPath + "21_1098232_1362659.json",
		},
		{
			x: 17, y: 19, z: 5,
			opts:     &TileOptions{Format: JSONTile, LineColor: lineColor, LabelColor: labelColor, Projection: NewGeodeticTMS(), ZoomAdjust: 0},
			testFile: testDataPath + "5_17_19_geodetic.json",
		},
		{
			x: 1098232, y: 1362659, z: 21,
			opts:     &TileOptions{Format: JSONTile, LineColor: lineColor, LabelColor: labelColor, Projection: NewGeodeticTMS(), ZoomAdjust: 0},
			testFile: testDataPath + "21_1098232_1362659_geodetic.json",
		},
	}
	for n, test := range tests {
		// Read the test data, convert to struct.
		want := &geojson.FeatureCollection{}
		if err := json.Unmarshal(readTestData(test.testFile), want); err != nil {
			t.Errorf("Test %d: data unmarshal failed: %v", n, err)
		}
		// Make the tile reference and get the geojson struct.
		tr := MakeTileRef(test.x, test.y, test.z, test.opts)
		got, err := tr.GeoJSON()
		if err != nil {
			t.Errorf("Test %d: GeoJSON generation failed: %v", n, err)
		}
		if !cmp.Equal(got, want) {
			if blob, err := got.MarshalJSON(); err != nil {
				t.Errorf("Test %d: got %v, want %v", n, got, want)
			} else {
				t.Errorf("Test %d: got %s", n, string(blob))
			}
		}
	}
}
