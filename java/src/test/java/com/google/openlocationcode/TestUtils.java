package com.google.openlocationcode;

import java.io.File;

/**
 * Test class for accumulating all the general methods at one place this will provide more
 * re-usability. KLOC in the tests will be decreased.
 */
public class TestUtils {
  // Gets the test file, factoring in whether it's being built from Maven or Bazel.
  public static File getTestFile(String testFile) {
    String testPath;
    String bazelRootPath = System.getenv("JAVA_RUNFILES");
    if (bazelRootPath == null) {
      File userDir = new File(System.getProperty("user.dir"));
      testPath = userDir.getParent() + "/test_data";
    } else {
      testPath = bazelRootPath + "/openlocationcode/test_data";
    }
    return new File(testPath, testFile);
  }
}
