package com.google.openlocationcode;

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

    private final double latitude;
    private final double longitude;
    private final int length;
    private final String code;

    public TestData(String line) {
      String[] parts = line.split(",");
      if (parts.length != 4) {
        throw new IllegalArgumentException("Wrong format of testing data.");
      }
      this.latitude = Double.valueOf(parts[0]);
      this.longitude = Double.valueOf(parts[1]);
      this.length = Integer.valueOf(parts[2]);
      this.code = parts[3];
    }
  }

  private final List<TestData> testDataList = new ArrayList<>();

  @Before
  public void setUp() throws Exception {
    InputStream testDataStream = new FileInputStream(getTestFile());
    BufferedReader reader = new BufferedReader(new InputStreamReader(testDataStream, UTF_8));
    String line;
    while ((line = reader.readLine()) != null) {
      if (line.startsWith("#") || line.length() == 0) {
        continue;
      }
      testDataList.add(new TestData(line));
    }
  }

  // Gets the test file, factoring in whether it's being built from Maven or Bazel.
  private File getTestFile() {
    String testPath;
    String bazelRootPath = System.getenv("JAVA_RUNFILES");
    if (bazelRootPath == null) {
      File userDir = new File(System.getProperty("user.dir"));
      testPath = userDir.getParent() + "/test_data";
    } else {
      testPath = bazelRootPath + "/openlocationcode/test_data";
    }
    return new File(testPath, "encoding.csv");
  }

  @Test
  public void testEncodeFromLatLong() {
    for (TestData testData : testDataList) {
      Assert.assertEquals(
          String.format(
              "Latitude %f, longitude %f and length %d were wrongly encoded.",
              testData.latitude,
              testData.longitude,
              testData.length),
          testData.code,
          OpenLocationCode.encode(testData.latitude, testData.longitude, testData.length).toString());
    }
  }
}
