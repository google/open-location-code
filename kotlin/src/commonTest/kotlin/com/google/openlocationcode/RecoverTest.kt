package com.google.openlocationcode

import kotlin.test.Test
import kotlin.test.assertEquals

class RecoverTest {
    @Test
    fun testRecoveryNearSouthPole() {
        val olc = OpenLocationCode("XXXXXX+XX")
        assertEquals("2CXXXXXX+XX", olc.recover(-81.0, 0.0).code)
    }

    @Test
    fun testRecoveryNearNorthPole() {
        val olc = OpenLocationCode("2222+22")
        assertEquals("CFX22222+22", olc.recover(89.6, 0.0).code)
    }
}
