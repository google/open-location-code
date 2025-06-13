describe("Open Location Code", function() {
  var precision = 1e-10;

  jasmine.getFixtures().fixturesPath = "base/";

  const encodingTests = JSON.parse(jasmine.getFixtures().read("encoding.json"));
  it("has encoding tests", function() {
    expect(encodingTests.length).toBeGreaterThan(1);
  });

  const decodingTests = JSON.parse(jasmine.getFixtures().read("decoding.json"));
  it("has decoding tests", function() {
    expect(decodingTests.length).toBeGreaterThan(1);
  });

  const validityTests = JSON.parse(jasmine.getFixtures().read("validityTests.json"));
  it("has validity tests", function() {
    expect(validityTests.length).toBeGreaterThan(1);
  });

  const shortenTests = JSON.parse(jasmine.getFixtures().read("shortCodeTests.json"));
  it("has shorten tests", function() {
    expect(shortenTests.length).toBeGreaterThan(1);
  });

  describe("locationToIntegers Tests", function() {
    for (let i = 0; i < encodingTests.length; i++) {
      const test = encodingTests[i];
      const lat = test[0];
      const lng = test[1];
      const wantLat = test[2];
      const wantLng = test[3];
      const got = OpenLocationCode.locationToIntegers(lat, lng);
      // Due to floating point precision limitations, we may get values 1 less
      // than expected.
      it("converting latitude " + lat + " to integer, want " + wantLat + ", got " + got[0], function() {
        expect(got[0] == wantLat || got[0] == wantLat - 1).toBe(true);
      });
      it("converting longitude " + lng + " to integer, want " + wantLng + ", got " + got[1], function() {
        expect(got[1] == wantLng || got[1] == wantLng - 1).toBe(true);
      });
    }
  });

  describe("encode (degrees) Tests", function() {
    // Allow a 5% error rate encoding from degree coordinates (because of floating
    // point precision).
    const allowedErrorRate = 0.05;
    let errors = 0;
    for (let i = 0; i < encodingTests.length; i++) {
      const test = encodingTests[i];
      const lat = test[0];
      const lng = test[1];
      const codeLength = test[4];
      const want = test[5];
      const got = OpenLocationCode.encode(lat, lng, codeLength);
      if (got !== want) {
        console.log('ENCODING DIFFERENCE: Expected code ' + want +', got ' + got);
        errors ++;
      }
    }
    it("Encoding degrees error rate too high", function() {
      expect(errors / encodingTests.length).toBeLessThan(allowedErrorRate);
    });
  });

  describe("encodeIntegers Tests", function() {
    for (let i = 0; i < encodingTests.length; i++) {
      const test = encodingTests[i];
      const lat = test[2];
      const lng = test[3];
      const codeLength = test[4];
      const want = test[5];
      it("Encoding integers " + lat + "," + lng + " with length " + codeLength, function() {
        const got = OpenLocationCode.encodeIntegers(lat, lng, codeLength);
        expect(got).toBe(want);
      });
    }
  });

  describe("Decoding Tests", function() {
    for (let i = 0; i < decodingTests.length; i++) {
      const test = decodingTests[i];
      const area = OpenLocationCode.decode(test[0]);
      it("Decoding code " + test[0] + ", checking codelength", function() {
        expect(area.codeLength).toBe(test[1]);
      })
      it("Decoding code " + test[0] + ", checking latitudeLo", function() {
        expect(area.latitudeLo).toBeCloseTo(test[2], precision, test[0]);
      })
      it("Decoding code " + test[0] + ", checking longitudeLo", function() {
        expect(area.longitudeLo).toBeCloseTo(test[3], precision, test[0]);
      })
      it("Decoding code " + test[0] + ", checking latitudeHi", function() {
        expect(area.latitudeHi).toBeCloseTo(test[4], precision, test[0]);
      })
      it("Decoding code " + test[0] + ", checking longitudeHi", function() {
        expect(area.longitudeHi).toBeCloseTo(test[5], precision, test[0]);
      })
    }
  });

  describe("Validity Tests", function() {
    for (let i = 0; i < validityTests.length; i++) {
      const test = validityTests[i];
      it("isValid(" + test[0] + ")", function() {
        expect(OpenLocationCode.isValid(test[0])).toBe(test[1] === "true", test[0]);
      });
      it("isShort(" + test[0] + ")", function() {
        expect(OpenLocationCode.isShort(test[0])).toBe(test[2] === "true", test[0]);
      });
      it("isFull(" + test[0] + ")", function() {
        expect(OpenLocationCode.isFull(test[0])).toBe(test[3] === "true", test[0]);
      });
    }
  });

  describe("Short Code Tests", function() {
    for (let i = 0; i < shortenTests.length; i++) {
      const test = shortenTests[i];
      if (test[4] == "B" || test[4] == "S") {
        // Shorten the full length code.
        it("shorten(" + test[0] + ", " + test[1] + ", " + test[2], function() {
          const got = OpenLocationCode.shorten(test[0], test[1], test[2]);
          expect(got).toBe(test[3], test[0]);
        });
      }
      if (test[4] == "B" || test[4] == "R") {
        // Now try expanding the shortened code.
        it("recoverNearest(" + test[3] + ", " + test[1] + ", " + test[2], function() {
          const got = OpenLocationCode.recoverNearest(test[3], test[1], test[2]);
          expect(got).toBe(test[0]);
        });
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
