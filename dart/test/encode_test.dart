/*
 Copyright 2015 Google Inc. All rights reserved.

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

import 'package:open_location_code/open_location_code.dart' as olc;
import 'package:test/test.dart';
import 'utils.dart';

// code,lat,lng,latLo,lngLo,latHi,lngHi
void checkEncodeDegrees(String csvLine) {
  var elements = csvLine.split(',');
  num lat = double.parse(elements[0]);
  num lng = double.parse(elements[1]);
  int len = int.parse(elements[4]);
  var want = elements[5];
  var got = olc.encode(lat, lng, codeLength: len);
  expect(got, equals(want));
}

void checkEncodeIntegers(String csvLine) {
  var elements = csvLine.split(',');
  int lat = int.parse(elements[2]);
  int lng = int.parse(elements[3]);
  int len = int.parse(elements[4]);
  var want = elements[5];
  var got = olc.encodeIntegers(lat, lng, len);
  expect(got, equals(want));
}

void checkLocationToIntegers(String csvLine) {
  var elements = csvLine.split(',');
  num latDegrees = double.parse(elements[0]);
  num lngDegrees = double.parse(elements[1]);
  int latInteger = int.parse(elements[2]);
  int lngInteger = int.parse(elements[3]);
  var got = olc.locationToIntegers(latDegrees, lngDegrees);
  // Due to floating point precision limitations, we may get values 1 less than expected.
  expect(got[0], lessThanOrEqualTo(latInteger));
  expect(got[0] + 1, greaterThanOrEqualTo(latInteger));
  expect(got[1], lessThanOrEqualTo(lngInteger));
  expect(got[1] + 1, greaterThanOrEqualTo(lngInteger));
}

void main() {
  // Encoding from degrees permits a small percentage of errors.
  // This is due to floating point precision limitations.
  test('Check encode from degrees', () {
    // The proportion of tests that we will accept generating a different code.
    // This should not be significantly different from any other implementation.
    num allowedErrRate = 0.05;
    int errors = 0;
    int tests = 0;
    csvLinesFromFile('encoding.csv').forEach((csvLine) {
      tests++;
      var elements = csvLine.split(',');
      num lat = double.parse(elements[0]);
      num lng = double.parse(elements[1]);
      int len = int.parse(elements[4]);
      var want = elements[5];
      var got = olc.encode(lat, lng, codeLength: len);
      if (got != want) {
        print("ENCODING DIFFERENCE: Got '$got', expected '$want'");
        errors++;
      }
    });
    expect(errors / tests, lessThanOrEqualTo(allowedErrRate));
  });

  test('Check encode from integers', () {
    csvLinesFromFile('encoding.csv').forEach(checkEncodeIntegers);
  });

  test('Check conversion of degrees to integers', () {
    csvLinesFromFile('encoding.csv').forEach(checkLocationToIntegers);
  });

  test('MaxCodeLength', () {
    // Check that we do not return a code longer than is valid.
    var code = olc.encode(51.3701125, -10.202665625, codeLength: 1000000);
    var area = olc.decode(code);
    expect(code.length, 16);
    expect(area.codeLength, 15);
    expect(olc.isValid(code), true);

    // Extend the code with a valid character and make sure it is still valid.
    var tooLongCode = code + 'W';
    expect(olc.isValid(tooLongCode), true);

    // Extend the code with an invalid character and make sure it is invalid.
    tooLongCode = code + 'U';
    expect(olc.isValid(tooLongCode), false);
  });
}
