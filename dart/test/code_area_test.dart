import 'package:open_location_code/open_location_code.dart' as olc;
import 'package:test/test.dart';

main() {
  test('Creating CodeArea', () {
    var a = olc.CodeArea(
        20.349999999999994, 2.75, 20.39999999999999, 2.8000000000000114, 6);
    expect(a.toString(),
        'CodeArea(south:20.349999999999994, west:2.75, north:20.39999999999999, east:2.8000000000000114, codelen: 6)');
    expect(
        a.center.toString(), 'LatLng(20.374999999999993, 2.7750000000000057)');

    var b = olc.CodeArea(
        -41.273125, 174.78587500000003, -41.273, 174.78600000000006, 12);
    expect(b.toString(),
        'CodeArea(south:-41.273125, west:174.78587500000003, north:-41.273, east:174.78600000000006, codelen: 12)');
    expect(b.center.toString(), 'LatLng(-41.2730625, 174.78593750000005)');
  });
}
