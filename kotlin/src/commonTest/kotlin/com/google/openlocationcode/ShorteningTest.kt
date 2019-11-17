package com.google.openlocationcode

import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals

class ShorteningTest {
    data class TestData(
        val code: String,
        val referenceLatitude: Double,
        val referenceLongitude: Double,
        val shortCode: String,
        val testType: String
    ) {
        companion object {
            fun fromLine(line: String): TestData {
                val parts = line.split(',')
                require(parts.size == 5) { "Wrong format of testing data." }
                return TestData(
                    code = parts[0],
                    referenceLatitude = parts[1].toDouble(),
                    referenceLongitude = parts[2].toDouble(),
                    shortCode = parts[3],
                    testType = parts[4]
                )
            }
        }
    }


    private lateinit var testDataList: List<TestData>

    @BeforeTest
    fun setup() {
        testDataList =
            loadTestCsvFileAsLines("shortCodeTests.csv")
                .filterNot { it.startsWith('#') }
                .map { TestData.fromLine(it) }
    }


    @Test
    fun testShortening() {
        for (testData in testDataList) {
            if ("B" != testData.testType && "S" != testData.testType) {
                continue
            }
            val olc = OpenLocationCode(testData.code)
            val shortened = olc.shorten(testData.referenceLatitude, testData.referenceLongitude)
            assertEquals(testData.shortCode, shortened.code, "Wrong shortening of code ${testData.code}")
        }
    }

    @Test
    fun testRecovering() {
        for (testData in testDataList) {
            if ("B" != testData.testType && "R" != testData.testType) {
                continue
            }
            val olc = OpenLocationCode(testData.shortCode)
            val recovered = olc.recover(testData.referenceLatitude, testData.referenceLongitude)
            assertEquals(testData.code, recovered.code)
        }
    }
}
