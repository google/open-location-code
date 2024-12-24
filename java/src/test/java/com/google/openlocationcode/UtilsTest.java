package com.google.openlocationcode;

import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.JUnit4;

/** Tests various util methods. */
@RunWith(JUnit4.class)
public class UtilsTest {

  public static final double PRECISION = 1e-10;

  @Test
  public void testClipping() {
    Assert.assertEquals(
        "Clipping of negative latitude doesn't work.",
        OpenLocationCode.encode(-90, 5),
        OpenLocationCode.encode(-91, 5));
    Assert.assertEquals(
        "Clipping of positive latitude doesn't work.",
        OpenLocationCode.encode(90, 5),
        OpenLocationCode.encode(91, 5));
    Assert.assertEquals(
        "Clipping of negative longitude doesn't work.",
        OpenLocationCode.encode(5, 175),
        OpenLocationCode.encode(5, -185));
    Assert.assertEquals(
        "Clipping of very long negative longitude doesn't work.",
        OpenLocationCode.encode(5, 175),
        OpenLocationCode.encode(5, -905));
    Assert.assertEquals(
        "Clipping of very long positive longitude doesn't work.",
        OpenLocationCode.encode(5, -175),
        OpenLocationCode.encode(5, 905));
  }

  @Test
  public void testMaxCodeLength() {
    // Check that we do not return a code longer than is valid.
    String code = OpenLocationCode.encode(51.3701125, -10.202665625, 1000000);
    Assert.assertEquals(
        "Encoded code should have a length of MAX_DIGIT_COUNT + 1 for the plus symbol",
        OpenLocationCode.MAX_DIGIT_COUNT + 1,
        code.length());
    Assert.assertTrue("Code should be valid.", OpenLocationCode.isValidCode(code));
    // Extend the code with a valid character and make sure it is still valid.
    String tooLongCode = code + "W";
    Assert.assertTrue(
        "Too long code with all valid characters should be valid.",
        OpenLocationCode.isValidCode(tooLongCode));
    // Extend the code with an invalid character and make sure it is invalid.
    tooLongCode = code + "U";
    Assert.assertFalse(
        "Too long code with invalid character should be invalid.",
        OpenLocationCode.isValidCode(tooLongCode));
  }
}
