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

void checkEncode(String csvLine) {
  var elements = csvLine.split(',');
  num lat = double.parse(elements[0]);
  num lng = double.parse(elements[1]);
  int lat_int = int.parse(elements[2]);
  int lng_int = int.parse(elements[3]);
  int len = int.parse(elements[4]);
  var want = elements[5];
  var got = olc.encode(lat, lng, codeLength: len);
  expect(got, equals(want));
}

void checkLocationToIntegers(String csvLine) {
  var elements = csvLine.split(',');
  num lat = double.parse(elements[0]);
  num lng = double.parse(elements[1]);
  int lat_int = int.parse(elements[2]);
  int lng_int = int.parse(elements[3]);
  var got = olc.locationToIntegers(lat, lng);
  expect(got[0], equals(lat_int));
  expect(got[1], equals(lng_int));
}

void checkEncodeIntegers(String csvLine) {
  var elements = csvLine.split(',');
  int lat_int = int.parse(elements[2]);
  int lng_int = int.parse(elements[3]);
  int len = int.parse(elements[4]);
  var want = elements[5];
  var got = olc.encodeIntegers(lat_int, lng_int, len);
  expect(got, equals(want));
}

void main() {
  test('Check encode', () {
    csvLinesFromFile('encoding.csv').forEach(checkEncode);
  });
  test('Check locationToIntegers', () {
    csvLinesFromFile('encoding.csv').forEach(checkLocationToIntegers);
  });
  test('Check encodeIntegers', () {
    csvLinesFromFile('encoding.csv').forEach(checkEncodeIntegers);
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
