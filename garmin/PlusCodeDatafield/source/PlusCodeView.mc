// Copyright 2017 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

/**
 * Provide the data view.
 */
class PlusCodeView extends Ui.DataField {

  /**
   * Duplicate Position class constants.
   * (Accessing the Position class needs permissions but datafields can't have
   * permissions.)
   */
  const QUALITY_NOT_AVAILABLE = 0;
  const QUALITY_LAST_KNOWN = 1;
  const QUALITY_POOR = 2;
  const QUALITY_USABLE = 3;
  const QUALITY_GOOD = 4;

  // The code for the current location, and the location accuracy.
  hidden var mCode = "";
  hidden var mAccuracy = 0;

  function initialize() {
    DataField.initialize();
  }

  // Positions the text fields. This dynamically selects the font size and
  // positioning depending on the device.
  function onLayout(dc) {
    var testCode = "WWWW+WQ";
    // Set the layout.
    View.setLayout(Rez.Layouts.MainLayout(dc));
    var areaCodeView = View.findDrawableById("areacode");
    var localCodeView = View.findDrawableById("localcode");
    // Get the available width and height.
    var width = dc.getWidth();
    var height = dc.getHeight();
    // Get the height of the fields.
    var areaCodeHeight = dc.getTextDimensions(testCode, Gfx.FONT_TINY)[1];
    var localCodeHeight = areaCodeHeight;
    // Find the largest font we can use to display the local code.
    if (dc.getTextWidthInPixels(testCode, Gfx.FONT_MEDIUM) > width) {
      localCodeView.setFont(Gfx.FONT_SMALL);
    } else if (dc.getTextWidthInPixels(testCode, Gfx.FONT_LARGE) > width) {
      localCodeView.setFont(Gfx.FONT_MEDIUM);
      localCodeHeight = dc.getTextDimensions(testCode, Gfx.FONT_MEDIUM)[1];
    } else {
      localCodeView.setFont(Gfx.FONT_LARGE);
      localCodeHeight = dc.getTextDimensions(testCode, Gfx.FONT_LARGE)[1];
    }
    // How much space do we need for both labels?
    var totalHeight = areaCodeHeight + localCodeHeight + 3;
    // Work out the Y position of each label.
    // NB: Y coordinates give the TOP of the text.
    areaCodeView.locY = height / 2 - totalHeight / 2;
    localCodeView.locY = areaCodeView.locY + areaCodeHeight + 3;
    areaCodeView.locX = width / 2;
    localCodeView.locX = width / 2;

    // If we are on a round watch face, we might be partially obscured and
    // need to adjust the placement of the fields.
    var obscurityFlags = DataField.getObscurityFlags();
    if (obscurityFlags & (OBSCURE_TOP | OBSCURE_BOTTOM) == OBSCURE_TOP) {
      areaCodeView.locY = height - totalHeight;
      localCodeView.locY = height - localCodeHeight - 3;
    } else if (obscurityFlags & (OBSCURE_TOP | OBSCURE_BOTTOM) == OBSCURE_BOTTOM) {
      areaCodeView.locY = 0;
      localCodeView.locY = areaCodeHeight + 3;
    }
    if (obscurityFlags & (OBSCURE_LEFT | OBSCURE_RIGHT) == OBSCURE_LEFT) {
      // Push things over to the right.
      areaCodeView.setJustification(Gfx.TEXT_JUSTIFY_RIGHT);
      localCodeView.setJustification(Gfx.TEXT_JUSTIFY_RIGHT);
      areaCodeView.locX = width - 5;
      localCodeView.locX = width - 5;
    } else if (obscurityFlags & (OBSCURE_LEFT | OBSCURE_RIGHT) == OBSCURE_RIGHT) {
      // Push things over to the left.
      areaCodeView.setJustification(Gfx.TEXT_JUSTIFY_LEFT);
      localCodeView.setJustification(Gfx.TEXT_JUSTIFY_LEFT);
      areaCodeView.locX = 5;
      localCodeView.locX = 5;
    }

    // Adjust if they are out of view.
    if (areaCodeView.locY < 3) {
      areaCodeView.locY = 3;
      localCodeView.locY = areaCodeView.locY + areaCodeHeight + 3;
    }
    // Allow the local code to hang slightly over - this only affects Q and J.
    if (localCodeView.locY + localCodeHeight > height + 2) {
      localCodeView.locY = height - localCodeHeight + 2;
    }
    return true;
  }

