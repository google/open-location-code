package com.google.openlocationcode

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class MiscUtilsTest {
    @Test
    fun testClipping() {
        assertEquals(
            OpenLocationCode.encode(-90.0, 5.0),
            OpenLocationCode.encode(-91.0, 5.0),
            "Clipping of negative latitude doesn't work."
        )
        assertEquals(
            OpenLocationCode.encode(90.0, 5.0),
            OpenLocationCode.encode(91.0, 5.0),
            "Clipping of positive latitude doesn't work."
        )
        assertEquals(
            OpenLocationCode.encode(5.0, 175.0),
            OpenLocationCode.encode(5.0, -185.0),
            "Clipping of negative longitude doesn't work."
        )
        assertEquals(
            OpenLocationCode.encode(5.0, 175.0),
            OpenLocationCode.encode(5.0, -905.0),
            "Clipping of very long negative longitude doesn't work."
        )
        assertEquals(
            OpenLocationCode.encode(5.0, -175.0),
            OpenLocationCode.encode(5.0, 905.0),
            "Clipping of very long positive longitude doesn't work."
        )
    }

    @Test
    fun testMaxCodeLength() {
        // Check that we do not return a code longer than is valid.
        val code = OpenLocationCode.encode(51.3701125, -10.202665625, 1000000)
        assertEquals(
            (OpenLocationCode.MAX_DIGIT_COUNT + 1).toLong(),
            code.length.toLong(),
            "Encoded code should have a length of MAX_DIGIT_COUNT + 1 for the plus symbol"
        )
        assertTrue(OpenLocationCode.isValidCode(code), "Code should be valid.")
        // Extend the code with a valid character and make sure it is still valid.
        var tooLongCode = code + "W"
        assertTrue(
            OpenLocationCode.isValidCode(tooLongCode),
            "Too long code with all valid characters should be valid."
        )
        // Extend the code with an invalid character and make sure it is invalid.
        tooLongCode = code + "U"
        assertFalse(
            OpenLocationCode.isValidCode(tooLongCode),
            "Too long code with invalid character should be invalid."
        )
    }

}