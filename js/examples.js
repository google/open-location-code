/*
 Copyright 2014 Google Inc. All rights reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/
// Utility functions for the example HTML pages.

/** Array of polygons/rectangles to be displayed. */
var polygons = [];
function clearPolygons() {
  for (var i = 0; i < polygons.length; i++) {
    polygons[i].setMap(null);
  }
  polygons = [];
}

/** Array of text labels to be displayed. */
var textLabels = [];
function clearTextLabels() {
  for (var i = 0; i < textLabels.length; i++) {
    textLabels[i].setMap(null);
  }
  textLabels = [];
}

/**
  Zoom the map to a display a code area. If the zoom level is passed set the
  maps zoom level.

  @param {string} code The OLC code to zoom to the center of.
  @param {zoomLevel} zoomLevel An optional zoom level. If not passed, the zoom
      level is chosen in order to display the entire OLC code area.
*/
function zoomTo(code, zoomLevel) {
  var codeArea = OpenLocationCode.decode(code);
  var center = new google.maps.LatLng(
      codeArea.latitudeCenter, codeArea.longitudeCenter);
  map.setCenter(center);
  if (typeof zoomLevel != 'undefined') {
    map.setZoom(zoomLevel);
    return;
  }
  var oldZoom = map.getZoom();
  var sw = new google.maps.LatLng(codeArea.latitudeLo, codeArea.longitudeLo);
  var ne = new google.maps.LatLng(codeArea.latitudeHi, codeArea.longitudeHi);
  map.fitBounds(new google.maps.LatLngBounds(sw, ne));
  var newZoom = map.getZoom();
  if (newZoom < oldZoom) {
    // We've had to zoom out to see it - that's ok.
    return;
  }
  if (oldZoom > 14 && newZoom > 17) {
    map.setZoom(oldZoom);
  }
}

/**
  Reformat an OLC code by decoding and encoding the center.

  @param {string} code A valid full OLC code to reformat.
  @return {string} The formatted code.
*/
function formatCode(code) {
  var codeArea = OpenLocationCode.decode(code);
  return OpenLocationCode.encode(
      codeArea.latitudeCenter, codeArea.longitudeCenter, codeArea.codeLength);
}

/**
  Create a rectangle for an OLC code.

  @param {goog.maps.Map} map The map to place the polygon on.
  @param {string} code The OLC code to display.
  @param {string} fill The color to use for the outline and fill (CSS syntax).
  @return {goog.maps.Rectangle} The rectangle for the code.
*/
function displayOlcArea(map, code, fill) {
    if (typeof fill == 'undefined') {
      fill = '#e51c23';
    }
  var codeArea = OpenLocationCode.decode(code);
  var sw = new google.maps.LatLng(codeArea.latitudeLo, codeArea.longitudeLo);
  var ne = new google.maps.LatLng(codeArea.latitudeHi, codeArea.longitudeHi);
  var bounds = new google.maps.LatLngBounds(sw, ne);

  // Draw the rectangle.
  var rectangle = new google.maps.Rectangle({
      bounds: bounds,
      strokeColor: fill,
      strokeOpacity: 1.0,
      strokeWeight: 2,
      fillColor: fill,
      fillOpacity: 0.3,
      clickable: false,
      map: map
  });
  return rectangle;
}

// Geocoder functions.

/**
  Geocode an address to get a lat/lng and call a callback function. Errors are
  written to an element with the id 'address'.

  @param {string} olcCode The OLC code to pass to the callback function.
  @param {string} address The address to geocode.
  @param {*} callbackFunction A function to call with the OLC code, the address
      and the coordinates of the address.
  */
