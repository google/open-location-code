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
using Toybox.Application as App;
using Toybox.Graphics as Gfx;

/**
 * Provides a Drawable object for the background of the datafield.
 * It's used in the layout.
 */
class PlusCodeBackground extends Ui.Drawable {

  hidden var mColor;

  function initialize() {
    var dictionary = {
            :identifier => "Background"
    };

    Drawable.initialize(dictionary);
  }

  function setColor(color) {
    mColor = color;
  }

  function draw(dc) {
    dc.setColor(Gfx.COLOR_TRANSPARENT, mColor);
    dc.clear();
  }
}
