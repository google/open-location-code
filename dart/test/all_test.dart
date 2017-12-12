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
import 'package:path/path.dart' as path;
import 'dart:io';

// code,isValid,isShort,isFull
void checkValidity(String csvLine) {
  List<String> elements = csvLine.split(",");
  String code = elements[0];
  bool isValid = elements[1] == 'true';
  bool isShort = elements[2] == 'true';
  bool isFull = elements[3] == 'true';
  expect(olc.isValid(code), equals(isValid));
  expect(olc.isShort(code), equals(isShort));
  expect(olc.isFull(code), equals(isFull));
}

// code,lat,lng,latLo,lngLo,latHi,lngHi
checkEncodeDecode(String csvLine) {
  List<String> elements = csvLine.split(",");
  String code = elements[0];
  num lat = double.parse(elements[1]);
  num lng = double.parse(elements[2]);
  num latLo = double.parse(elements[3]);
  num lngLo = double.parse(elements[4]);
  num latHi = double.parse(elements[5]);
  num lngHi = double.parse(elements[6]);
  olc.CodeArea codeArea = olc.decode(code);
  String codeOlc = olc.encode(lat, lng, codeLength: codeArea.codeLength);
  expect(code, equals(codeOlc));
  expect(codeArea.south, closeTo(latLo, 0.001));
  expect(codeArea.north, closeTo(latHi, 0.001));
  expect(codeArea.west, closeTo(lngLo, 0.001));
  expect(codeArea.east, closeTo(lngHi, 0.001));
}

// full code,lat,lng,shortcode
checkShortCode(String csvLine) {
  List<String> elements = csvLine.split(",");
  String code = elements[0];
  num lat = double.parse(elements[1]);
  num lng = double.parse(elements[2]);
  String shortCode = elements[3];
  String testType = elements[4];
  if (testType == "B" || testType == "S") {
    String short = olc.shorten(code, lat, lng);
    expect(short, equals(shortCode));
  }
  if (testType == "B" || testType == "R") {
    String expanded = olc.recoverNearest(shortCode, lat, lng);
    expect(expanded, equals(code));
  }
}

List<String> getCsvLines(String fileName) {
  return new File(fileName)
      .readAsLinesSync()
      .where((x) => !x.isEmpty && !x.startsWith('#'))
      .map((x) => x.trim())
      .toList();
}

main() {
  // Requires test csv files in a test_data directory under open location code project root.
  Directory projectRoot = Directory.current.parent;
  String testDataPath = path.absolute(projectRoot.path, 'test_data');
  print("Test data path: $testDataPath");

  group('Open location code tests', () {
    test('Clip latitude test', () {
      expect(olc.clipLatitude(100.0), 90.0);
      expect(olc.clipLatitude(-100.0), -90.0);
      expect(olc.clipLatitude(10.0), 10.0);
      expect(olc.clipLatitude(-10.0), -10.0);
    });

    test('Check Validity', () {
      var lines = getCsvLines(path.absolute(testDataPath, 'validityTests.csv'));
      for (String line in lines) {
        checkValidity(line);
      }
    });

    test('Check encode decode', () {
      var lines = getCsvLines(path.absolute(testDataPath, 'encodingTests.csv'));
      for (String line in lines) {
        checkEncodeDecode(line);
      }
    });

    test('Check short codes', () {
      var lines =
          getCsvLines(path.absolute(testDataPath, 'shortCodeTests.csv'));
      for (String line in lines) {
        checkShortCode(line);
      }
    });
  });
}