function geocodeAddress(olcCode, address, callbackFunction) {
  if (typeof google === 'undefined' || typeof google.maps === 'undefined') {
    return false;
  }
  // Google Maps API geocoder object.
  var geocoder = new google.maps.Geocoder();
  // Send the address off to the geocoder.
  geocoder.geocode(
      {'address': address},
      function(results, status) {
        if (status != google.maps.GeocoderStatus.OK) {
          document.getElementById('address').innerHTML = 'Geocoder failed';
          return;
        }
        var addressLocation = results[0].geometry.location;
        callbackFunction(
            olcCode, address, addressLocation.lat(), addressLocation.lng());
      });
}

/**
  Reverse geocode a lat/lng, extract an address and call a callback function.
  Errors are written to an element with the id 'address'.

  @param {number} lat The latitude in degrees.
  @param {number} lng The longitude in degrees.
  @param {string} olcCode The OLC code to pass to the callback function.
  @param {*} callbackFunction A function to call with the OLC code and the
      address.
*/
function geocodeLatLng(lat, lng, olcCode, callbackFunction) {
  if (typeof google === 'undefined' || typeof google.maps === 'undefined') {
    return false;
  }
  // Google Maps API geocoder object.
  var geocoder = new google.maps.Geocoder();
  // Reverse geocode the lat/lng.
  var latlng = new google.maps.LatLng(lat, lng);
  geocoder.geocode(
      {'latLng': latlng},
      function(results, status) {
        if (status != google.maps.GeocoderStatus.OK) {
          document.getElementById('address').innerHTML = 'Geocoder failed';
          return;
        }
        var addressNames = [];
        var addressComponents = [];
        // We always want the postal code.
        var postal_code = '';
        // Defines the other component types in the order we want them.
        var componentTypes = [
            'neighborhood',
            'sublocality_level_2',
            'sublocality_level_1',
            'locality',
            'administrative_area_level_4',
            'administrative_area_level_3',
            'administrative_area_level_2',
            'administrative_area_level_1'];
        // Scan all the results and all the address components for matches
        // with the desired types. Take the first match for any component and
        // save them in the addressXXX lists.
        for (var i = 0; i < results.length; i++) {
          for (var j = 0; j < results[i].address_components.length; j++) {
            var component = results[i].address_components[j];
            for (var k = 0; k < component.types.length; k++) {
              if (componentTypes.indexOf(component.types[k]) > -1 &&
                  addressComponents.indexOf(component.types[k]) == -1 &&
                  addressNames.indexOf(component.long_name) == -1 &&
                  component.long_name.indexOf(',') == -1) {
                addressNames.push(component.long_name);
                addressComponents.push(component.types[k]);
              }
            }
          }
        }
        // Go through the componentTypes in order and build up the address.
        var geocodedAddress = [];
        for (var i = 0; i < componentTypes.length; i++) {
          var componentIndex = addressComponents.indexOf(componentTypes[i]);
          if (componentIndex != -1) {
            geocodedAddress.push(addressNames[componentIndex]);
          }
          if (geocodedAddress.length == 3) {
            break;
          }
        }
        // Add the postal code if we got one.
        if (postal_code !== '') {
          geocodedAddress.push(postal_code);
        }
        // Call the callback function.
        callbackFunction(olcCode, geocodedAddress.join(', '));
      });
}

