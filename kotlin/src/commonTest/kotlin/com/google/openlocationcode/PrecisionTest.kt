package com.google.openlocationcode

import kotlin.test.Test


class PrecisionTest {
    @Test
    fun testWidthInDegrees() {
        assertEquals(OpenLocationCode.decode("67000000+").longitudeWidth, 20.0, TEST_DOUBLE_PRECISION)
        assertEquals(OpenLocationCode.decode("67890000+").longitudeWidth, 1.0, TEST_DOUBLE_PRECISION)
        assertEquals(OpenLocationCode.decode("6789CF00+").longitudeWidth, 0.05, TEST_DOUBLE_PRECISION)
        assertEquals(OpenLocationCode.decode("6789CFGH+").longitudeWidth, 0.0025, TEST_DOUBLE_PRECISION)
        assertEquals(OpenLocationCode.decode("6789CFGH+JM").longitudeWidth, 0.000125, TEST_DOUBLE_PRECISION)
        assertEquals(OpenLocationCode.decode("6789CFGH+JMP").longitudeWidth, 0.00003125, TEST_DOUBLE_PRECISION)
    }

    @Test
    fun testHeightInDegrees() {
        assertEquals(OpenLocationCode.decode("67000000+").latitudeHeight, 20.0, TEST_DOUBLE_PRECISION)
        assertEquals(OpenLocationCode.decode("67890000+").latitudeHeight, 1.0, TEST_DOUBLE_PRECISION)
        assertEquals(OpenLocationCode.decode("6789CF00+").latitudeHeight, 0.05, TEST_DOUBLE_PRECISION)
        assertEquals(OpenLocationCode.decode("6789CFGH+").latitudeHeight, 0.0025, TEST_DOUBLE_PRECISION)
        assertEquals(OpenLocationCode.decode("6789CFGH+JM").latitudeHeight, 0.000125, TEST_DOUBLE_PRECISION)
        assertEquals(OpenLocationCode.decode("6789CFGH+JMP").latitudeHeight, 0.000025, TEST_DOUBLE_PRECISION)
    }
}