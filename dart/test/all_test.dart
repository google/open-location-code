// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

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
  String short = olc.shorten(code, lat, lng);
  expect(short, equals(shortCode));
  String expanded = olc.recoverNearest(short, lat, lng);
  expect(expanded, equals(code));
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
