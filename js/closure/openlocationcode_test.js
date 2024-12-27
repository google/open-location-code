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

const /** @const {string} */ DECODING_TEST_FILE =
    '/filez/_main/test_data/decoding.csv';
const /** @const {string} */ ENCODING_TEST_FILE =
    '/filez/_main/test_data/encoding.csv';
const /** @const {string} */ SHORT_CODE_TEST_FILE =
    '/filez/_main/test_data/shortCodeTests.csv';
const /** @const {string} */ VALIDITY_TEST_FILE =
    '/filez/_main/test_data/validityTests.csv';

// Initialise the async test framework.
const /** @const {!AsyncTestCase} */ asyncTestCase = AsyncTestCase.createAndInstall();

testSuite({
  testDecode: function() {
    const xhrIo_ = new XhrIo();
    xhrIo_.listenOnce(EventType.COMPLETE, () => {
      const lines = xhrIo_.getResponseText().match(/^[^#].+/gm);
      for (var i = 0; i < lines.length; i++) {
        const fields = lines[i].split(',');
        const code = fields[0];
        const length = parseInt(fields[1], 10);
        const latLo = parseFloat(fields[2]);
        const lngLo = parseFloat(fields[3]);
        const latHi = parseFloat(fields[4]);
        const lngHi = parseFloat(fields[5]);

        const gotCodeArea = OpenLocationCode.decode(code);
        // Check that the decode gave the correct coordinates.
        assertRoughlyEquals('testEncode ' + 1, length, gotCodeArea.codeLength, 1e-10);
        assertRoughlyEquals('testEncode ' + 1, latLo, gotCodeArea.latitudeLo, 1e-10);
        assertRoughlyEquals('testEncode ' + 1, lngLo, gotCodeArea.longitudeLo, 1e-10);
        assertRoughlyEquals('testEncode ' + 1, latHi, gotCodeArea.latitudeHi, 1e-10);
        assertRoughlyEquals('testEncode ' + 1, lngHi, gotCodeArea.longitudeHi, 1e-10);

        asyncTestCase.continueTesting();
      }
    });
    asyncTestCase.waitForAsync('Waiting for xhr to respond');
    xhrIo_.send(DECODING_TEST_FILE, 'GET');
  },
  testEncode: function() {
    const xhrIo_ = new XhrIo();
    xhrIo_.listenOnce(EventType.COMPLETE, () => {
      const lines = xhrIo_.getResponseText().match(/^[^#].+/gm);
      for (var i = 0; i < lines.length; i++) {
        const fields = lines[i].split(',');
        const lat = parseFloat(fields[0]);
        const lng = parseFloat(fields[1]);
        const length = parseInt(fields[2], 10);
        const code = fields[3];

        const gotCode = OpenLocationCode.encode(lat, lng, length);
        // Did we get the same code?
        assertEquals('testEncode ' + 1, code, gotCode);

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

        if (testType == 'B' || testType == 'S') {
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
    assertEquals('2CXXXXXX+XX', OpenLocationCode.recoverNearest('XXXXXX+XX', -81.0, 0.0));
    assertEquals('CFX22222+22', OpenLocationCode.recoverNearest('2222+22', 89.6, 0.0));
    assertEquals('CFX22222+22', OpenLocationCode.recoverNearest('2222+22', 89.6, 0.0));
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
  testBenchmarks: function() {
    var input = [];
    for (var i = 0; i < 100000; i++) {
      var lat = Math.random() * 180 - 90;
      var lng = Math.random() * 360 - 180;
      var decimals = Math.floor(Math.random() * 10);
      lat = Math.round(lat * Math.pow(10, decimals)) / Math.pow(10, decimals);
      lng = Math.round(lng * Math.pow(10, decimals)) / Math.pow(10, decimals);
      var length = 2 + Math.round(Math.random() * 13);
      if (length < 10 && length % 2 === 1) {
        length += 1;
      }
      input.push([lat, lng, length, OpenLocationCode.encode(lat, lng, length)]);
    }
    var startMillis = Date.now();
    for (var i = 0; i < input.length; i++) {
      OpenLocationCode.encode(input[i][0], input[i][1], input[i][2]);
    }
    var durationMillis = Date.now() - startMillis;
    console.info(
        'Encoding: ' + input.length + ', total ' + durationMillis * 1000 +
        ' usecs, average duration ' +
        ((durationMillis * 1000) / input.length) + ' usecs');

    startMillis = Date.now();
    for (var i = 0; i < input.length; i++) {
      OpenLocationCode.decode(input[i][3]);
    }
    durationMillis = Date.now() - startMillis;
    console.info(
        'Decoding: ' + input.length + ', total ' + durationMillis * 1000 +
        ' usecs, average duration ' +
        ((durationMillis * 1000) / input.length) + ' usecs');
  },
});
