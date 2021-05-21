package gridserver

import (
	"math"
	"testing"
)

func TestTileLatLngBounds(t *testing.T) {
	var tests = []struct {
		x, y, z int
		p       Projection
		sw, ne  *LatLng
	}{
		{
			x: 0, y: 0, z: 1,
			p:  NewMercatorTMS(),
			sw: &LatLng{-85.051128, -180},
			ne: &LatLng{0, 0},
		},
		{
			x: 0, y: 0, z: 0,
			p:  NewGeodeticTMS(),
			sw: &LatLng{-90, -180},
			ne: &LatLng{90, 0},
		},
		{
			x: 1, y: 0, z: 0,
			p:  NewGeodeticTMS(),
			sw: &LatLng{-90, 0},
			ne: &LatLng{90, 180},
		},
	}
	for _, test := range tests {
		latlo, lnglo, lathi, lnghi := test.p.TileLatLngBounds(test.x, test.y, test.z)
		if !floatEquals(latlo, test.sw.Lat, 1e-6) ||
			!floatEquals(lnglo, test.sw.Lng, 1e-6) ||
			!floatEquals(lathi, test.ne.Lat, 1e-6) ||
			!floatEquals(lnghi, test.ne.Lng, 1e-6) {
			t.Errorf(
				"TileLatLngBounds(%v, %v, %v): wanted %s - %s, got %v,%v - %v,%v",
				test.x, test.y, test.z, test.sw, test.ne, latlo, lnglo, lathi, lnghi)
		}
	}
}

func TestLatLngToRaster(t *testing.T) {
	var tests = []struct {
		p              Projection
		lat, lng, zoom float64
		x, y           float64
	}{
		{
			p:   NewMercatorTMS(),
			lat: 90, lng: -180, zoom: 1,
			x: 0, y: -2786.073317,
		},
		{
			p:   NewMercatorTMS(),
			lat: 85.05112875, lng: -180, zoom: 1,
			x: 0, y: 0,
		},
		{
			p:   NewMercatorTMS(),
			lat: 0, lng: 0, zoom: 1,
			x: 256, y: 256,
		},
		{
			p:   NewMercatorTMS(),
			lat: -85.05112875, lng: 180, zoom: 1,
			x: 512, y: 512,
		},
		{
			p:   NewMercatorTMS(),
			lat: -90, lng: 180, zoom: 1,
			x: 512, y: 3298.073317,
		},
	}
	for _, test := range tests {
		gotx, goty := test.p.LatLngToRaster(test.lat, test.lng, test.zoom)
		if !floatEquals(gotx, test.x, 1e-6) ||
			!floatEquals(goty, test.y, 1e-6) {
			t.Errorf(
				"TestLatLngToRaster(%v, %v, %v): wanted %v,%v, got %v,%v diff (%v, %v)",
				test.lat, test.lng, test.zoom, test.x, test.y, gotx, goty,
				math.Abs(test.x-gotx), math.Abs(test.y-goty))
		}
	}
}

func floatEquals(a, b, margin float64) bool {
	return math.Abs(a-b) < margin
}
