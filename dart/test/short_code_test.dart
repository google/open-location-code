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

// full code,lat,lng,shortcode
void checkShortCode(String csvLine) {
  var elements = csvLine.split(',');
  var code = elements[0];
  num lat = double.parse(elements[1]);
  num lng = double.parse(elements[2]);
  var shortCode = elements[3];
  var testType = elements[4];
  if (testType == 'B' || testType == 'S') {
    var short = olc.shorten(code, lat, lng);
    expect(short, equals(shortCode));
  }
  if (testType == 'B' || testType == 'R') {
    var expanded = olc.recoverNearest(shortCode, lat, lng);
    expect(expanded, equals(code));
  }
}

void main() {
  test('Check short codes', () {
    csvLinesFromFile('shortCodeTests.csv').forEach(checkShortCode);
  });
}
