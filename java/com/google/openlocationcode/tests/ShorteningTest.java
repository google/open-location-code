package com.google.openlocationcode.tests;

import com.google.openlocationcode.OpenLocationCode;

import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

/** Tests shortening functionality of Open Location Code. */
public class ShorteningTest {

  private class TestData {

    private final String code;
    private final double referenceLatitude;
    private final double referenceLongitude;
    private final String shortCode;

    public TestData(String line) {
      String[] parts = line.split(",");
      if (parts.length != 4) {
        throw new IllegalArgumentException("Wrong format of testing data.");
      }
      this.code = parts[0];
      this.referenceLatitude = Double.valueOf(parts[1]);
      this.referenceLongitude = Double.valueOf(parts[2]);
      this.shortCode = parts[3];
    }
  }

  private final List<TestData> testDataList = new ArrayList<>();

  @Before
  public void setUp() throws Exception {
    File testFile = new File(System.getenv("JAVA_RUNFILES"), "openlocationcode/test_data/shortCodeTests.csv");
    InputStream testDataStream = new FileInputStream(testFile);
    BufferedReader reader = new BufferedReader(new InputStreamReader(testDataStream));
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
      OpenLocationCode olc = new OpenLocationCode(testData.code);
      OpenLocationCode shortened =
          olc.shorten(testData.referenceLatitude, testData.referenceLongitude);
      Assert.assertEquals(
          "Wrong shortening of code " + testData.code,
          testData.shortCode,
          shortened.getCode());
    }
  }

  @Test
  public void testRecovering() {
    for (TestData testData : testDataList) {
      OpenLocationCode olc = new OpenLocationCode(testData.shortCode);
      OpenLocationCode recovered =
          olc.recover(testData.referenceLatitude, testData.referenceLongitude);
      Assert.assertEquals(testData.code, recovered.getCode());
    }
  }
}