  // Compute the code from the location in the activity info object.
  function compute(info) {
    mAccuracy = 0;
    mCode = "";
    if (info has :currentLocation && info.currentLocation != null) {
      mCode = encodeOLC(
        info.currentLocation.toDegrees()[0],
        info.currentLocation.toDegrees()[1]);
    }
    if (info has :currentLocationAccuracy && info.currentLocationAccuracy != null) {
      mAccuracy = info.currentLocationAccuracy;
    }
  }

  // Displays the code.
  function onUpdate(dc) {
    // Set the background color.
    View.findDrawableById("Background").setColor(getBackgroundColor());
    // Get the views.
    var areaCodeView = View.findDrawableById("areacode");
    var localCodeView = View.findDrawableById("localcode");

    // Select the location display color.
    // Black/white means it's good.
    // Light gray is either poor or the last known location.
    if (mAccuracy == QUALITY_LAST_KNOWN || mAccuracy == QUALITY_POOR) {
      areaCodeView.setColor(Gfx.COLOR_LT_GRAY);
      localCodeView.setColor(Gfx.COLOR_LT_GRAY);
    } else if (getBackgroundColor() == Gfx.COLOR_BLACK) {
      areaCodeView.setColor(Gfx.COLOR_WHITE);
      localCodeView.setColor(Gfx.COLOR_WHITE);
    } else {
      areaCodeView.setColor(Gfx.COLOR_BLACK);
      localCodeView.setColor(Gfx.COLOR_BLACK);
    }
    // Display the code if we have one.
    if (mCode.length() == 11 && mAccuracy != QUALITY_NOT_AVAILABLE) {
      areaCodeView.setText(mCode.substring(0, 4));
      localCodeView.setText(mCode.substring(4, 11));
    } else {
      areaCodeView.setText(Rez.Strings.default_label);
      localCodeView.setText(Rez.Strings.default_value);
    }
    // Call parent's onUpdate(dc) to redraw the layout
    View.onUpdate(dc);
  }

  /**
   * From here on we include a basic, encode only, implementation of the
   * Open Location Code library.
   * See https://github.com/google/open-location-code for full implementations.
   */
  const OLC_ALPHABET = "23456789CFGHJMPQRVWX";

  /**
   * Encode the specified latitude and longitude into a 10 digit Plus Code using
   * the Open Location Code algorithm. See
   * https://github.com/google/open-location-code
   */
  function encodeOLC(lat, lng) {
    // Convert coordinates to positive ranges.
    lat = lat + 90d;
    lng = lng + 180d;
    // Starting precision in degrees.
    var precision = 20d;
    // Code starts empty.
    var code = "";
    // Do the pairs.
    for (var i = 0; i < 5; i++) {
      // After four pairs, add a "+" character to the code.
      if (i == 4) {
        code = code + "+";
      }
      // Do latitude.
      var digitValue = Math.floor(lat / precision);
      code = code + OLC_ALPHABET.substring(digitValue, digitValue + 1);
      lat = lat - digitValue * precision;
      // And longitude.
      digitValue = Math.floor(lng / precision);
      code = code + OLC_ALPHABET.substring(digitValue, digitValue + 1);
      lng = lng - digitValue * precision;
      // Reduce precision for next pair.
      precision = precision / 20d;
    }
    return code;
  }
}
