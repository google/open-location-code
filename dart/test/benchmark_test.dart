import 'package:open_location_code/open_location_code.dart' as olc;
import 'package:test/test.dart';
import 'dart:math';

void main() {
  test('Benchmarking encode and decode', () {
    var now = DateTime.now();
    var random = Random(now.millisecondsSinceEpoch);
    var testData = [];
    for (var i = 0; i < 1000000; i++) {
      var lat = random.nextDouble() * 180 - 90;
      var lng = random.nextDouble() * 360 - 180;
      var exp = pow(10, (random.nextDouble() * 10).toInt());
      lat = (lat * exp).round() / exp;
      lng = (lng * exp).round() / exp;
      var length = 2 + (random.nextDouble() * 13).round();
      if (length < 10 && length % 2 == 1) {
        length += 1;
      }
      var code = olc.encode(lat, lng, codeLength: length);
      olc.decode(code);
      testData.add([lat, lng, length, code]);
    }
    var stopwatch = Stopwatch()..start();
    for (var i = 0; i < testData.length; i++) {
      olc.encode(testData[i][0], testData[i][1], codeLength: testData[i][2]);
    }
    var duration = stopwatch.elapsedMicroseconds;
    print('Encoding benchmark ${testData.length}, duration ${duration} usec, '
        'average ${duration / testData.length} usec');

    stopwatch = Stopwatch()..start();
    for (var i = 0; i < testData.length; i++) {
      olc.decode(testData[i][3]);
    }
    duration = stopwatch.elapsedMicroseconds;
    print('Decoding benchmark ${testData.length}, duration ${duration} usec, '
        'average ${duration / testData.length} usec');
  });
}
