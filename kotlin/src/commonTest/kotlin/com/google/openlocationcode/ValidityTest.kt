package com.google.openlocationcode

import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals

class ValidityTest {

    data class TestData(
        val code: String,
        val isValid: Boolean,
        val isShort: Boolean,
        val isFull: Boolean
    ) {
        companion object {
            fun fromLine(line: String): TestData {
                val parts = line.split(',')
                require(parts.size == 4) { "Wrong format of testing data." }
                return TestData(
                    code = parts[0],
                    isValid = parts[1].toBoolean(),
                    isShort = parts[2].toBoolean(),
                    isFull = parts[3].toBoolean()
                )
            }
        }
    }

    private lateinit var testDataList: List<TestData>

    @BeforeTest
    fun setUp() {
        testDataList = loadTestCsvFileAsLines("validityTests.csv")
            .filterNot { it.startsWith('#') }
            .map { TestData.fromLine(it) }
    }

    @Test
    fun testIsValid() {
        for (testData in testDataList) {
            assertEquals(
                testData.isValid,
                OpenLocationCode.isValidCode(testData.code),
                "Validity of code ${testData.code} is wrong."
            )
        }
    }

    @Test
    fun testIsShort() {
        for (testData in testDataList) {
            assertEquals(
                testData.isShort,
                OpenLocationCode.isShortCode(testData.code),
                "Shortness of code ${testData.code} is wrong."
            )
        }
    }

    @Test
    fun testIsFull() {
        for (testData in testDataList) {
            assertEquals(
                testData.isFull,
                OpenLocationCode.isFullCode(testData.code),
                "Fullness of code ${testData.code} is wrong."
            )
        }
    }
}
