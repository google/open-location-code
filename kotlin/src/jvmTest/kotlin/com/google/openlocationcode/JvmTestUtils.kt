package com.google.openlocationcode

import java.io.File

actual fun loadTestCsvFileAsLines(filename: String): List<String> {
    return getTestFile(filename).readLines()
}

private fun getTestFile(testFile: String): File {
    val userDir = File(System.getProperty("user.dir"))
    val testPath = userDir.parent + "/test_data"
    return File(testPath, testFile)
}

