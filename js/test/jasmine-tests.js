


describe("Open Location Code", function() {
  var precision = 1e-10;

  it("Encoding Tests", function() {
    jasmine.getFixtures().fixturesPath = 'base/';
    var encTests = JSON.parse(jasmine.getFixtures().read("encoding.json"));
    expect(encTests.length).toBeGreaterThan(1);
    for (var i = 0; i < encTests.length; i++) {
      var test = encTests[i];
      var code = OpenLocationCode.encode(test[0], test[1], test[2]);
      // Did we get the same code?
      expect(code).toBe(test[3]);
    }
  });

  it("Decoding Tests", function() {
    jasmine.getFixtures().fixturesPath = 'base/';
    var encTests = JSON.parse(jasmine.getFixtures().read("decoding.json"));
    expect(encTests.length).toBeGreaterThan(1);
    for (var i = 0; i < encTests.length; i++) {
      var test = encTests[i];
      var area = OpenLocationCode.decode(test[0]);
      // Did we get the same values?
      expect(area.codeLength).toBe(test[1]);
      expect(area.latitudeLo).toBeCloseTo(test[2], precision);
      expect(area.longitudeLo).toBeCloseTo(test[3], precision);
      expect(area.latitudeHi).toBeCloseTo(test[4], precision);
      expect(area.longitudeHi).toBeCloseTo(test[5], precision);
    }
  });

  it("Validity Tests", function() {
    jasmine.getFixtures().fixturesPath = 'base/';
    var encTests = JSON.parse(jasmine.getFixtures().read("validityTests.json"));
    expect(encTests.length).toBeGreaterThan(1);
    for (var i = 0; i < encTests.length; i++) {
      var test = encTests[i];
      expect(OpenLocationCode.isValid(test[0])).toBe(test[1] === 'true');
      expect(OpenLocationCode.isShort(test[0])).toBe(test[2] === 'true');
      expect(OpenLocationCode.isFull(test[0])).toBe(test[3] === 'true');
    }
  });

  it("Short Code Tests", function() {
    jasmine.getFixtures().fixturesPath = 'base/';
    var encTests = JSON.parse(jasmine.getFixtures().read("shortCodeTests.json"));
    expect(encTests.length).toBeGreaterThan(1);
    for (var i = 0; i < encTests.length; i++) {
      var test = encTests[i];
      if (test[4] == "B" || test[4] == "S") {
        // Shorten the full length code.
        var shorten = OpenLocationCode.shorten(
            test[0], test[1], test[2]);
        // Confirm we got what we expected.
        expect(shorten).toBe(test[3]);
      }
      if (test[4] == "B" || test[4] == "R") {
        // Now try expanding the shortened code.
        var expanded = OpenLocationCode.recoverNearest(
            test[3], test[1], test[2]);
        expect(expanded).toBe(test[0]);
      }
    }
  });
});
