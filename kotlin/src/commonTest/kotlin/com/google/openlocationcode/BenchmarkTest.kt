package com.google.openlocationcode

import kotlin.random.Random
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.time.ExperimentalTime
import kotlin.time.measureTime

@ExperimentalTime
class BenchmarkTest {

    data class TestData(
        val latitude: Double,
        val longitude: Double,
        val length: Int
    ) {
        val code: String = OpenLocationCode.encode(latitude, longitude, length)

        companion object {
            fun generateRandomRecord(): TestData {
                var length = generator.nextInt(11) + 4
                if (length < 10 && length % 2 == 1) {
                    length++
                }
                return TestData(
                    latitude = generator.nextDouble() * 180 - 90,
                    longitude = generator.nextDouble() * 360 - 180,
                    length = length
                )
            }
        }
    }

    private val testDataList = mutableListOf<TestData>()

    @BeforeTest
    fun setUp() {
        testDataList.clear()
        for (i in 0 until LOOPS) {
            testDataList.add(TestData.generateRandomRecord())
        }
    }

    @Test
    fun benchmarkEncode() {
        val elapsed = measureTime {
            for (testData in testDataList) {
                OpenLocationCode.encode(testData.latitude, testData.longitude, testData.length)
            }
        }
        val microsecs = elapsed.inMicroseconds

        println("Encode $LOOPS loops in $microsecs usecs, ${microsecs.toDouble() / LOOPS} usec per call")
    }

    @Test
    fun benchmarkDecode() {
        val elapsed = measureTime {
            for (testData in testDataList) {
                OpenLocationCode.decode(testData.code)
            }
        }
        val microsecs = elapsed.inMicroseconds

        println("Encode $LOOPS loops in $microsecs usecs, ${microsecs.toDouble() / LOOPS} usec per call")
    }

    companion object {
        val LOOPS = 1000000

        var generator = Random(91991)
    }
}