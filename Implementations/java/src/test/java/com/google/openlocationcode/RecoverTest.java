package com.google.openlocationcode;

import junit.framework.Assert;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.JUnit4;

/** Test recovery near the poles. */
@RunWith(JUnit4.class)
public class RecoverTest {

  @Test
  public void testRecoveryNearSouthPole() {
    OpenLocationCode olc = new OpenLocationCode("XXXXXX+XX");
    Assert.assertEquals("2CXXXXXX+XX", olc.recover(-81.0, 0.0).getCode());
  }

  @Test
  public void testRecoveryNearNorthPole() {
    OpenLocationCode olc = new OpenLocationCode("2222+22");
    Assert.assertEquals("CFX22222+22", olc.recover(89.6, 0.0).getCode());
  }
}
