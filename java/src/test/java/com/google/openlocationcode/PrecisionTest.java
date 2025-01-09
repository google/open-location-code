package com.google.openlocationcode;

import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.JUnit4;

/** Tests size of rectangles defined by Plus Codes of various size. */
@RunWith(JUnit4.class)
public class PrecisionTest {

  private static final double EPSILON = 1e-10;

  @Test
  public void testWidthInDegrees() {
    Assert.assertEquals(
        new OpenLocationCode("67000000+").decode().getLongitudeWidth(), 20., EPSILON);
    Assert.assertEquals(
        new OpenLocationCode("67890000+").decode().getLongitudeWidth(), 1., EPSILON);
    Assert.assertEquals(
        new OpenLocationCode("6789CF00+").decode().getLongitudeWidth(), 0.05, EPSILON);
    Assert.assertEquals(
        new OpenLocationCode("6789CFGH+").decode().getLongitudeWidth(), 0.0025, EPSILON);
    Assert.assertEquals(
        new OpenLocationCode("6789CFGH+JM").decode().getLongitudeWidth(), 0.000125, EPSILON);
    Assert.assertEquals(
        new OpenLocationCode("6789CFGH+JMP").decode().getLongitudeWidth(), 0.00003125, EPSILON);
  }

  @Test
  public void testHeightInDegrees() {
    Assert.assertEquals(
        new OpenLocationCode("67000000+").decode().getLatitudeHeight(), 20., EPSILON);
    Assert.assertEquals(
        new OpenLocationCode("67890000+").decode().getLatitudeHeight(), 1., EPSILON);
    Assert.assertEquals(
        new OpenLocationCode("6789CF00+").decode().getLatitudeHeight(), 0.05, EPSILON);
    Assert.assertEquals(
        new OpenLocationCode("6789CFGH+").decode().getLatitudeHeight(), 0.0025, EPSILON);
    Assert.assertEquals(
        new OpenLocationCode("6789CFGH+JM").decode().getLatitudeHeight(), 0.000125, EPSILON);
    Assert.assertEquals(
        new OpenLocationCode("6789CFGH+JMP").decode().getLatitudeHeight(), 0.000025, EPSILON);
  }
}
