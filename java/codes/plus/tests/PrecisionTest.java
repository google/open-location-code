package codes.plus.tests;

import codes.plus.OpenLocationCode;
import org.junit.Assert;
import org.junit.Test;

/**
 * Tests size of rectangles defined by open location codes of various size.
 */
public class PrecisionTest {

    @Test
    public void testWidthInDegrees() {
        Assert.assertEquals(new OpenLocationCode("67000000+").decode().getLongitudeWidth(), 20.);
        Assert.assertEquals(new OpenLocationCode("67890000+").decode().getLongitudeWidth(), 1.);
        Assert.assertEquals(new OpenLocationCode("6789CF00+").decode().getLongitudeWidth(), 0.05);
        Assert.assertEquals(new OpenLocationCode("6789CFGH+").decode().getLongitudeWidth(), 0.0025);
        Assert.assertEquals(new OpenLocationCode("6789CFGH+JM").decode().getLongitudeWidth(), 0.000125);
        Assert.assertEquals(new OpenLocationCode("6789CFGH+JMP").decode().getLongitudeWidth(), 0.00003125);
    }

    @Test
    public void testHeightInDegrees() {
        Assert.assertEquals(new OpenLocationCode("67000000+").decode().getLatitudeHeight(), 20.);
        Assert.assertEquals(new OpenLocationCode("67890000+").decode().getLatitudeHeight(), 1.);
        Assert.assertEquals(new OpenLocationCode("6789CF00+").decode().getLatitudeHeight(), 0.05);
        Assert.assertEquals(new OpenLocationCode("6789CFGH+").decode().getLatitudeHeight(), 0.0025);
        Assert.assertEquals(new OpenLocationCode("6789CFGH+JM").decode().getLatitudeHeight(), 0.000125);
        Assert.assertEquals(new OpenLocationCode("6789CFGH+JMP").decode().getLatitudeHeight(), 0.000025);
    }
}
