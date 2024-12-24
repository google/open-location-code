package com.google.openlocationcode;

import java.io.File;

public class TestUtils {
  // Gets the test file, factoring in whether it's being built from Maven or Bazel.
  public static File getTestFile(String testFile) {
    String testPath;
    String bazelRootPath = System.getenv("JAVA_RUNFILES");
    if (bazelRootPath == null) {
      File userDir = new File(System.getProperty("user.dir"));
      testPath = userDir.getParent() + "/test_data";
    } else {
      testPath = bazelRootPath + "/_main/test_data";
    }
    return new File(testPath, testFile);
  }
}
