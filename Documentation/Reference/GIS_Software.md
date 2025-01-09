# Plus Codes in GIS software

This page provides information about using Plus Codes in GIS software.

## Tile Service

If you want to visualise the Plus Codes grid, you can use the [grid service](https://grid.plus.codes) to fetch the grid tiles.

This is a shared service, and it may rate limit you.
If you need to use the grid heavily, you can start your own [tile_server](https://github.com/google/open-location-code/blob/main/tile_server).

The tile service provides GeoJSON objects, one per Plus Codes square, or PNG images that can be added as an overlay.

## Software

### QGIS

| precision level | intervals in degrees |
|-----|-----|
| 10 | 0.000125 |
| 8 | 0.0025 |
| 6 | 0.05 |
| 4 | 1 |
| 2 | 20 |

We can generate the grid lines in QGIS.

Just make sure your starting lat-long values are an exact multiple of the interval values for your chosen precision level you want.

Example : Creating a grid with precision 6 : starting latitude cannot be 16.4563.
Change it to 16.45 or 16.50 so that when you divide it by 0.05 it gives you an integer answer.

In QGIS, you can generate a grid by clicking in the top Menu: Vector > Research tools > Vector Grid

* Grid extent (xmin,xmax,ymin,ymax): 78.1,79,16.9,18.2 (in my example, a city in India)
* Set both lat and lon interval as per the precision level you want.
  So for precision level 6, enter 0.05 for both.
* You can set output as lines or polygons, your choice.
  Lines make simpler and smaller shapefiles.
* And that should generate the grid for you.
  You can save that layer as a shapefile in any format.

Note that this will not put any information about the Plus Codes in your grid's metadata.
They're just lines/boxes.

But if you make polygons, then I can think of a roundabout way of adding Plus Code values to those polygons (I have not done this myself yet):

* Generate a centroid layer (Vector > Geometry Tools > Polygon Centroid) from the grid-polygons layer.
  This will place points inside each grid box. (in a new points layer.)
* Install "Lat Lon Tools" plugin.
* That plugin can generate Plus Codes from points.
  So run it on the centroid layer you made.
* (And this I can't quite figure out yet) Figure out a way to move the meta field from the centroid layer to the grid polygons layer.

There is a plugin for QGIS, [Lat Lon tools](https://github.com/NationalSecurityAgency/qgis-latlontools-plugin).

