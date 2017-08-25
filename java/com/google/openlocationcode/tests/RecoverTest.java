package com.google.openlocationcode.tests;

import com.google.openlocationcode.OpenLocationCode;

import junit.framework.Assert;
import org.junit.Test;

/** Test recovery near the poles. */
public class RecoverTest {

    @Test
    public void testRecoveryNearSouthPole() {
        OpenLocationCode olc = new OpenLocationCode("XXXXXX+XX");
        Assert.assertEquals("2CXXXXXX+XX",olc.recover(-81.0,0.0).getCode());
    }

    @Test
    public void testRecoveryNearNorthPole() {
        OpenLocationCode olc = new OpenLocationCode("2222+22");
        Assert.assertEquals("CFX22222+22", olc.recover(89.6, 0.0).getCode());
    }
}
