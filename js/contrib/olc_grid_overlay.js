/*
 * Open Location Code grid overlay. This displays the OLC grid with labels for
 * each major grid square, and if divided, labels for the rows and columns.
 *
 * The default class definition for labels is automatically added to the document. If you want to
 * modify it, copy the following style using a different class name. Specify it using the
 * roadMapLabelClass or satelliteMapLabelClass options:
 *
 *   font-family: Arial, sans; color: #7BAAF7; text-align: center; position: fixed; display: flex;
 *   justify-content: center; flex-direction: column;
 */
(function (root, factory) {
  /* global define, module */
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['b'], function (b) {
      return (root.returnExportsGlobal = factory(b));
    });
  } else if (typeof module === 'object' && module.exports) {
    // Node. Does not work with strict CommonJS, but
    // only CommonJS-like enviroments that support module.exports,
    // like Node.
    module.exports = factory(require('b'));
  } else {
    // Browser globals
    root.OLCGridOverlay = factory();
  }
} (this, function () {
  function OLCGridOverlay(opts) {
    this._checkDefaultLabelStyle();
    opts = opts || {};
    if (typeof(opts.map) !== 'undefined') {
      this.setMap(map);
    }
    this._minorGridDisplay = true;
    if (typeof(opts.minorGridDisplay) === 'boolean') {
      this._minorGridDisplay = opts.minorGridDisplay;
    }
    this._roadmap = {
      gridColor: '#7BAAF7',
      labelClass: 'olc_overlay_text',
      majorOpacity: 0.75,
      minorOpacity: 0.2
    };
    this._satellite = {
      gridColor: '#7BAAF7',
      labelClass: 'olc_overlay_text',
      majorOpacity: 0.8,
      minorOpacity: 0.4
    };
    if (typeof(opts.roadMapColor) === 'string') {
      this._roadmap.gridColor = opts.roadMapColor;
    }
    if (typeof(opts.roadMapLabelClass) === 'string') {
      this._roadmap.labelClass = opts.roadMapLabelClass;
    }
    if (typeof(opts.satelliteMapColor) === 'string') {
      this._satellite.gridColor = opts.satelliteMapColor;
    }
    if (typeof(opts.satelliteMapLabelClass) === 'string') {
      this._satellite.labelClass = opts.satelliteMapLabelClass;
    }

    this._gridSettings = this._roadmap;
    this._gridLines = [];
    this._listeners = [];
    this._olcAlphabet = '23456789CFGHJMPQRVWX';
    this._gridBounds = {latLo: 0, lngLo: 0, latHi: 0, lngHi: 0};
    this._majorGridSizeDeg = 0;
    this._majorGridZoomLevels = [
      {zoom: 6, grid: 20},
      {zoom: 10, grid: 1},
      {zoom: 14, grid: 1/20},
      {zoom: 32, grid: 1/400}
    ];
    this._labelFontSizes = {
      cellLabelMinFontPx: 16,
      cellLabelMaxFontPx: 100,
      gridLabelMinFontPx: 8,
      gridLabelMaxFontPx: 24
    };
  }

  OLCGridOverlay.prototype = new google.maps.OverlayView();

  // Add event listeners that cause the grid to be drawn or redrawn.
  OLCGridOverlay.prototype.onAdd = function() {
    var self = this;
    this._draw();

    function redraw() {
        self._clear();
        self._draw();
    }
    function clear() {
        self._clear();
    }
    function clearLabels() {
        self._clearLabels();
    }
    this._listeners.push(google.maps.event.addListener(this.getMap(), 'idle', redraw));
    this._listeners.push(google.maps.event.addListener(this.getMap(), "maptypeid_changed", redraw));
    this._listeners.push(google.maps.event.addListener(this.getMap(), "zoom_changed", clear));
    this._listeners.push(google.maps.event.addListener(this.getMap(), "dragstart", clearLabels));
  };

  // Does nothing - updates are driven by the event listeners.
  OLCGridOverlay.prototype.draw = function() {
  };

  // Remove all lines, labels and listeners.
  OLCGridOverlay.prototype.onRemove = function() {
    this._clear();
    for (var i = 0; i < this._listeners.length; i++) {
      google.maps.event.removeListener(this._listeners[i]);
    }
  };

  OLCGridOverlay.prototype.hide = function() {
  };

  OLCGridOverlay.prototype.show = function() {
  };

  OLCGridOverlay.prototype._checkDefaultLabelStyle = function() {
    for (var i = 0; i < document.styleSheets.length; i++) {
      var rules = document.styleSheets[i].rules || document.styleSheets[i].cssRules;
      for (var x in rules) {
        if (typeof rules[x].selectorText === 'string' && rules[x].selectorText === ".olc_overlay_text") {
          return;
        }
      }
    }
    var defaultLabelStyle = document.createElement('style');
    defaultLabelStyle.type = 'text/css';
    defaultLabelStyle.innerHTML = '.olc_overlay_text { '
        + ' font-family: Arial, sans; '
        + ' color: #7BAAF7; '
        + ' text-align: center; '
        + ' position: fixed; '
        + ' display: flex; '
        + ' justify-content: center; '
        + ' flex-direction: column; }';
    document.getElementsByTagName('head')[0].appendChild(defaultLabelStyle);
  };

  // Remove all lines and labels.
  OLCGridOverlay.prototype._clear = function() {
    this._clearLines();
    this._clearLabels();
  }

  // Remove the lines.
  OLCGridOverlay.prototype._clearLines = function() {
    try {
      for (var i = 0; i < this._gridLines.length; i++) {
        this._gridLines[i].setMap(null);
      }
    }
    catch (e) {
    }
    this._gridLines = [];
  };

  // Remove the labels.
  OLCGridOverlay.prototype._clearLabels = function() {
    this._clearMarkerLayer();
  };

  // Main draw method that draws grids and labels.
  OLCGridOverlay.prototype._draw = function() {
    // Calculates the size of the main grid (in degrees) depending on the zoom level.
    for (var i = 0; i < this._majorGridZoomLevels.length; i++) {
      if (this.getMap().getZoom() <= this._majorGridZoomLevels[i].zoom) {
        this._majorGridSizeDeg = this._majorGridZoomLevels[i].grid;
        break;
      }
    }
    var mapbounds = this.getMap().getBounds();
    var sw = mapbounds.getSouthWest();
    var ne = mapbounds.getNorthEast();
    // Expand the bounds to a multiple of the OLC major grid size.
    // Add 90 to latitudes so the first cell is from -90 to -70. If we didn't do this, it would range from -100 to -80.
    this._gridBounds.latLo = Math.floor((sw.lat() + 90) / this._majorGridSizeDeg) * this._majorGridSizeDeg - 90;
    this._gridBounds.latLo = Math.max(this._gridBounds.latLo, -90);
    this._gridBounds.latHi = Math.ceil((ne.lat() + 90) / this._majorGridSizeDeg) * this._majorGridSizeDeg - 90;
    this._gridBounds.latHi = Math.min(this._gridBounds.latHi, 90);
    // Longitude needs to be corrected if it transitions 180.
    this._gridBounds.lngLo = Math.floor(sw.lng() / this._majorGridSizeDeg) * this._majorGridSizeDeg;
    this._gridBounds.lngHi = Math.ceil(ne.lng() / this._majorGridSizeDeg) * this._majorGridSizeDeg;
    // Handle a map with 180/-180 in the middle.
    if (this._gridBounds.lngLo > this._gridBounds.lngHi) {
      this._gridBounds.lngHi = this._gridBounds.lngHi + 360;
    }

    // Based on the map type, choose the settings grid lines and labels.
    this._gridSettings = this._roadmap;
    var type = this.getMap().getMapTypeId();
    if (type === google.maps.MapTypeId.HYBRID || type === google.maps.MapTypeId.SATELLITE) {
      this._gridSettings = this._satellite;
    }
    // Draw the major lines and label the cells.
    this._drawLines(this._majorGridSizeDeg, this._gridSettings.majorOpacity);
    this._labelOLCCells();
    this.show();

    // If not displaying the minor grid, or if it is less than 10 pixels height, we are done.
    if (!this._minorGridDisplay || Math.abs(
        this._llToPixels(this.getMap().getCenter().lat(), 0).y -
        this._llToPixels(this.getMap().getCenter().lat() + this._majorGridSizeDeg / 20, 0).y) < 10) {
      return;
    }
    // Draw the minor lines and label the rows and columns.
    this._drawLines(this._majorGridSizeDeg / 20, this._gridSettings.minorOpacity);
    this._labelGridRowsCols();
    this.show();
  };

  // Draw a grid of lines covering the current major grid area. Passed the step size and opacity for the lines.
  OLCGridOverlay.prototype._drawLines = function(stepsize, opacity) {
    // Draw vertical lines.
    for (var lng = this._gridBounds.lngLo; lng < this._gridBounds.lngHi; lng = lng + stepsize) {
      var line = new google.maps.Polyline({
          path: [{lat: this._gridBounds.latLo, lng: lng}, {lat: this._gridBounds.latHi, lng: lng}],
          strokeColor: this._gridSettings.gridColor,
          strokeWeight: 1,
          strokeOpacity: opacity,
          clickable: false,
          map: this.getMap()
      });
      this._gridLines.push(line);
    }
    // Draw horizontal lines.
    for (var lat = this._gridBounds.latLo; lat < this._gridBounds.latHi; lat = lat + stepsize) {
      var line = new google.maps.Polyline({
          // Draw from -180 to 0 to 180 to avoid wrapping problems.
          path: [{lat: lat, lng: -180}, {lat: lat, lng: 0}, {lat: lat, lng: 180}],
          strokeColor: this._gridSettings.gridColor,
          strokeWeight: 1,
          strokeOpacity: opacity,
          clickable: false,
          map: this.getMap()
      });
      this._gridLines.push(line);
    }
  };

  // Add labels for each of the OLC cells. The label will depend on the grid size.
  OLCGridOverlay.prototype._labelOLCCells = function() {
    for (var lat = this._gridBounds.latLo; lat <= this._gridBounds.latHi; lat = lat + this._majorGridSizeDeg) {
      for (var lng = this._gridBounds.lngLo; lng <= this._gridBounds.lngHi; lng = lng + this._majorGridSizeDeg) {
        // Get the OLC code for the center of the grid square. The label depends on the grid resolution.
        var olc = OpenLocationCode.encode(lat + (this._majorGridSizeDeg / 2), lng + (this._majorGridSizeDeg / 2));
        var contents = {}
        if (this._majorGridSizeDeg == 20) {
          contents.mainlabel = olc.substr(0, 2);
        } else if (this._majorGridSizeDeg == 1) {
          contents.mainlabel = olc.substr(0, 4);
        } else if (this._majorGridSizeDeg == .05) {
          contents.mainlabel = olc.substr(4, 2);
          contents.title = olc.substr(0, 4);
        } else {
          contents.mainlabel = olc.substr(4, 5);
          contents.title = olc.substr(0, 4);
        }
        this._makeLabel(
            contents,
            lat,
            lng,
            this._majorGridSizeDeg,
            this._gridSettings.labelClass,
            this._labelFontSizes.cellLabelMinFontPx,
            this._labelFontSizes.cellLabelMaxFontPx);
      }
    }
  };

  // Draw the labels for the grid rows and columns.
  OLCGridOverlay.prototype._labelGridRowsCols = function() {
    var mapbounds = this.getMap().getBounds();
    var row_lo = mapbounds.getSouthWest().lng();
    var row_hi = mapbounds.getNorthEast().lng() - this._majorGridSizeDeg / 20;
    var col_lo = mapbounds.getSouthWest().lat();
    var col_hi = mapbounds.getNorthEast().lat() - this._majorGridSizeDeg / 20;

    // Row labels.
    var step = 0;
    for (var lat = this._gridBounds.latLo; lat <= this._gridBounds.latHi; lat = lat + this._majorGridSizeDeg / 20, step++) {
      // Don't put lat and lng labels in the same place.
      if (Math.abs(lat - col_lo) < (this._majorGridSizeDeg / 20 / 2) ||
          Math.abs(lat - col_hi) < (this._majorGridSizeDeg / 20 / 2)) {
        continue;
      }
      this._labelGrid(this._olcAlphabet[step % 20], lat, row_lo);
      this._labelGrid(this._olcAlphabet[step % 20], lat, row_hi);
    }
    // Column labels.
    step = 0;
    for (var lng = this._gridBounds.lngLo; lng <= this._gridBounds.lngHi; lng = lng + this._majorGridSizeDeg / 20, step++) {
      // Don't put lat and lng labels in the same place.
      if ((Math.abs(lng - row_lo) < (this._majorGridSizeDeg / 20 / 2)) ||
          (Math.abs(lng - row_hi) < (this._majorGridSizeDeg / 20 / 2))) {
        continue;
      }
      this._labelGrid(this._olcAlphabet[step % 20], col_lo, lng);
      this._labelGrid(this._olcAlphabet[step % 20], col_hi, lng);
    }
  };

  // Make an OLC row or column label whose lower left corner is at lat,lng.
  OLCGridOverlay.prototype._labelGrid = function(label, lat, lng) {
    this._makeLabel(
        {mainlabel: label},
        lat,
        lng,
        this._majorGridSizeDeg / 20,
        this._gridSettings.labelClass,
        this._labelFontSizes.gridLabelMinFontPx,
        this._labelFontSizes.gridLabelMaxFontPx);
  };

  // Create a text label as a DIV and add it to the marker layer.
  // The contents are specified as an object with two attributes: title and mainlabel.
  // The title value will be displayed first and smaller. The mainlabel content is displayed
  // second, scaled to fill the width but restricted to between min- and maxfontsize.
  // The DIV will have it's lower left corner at lat,lng with width and height deg degrees.
  OLCGridOverlay.prototype._makeLabel = function(contents, lat, lng, deg, classname, minfontsize, maxfontsize) {
    // Convert the lat and lng to pixels to get the position and dimensions of the div.
    var lo = this._llToPixels(lat, lng);
    var hi = this._llToPixels(lat + deg, lng + deg);
    var height = Math.abs(hi.y - lo.y);
    var width = Math.abs(hi.x - lo.x);
    var left = lo.x;
    var top = lo.y - height;

    var div = document.createElement("DIV");
    div.className = classname;
    div.style.left = left + "px";
    div.style.top = top + "px";
    div.style.width = width + "px";
    div.style.height = height + "px";

    var html = '';
    if (typeof(contents.title) == 'string') {
      var ratio = Math.min(Math.round(contents.mainlabel.length / contents.title.length * 100), 75);
      html += '<span style="font-size: ' + ratio + '%;">' + contents.title + '<br/></span>';
    }

    if (typeof(contents.mainlabel) == 'string') {
      html += '<span>' + contents.mainlabel + '</span>';
    }
    div.innerHTML = html;
    // Set the font size to width in pixels / number of chars in the main part of the label. Limit it
    // between the minimum and maximum font size.
    var fontsize = Math.min(Math.max(width / contents.mainlabel.length, minfontsize), maxfontsize);
    div.style.fontSize = fontsize + "px";
    this._addToMarkerLayer(div);
  };

  // Convert a lat/lng to a pixel reference.
  OLCGridOverlay.prototype._llToPixels = function(lat, lng) {
    return this.getProjection().fromLatLngToDivPixel(new google.maps.LatLng({lat: lat, lng: lng}));
  };

  // Add something to the marker layer - above the polylines (overlayLayer) but below mouse targets (overlayMouseTarget).
  OLCGridOverlay.prototype._addToMarkerLayer = function(div) {
    var panes = this.getPanes();
    panes.markerLayer.appendChild(div);
  };

  // Clear the marker layer.
  OLCGridOverlay.prototype._clearMarkerLayer = function() {
    var panes = this.getPanes();
    while (panes.markerLayer.firstChild) {
      panes.markerLayer.removeChild(panes.markerLayer.firstChild);
    }
  };
  return OLCGridOverlay;
}));
