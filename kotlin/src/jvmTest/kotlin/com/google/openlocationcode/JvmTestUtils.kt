package com.google.openlocationcode

import java.io.File

actual fun loadTestCsvFileAsLines(filename: String): List<String> {
    return getTestFile(filename).readLines()
}

private fun getTestFile(testFile: String): File {
    val testPath: String
    val bazelRootPath = System.getenv("JAVA_RUNFILES")
    if (bazelRootPath == null) {
        val userDir = File(System.getProperty("user.dir"))
        testPath = userDir.parent + "/test_data"
    } else {
        testPath = "$bazelRootPath/openlocationcode/test_data"
    }
    return File(testPath, testFile)
}

