# Open Location Code Grid Overlay Server

This code provides a Go server to handle
[Tile Map Service](https://en.wikipedia.org/wiki/Tile_Map_Service) requests. It
is able to respond with [GeoJSON](https://geojson.org), image tiles or
[Mapbox Vector Tiles](https://github.com/mapbox/vector-tile-spec) (version 2.1), any of
which can be added as an overlay to a map.

## Limitations

1. This server does not implement any GetCapabilities methods.
1. A fixed image tile size of 256x256 pixels is used.

## Tile Requests

The server responds to tile requests. These send a zoom level, and x and y tile
numbers. The request URL determines whether the response should be GeoJSON, an
image, or a Mapbox Vector Tile.

The format of the requests is:

```
//hostname:port/grid/[tilespec]/z/x/y.[format]?[options]
```

* `tilespec` must be either `wms` or `tms`. The only difference in these is
    that the Y tiles are numbered from north to south (`wms`) or from south to
    north (`tms`).
* `format` must be either `json` for a GeoJSON FeatureCollection, `png`
    for a PNG image tile, or `mvt` for a Mapbox Vector Tile.
* The optional parameters are:
  * `linecol`: this defines the RGBA colour to use for lines in the PNG
        tiles.
  * `labelcol`: this defines the RGBA colour to use for the labels in the
        PNG tiles.
  * `zoomadjust`: this is added to the map zoom value, to cause the returned
        grid to be finer or coarser. This affects both GeoJSON, image tiles,
        and Mapbox Vector Tile.
  * `projection`: this can be used to change the map projection from the
        default, spherical mercator, to geodetic. Valid values are:
    * `mercator` or `epsg:3857`: selects spherical mercator (default)
    * `geodetic` or `epsg:4326`: selects geodetic projection

An example request could be:

```
http://localhost:8080/grid/tms/16/35694/42164.png?linecol=0xff0000ff&labelcol=0xff000060&zoomadjust=1&projection=epsg:4326
```


Start the server with:

```
go run tile_server/main.go
```

Review `example.html` for how to integrate the tile server with
[Openlayers](https://openlayers.org/), [Leaflet](https://leafletjs.com/) or
[Google Maps API](https://developers.google.com/maps/documentation/javascript/tutorial).

```javascript
var imageMap = new ol.Map({
  target: 'imagemap',
  layers: [
    new ol.layer.Tile({
      source: new ol.source.OSM()
    }),
    new ol.layer.Tile({
      source: new ol.source.XYZ({
        attributions: 'lus.codes grid</a>',
        url: 'http://localhost:8080/grid/tms/{z}/{x}/{y}.png'
      }),
    }),
  ],
  view: new ol.View({
    center: ol.proj.fromLonLat([8.54, 47.5]),
    zoom: 4
  })
});
```

## Tile Details

The labels on the image tiles use the Go font
[goregular](https://blog.golang.org/go-fonts). The grid lines are black, the
text uses black with half-opacity, but these can be changed.

The GeoJSON responses consist of a `FeatureCollection`, consisting of one
`Feature` for each OLC grid cell that overlaps the tile. The `Feature` consists
of a polygon geometry, and a number of properties.

All features have the `name` and `global_code` properties. `area_code` and
`local_code` properties are only populated if the code has more than 10 digits.
Examples:

`global_code` | `name`       | `area_code` | `local_code`
------------- | ------------ | ----------- | ------------
8F000000+     | 8F           | n/a         | n/a
C2M2GVC7+     | C2M2GVC7     | n/a         | n/a
C2M2GVC7+WM   | C2M2GVC7+WM  | C2M2        | GVC7+WM
C2M2GVC7+WMP  | C2M2GVC7+WMP | C2M2        | GVC7+WMP

An example of the GeoJSON output for one feature is:

```json
{
   "type":"Feature",
   "geometry":{
      "type":"Polygon",
      "coordinates":[
         [
            [-179.13587500002043, 83.52224999589674],
            [-179.13587500002043, 83.52237499589674],
            [-179.13575000002044, 83.52237499589674],
            [-179.13575000002044, 83.52224999589674]
         ]
      ]
   },
   "properties":{
      "area_code":"C2M2",
      "global_code":"C2M2GVC7+WM",
      "local_code":"GVC7+WM",
      "name":"C2M2GVC7+WM"
   }
}
```

### Image Tile Grid

If the grid size is large enough, then the next detail level is also drawn. This
uses the same colour as the label but with the alpha channel reduced.

## Server Options

The server will listen on port 8080. You can change this with the `--port` flag.

You can turn on logging with the `--logtostderr` flag.

## Testing

The projection code has some tests to confirm that coordinates are correctly
processed. You can run the tests with:

```
go test ./tile_server/gridserver -v --logtostderr
```

## Dependencies

The following other projects need to be installed:

[orb](https://github.com/paulmach/orb) provides the definition for
the GeoJSON and Mapbox Vector Tile response objects. Install with:

```
go get github.com/paulmach/orb
```

[Freetype](https://github.com/golang/freetype) is used for the labels in the PNG
tiles. Install with:

```
go get github.com/golang/freetype
```

[Open Location Code](https://github.com/open-location-code/) generates the codes
for the labels. Install with:

```
go get github.com/google/open-location-code
```

[Glog](https://github.com/golang/glog) provides the logging. Install with:

```
go get github.com/golang/glog
```
