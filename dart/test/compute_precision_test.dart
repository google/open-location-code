import 'package:open_location_code/open_location_code.dart' as olc;
import 'package:test/test.dart';

void main() {
  test('Compute precision test', () {
    expect(olc.computeLatitudePrecision(10), 0.000125);
    expect(olc.computeLatitudePrecision(11), 0.000025);
  });
}
