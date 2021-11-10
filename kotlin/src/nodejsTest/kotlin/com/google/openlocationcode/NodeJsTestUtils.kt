package com.google.openlocationcode

external fun require(module:String):dynamic

val fs = require("fs");
val process = require("process")

actual fun loadTestCsvFileAsLines(filename: String): List<String> {
   // working dir in Gradle is set to
   // build/js/packages/openlocationcode-kotlin-nodejs-test
   // TODO: make this an env variable so it could be overridden in some other way

   val testDataPath = "../../../../../test_data"
   val fullFilename = "$testDataPath/$filename"

   println("Loading test file: $fullFilename")

   val data = fs.readFileSync(fullFilename, "utf8") as String
   val lines = data.replace("\r\n", "\n").split('\n').filterNot { it.isBlank() }

   return lines
}