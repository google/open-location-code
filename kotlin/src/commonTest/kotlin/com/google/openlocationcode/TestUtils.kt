package com.google.openlocationcode

import kotlin.math.abs
import kotlin.test.assertEquals

val TEST_DOUBLE_PRECISION = 1e-10

fun doubleIsDifferent(d1: Double, d2: Double, delta: Double): Boolean {
    if (d1 == d2) {
        return false
    }
    return !(abs(d1 - d2) <= delta)
}

fun assertEquals(expected: Double, actual: Double, delta: Double, message: String) {
    if (doubleIsDifferent(expected, actual, delta)) {
        assertEquals(expected, actual, message)
    }
}

fun assertEquals(expected: Double, actual: Double, delta: Double) {
    if (doubleIsDifferent(expected, actual, delta)) {
        assertEquals(expected, actual)
    }
}

// must be implemented on each platform added to run tests
expect fun loadTestCsvFileAsLines(filename: String): List<String>