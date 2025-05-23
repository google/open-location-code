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
      if (parts.length != 6) {
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
  public void testEncodeFromDegrees() {
    double allowedErrorRate = 0.05;
    int failedEncodings = 0;
    for (TestData testData : testDataList) {
      String got =
          OpenLocationCode.encode(
              testData.latitudeDegrees, testData.longitudeDegrees, testData.length);
      if (got != testData.code) {
        failedEncodings++;
        System.out.printf(
            "ENCODING DIFFERENCE: encode(%f,%f,%d) got %s, want %s\n",
            testData.latitudeDegrees,
            testData.longitudeDegrees,
            testData.length,
            got,
            testData.code);
      }
    }
    double gotRate = (double) failedEncodings / (double) testDataList.size();
    Assert.assertTrue(
        String.format(
            "Too many encoding errors (actual rate %f, allowed rate %f), see ENCODING DIFFERENCE"
                + " lines",
            gotRate, allowedErrorRate),
        gotRate <= allowedErrorRate);
  }

  @Test
  public void testDegreesToIntegers() {
    for (TestData testData : testDataList) {
      long[] got =
          OpenLocationCode.degreesToIntegers(testData.latitudeDegrees, testData.latitudeDegrees);
      Assert.assertTrue(
          String.format(
              "degreesToIntegers(%f, %f) returned latitude %d, expected %d",
              testData.latitudeDegrees,
              testData.longitudeDegrees,
              got[0],
              testData.latitudeInteger),
          got[0] == testData.latitudeInteger || got[0] == testData.latitudeInteger - 1);
      Assert.assertTrue(
          String.format(
              "degreesToIntegers(%f, %f) returned longitude %d, expected %d",
              testData.latitudeDegrees,
              testData.longitudeDegrees,
              got[1],
              testData.longitudeInteger),
          got[1] == testData.longitudeInteger || got[1] == testData.longitudeInteger - 1);
    }
  }

  @Test
  public void testEncodeFromIntegers() {
    for (TestData testData : testDataList) {
      Assert.assertEquals(
          String.format(
              "Latitude %d, longitude %d and length %d were wrongly encoded.",
              testData.latitudeInteger, testData.longitudeInteger, testData.length),
          testData.code,
          OpenLocationCode.encodeIntegers(
              testData.latitudeInteger, testData.longitudeInteger, testData.length));
    }
  }
}
