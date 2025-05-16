package com.google.openlocationcode;

import static java.nio.charset.StandardCharsets.UTF_8;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.JUnit4;

/** Tests encoding and decoding between Open Location Code and latitude/longitude pair. */
@RunWith(JUnit4.class)
public class EncodingTest {

  public static final double PRECISION = 1e-10;

  private static class TestData {

    private final double latitudeDegrees;
    private final double longitudeDegrees;
    private final long latitudeInteger;
    private final long longitudeInteger;
    private final int length;
    private final String code;

    public TestData(String line) {
      String[] parts = line.split(",");
      if (parts.length != 4) {
        throw new IllegalArgumentException("Wrong format of testing data.");
      }
      this.latitudeDegrees = Double.parseDouble(parts[0]);
      this.longitudeDegrees = Double.parseDouble(parts[1]);
      this.latitudeInteger = Long.parseLong(parts[2]);
      this.longitudeInteger = Long.parseLong(parts[3]);
      this.length = Integer.parseInt(parts[4]);
      this.code = parts[5];
    }
  }

  private final List<TestData> testDataList = new ArrayList<>();

  @Before
  public void setUp() throws Exception {
    InputStream testDataStream = new FileInputStream(TestUtils.getTestFile("encoding.csv"));
    BufferedReader reader = new BufferedReader(new InputStreamReader(testDataStream, UTF_8));
    String line;
    while ((line = reader.readLine()) != null) {
      if (line.startsWith("#") || line.length() == 0) {
        continue;
      }
      testDataList.add(new TestData(line));
    }
  }

  @Test
  public void testEncodeFromLatLong() {
    for (TestData testData : testDataList) {
      Assert.assertEquals(
          String.format(
              "Latitude %f, longitude %f and length %d were wrongly encoded.",
              testData.latitudeDegrees, testData.longitudeDegrees, testData.length),
          testData.code,
          OpenLocationCode.encode(testData.latitudeDegrees, testData.longitudeDegrees, testData.length));
    }
  }

  @Test
  public void testDegreesToIntegers() {
    for (TestData testData : testDataList) {
      long[] got = OpenLocationCode.degreesToIntegers(testData.latitudeDegrees, testData.longitudeDegrees);
      Assert.assertEquals(
          String.format("Latitude %f integer conversion is incorrect", testData.latitudeDegrees),
          testData.latitudeInteger,
          got[0]);
      Assert.assertEquals(
          String.format("Longitude %f integer conversion is incorrect", testData.longitudeDegrees),
          testData.longitudeInteger,
          got[1]);
    }
  }

  @Test
  public void testEncodeIntegers() {
    for (TestData testData : testDataList) {
      Assert.assertEquals(
          String.format(
              "Latitude %d, longitude %d and length %d were wrongly encoded.",
              testData.latitudeInteger, testData.longitudeInteger, testData.length),
          testData.code,
          OpenLocationCode.encodeIntegers(testData.latitudeInteger, testData.longitudeInteger, testData.length));
    }
  }
}
