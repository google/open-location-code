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

/** Tests shortening functionality of Open Location Code. */
@RunWith(JUnit4.class)
public class ShorteningTest {

  private static class TestData {

    private final String code;
    private final double referenceLatitude;
    private final double referenceLongitude;
    private final String shortCode;
    private final String testType;

    public TestData(String line) {
      String[] parts = line.split(",");
      if (parts.length != 5) {
        throw new IllegalArgumentException("Wrong format of testing data.");
      }
      this.code = parts[0];
      this.referenceLatitude = Double.parseDouble(parts[1]);
      this.referenceLongitude = Double.parseDouble(parts[2]);
      this.shortCode = parts[3];
      this.testType = parts[4];
    }
  }

  private final List<TestData> testDataList = new ArrayList<>();

  @Before
  public void setUp() throws Exception {
    InputStream testDataStream = new FileInputStream(TestUtils.getTestFile("shortCodeTests.csv"));
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
  public void testShortening() {
    for (TestData testData : testDataList) {
      if (!"B".equals(testData.testType) && !"S".equals(testData.testType)) {
        continue;
      }
      OpenLocationCode olc = new OpenLocationCode(testData.code);
      OpenLocationCode shortened =
          olc.shorten(testData.referenceLatitude, testData.referenceLongitude);
      Assert.assertEquals(
          "Wrong shortening of code " + testData.code, testData.shortCode, shortened.getCode());
    }
  }

  @Test
  public void testRecovering() {
    for (TestData testData : testDataList) {
      if (!"B".equals(testData.testType) && !"R".equals(testData.testType)) {
        continue;
      }
      OpenLocationCode olc = new OpenLocationCode(testData.shortCode);
      OpenLocationCode recovered =
          olc.recover(testData.referenceLatitude, testData.referenceLongitude);
      Assert.assertEquals(testData.code, recovered.getCode());
    }
  }
}
