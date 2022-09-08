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

/**
 * Tests methods {@link com.google.openlocationcode.OpenLocationCode#isValidCode(String)}, {@link
 * com.google.openlocationcode.OpenLocationCode#isShortCode(String)}} and {@link
 * com.google.openlocationcode.OpenLocationCode#isFullCode(String)} Open Location Code.
 */
@RunWith(JUnit4.class)
public class ValidityTest {

  private static class TestData {

    private final String code;
    private final boolean isValid;
    private final boolean isShort;
    private final boolean isFull;

    public TestData(String line) {
      String[] parts = line.split(",");
      if (parts.length != 4) {
        throw new IllegalArgumentException("Wrong format of testing data.");
      }
      this.code = parts[0];
      this.isValid = Boolean.parseBoolean(parts[1]);
      this.isShort = Boolean.parseBoolean(parts[2]);
      this.isFull = Boolean.parseBoolean(parts[3]);
    }
  }

  private final List<TestData> testDataList = new ArrayList<>();

  @Before
  public void setUp() throws Exception {
    InputStream testDataStream = new FileInputStream(TestUtils.getTestFile("validityTests.csv"));
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
  public void testIsValid() {
    for (TestData testData : testDataList) {
      Assert.assertEquals(
          "Validity of code " + testData.code + " is wrong.",
          testData.isValid,
          OpenLocationCode.isValidCode(testData.code));
    }
  }

  @Test
  public void testIsShort() {
    for (TestData testData : testDataList) {
      Assert.assertEquals(
          "Shortness of code " + testData.code + " is wrong.",
          testData.isShort,
          OpenLocationCode.isShortCode(testData.code));
    }
  }

  @Test
  public void testIsFull() {
    for (TestData testData : testDataList) {
      Assert.assertEquals(
          "Fullness of code " + testData.code + " is wrong.",
          testData.isFull,
          OpenLocationCode.isFullCode(testData.code));
    }
  }
}
