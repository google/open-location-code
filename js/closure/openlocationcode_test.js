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
 */
goog.module('openlocationcode_test');
goog.setTestOnly('openlocationcode_test');

const AsyncTestCase = goog.require('goog.testing.AsyncTestCase');
const EventType = goog.require('goog.net.EventType');
const OpenLocationCode = goog.require('openlocationcode.OpenLocationCode');
const XhrIo = goog.require('goog.net.XhrIo');
const testSuite = goog.require('goog.testing.testSuite');
goog.require('goog.testing.asserts');

const /** @const {string} */ ENCODING_TEST_FILE =
    '/filez/openlocationcode/test_data/encodingTests.csv';
const /** @const {string} */ SHORT_CODE_TEST_FILE =
    '/filez/openlocationcode/test_data/shortCodeTests.csv';
const /** @const {string} */ VALIDITY_TEST_FILE =
    '/filez/openlocationcode/test_data/validityTests.csv';

// Initialise the async test framework.
const /** @const {!AsyncTestCase} */ asyncTestCase = AsyncTestCase.createAndInstall();

testSuite({
  testEncode: function() {
    const xhrIo_ = new XhrIo();
    xhrIo_.listenOnce(EventType.COMPLETE, () => {
      const lines = xhrIo_.getResponseText().match(/^[^#].+/gm);
      for (var i = 0; i < lines.length; i++) {
        const fields = lines[i].split(',');
        const code = fields[0];
        const lat = parseFloat(fields[1]);
        const lng = parseFloat(fields[2]);
        const latLo = parseFloat(fields[3]);
        const lngLo = parseFloat(fields[4]);
        const latHi = parseFloat(fields[5]);
        const lngHi = parseFloat(fields[6]);

        const gotCodeArea = OpenLocationCode.decode(code);
        // Encode the center coordinates.
        const gotCode = OpenLocationCode.encode(lat, lng, gotCodeArea.codeLength);
        // Did we get the same code?
        assertEquals('testEncode ' + 1, code, gotCode);
        // Check that the decode gave the correct coordinates.
        assertRoughlyEquals('testEncode ' + 1, latLo, gotCodeArea.latitudeLo, 1e-10);
        assertRoughlyEquals('testEncode ' + 1, lngLo, gotCodeArea.longitudeLo, 1e-10);
        assertRoughlyEquals('testEncode ' + 1, latHi, gotCodeArea.latitudeHi, 1e-10);
        assertRoughlyEquals('testEncode ' + 1, lngHi, gotCodeArea.longitudeHi, 1e-10);

        asyncTestCase.continueTesting();
      }
    });
    asyncTestCase.waitForAsync('Waiting for xhr to respond');
    xhrIo_.send(ENCODING_TEST_FILE, 'GET');
  },
  testShortCodes: function() {
    const xhrIo_ = new XhrIo();
    asyncTestCase.waitForAsync('Waiting for xhr to respond');
    xhrIo_.listenOnce(EventType.COMPLETE, () => {
      const lines = xhrIo_.getResponseText().match(/^[^#].+/gm);
      for (var i = 0; i < lines.length; i++) {
        const fields = lines[i].split(',');
        const code = fields[0];
        const lat = parseFloat(fields[1]);
        const lng = parseFloat(fields[2]);
        const shortCode = fields[3];
        const testType = fields[4];

        if (testType == "B" || testType == "S") {
          const gotShort = OpenLocationCode.shorten(code, lat, lng);
          assertEquals('testShortCodes ' + i, shortCode, gotShort);
        }
        if (testType == 'B' || testType == 'R') {
          const gotCode = OpenLocationCode.recoverNearest(shortCode, lat, lng);
          assertEquals('testShortCodes ' + i, code, gotCode);
        }

        asyncTestCase.continueTesting();
      }
    });
    xhrIo_.send(SHORT_CODE_TEST_FILE, 'GET');
  },
  testRecoveryNearPoles: function() {
    assertEquals("2CXXXXXX+XX", OpenLocationCode.recoverNearest("XXXXXX+XX", -81.0, 0.0));
    assertEquals("CFX22222+22", OpenLocationCode.recoverNearest("2222+22", 89.6, 0.0));
    assertEquals("CFX22222+22", OpenLocationCode.recoverNearest("2222+22", 89.6, 0.0));
  },
  testValidity: function() {
    const xhrIo_ = new XhrIo();
    xhrIo_.listenOnce(EventType.COMPLETE, () => {
      const lines = xhrIo_.getResponseText().match(/^[^#].+/gm);
      for (var i = 0; i < lines.length; i++) {
        const fields = lines[i].split(',');
        const code = fields[0];
        const isValid = fields[1] == 'true';
        const isShort = fields[2] == 'true';
        const isFull = fields[3] == 'true';

        assertEquals('testValidity ' + i, isValid, OpenLocationCode.isValid(code));
        assertEquals('testValidity ' + i, isShort, OpenLocationCode.isShort(code));
        assertEquals('testValidity ' + i, isFull, OpenLocationCode.isFull(code));

        asyncTestCase.continueTesting();
      }
    });
    asyncTestCase.waitForAsync('Waiting for xhr to respond');
    xhrIo_.send(VALIDITY_TEST_FILE, 'GET');
  },
});
