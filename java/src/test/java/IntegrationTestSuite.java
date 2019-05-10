import com.google.openlocationcode.*;

import org.junit.runner.RunWith;
import org.junit.runners.Suite;

/**
 * This test suite will run for all the unit tests and so, more or less this will be serving as
 * IntegrationTestSuite.
 */
@RunWith(Suite.class)
@Suite.SuiteClasses({
  DecodingTest.class,
  EncodingTest.class,
  PrecisionTest.class,
  RecoverTest.class,
  ShorteningTest.class,
  UtilsTest.class,
  ValidityTest.class
})
public class IntegrationTestSuite {}