/**
  Display an OLC outline and its internal grid.
  If the passed OLC code is blank, the top level OLC grid is displayed.

  @constructor
  @param {string} olcCode A full OLC code.
  @param {string} lineColor The color to use for lines (CSS syntax).
  @param {goog.maps.Map} map The Google Maps API map.
*/
var OlcStandardGrid = function(olcCode, lineColor, map) {
  // Now initialize all properties.
  var latLo, latHi, lngLo, lngHi;
  var latSteps = 20;
  var lngSteps = 20;
  var stepDegrees;
  if (olcCode != '') {
    var codeArea = OpenLocationCode.decode(olcCode);
    latLo = codeArea.latitudeLo;
    latHi = codeArea.latitudeHi;
    lngLo = codeArea.longitudeLo;
    lngHi = codeArea.longitudeHi;
    stepDegrees = (latHi - latLo) / latSteps;
    steps = 20;
  } else {
    latLo = -90;
    latHi = 90;
    lngLo = -180;
    lngHi = 180;
    stepDegrees = 20;
    latSteps = 9;
    lngSteps = 18;
  }
  // Quarter and half step sizes are for label offsets.
  var quarterStep = stepDegrees / 4;
  var halfStep = stepDegrees / 2;

  // Save the gridlines and labels so we can clear them.
  this.gridlines_ = [];
  this.labels_ = [];

  // Now draw the vertical grid lines and add their indicators.
  for (var step = 0; step <= lngSteps; step++) {
    var lng = lngLo + step * stepDegrees;
    var path = [new google.maps.LatLng(latLo, lng),
                new google.maps.LatLng((latLo + latHi) / 2, lng),
                new google.maps.LatLng(latHi, lng)];
    var line = new google.maps.Polyline({
      path: path,
      strokeColor: lineColor,
      strokeOpacity: 1,
      strokeWeight: 2,
      clickable: false,
      map: map
    });
    this.gridlines_.push(line);
    if (step < lngSteps) {
      var label = new TextOverlay(
          new google.maps.LatLng(latHi - quarterStep, lng + halfStep),
          OpenLocationCode.getAlphabet().charAt(step),
          map);
      this.labels_.push(label);
      var label = new TextOverlay(
        new google.maps.LatLng(latLo + quarterStep, lng + halfStep),
        OpenLocationCode.getAlphabet().charAt(step),
        map);
      this.labels_.push(label);
    }
  }
  // Now draw the horizontal grid lines.
  for (var step = 0; step <= latSteps; step++) {
    var lat = latLo + step * stepDegrees;
    var path = [new google.maps.LatLng(lat, lngLo),
                new google.maps.LatLng(lat, (lngLo + lngHi) / 2),
                new google.maps.LatLng(lat, lngHi)];
    var line = new google.maps.Polyline({
      path: path,
      strokeColor: lineColor,
      strokeOpacity: 1,
      strokeWeight: 2,
      clickable: false,
      map: map
    });
    this.gridlines_.push(line);
    if (step < latSteps) {
      var label = new TextOverlay(
          new google.maps.LatLng(lat + halfStep, lngLo + quarterStep),
          OpenLocationCode.getAlphabet().charAt(step),
          map);
      this.labels_.push(label);
      var label = new TextOverlay(
        new google.maps.LatLng(lat + halfStep, lngHi - quarterStep),
        OpenLocationCode.getAlphabet().charAt(step),
        map);
      this.labels_.push(label);
    }
  }
};

/** Called when the map's panes are ready and the overlay has been added. */
OlcStandardGrid.prototype.clear = function() {
  for (var i = 0; i < this.gridlines_.length; i++) {
    this.gridlines_[i].setMap(null);
  }
  this.gridlines_ = [];
  for (var i = 0; i < this.labels_.length; i++) {
    this.labels_[i].setMap(null);
  }
  this.labels_ = [];
};

