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
public class DecodingTest {

  public static final double PRECISION = 1e-10;

  private static class TestData {

    private final String code;
    private final int length;
    private final double decodedLatitudeLo;
    private final double decodedLatitudeHi;
    private final double decodedLongitudeLo;
    private final double decodedLongitudeHi;

    public TestData(String line) {
      String[] parts = line.split(",");
      if (parts.length != 6) {
        throw new IllegalArgumentException("Wrong format of testing data.");
      }
      this.code = parts[0];
      this.length = Integer.parseInt(parts[1]);
      this.decodedLatitudeLo = Double.parseDouble(parts[2]);
      this.decodedLongitudeLo = Double.parseDouble(parts[3]);
      this.decodedLatitudeHi = Double.parseDouble(parts[4]);
      this.decodedLongitudeHi = Double.parseDouble(parts[5]);
    }
  }

  private final List<TestData> testDataList = new ArrayList<>();

  @Before
  public void setUp() throws Exception {
    InputStream testDataStream = new FileInputStream(TestUtils.getTestFile("decoding.csv"));
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
  public void testDecode() {
    for (TestData testData : testDataList) {
      OpenLocationCode.CodeArea decoded = new OpenLocationCode(testData.code).decode();

      Assert.assertEquals(
          "Wrong length for code " + testData.code, testData.length, decoded.getLength());
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
