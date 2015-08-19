// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library dart.test;

import 'package:dart/olc.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

// code,isValid,isShort,isFull
bool checkValidity(OpenLocationCode olc, String csvLine) {
  List<String> elements = csvLine.split(",");
  String code = elements[0];
  bool isValid = elements[1] == 'true';
  bool isShort = elements[2] == 'true';
  bool isFull = elements[3] == 'true';
  bool isValidOlc = olc.isValid(code);
  bool isShortOlc = olc.isShort(code);
  bool isFullOlc = olc.isFull(code);
  return isFull == isFullOlc && isShortOlc == isShort && isValidOlc == isValid;
}

// code,lat,lng,latLo,lngLo,latHi,lngHi
checkEncodeDecode(OpenLocationCode olc, String csvLine) {
  List<String> elements = csvLine.split(",");
  String code = elements[0];
  num lat = double.parse(elements[1]);
  num lng = double.parse(elements[2]);
  num latLo = double.parse(elements[3]);
  num lngLo = double.parse(elements[4]);
  num latHi = double.parse(elements[5]);
  num lngHi = double.parse(elements[6]);
  CodeArea codeArea = olc.decode(code);
  String codeOlc = olc.encode(lat, lng, codeLength: codeArea.codeLength);
  expect(code, equals(codeOlc));
  expect(codeArea.latitudeLo, closeTo(latLo, 0.001));
  expect(codeArea.latitudeHi, closeTo(latHi, 0.001));
  expect(codeArea.longitudeLo, closeTo(lngLo, 0.001));
  expect(codeArea.longitudeHi, closeTo(lngHi, 0.001));
}

// full code,lat,lng,shortcode
checkShortCode(OpenLocationCode olc, String csvLine) {
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

main(List<String> args) {
  // Requires test csv files in a test_data directory under open location code project root.
  Directory projectRoot =
      new Directory.fromUri(Platform.script).parent.parent.parent;
  String testDataPath = path.absolute(projectRoot.path, 'test_data');
  print("Test data path: $testDataPath");

  group('Open location code tests', () {
    OpenLocationCode olc;

    setUp(() {
      olc = new OpenLocationCode();
    });

    test('Clip latitude test', () {
      expect(olc.clipLatitude(100.0), 90.0);
      expect(olc.clipLatitude(-100.0), -90.0);
      expect(olc.clipLatitude(10.0), 10.0);
      expect(olc.clipLatitude(-10.0), -10.0);
    });

    test('Check Validity', () {
      for (String line in getCsvLines(path.absolute(testDataPath, 'validityTests.csv'))) {
        expect(checkValidity(olc, line), true);
      }
    });

    test('Check encode decode', () {
      List<String> encodeLines =
          getCsvLines(path.absolute(testDataPath, 'encodingTests.csv'));
      for (String line in encodeLines) {
        checkEncodeDecode(olc, line);
      }
    });

    test('Check short codes', () {
      List<String> shortCodeLines =
          getCsvLines(path.absolute(testDataPath, 'shortCodeTests.csv'));
      for (String line in shortCodeLines) {
        checkShortCode(olc, line);
      }
    });
  });
}
