package com.google.openlocationcode

import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.fail

class EncodingTest {

    data class TestData(
        val latitude: Double,
        val longitude: Double,
        val length: Int,
        val code: String
    ) {
        companion object {
            fun fromLine(line: String): TestData {
                val parts = line.split(',')
                require(parts.size == 4) { "Wrong format of testing data." }
                return TestData(
                    latitude = parts[0].toDouble(),
                    longitude = parts[1].toDouble(),
                    length = parts[2].toInt(),
                    code = parts[3]
                )
            }
        }
    }

    private lateinit var testDataList: List<TestData>

    @BeforeTest
    fun setUp() {
        testDataList = loadTestCsvFileAsLines("encoding.csv")
            .filterNot { it.startsWith('#') }
            .map { TestData.fromLine(it) }
    }

    @Test
    fun testEncodeFromLatLong() {
        for (testData in testDataList.filter { it.code.isNotBlank() }) {
            assertEquals(
                testData.code,
                OpenLocationCode.encode(testData.latitude, testData.longitude, testData.length),
                "Latitude ${testData.latitude}, longitude ${testData.longitude} and length ${testData.length} were wrongly encoded."
            )
        }
    }

    @Test
    fun testEncodeThrowsIllegalArgumentException() {
        try {
            for (testData in testDataList.filter { it.code.isBlank() }) {
                OpenLocationCode.encode(testData.latitude, testData.longitude, testData.length);
            }
            fail("Expected IllegalArgumentException")
        } catch (ex: IllegalArgumentException) {
            // pass!
        }
    }

}
