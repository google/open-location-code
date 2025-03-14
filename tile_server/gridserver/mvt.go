package gridserver

import (
	log "github.com/golang/glog"
	"github.com/paulmach/orb/encoding/mvt"
	"github.com/paulmach/orb/maptile"
)

const (
	layerName    = "grid"
	layerVersion = 2
	layerExtent  = 4096
)

// MVT returns a Mapbox Vector Tile (MVT) marshalled as bytes.
func (t *TileRef) MVT() ([]byte, error) {
	log.Infof("Producing mvt for tile z/x/y %v/%v/%v (%s)", t.Z, t.X, t.Y, t.Path())
	gj, err := t.GeoJSON()
	if err != nil {
		return nil, err
	}

	layer := &mvt.Layer{
		Name:     layerName,
		Version:  layerVersion,
		Extent:   layerExtent,
		Features: gj.Features,
	}

	// Since GeoJSON stores geometries in latitude and longitude (WGS84),
	// we only need to project the coordinates if the desired output projection is Mercator.
	if t.Options.Projection.String() == "mercator" {
		// Convert TMS coordinates to WMS coordinates
		wmsY := (1 << uint(t.Z)) - t.Y - 1
		layer.ProjectToTile(maptile.New(uint32(t.X), uint32(wmsY), maptile.Zoom(t.Z)))
	}

	data, err := mvt.Marshal(mvt.Layers{layer})
	if err != nil {
		return nil, err
	}
	return data, nil
}
