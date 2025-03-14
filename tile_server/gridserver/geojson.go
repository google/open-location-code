package gridserver

import (
	"math"

	log "github.com/golang/glog"
	olc "github.com/google/open-location-code/go"
	"github.com/paulmach/orb"
	"github.com/paulmach/orb/geojson"
)

// GeoJSON returns a GeoJSON object for the tile.
// Objects (lines etc) may extend outside the tile dimensions, so clipping objects to match tile boundaries is up to the client.
func (t *TileRef) GeoJSON() (*geojson.FeatureCollection, error) {
	log.Infof("Producing geojson for tile z/x/y %v/%v/%v (%s)", t.Z, t.X, t.Y, t.Path())
	cl, latp, lngp := olcPrecision(t.Z + t.Options.ZoomAdjust)
	lo, hi := expand(t.SW, t.NE, latp, lngp)
	fc := geojson.NewFeatureCollection()
	latSteps := int(math.Ceil((hi.Lat - lo.Lat) / latp))
	lngSteps := int(math.Ceil((hi.Lng - lo.Lng) / lngp))
	for lats := 0; lats < latSteps; lats++ {
		for lngs := 0; lngs < lngSteps; lngs++ {
			// Compute the SW corner of this cell.
			sw := LatLng{lo.Lat + latp*float64(lats), lo.Lng + lngp*float64(lngs)}
			// Make the geometry of the cell. Longitude comes first!
			g := orb.Polygon{orb.Ring{
				orb.Point{sw.Lng, sw.Lat},               // SW
				orb.Point{sw.Lng, sw.Lat + latp},        // NW
				orb.Point{sw.Lng + lngp, sw.Lat + latp}, // NE
				orb.Point{sw.Lng + lngp, sw.Lat},        // SE
			}}
			// Create the cell as a polygon.
			cell := geojson.NewFeature(g)
			// Compute the code of the center.
			code := olc.Encode(sw.Lat+latp/2, sw.Lng+lngp/2, cl)
			cell.Properties["name"] = code
			if cl < 10 {
				cell.Properties["name"] = code[:cl]
			}
			cell.Properties["global_code"] = code
			if cl >= 10 {
				cell.Properties["area_code"] = code[:4]
				cell.Properties["local_code"] = code[4:]
			}
			// Add to the feature collection.
			fc.Append(cell)
		}
	}
	return fc, nil
}

// bounds returns the lat/lng bounding box for the feature.
func bounds(f *geojson.Feature) (latlo, lnglo, lathi, lnghi float64) {
	latlo = f.Geometry.(orb.Polygon)[0][0][1]
	lnglo = f.Geometry.(orb.Polygon)[0][0][0]
	lathi = f.Geometry.(orb.Polygon)[0][2][1]
	lnghi = f.Geometry.(orb.Polygon)[0][2][0]
	return
}

// featureLabel returns the label for the cell. This can be a multi-line string.
func featureLabel(f *geojson.Feature) string {
	if n, ok := f.Properties["name"]; ok {
		ns := n.(string)
		switch {
		case len(ns) <= 4:
			return ns
		case len(ns) < 8:
			return ns[0:4] + "\n" + ns[4:]
		case len(ns) == 8:
			return ns[0:4] + "\n" + ns[4:] + "+"
		default:
			return ns[0:4] + "\n" + ns[4:9] + "\n" + ns[9:]
		}
	}
	return ""
}

// olcPrecision computes the OLC grid precision parameters for the zoom level.
func olcPrecision(z int) (codeLen int, latPrecision float64, lngPrecision float64) {
	codeLen = 2
	if z >= 24 {
		codeLen = 12
	} else if z >= 22 {
		codeLen = 11
	} else if z >= 19 {
		codeLen = 10
	} else if z >= 15 {
		codeLen = 8
	} else if z >= 11 {
		codeLen = 6
	} else if z >= 6 {
		codeLen = 4
	}
	if area, err := olc.Decode(olc.Encode(0, 0, codeLen)); err == nil {
		latPrecision = area.LatHi - area.LatLo
		lngPrecision = area.LngHi - area.LngLo
	} else {
		// Go bang since if this fails something is badly wrong with the olc library.
		log.Fatalf("Failed encoding 0,0 for codeLen %v", codeLen)
	}
	return
}

// expand grows the coordinates of a bounding box to be multiples of the precision (in degrees).
func expand(sw, ne *LatLng, latp, lngp float64) (*LatLng, *LatLng) {
	// Lat and lng need to be based at zero otherwise the rounding is off.
	lo := LatLng{
		Lat: math.Floor((sw.Lat+90)/latp)*latp - 90,
		Lng: math.Floor((sw.Lng+180)/lngp)*lngp - 180,
	}
	hi := LatLng{
		Lat: math.Ceil((ne.Lat+90)/latp)*latp - 90,
		Lng: math.Ceil((ne.Lng+180)/lngp)*lngp - 180,
	}
	// Make sure we don't do anything illegal.
	lo.Lat = math.Min(90, math.Max(-90, lo.Lat))
	hi.Lat = math.Min(90, math.Max(-90, hi.Lat))
	lo.Lng = math.Min(180, math.Max(-180, lo.Lng))
	hi.Lng = math.Min(180, math.Max(-180, hi.Lng))
	return &lo, &hi
}
