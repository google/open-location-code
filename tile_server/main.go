// main starts the server.
package main

import (
	"flag"
	"fmt"
	"net/http"

	log "github.com/golang/glog"
	// Use the production gridserver. In development, change to just "./gridserver".
	"github.com/google/open-location-code/tile_server/gridserver"
	"golang.org/x/image/font/gofont/goregular"
)

var (
	port = flag.Int("port", 8080, "Port to run the server on")
)

const (
	originHeader       = "Access-Control-Allow-Origin"
	contentTypeHeader  = "Content-Type"
	contentTypeGeoJSON = "application/vnd.geo+json"
	contentTypePNG     = "image/png"
	contentTypeMVT     = "application/vnd.mapbox-vector-tile"
)

func init() {
	flag.Parse()
}

func main() {
	log.Infof("Starting...")
	gridserver.SetImageFont(goregular.TTF)
	http.HandleFunc("/", Handler)
	log.Infof("Ready")
	if err := http.ListenAndServe(fmt.Sprintf(":%v", *port), nil); err != nil {
		panic(err)
	}
}

// Handler processes a tileReq for a single tile and writes either the GeoJSON or image as a response.
func Handler(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseForm(); err != nil {
		log.Errorf("Bad http request: %v: %v", r.URL, err)
		http.Error(w, err.Error(), 400)
		return
	}
	tile, err := gridserver.Parse(r)
	if err != nil {
		log.Errorf("Bad tile request: %v: %v", r.URL, err)
		http.Error(w, err.Error(), 400)
		return
	}
	w.Header().Set(originHeader, "*")

	// Response content. May be a tile or JSON.
	ctype := contentTypeGeoJSON
	blob := []byte("")
	if tile.Options.Format == gridserver.JSONTile {
		json, err := tile.GeoJSON()
		if err != nil {
			log.Errorf("Error producing geojson tile: %v", err)
			http.Error(w, err.Error(), 500)
			return
		}
		if blob, err = json.MarshalJSON(); err != nil {
			log.Errorf("Error marshaling geojson tile: %v", err)
			http.Error(w, err.Error(), 500)
			return
		}
	} else if tile.Options.Format == gridserver.ImageTile {
		ctype = contentTypePNG
		if blob, err = tile.Image(); err != nil {
			log.Errorf("Error producing image tile: %v", err)
			http.Error(w, err.Error(), 500)
			return
		}
	} else if tile.Options.Format == gridserver.VectorTile {
		ctype = contentTypeMVT
		if blob, err = tile.MVT(); err != nil {
			log.Errorf("Error producing mapbox vector tile: %v", err)
			http.Error(w, err.Error(), 500)
			return
		}
	}
	w.Header().Set(contentTypeHeader, ctype)
	w.Write(blob)
}
