package com.google.openlocationcode.tests;

import static java.nio.charset.StandardCharsets.UTF_8;

import com.google.openlocationcode.OpenLocationCode;

import java.io.BufferedReader;
import java.io.File;
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

    private final String code;
    private final double latitude;
    private final double longitude;
    private final double decodedLatitudeLo;
    private final double decodedLatitudeHi;
    private final double decodedLongitudeLo;
    private final double decodedLongitudeHi;

    public TestData(String line) {
      String[] parts = line.split(",");
      if (parts.length != 7) {
        throw new IllegalArgumentException("Wrong format of testing data.");
      }
      this.code = parts[0];
      this.latitude = Double.valueOf(parts[1]);
      this.longitude = Double.valueOf(parts[2]);
      this.decodedLatitudeLo = Double.valueOf(parts[3]);
      this.decodedLongitudeLo = Double.valueOf(parts[4]);
      this.decodedLatitudeHi = Double.valueOf(parts[5]);
      this.decodedLongitudeHi = Double.valueOf(parts[6]);
    }
  }

  private static final String TEST_PATH =
      System.getenv("JAVA_RUNFILES") + "/openlocationcode/test_data";
  private final List<TestData> testDataList = new ArrayList<>();

  @Before
  public void setUp() throws Exception {
    File testFile = new File(TEST_PATH, "encodingTests.csv");
    InputStream testDataStream = new FileInputStream(testFile);
    BufferedReader reader = new BufferedReader(new InputStreamReader(testDataStream, UTF_8));
    String line;
    while ((line = reader.readLine()) != null) {
      if (line.startsWith("#")) {
        continue;
      }
      testDataList.add(new TestData(line));
    }
  }

  @Test
  public void testEncodeFromLatLong() {
    for (TestData testData : testDataList) {
      int codeLength = testData.code.length() - 1;
      if (testData.code.contains("0")) {
        codeLength = testData.code.indexOf("0");
      }
      Assert.assertEquals(
          String.format(
              "Latitude %f and longitude %f were wrongly encoded.",
              testData.latitude,
              testData.longitude),
          testData.code,
          OpenLocationCode.encode(testData.latitude, testData.longitude, codeLength).toString());
    }
  }

  @Test
  public void testDecode() {
    for (TestData testData : testDataList) {
      OpenLocationCode.CodeArea decoded = new OpenLocationCode(testData.code).decode();

      Assert.assertEquals(
          "Wrong low latitude for code " + testData.code,
          testData.decodedLatitudeLo,
          decoded.getSouthLatitude(),
          PRECISION);
      Assert.assertEquals(
          "Wrong high latitude for code " + testData.code,
          testData.decodedLatitudeHi,
          decoded.getNorthLatitude(),
          PRECISION);
      Assert.assertEquals(
          "Wrong low longitude for code " + testData.code,
          testData.decodedLongitudeLo,
          decoded.getWestLongitude(),
          PRECISION);
      Assert.assertEquals(
          "Wrong high longitude for code " + testData.code,
          testData.decodedLongitudeHi,
          decoded.getEastLongitude(),
          PRECISION);
    }
  }

  @Test
  public void testClipping() {
    Assert.assertEquals(
        "Clipping of negative latitude doesn't work.",
        OpenLocationCode.encode(-90, 5),
        OpenLocationCode.encode(-91, 5));
    Assert.assertEquals(
        "Clipping of positive latitude doesn't work.",
        OpenLocationCode.encode(90, 5),
        OpenLocationCode.encode(91, 5));
    Assert.assertEquals(
        "Clipping of negative longitude doesn't work.",
        OpenLocationCode.encode(5, 175),
        OpenLocationCode.encode(5, -185));
    Assert.assertEquals(
        "Clipping of very long negative longitude doesn't work.",
        OpenLocationCode.encode(5, 175),
        OpenLocationCode.encode(5, -905));
    Assert.assertEquals(
        "Clipping of very long positive longitude doesn't work.",
        OpenLocationCode.encode(5, -175),
        OpenLocationCode.encode(5, 905));
  }

  @Test
  public void testContains() {
    for (TestData testData : testDataList) {
      OpenLocationCode olc = new OpenLocationCode(testData.code);
      OpenLocationCode.CodeArea decoded = olc.decode();
      Assert.assertTrue(
          "Containment relation is broken for the decoded middle point of code " + testData.code,
          olc.contains(decoded.getCenterLatitude(), decoded.getCenterLongitude()));
      Assert.assertTrue(
          "Containment relation is broken for the decoded bottom left corner of code "
              + testData.code,
          olc.contains(decoded.getSouthLatitude(), decoded.getWestLongitude()));
      Assert.assertFalse(
          "Containment relation is broken for the decoded top right corner of code "
              + testData.code,
          olc.contains(decoded.getNorthLatitude(), decoded.getEastLongitude()));
      Assert.assertFalse(
          "Containment relation is broken for the decoded bottom right corner of code "
              + testData.code,
          olc.contains(decoded.getSouthLatitude(), decoded.getEastLongitude()));
      Assert.assertFalse(
          "Containment relation is broken for the decoded top left corner of code " + testData.code,
          olc.contains(decoded.getNorthLatitude(), decoded.getWestLongitude()));
    }
  }
}
