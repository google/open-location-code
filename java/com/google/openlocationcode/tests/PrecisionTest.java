package com.google.openlocationcode.tests;

import com.google.openlocationcode.OpenLocationCode;

import org.junit.Assert;
import org.junit.Test;

/**
 * Tests size of rectangles defined by open location codes of various size.
 */
public class PrecisionTest {

  @Test
  public void testWidthInDegrees() {
    Assert.assertEquals(OpenLocationCode.of("67000000+").decode().getLongitudeWidth(), 20., 0);
    Assert.assertEquals(OpenLocationCode.of("67890000+").decode().getLongitudeWidth(), 1., 0);
    Assert.assertEquals(OpenLocationCode.of("6789CF00+").decode().getLongitudeWidth(), 0.05, 0);
    Assert.assertEquals(OpenLocationCode.of("6789CFGH+").decode().getLongitudeWidth(), 0.0025, 0);
    Assert.assertEquals(
        OpenLocationCode.of("6789CFGH+JM").decode().getLongitudeWidth(), 0.000125, 0);
    Assert.assertEquals(
        OpenLocationCode.of("6789CFGH+JMP").decode().getLongitudeWidth(), 0.00003125, 0);
  }

  @Test
  public void testHeightInDegrees() {
    Assert.assertEquals(OpenLocationCode.of("67000000+").decode().getLatitudeHeight(), 20., 0);
    Assert.assertEquals(OpenLocationCode.of("67890000+").decode().getLatitudeHeight(), 1., 0);
    Assert.assertEquals(OpenLocationCode.of("6789CF00+").decode().getLatitudeHeight(), 0.05, 0);
    Assert.assertEquals(OpenLocationCode.of("6789CFGH+").decode().getLatitudeHeight(), 0.0025, 0);
    Assert.assertEquals(
        OpenLocationCode.of("6789CFGH+JM").decode().getLatitudeHeight(), 0.000125, 0);
    Assert.assertEquals(
        OpenLocationCode.of("6789CFGH+JMP").decode().getLatitudeHeight(), 0.000025, 0);
  }
}