/**
  Display an OLC outline and its internal 4x5 grid.
  @constructor
  @param {string} olcCode A full OLC code.
  @param {string} lineColor The color to use for lines (CSS syntax).
  @param {goog.maps.Map} map The Google Maps API map.
*/
function OlcRefinedGrid(olcCode, lineColor, map) {
  // Initialize all properties.
  var codeArea = OpenLocationCode.decode(olcCode);
  var sw = new google.maps.LatLng(codeArea.latitudeLo, codeArea.longitudeLo);
  var ne = new google.maps.LatLng(codeArea.latitudeHi, codeArea.longitudeHi);
  var bounds = new google.maps.LatLngBounds(sw, ne);

  this.gridlines_ = [];
  this.labels_ = [];
  var lngStep = (codeArea.longitudeHi - codeArea.longitudeLo) / 4;
  var lngHalfStep = lngStep / 2;
  var latStep = (codeArea.latitudeHi - codeArea.latitudeLo) / 5;
  var latHalfStep = latStep / 2;
  // Now draw the vertical grid lines.
  for (var i = 0; i <= 4; i++) {
    var lower = new google.maps.LatLng(
        codeArea.latitudeLo, codeArea.longitudeLo + i * lngStep);
    var upper = new google.maps.LatLng(
        codeArea.latitudeHi, codeArea.longitudeLo + i * lngStep);
    var line = new google.maps.Polyline({
      path: [lower, upper],
      strokeColor: lineColor,
      strokeOpacity: 1,
      strokeWeight: 2,
      clickable: false,
      map: map
    });
    this.gridlines_.push(line);
  }
  // Now draw the horizontal grid lines.
  for (var i = 0; i <= 5; i++) {
    var left = new google.maps.LatLng(
        codeArea.latitudeLo + i * latStep, codeArea.longitudeLo);
    var right = new google.maps.LatLng(
        codeArea.latitudeLo + i * latStep, codeArea.longitudeHi);
    var line = new google.maps.Polyline({
      path: [left, right],
      strokeColor: lineColor,
      strokeOpacity: 1,
      strokeWeight: 2,
      clickable: false,
      map: map
    });
    this.gridlines_.push(line);
  }
  for (var col = 0; col < 4; col++) {
    for (var row = 0; row < 5; row++) {
      var center = new google.maps.LatLng(
          codeArea.latitudeLo + latHalfStep + row * latStep,
          codeArea.longitudeLo + lngHalfStep + col * lngStep);
      var label = new TextOverlay(
          center,
          OpenLocationCode.getAlphabet().charAt(row * 4 + col),
          map);
      this.labels_.push(label);
    }
  }
}

/** Called when the map's panes are ready and the overlay has been added. */
OlcRefinedGrid.prototype.clear = function() {
  for (var i = 0; i < this.gridlines_.length; i++) {
    this.gridlines_[i].setMap(null);
  }
  this.gridlines_ = [];
  for (var i = 0; i < this.labels_.length; i++) {
    this.labels_[i].setMap(null);
  }
  this.labels_ = [];
};

/** Define the text overlay prototype as an OverlayView. */
TextOverlay.prototype = new google.maps.OverlayView();

/**
   Create a new text overlay to display text on the map.

   @constructor
   @param {goog.maps.LatLng} latLng The location to place the text.
   @param {string} displayText The text to place.
   @param {goog.maps.Map} map The Google Maps API map.
 */
function TextOverlay(latLng, displayText, map) {
  // Now initialize all properties.
  this.latLng_ = latLng;
  this.displayText_ = displayText;
  this.className_ = 'map_label';
  this.map_ = map;
  this.div_ = null;
  this.heightOffset_ = 0;
  this.widthOffset_ = 0;
  this.setMap(map);
}

/** Called when the map's panes are ready and the overlay has been added. */
TextOverlay.prototype.onAdd = function() {
  var div = document.createElement('DIV');
  div.className = this.className_;
  div.innerHTML = this.displayText_;
  div.style.position = 'absolute';
  this.div_ = div;
  var panes = this.getPanes();
  panes.overlayLayer.appendChild(div);
  this.heightOffset_ = this.div_.offsetHeight / 2;
  this.widthOffset_ = this.div_.offsetWidth / 2;
};
/** Called to draw the overlay. */
TextOverlay.prototype.draw = function() {
  var overlayProjection = this.getProjection();
  var position = overlayProjection.fromLatLngToDivPixel(this.latLng_);
  this.div_.style.left = (position.x - this.widthOffset_) + 'px';
  this.div_.style.top = (position.y - this.heightOffset_) + 'px';
};
/** Called when the overlay's map property is set to null. */
TextOverlay.prototype.onRemove = function() {
  this.div_.parentNode.removeChild(this.div_);
  this.div_ = null;
};

