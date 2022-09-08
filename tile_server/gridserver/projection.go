package gridserver

import (
	"math"
)

const (
	earthRadiusMeters        = 6378137
	earthCircumferenceMeters = 2 * math.Pi * earthRadiusMeters
)

// Projection defines the interface for types that convert between pixel and lat/lng coordinates.
type Projection interface {
	TileOrigin(tx, ty, zoom int) (float64, float64)
	TileLatLngBounds(tx, ty, zoom int) (float64, float64, float64, float64)
	LatLngToRaster(float64, float64, float64) (x, y float64)
	String() string
}

// MercatorTMS provides a spherical mercator projection using TMS tile specifications.
// Although TMS tiles are numbered from south to north, raster coordinates are numbered from north to south.
// This code is indebted to the gdal2tiles.py from OSGEO GDAL.
type MercatorTMS struct {
	tileSize       float64
	metersPerPixel float64
	originShift    float64
}

// NewMercatorTMS gets new projection object.
func NewMercatorTMS() *MercatorTMS {
	m := MercatorTMS{
		tileSize:       tileSize,
		metersPerPixel: earthCircumferenceMeters / tileSize,
		originShift:    earthCircumferenceMeters / 2,
	}
	return &m
}

// TileOrigin returns the left and top of the tile in raster pixels.
func (m *MercatorTMS) TileOrigin(tx, ty, zoom int) (x, y float64) {
	// Flip y into WMS numbering (north to south).
	ty = int(math.Pow(2, float64(zoom))) - ty - 1
	y = float64(ty) * tileSize
	x = float64(tx) * tileSize
	return
}

// TileLatLngBounds returns bounds of a TMS tile in latitude/longitude using WGS84 datum.
func (m *MercatorTMS) TileLatLngBounds(tx, ty, zoom int) (latlo, lnglo, lathi, lnghi float64) {
	minx, miny := m.pixelsToMeters(float64(tx)*m.tileSize, float64(ty)*m.tileSize, float64(zoom))
	maxx, maxy := m.pixelsToMeters((float64(tx)+1)*m.tileSize, (float64(ty)+1)*m.tileSize, float64(zoom))
	latlo, lnglo = m.metersToLatLng(minx, miny)
	lathi, lnghi = m.metersToLatLng(maxx, maxy)
	return
}

// LatLngToRaster converts a WGS84 latitude and longitude to absolute pixel values.
// Note that the pixel origin is at top left.
func (m *MercatorTMS) LatLngToRaster(lat, lng float64, zoom float64) (x, y float64) {
	var mx, my float64
	if lat < 0 {
		// If the latitude is negative, work it out as if it was positive.
		// (This is because the algorithm returns Inf if lat = -90.)
		mx, my = m.latLngToMeters(-lat, lng)
	} else {
		mx, my = m.latLngToMeters(lat, lng)
	}
	resolution := m.metersPerPixel / math.Pow(2, zoom)
	// Shift the meter values to the origin and convert them to pixels.
	x = (mx + m.originShift) / resolution
	y = (my + m.originShift) / resolution

	// If the latitude was positive, convert the y coordinate to be numbered from top to bottom.
	// (If it was negative, we don't have to do anything because we already reversed the latitude.)
	if lat > 0 {
		y = float64(int(m.tileSize)<<uint(zoom)) - y
	}
	return
}

// String provides the name of the projection.
func (m *MercatorTMS) String() string {
	return "mercator"
}

// latLngToMeters converts given lat/lon in WGS84 Datum to XY in Spherical MercatorTMS EPSG:900913.
func (m *MercatorTMS) latLngToMeters(lat, lng float64) (mx float64, my float64) {
	mx = lng * m.originShift / 180.0
	my = math.Log(math.Tan((90+lat)*math.Pi/360.0)) / (math.Pi / 180.0)
	my = my * m.originShift / 180.0
	return
}

// metersToLatLng converts XY point from Spherical MercatorTMS EPSG:900913 to lat/lng in WGS84 Datum.
func (m *MercatorTMS) metersToLatLng(mx, my float64) (lat float64, lng float64) {
	lng = (mx / m.originShift) * 180.0
	lat = (my / m.originShift) * 180.0
	lat = 180 / math.Pi * (2*math.Atan(math.Exp(lat*math.Pi/180.0)) - math.Pi/2.0)
	return
}

// pixelsToMeters converts pixel coordinates in given zoom level of pyramid to EPSG:900913.
func (m *MercatorTMS) pixelsToMeters(px, py, zoom float64) (mx, my float64) {
	resolution := m.metersPerPixel / math.Pow(2, zoom)
	mx = px*resolution - m.originShift
	my = py*resolution - m.originShift
	return
}

// GeodeticTMS provides a EPSG:4326 projection.
// The top zoom level is scaled to two tiles. Zoom levels are not square but rectangular.
// Although TMS tiles are numbered from south to north, raster coordinates are numbered from north to south.
// This code is indebted to the gdal2tiles.py from OSGEO GDAL.
type GeodeticTMS struct {
	tileSize    float64
	resFact     float64
	originShift float64
}

// NewGeodeticTMS gets new projection object.
func NewGeodeticTMS() *GeodeticTMS {
	g := GeodeticTMS{
		tileSize: tileSize,
		resFact:  180.0 / tileSize,
	}
	return &g
}

// TileOrigin returns the left and top of the tile in raster pixels.
func (g *GeodeticTMS) TileOrigin(tx, ty, zoom int) (x, y float64) {
	// Flip y into WMS numbering (north to south).
	ty = int(math.Pow(2, float64(zoom))) - ty - 1
	y = float64(ty) * tileSize
	x = float64(tx) * tileSize
	return
}

// TileLatLngBounds returns bounds of a TMS tile in latitude/longitude using WGS84 datum.
func (g *GeodeticTMS) TileLatLngBounds(tx, ty, zoom int) (latlo, lnglo, lathi, lnghi float64) {
	res := g.resFact / math.Pow(2, float64(zoom))
	lnglo = float64(tx)*tileSize*res - 180
	latlo = float64(ty)*tileSize*res - 90
	lnghi = float64(tx+1)*tileSize*res - 180
	lathi = float64(ty+1)*tileSize*res - 90
	return
}

// LatLngToRaster converts a WGS84 latitude and longitude to absolute pixel values.
// Note that the pixel origin is at top left.
func (g *GeodeticTMS) LatLngToRaster(lat, lng float64, zoom float64) (x, y float64) {
	res := g.resFact / math.Pow(2, float64(zoom))
	x = (180 + lng) / res
	// Use -lat because we want the pixel origin to be at the top, not at the bottom.
	y = (90 - lat) / res
	return
}

// String provides the name of the projection.
func (g *GeodeticTMS) String() string {
	return "geodetic"
}
