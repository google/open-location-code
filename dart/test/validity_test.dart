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

// code,isValid,isShort,isFull
void checkValidity(String csvLine) {
  var elements = csvLine.split(',');
  var code = elements[0];
  var isValid = elements[1] == 'true';
  var isShort = elements[2] == 'true';
  var isFull = elements[3] == 'true';
  expect(olc.isValid(code), equals(isValid));
  expect(olc.isShort(code), equals(isShort));
  expect(olc.isFull(code), equals(isFull));
}

void main() {
  test('Check Validity', () {
    csvLinesFromFile('validityTests.csv').forEach(checkValidity);
  });
}
