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
      expect(area.latitudeLo).toBeCloseTo(test[2], precision, test[0]);
      expect(area.longitudeLo).toBeCloseTo(test[3], precision, test[0]);
      expect(area.latitudeHi).toBeCloseTo(test[4], precision, test[0]);
      expect(area.longitudeHi).toBeCloseTo(test[5], precision, test[0]);
    }
  });

  it("Validity Tests", function() {
    jasmine.getFixtures().fixturesPath = 'base/';
    var encTests = JSON.parse(jasmine.getFixtures().read("validityTests.json"));
    expect(encTests.length).toBeGreaterThan(1);
    for (var i = 0; i < encTests.length; i++) {
      var test = encTests[i];
      expect(OpenLocationCode.isValid(test[0])).toBe(test[1] === 'true', test[0]);
      expect(OpenLocationCode.isShort(test[0])).toBe(test[2] === 'true', test[0]);
      expect(OpenLocationCode.isFull(test[0])).toBe(test[3] === 'true', test[0]);
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
        expect(shorten).toBe(test[3], test[0]);
      }
      if (test[4] == "B" || test[4] == "R") {
        // Now try expanding the shortened code.
        var expanded = OpenLocationCode.recoverNearest(
            test[3], test[1], test[2]);
        expect(expanded).toBe(test[0]);
      }
    }
  });

  it("Encoding benchmark", function() {
    var input = [];
    for (var i = 0; i < 1000000; i++) {
      var lat = Math.random() * 180 - 90;
      var lng = Math.random() * 360 - 180;
      var decimals = Math.floor(Math.random() * 10);
      lat = Math.round(lat * Math.pow(10, decimals)) / Math.pow(10, decimals);
      lng = Math.round(lng * Math.pow(10, decimals)) / Math.pow(10, decimals);
      var length = 2 + Math.round(Math.random() * 13);
      if (length < 10 && length % 2 === 1) {
       length += 1;
      }
      input.push([lat, lng, length]);
    }
    var start = Date.now();
    for (var i = 0; i < input.length; i++) {
      OpenLocationCode.encode(input[i][0], input[i][1], input[i][2]);
    }
    var duration_millis = Date.now() - start;
    console.info(
        "Encoding: " + input.length + ", average duration " +
        (1000 * duration_millis / input.length) + " usecs");
  });

  it("Decoding benchmark", function() {
    var input = [];
    for (var i = 0; i < 1000000; i++) {
      var lat = Math.random() * 180 - 90;
      var lng = Math.random() * 360 - 180;
      var decimals = Math.floor(Math.random() * 10);
      lat = Math.round(lat * Math.pow(10, decimals)) / Math.pow(10, decimals);
      lng = Math.round(lng * Math.pow(10, decimals)) / Math.pow(10, decimals);
      var length = 2 + Math.round(Math.random() * 13);
      if (length < 10 && length % 2 === 1) {
       length += 1;
      }
      input.push(OpenLocationCode.encode(lat, lng, length));
    }
    var start = Date.now();
    for (var i = 0; i < input.length; i++) {
      OpenLocationCode.decode(input[i]);
    }
    var duration_millis = Date.now() - start;
    console.info(
        "Decoding: " + input.length + ", average duration " +
        (1000 * duration_millis / input.length) + " usecs");
  });
});
