package com.google.olc;

import static org.junit.Assert.*;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.junit.BeforeClass;
import org.junit.Test;



public class OpenLocationCodeTest {

	static Map<String, Boolean> validCodes = new HashMap<>();
	static Map<String, Boolean> shortCodes = new HashMap<>();
	static Map<String, Boolean> fullCodes = new HashMap<>();
	static Map<String, Point> encoded = new HashMap<>();
	static Map<String, CodeArea> decoded = new HashMap<>();
	static Map<String, String> shorts = new HashMap<>();
	static Map<String, Point> short_points = new HashMap<>();
	static final boolean DEBUG = false;

	@BeforeClass
	static public void setup() throws IOException {
		if (DEBUG) {
			Handler[] handlers = Logger.getLogger("").getHandlers();
			for (int index = 0; index < handlers.length; index++) {
				handlers[index].setLevel(Level.FINEST);
			}
		}
		InputStream is = OpenLocationCodeTest.class.getResourceAsStream("validitytests.csv");
		BufferedReader reader = new BufferedReader(new InputStreamReader(is));
		String line = "";
		while ((line = reader.readLine()) != null) {
			if (line.startsWith("#"))
				continue;
			String[] tokens = line.split(",");
			// code,isValid,isShort,isFull
			validCodes.put(tokens[0], new Boolean(tokens[1]));
			shortCodes.put(tokens[0], new Boolean(tokens[2]));
			fullCodes.put(tokens[0], new Boolean(tokens[3]));

		}
		reader.close();
		InputStream is2 = OpenLocationCodeTest.class.getResourceAsStream("encodingTests.csv");
		BufferedReader reader2 = new BufferedReader(new InputStreamReader(is2));
		line = "";
		while ((line = reader2.readLine()) != null) {
			if (line.startsWith("#"))
				continue;
			String[] tokens = line.split(",");
			// code,lat,lng,latLo,lngLo,latHi,lngHi
			double lat = Double.parseDouble(tokens[1]);
			double lon = Double.parseDouble(tokens[2]);
			Point p = new Point(lat, lon);
		
			String code = tokens[0];
			encoded.put(code, p);
			double latlo = Double.parseDouble(tokens[3]);
			double lonlo = Double.parseDouble(tokens[4]);
			double lathi = Double.parseDouble(tokens[5]);
			double lonhi = Double.parseDouble(tokens[6]);
			int expectedLength = code.replaceAll("\\+", "").replaceAll("0+", "").length();
			CodeArea area = new CodeArea(latlo, lonlo, lathi, lonhi, expectedLength);
			decoded.put(code, area);
		}
		InputStream is3 = OpenLocationCodeTest.class.getResourceAsStream("shorteningTests.csv");
		BufferedReader reader3 = new BufferedReader(new InputStreamReader(is3));
		line = "";
		while ((line = reader3.readLine()) != null) {
			if (line.startsWith("#"))
				continue;
			String[] tokens = line.split(",");
			// full code,lat,lng,shortcode
			shorts.put(tokens[0], tokens[3]);
			double lat = Double.parseDouble(tokens[1]);
			double lon = Double.parseDouble(tokens[2]);
			Point p = new Point(lat, lon);
			
			short_points.put(tokens[0], p);
		}
	}

	@Test
	public void testIsValid() {
		for (Entry<String, Boolean> key : validCodes.entrySet()) {
			assertEquals("wrong validity " + key.getKey(), key.getValue(), OpenLocationCode.isValid(key.getKey()));
		}
	}

	@Test
	public void testIsShort() {
		for (Entry<String, Boolean> key : shortCodes.entrySet()) {
			assertEquals("wrong shortness " + key.getKey(), key.getValue(), OpenLocationCode.isShort(key.getKey()));
		}
	}

	@Test
	public void testIsFull() {
		for (Entry<String, Boolean> key : fullCodes.entrySet()) {
			assertEquals("wrong fullness " + key.getKey(), key.getValue(), OpenLocationCode.isFull(key.getKey()));
		}
	}

	@Test
	public void testEncode() {
		for (Entry<String, Point> key : encoded.entrySet()) {
			assertTrue("invalid code ", OpenLocationCode.isValid(key.getKey()));
			int expectedLength = key.getKey().replaceAll("\\+", "").replaceAll("0+", "").length();
			String code = OpenLocationCode.encode(key.getValue(), expectedLength);

			assertEquals("wrong encoding " + key.getKey() + " for " + key.getValue(), key.getKey(), code);
		}
	}

	@Test
	public void testDecode() {
		for (Entry<String, CodeArea> key : decoded.entrySet()) {
			String code = key.getKey();
			assertTrue("invalid code ", OpenLocationCode.isValid(code));

			CodeArea c = OpenLocationCode.decode(code);

			assertEquals("wrong decoding " + code + " for " + key.getValue(), key.getValue(), c);
		}
	}

	@Test
	public void testShortening() {
		for (Entry<String, String> key : shorts.entrySet()) {
			Point p = short_points.get(key.getKey());
			assertEquals("Wrong shortening of code " + p, key.getValue(),
			    OpenLocationCode.shorten(key.getKey(), p.getX(), p.getY()));
		}
	}

	@Test
	public void testRecoverNearest() {
		for (Entry<String, String> key : shorts.entrySet()) {
			Point p = short_points.get(key.getKey());
			assertEquals("Wrong lengthening of code " + p, key.getKey(),
			    OpenLocationCode.recoverNearest(key.getValue(), p.getX(), p.getY()));
		}
	}
}
