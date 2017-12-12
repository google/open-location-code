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

/**
 * @fileoverview Tests for the closure implementation of Open Location Code.
 * This uses the test data from the github project,
 * http://github.com/google/openlocationcode/test_data
 * The test data is duplicated here because using bazel to run the tests doesn't
 * allow synchronous loading of the data files.
 */
goog.module('openlocationcode_test');
goog.setTestOnly('openlocationcode_test');

var OpenLocationCode = goog.require('openlocationcode.OpenLocationCode');
var testSuite = goog.require('goog.testing.testSuite');
goog.require('goog.testing.asserts');

testSuite({
  testEncode: function() {
    // Each test has a code, the lat/lng of the center, lat/lng lo and lat/lng hi.
    var tests = [
      [
        '7FG49Q00+',
        20.375,
        2.775,
        20.35,
        2.75,
        20.4,
        2.8,
      ],
      [
        '7FG49QCJ+2V',
        20.3700625,
        2.7821875,
        20.37,
        2.782125,
        20.370125,
        2.78225,
      ],
      [
        '7FG49QCJ+2VX',
        20.3701125,
        2.782234375,
        20.3701,
        2.78221875,
        20.370125,
        2.78225,
      ],
      [
        '7FG49QCJ+2VXGJ',
        20.3701135,
        2.78223535156,
        20.370113,
        2.782234375,
        20.370114,
        2.78223632813,
      ],
      [
        '8FVC2222+22',
        47.0000625,
        8.0000625,
        47.0,
        8.0,
        47.000125,
        8.000125,
      ],
      [
        '4VCPPQGP+Q9',
        -41.2730625,
        174.7859375,
        -41.273125,
        174.785875,
        -41.273,
        174.786,
      ],
      [
        '62G20000+',
        0.5,
        -179.5,
        0.0,
        -180.0,
        1,
        -179,
      ],
      [
        '22220000+',
        -89.5,
        -179.5,
        -90,
        -180,
        -89,
        -179,
      ],
      [
        '7FG40000+',
        20.5,
        2.5,
        20.0,
        2.0,
        21.0,
        3.0,
      ],
      [
        '22222222+22',
        -89.9999375,
        -179.9999375,
        -90.0,
        -180.0,
        -89.999875,
        -179.999875,
      ],
      [
        '6VGX0000+',
        0.5,
        179.5,
        0,
        179,
        1,
        180,
      ],
      // Special cases over 90 latitude and 180 longitude
      [
        'CFX30000+',
        90,
        1,
        89,
        1,
        90,
        2,
      ],
      [
        'CFX30000+',
        92,
        1,
        89,
        1,
        90,
        2,
      ],
      [
        '62H20000+',
        1,
        180,
        1,
        -180,
        2,
        -179,
      ],
      ['62H30000+', 1, 181, 1, -179, 2, -178],
    ];
    for (var i = 0; i < tests.length; i++) {
      var td = tests[i];
      // Decode the code.
      var ca = OpenLocationCode.decode(td[0]);
      // Encode the center coordinates.
      var code = OpenLocationCode.encode(td[1], td[2], ca.codeLength);
      // Did we get the same code?
      assertEquals('Test ' + 1, td[0], code);
      // Check that the decode gave the correct coordinates.
      assertRoughlyEquals('Test ' + 1, ca.latitudeLo, td[3], 1e-10);
      assertRoughlyEquals('Test ' + 1, ca.longitudeLo, td[4], 1e-10);
      assertRoughlyEquals('Test ' + 1, ca.latitudeHi, td[5], 1e-10);
      assertRoughlyEquals('Test ' + 1, ca.longitudeHi, td[6], 1e-10);
    }
  },
  testShortCodes: function() {
    var tests = [
      // full code, lat, lng, shortcode
      [
        '9C3W9QCJ+2VX',
        51.3701125,
        -1.217765625,
        '+2VX',
      ],
      // Adjust so we can't trim by 8 (+/- .000755)
      [
        '9C3W9QCJ+2VX',
        51.3708675,
        -1.217765625,
        'CJ+2VX',
      ],
      [
        '9C3W9QCJ+2VX',
        51.3693575,
        -1.217765625,
        'CJ+2VX',
      ],
      [
        '9C3W9QCJ+2VX',
        51.3701125,
        -1.218520625,
        'CJ+2VX',
      ],
      [
        '9C3W9QCJ+2VX',
        51.3701125,
        -1.217010625,
        'CJ+2VX',
      ],
      // Adjust so we can't trim by 6 (+/- .0151)
      [
        '9C3W9QCJ+2VX',
        51.3852125,
        -1.217765625,
        '9QCJ+2VX',
      ],
      [
        '9C3W9QCJ+2VX',
        51.3550125,
        -1.217765625,
        '9QCJ+2VX',
      ],
      [
        '9C3W9QCJ+2VX',
        51.3701125,
        -1.232865625,
        '9QCJ+2VX',
      ],
      [
        '9C3W9QCJ+2VX',
        51.3701125,
        -1.202665625,
        '9QCJ+2VX',
      ],
      // Added to detect error in recoverNearest functionality
      [
        '8FJFW222+',
        42.899,
        9.012,
        '22+',
      ],
      [
        '796RXG22+',
        14.95125,
        -23.5001,
        '22+',
      ],
    ];
    for (var i = 0; i < tests.length; i++) {
      var td = tests[i];
      // Shorten the code.
      var short = OpenLocationCode.shorten(td[0], td[1], td[2]);
      assertEquals('Test ' + i, short, td[3]);
      var recovered = OpenLocationCode.recoverNearest(short, td[1], td[2]);
      assertEquals('Test ' + i, recovered, td[0]);
    }
  },
  testRecoveryNearPoles: function() {
    assertEquals("2CXXXXXX+XX", OpenLocationCode.recoverNearest("XXXXXX+XX", -81.0, 0.0));
    assertEquals("CFX22222+22", OpenLocationCode.recoverNearest("2222+22", 89.6, 0.0));
  },
  testValidity: function() {
    var tests = [
      //   code,isValid,isShort,isFull
      // Valid full codes:
      [
        '8FWC2345+G6',
        true,
        false,
        true,
      ],
      [
        '8FWC2345+G6G',
        true,
        false,
        true,
      ],
      [
        '8fwc2345+',
        true,
        false,
        true,
      ],
      [
        '8FWCX400+',
        true,
        false,
        true,
      ],
      // Valid short codes:
      [
        'WC2345+G6g',
        true,
        true,
        false,
      ],
      [
        '2345+G6',
        true,
        true,
        false,
      ],
      [
        '45+G6',
        true,
        true,
        false,
      ],
      [
        '+G6',
        true,
        true,
        false,
      ],
      // Invalid codes
      [
        'G+',
        false,
        false,
        false,
      ],
      [
        '+',
        false,
        false,
        false,
      ],
      [
        '8FWC2345+G',
        false,
        false,
        false,
      ],
      [
        '8FWC2_45+G6',
        false,
        false,
        false,
      ],
      [
        '8FWC2η45+G6',
        false,
        false,
        false,
      ],
      [
        '8FWC2345+G6+',
        false,
        false,
        false,
      ],
      [
        '8FWC2300+G6',
        false,
        false,
        false,
      ],
      [
        'WC2300+G6g',
        false,
        false,
        false,
      ],
      [
        'WC2345+G',
        false,
        false,
        false,
      ],
    ];
    for (var i = 0; i < tests.length; i++) {
      var td = tests[i];
      assertEquals('Test ' + i, OpenLocationCode.isValid(td[0]), td[1]);
      assertEquals('Test ' + i, OpenLocationCode.isShort(td[0]), td[2]);
      assertEquals('Test ' + i, OpenLocationCode.isFull(td[0]), td[3]);
    }
  },
});
