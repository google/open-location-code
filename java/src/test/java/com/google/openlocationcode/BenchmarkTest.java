package com.google.openlocationcode;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.JUnit4;

/** Benchmark the encode and decode methods. */
@RunWith(JUnit4.class)
public class BenchmarkTest {

  public static final int LOOPS = 1000000;

  public static Random generator = new Random();

  private static class TestData {

    private final double latitude;
    private final double longitude;
    private final int length;
    private final String code;

    public TestData() {
      this.latitude = generator.nextDouble() * 180 - 90;
      this.longitude = generator.nextDouble() * 360 - 180;
      int length = generator.nextInt(11) + 4;
      if (length < 10 && length % 2 == 1) {
        length += 1;
      }
      this.length = length;
      this.code = OpenLocationCode.encode(this.latitude, this.longitude, this.length);
    }
  }

  private final List<TestData> testDataList = new ArrayList<>();

  @Before
  public void setUp() throws Exception {
    testDataList.clear();
    for (int i = 0; i < LOOPS; i++) {
      testDataList.add(new TestData());
    }
  }

  @Test
  public void benchmarkEncode() {
    long start = System.nanoTime();
    for (TestData testData : testDataList) {
      OpenLocationCode.encode(testData.latitude, testData.longitude, testData.length);
    }
    long microsecs = (System.nanoTime() - start) / 1000;

    System.out.printf(
        "Encode %d loops in %d usecs, %.3f usec per call\n",
        LOOPS, microsecs, (double) microsecs / LOOPS);
  }

  @Test
  public void benchmarkDecode() {
    long start = System.nanoTime();
    for (TestData testData : testDataList) {
      OpenLocationCode.decode(testData.code);
    }
    long microsecs = (System.nanoTime() - start) / 1000;

    System.out.printf(
        "Decode %d loops in %d usecs, %.3f usec per call\n",
        LOOPS, microsecs, (double) microsecs / LOOPS);
  }
}
