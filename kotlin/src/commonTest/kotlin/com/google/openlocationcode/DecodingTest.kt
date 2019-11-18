package com.google.openlocationcode


import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class DecodingTest {
    data class TestData(
        val code: String,
        val length: Int,
        val decodedLatitudeLo: Double,
        val decodedLatitudeHi: Double,
        val decodedLongitudeLo: Double,
        val decodedLongitudeHi: Double
    ) {
        companion object {
            fun fromLine(line: String): TestData {
                val parts = line.split(',')
                require(parts.size == 6) { "Wrong format of testing data." }
                return TestData(
                    code = parts[0],
                    length = parts[1].toInt(),
                    decodedLatitudeLo = parts[2].toDouble(),
                    decodedLongitudeLo = parts[3].toDouble(),
                    decodedLatitudeHi = parts[4].toDouble(),
                    decodedLongitudeHi = parts[5].toDouble()
                )
            }
        }
    }

    private lateinit var testDataList: List<TestData>

    @BeforeTest
    fun setup() {
        testDataList =
            loadTestCsvFileAsLines("decoding.csv")
                .filterNot { it.startsWith('#') }
                .map { TestData.fromLine(it) }
    }

    @Test
    fun testDecode() {
        for (testData in testDataList) {
            val decoded = OpenLocationCode.decode(testData.code)

            assertEquals(testData.length, decoded.length, "Wrong length for code ${testData.code}")
            assertEquals(
                testData.decodedLatitudeLo,
                decoded.southLatitude,
                TEST_DOUBLE_PRECISION,
                "Wrong low latitude for code ${testData.code}"
            )
            assertEquals(
                testData.decodedLatitudeHi,
                decoded.northLatitude,
                TEST_DOUBLE_PRECISION,
                "Wrong high latitude for code ${testData.code}"
            )
            assertEquals(
                testData.decodedLongitudeLo,
                decoded.westLongitude,
                TEST_DOUBLE_PRECISION,
                "Wrong low longitude for code ${testData.code}"
            )
            assertEquals(
                testData.decodedLongitudeHi,
                decoded.eastLongitude,
                TEST_DOUBLE_PRECISION,
                "Wrong high longitude for code ${testData.code}"
            )
        }
    }

    @Test
    fun testContains() {
        for (testData in testDataList) {
            val olc = OpenLocationCode(testData.code)

            val decoded = olc.decode()
            assertTrue(
                olc.contains(decoded.centerLatitude, decoded.centerLongitude),
                "Containment relation is broken for the decoded middle point of code ${testData.code}"
            )
            assertTrue(
                olc.contains(decoded.southLatitude, decoded.westLongitude),
                "Containment relation is broken for the decoded bottom left corner of code ${testData.code}"
            )
            assertFalse(
                olc.contains(decoded.northLatitude, decoded.eastLongitude),
                "Containment relation is broken for the decoded top right corner of code ${testData.code}"
            )
            assertFalse(
                olc.contains(decoded.southLatitude, decoded.eastLongitude),
                "Containment relation is broken for the decoded bottom right corner of code ${testData.code}"
            )
            assertFalse(
                olc.contains(decoded.northLatitude, decoded.westLongitude),
                "Containment relation is broken for the decoded top left corner of code ${testData.code}"
            )
        }
    }
}