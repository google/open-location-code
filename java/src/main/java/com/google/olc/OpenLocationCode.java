package com.google.olc;

import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;



public class OpenLocationCode {
	static Logger LOGGER = Logger.getLogger(OpenLocationCode.class.getName());

	static {
		LOGGER.setLevel(Level.FINEST);
	}

	// A separator used to break the code into two parts to aid memorability.
	static final char SEPARATOR_ = '+';

	// The number of characters to place before the separator.
	static final int SEPARATOR_POSITION_ = 8;

	// The character used to pad codes.
	static final char PADDING_CHARACTER_ = '0';

	// The character set used to encode the values.
	static final String CODE_ALPHABET_ = "23456789CFGHJMPQRVWX";

	// The base to use to convert numbers to/from.
	static final int ENCODING_BASE_ = CODE_ALPHABET_.length();

	// The maximum value for latitude in degrees.
	static final double LATITUDE_MAX_ = 90;

	// The maximum value for longitude in degrees.
	static final double LONGITUDE_MAX_ = 180;

	// Maxiumum code length using lat/lng pair encoding. The area of such a
	// code is approximately 13x13 meters (at the equator), and should be suitable
	// for identifying buildings. This excludes prefix and separator characters.
	static final int PAIR_CODE_LENGTH_ = 10;

	// The resolution values in degrees for each position in the lat/lng pair
	// encoding. These give the place value of each position, and therefore the
	// dimensions of the resulting area.
	static final double[] PAIR_RESOLUTIONS_ = { 20.0, 1.0, .05, .0025, .000125 };

	// Number of columns in the grid refinement method.
	static final int GRID_COLUMNS_ = 4;

	// Number of rows in the grid refinement method.
	static final int GRID_ROWS_ = 5;

	// Size of the initial grid in degrees.
	static final double GRID_SIZE_DEGREES_ = 0.000125;

	// Minimum length of a code that can be shortened.
	static final int MIN_TRIMMABLE_CODE_LEN_ = 6;

	/**
	 * Returns the OLC alphabet.
	 */
	public String getAlphabet() {
		return CODE_ALPHABET_;
	};

	/**
	 * Determines if a code is valid.
	 * 
	 * To be valid, all characters must be from the Open Location Code character
	 * set with at most one separator. The separator can be in any even-numbered
	 * position up to the eighth digit.
	 */
	static public boolean isValid(String code) {
		if (code == null || code.isEmpty()) {
			LOGGER.log(Level.FINER, "isValid: code is empty");
			return false;
		}
		// The separator is required.
		if (code.indexOf(SEPARATOR_) < 0) {

			LOGGER.log(Level.FINER, "isValid: code is missing separator");
			return false;
		}
		if (code.indexOf(SEPARATOR_) != code.lastIndexOf(SEPARATOR_)) {
			LOGGER.log(Level.FINER, "isValid: separator occurs more than once");
			return false;
		}
		// Is it the only character?
		if (code.length() == 1) {
			LOGGER.log(Level.FINER, "isValid: separator is the only character");
			return false;
		}
		// Is it in an illegal position?
		if (code.indexOf(SEPARATOR_) > SEPARATOR_POSITION_ || code.indexOf(SEPARATOR_) % 2 == 1) {
			LOGGER.log(Level.FINER, "isValid: separator is in an illegal position");
			return false;
		}
		// We can have an even number of padding characters before the separator,
		// but then it must be the final character.
		if (code.indexOf(PADDING_CHARACTER_) > -1) {
			// Not allowed to start with them!
			if (code.indexOf(PADDING_CHARACTER_) == 0) {
				LOGGER.log(Level.FINER, "isValid: Incorrect Padding");
				return false;
			}
			// There can only be one group and it must have even length.
			Pattern p = Pattern.compile("(" + PADDING_CHARACTER_ + "+)");
			Matcher m = p.matcher(code);
			if (m.find()) {
				String padMatch = m.group();

				if (padMatch.length() % 2 == 1 || padMatch.length() > SEPARATOR_POSITION_ - 2) {
					LOGGER.log(Level.FINER, "isValid: uneven Padding");
					LOGGER.finest(padMatch);

					return false;
				}

			}
			if (m.find()) {
				LOGGER.log(Level.FINER, "isValid: Too many Padding blocks ");
				return false;
			}
			// If the code is long enough to end with a separator, make sure it does.
			if (code.charAt(code.length() - 1) != SEPARATOR_) {
				LOGGER.log(Level.FINER, "isValid: Separator must be at end");
				return false;
			}
		}
		// If there are characters after the separator, make sure there isn't just
		// one of them (not legal).
		if (code.length() - code.indexOf(SEPARATOR_) - 1 == 1) {
			LOGGER.log(Level.FINER, "isValid: not enough characters after the separator");
			return false;
		}

		code = cleanCode(code);
		// Check the code contains only valid characters.
		String upperCase = code.toUpperCase();
		for (int i = 0, len = code.length(); i < len; i++) {

			char character = upperCase.charAt(i);
			if (character != SEPARATOR_ && CODE_ALPHABET_.indexOf(character) == -1) {
				LOGGER.log(Level.FINER, "isValid: invalid character " + character + " in code");
				return false;
			}
		}
		return true;
	}

	/**
	 * @param code
	 * @return
	 */
	private static String cleanCode(String code) {
		// Strip the separator and any padding characters.
		LOGGER.finest("Before Padding strip:" + code);
		String sperator = "\\" + SEPARATOR_;
		code = code.replaceAll(sperator, "");
		LOGGER.finest("After Separator strip " + sperator + ":" + code);
		String padding = "" + PADDING_CHARACTER_ + "+";
		code = code.replaceAll(padding, "");
		LOGGER.finest("After Padding strip " + padding + ":" + code);
		return code;
	};

	/**
	 * Determines if a code is a valid short code.
	 * 
	 * A short Open Location Code is a sequence created by removing four or more
	 * digits from an Open Location Code. It must include a separator character.
	 */
	static public boolean isShort(String code) {
		// Check it's valid.
		if (!isValid(code)) {
			return false;
		}
		// If there are less characters than expected before the SEPARATOR.
		int sepPosition = code.indexOf(SEPARATOR_);
		// LOGGER.finest("separator position " + sepPosition + " must be > 0 && <" +
		// SEPARATOR_POSITION_);
		if (sepPosition >= 0 && sepPosition < SEPARATOR_POSITION_) {
			return true;
		}
		// LOGGER.log(Level.FINER, "isShort: invalid separator position " +
		// sepPosition);
		return false;
	};

	/**
	 * Determines if a code is a valid full Open Location Code.
	 * 
	 * Not all possible combinations of Open Location Code characters decode to
	 * valid latitude and longitude values. This checks that a code is valid and
	 * also that the latitude and longitude values are legal. If the prefix
	 * character is present, it must be the first character. If the separator
	 * character is present, it must be after four characters.
	 */
	static public boolean isFull(String code) {
		if (!isValid(code)) {
			return false;
		}
		// If it's short, it's not full.
		if (isShort(code)) {
			return false;
		}

		// Work out what the first latitude character indicates for latitude.
		double firstLatValue = CODE_ALPHABET_.indexOf(code.toUpperCase().charAt(0)) * ENCODING_BASE_;
		if (firstLatValue >= LATITUDE_MAX_ * 2) {
			// The code would decode to a latitude of >= 90 degrees.
			return false;
		}
		if (code.length() > 1) {
			// Work out what the first longitude character indicates for longitude.
			double firstLngValue = CODE_ALPHABET_.indexOf(code.toUpperCase().charAt(1)) * ENCODING_BASE_;
			if (firstLngValue >= LONGITUDE_MAX_ * 2) {
				// The code would decode to a longitude of >= 180 degrees.
				return false;
			}
		}
		return true;
	}

	/**
	 * Encode a location into an Open Location Code.
	 * 
	 * Produces a code of the specified length, or the default length if no length
	 * is provided.
	 * 
	 * The length determines the accuracy of the code. The default length is 10
	 * characters, returning a code of approximately 13.5x13.5 meters. Longer
	 * codes represent smaller areas, but lengths > 14 are sub-centimetre and so
	 * 11 or 12 are probably the limit of useful codes.
	 * 
	 * Args: latitude: A latitude in signed decimal degrees. Will be clipped to
	 * the range -90 to 90. longitude: A longitude in signed decimal degrees. Will
	 * be normalised to the range -180 to 180. codeLength: The number of
	 * significant digits in the output code, not including any separator
	 * characters.
	 */

	public static String encode(double latitude, double longitude, int codeLength)

	{
		if (codeLength == 0) {
			codeLength = PAIR_CODE_LENGTH_;
		}
		if (codeLength < 2 || (codeLength < SEPARATOR_POSITION_ && codeLength % 2 == 1)) {
			throw new IllegalArgumentException("Invalid Open Location Code length");
		}
		// Ensure that latitude and longitude are valid.
		latitude = clipLatitude(latitude);
		longitude = normalizeLongitude(longitude);
		// Latitude 90 needs to be adjusted to be just less, so the returned code
		// can also be decoded.
		if (latitude == 90) {
			latitude = latitude - computeLatitudePrecision(codeLength);
		}
		String code = encodePairs(latitude, longitude, Math.min(codeLength, PAIR_CODE_LENGTH_));
		// If the requested length indicates we want grid refined codes.
		if (codeLength > PAIR_CODE_LENGTH_) {
			code += encodeGrid(latitude, longitude, codeLength - PAIR_CODE_LENGTH_);
		}
		return code;
	}

	/**
	 * Decodes an Open Location Code into the location coordinates.
	 * 
	 * Returns a CodeArea object that includes the coordinates of the bounding box
	 * - the lower left, center and upper right.
	 * 
	 * Args: code: The Open Location Code to decode.
	 * 
	 * Returns: A CodeArea object that provides the latitude and longitude of two
	 * of the corners of the area, the center, and the length of the original
	 * code.
	 */
	public static CodeArea decode(String code) {
		if (!isFull(code)) {
			throw (new IllegalArgumentException("Passed Open Location Code is not a valid full code: " + code));
		}
		// Strip out separator character (we've already established the code is
		// valid so the maximum is one), padding characters and convert to upper
		// case.
		code = cleanCode(code);

		code = code.toUpperCase();
		// Decode the lat/lng pair component.
		int endPoint = Math.min(code.length(), PAIR_CODE_LENGTH_);
		CodeArea codeArea = decodePairs(code.substring(0, endPoint));
		// If there is a grid refinement component, decode that.
		if (code.length() <= PAIR_CODE_LENGTH_) {
			return codeArea;
		}
		CodeArea gridArea = decodeGrid(code.substring(PAIR_CODE_LENGTH_));
		return new CodeArea(codeArea.getLatitudeLo() + gridArea.getLatitudeLo(),
		    codeArea.getLongitudeLo() + gridArea.getLongitudeLo(), codeArea.getLatitudeLo() + gridArea.getLatitudeHi(),
		    codeArea.getLongitudeLo() + gridArea.getLongitudeHi(), codeArea.getCodeLength() + gridArea.getCodeLength());
	};

	/**
	 * Decode the grid refinement portion of an OLC code.
	 * 
	 * This decodes an OLC code using the grid refinement method.
	 * 
	 * Args: code: A valid OLC code sequence that is only the grid refinement
	 * portion. This is the portion of a code starting at position 11.
	 */
	static CodeArea decodeGrid(String code) {
		double latitudeLo = 0.0;
		double longitudeLo = 0.0;
		double latPlaceValue = GRID_SIZE_DEGREES_;
		double lngPlaceValue = GRID_SIZE_DEGREES_;
		int i = 0;
		while (i < code.length()) {
			int codeIndex = CODE_ALPHABET_.indexOf(code.charAt(i));
			int row = (int) Math.floor(codeIndex / GRID_COLUMNS_);
			int col = codeIndex % GRID_COLUMNS_;

			latPlaceValue /= GRID_ROWS_;
			lngPlaceValue /= GRID_COLUMNS_;

			latitudeLo += row * latPlaceValue;
			longitudeLo += col * lngPlaceValue;
			i += 1;
		}
		return new CodeArea(latitudeLo, longitudeLo, latitudeLo + latPlaceValue, longitudeLo + lngPlaceValue,
		    code.length());
	};

	/**
	 * Decode an OLC code made up of lat/lng pairs.
	 * 
	 * This decodes an OLC code made up of alternating latitude and longitude
	 * characters, encoded using base 20.
	 * 
	 * Args: code: A valid OLC code, presumed to be full, but with the separator
	 * removed.
	 */
	static CodeArea decodePairs(String code) {
		// Get the latitude and longitude values. These will need correcting from
		// positive ranges.

		double[] latitude = decodePairsSequence(code, 0);
		double[] longitude = decodePairsSequence(code, 1);
		// Correct the values and set them into the CodeArea object.
		return new CodeArea(latitude[0] - LATITUDE_MAX_, longitude[0] - LONGITUDE_MAX_, latitude[1] - LATITUDE_MAX_,
		    longitude[1] - LONGITUDE_MAX_, code.length());
	};

	/**
	 * Decode either a latitude or longitude sequence.
	 * 
	 * This decodes the latitude or longitude sequence of a lat/lng pair encoding.
	 * Starting at the character at position offset, every second character is
	 * decoded and the value returned.
	 * 
	 * Args: code: A valid OLC code, presumed to be full, with the separator
	 * removed. offset: The character to start from.
	 * 
	 * Returns: A pair of the low and high values. The low value comes from
	 * decoding the characters. The high value is the low value plus the
	 * resolution of the last position. Both values are offset into positive
	 * ranges and will need to be corrected before use.
	 */
	static double[] decodePairsSequence(String code, int offset) {
		int i = 0;
		double value = 0;
		while (i * 2 + offset < code.length()) {
			value += CODE_ALPHABET_.indexOf(code.charAt(i * 2 + offset)) * PAIR_RESOLUTIONS_[i];
			i += 1;
		}
		return new double[] { value, value + PAIR_RESOLUTIONS_[i - 1] };
	};

	/**
	 * Encode a location using the grid refinement method into an OLC string.
	 * 
	 * The grid refinement method divides the area into a grid of 4x5, and uses a
	 * single character to refine the area. This allows default accuracy OLC codes
	 * to be refined with just a single character.
	 * 
	 * Args: latitude: A latitude in signed decimal degrees. longitude: A
	 * longitude in signed decimal degrees. codeLength: The number of characters
	 * required.
	 */
	static String encodeGrid(double latitude, double longitude, int codeLength) {
		String code = "";
		double latPlaceValue = GRID_SIZE_DEGREES_;
		double lngPlaceValue = GRID_SIZE_DEGREES_;
		// Adjust latitude and longitude so they fall into positive ranges and
		// get the offset for the required places.
		double adjustedLatitude = (latitude + LATITUDE_MAX_) % latPlaceValue;
		double adjustedLongitude = (longitude + LONGITUDE_MAX_) % lngPlaceValue;
		for (int i = 0; i < codeLength; i++) {
			// Work out the row and column.
			int row = (int) Math.floor(adjustedLatitude / (latPlaceValue / GRID_ROWS_));
			int col = (int) Math.floor(adjustedLongitude / (lngPlaceValue / GRID_COLUMNS_));
			latPlaceValue /= GRID_ROWS_;
			lngPlaceValue /= GRID_COLUMNS_;
			adjustedLatitude -= row * latPlaceValue;
			adjustedLongitude -= col * lngPlaceValue;
			code += CODE_ALPHABET_.charAt(row * GRID_COLUMNS_ + col);
		}
		return code;
	}

	/**
	 * Encode a location into a sequence of OLC lat/lng pairs.
	 * 
	 * This uses pairs of characters (longitude and latitude in that order) to
	 * represent each step in a 20x20 grid. Each code, therefore, has 1/400th the
	 * area of the previous code.
	 * 
	 * Args: latitude: A latitude in signed decimal degrees. longitude: A
	 * longitude in signed decimal degrees. codeLength: The number of significant
	 * digits in the output code, not including any separator characters.
	 */
	static String encodePairs(double latitude, double longitude, int codeLength) {
		String code = "";
		// Adjust latitude and longitude so they fall into positive ranges.
		double adjustedLatitude = latitude + LATITUDE_MAX_;
		double adjustedLongitude = longitude + LONGITUDE_MAX_;
		// Count digits - can't use string length because it may include a separator
		// character.
		int digitCount = 0;
		while (digitCount < codeLength) {
			// Provides the value of digits in this place in decimal degrees.
			double placeValue = PAIR_RESOLUTIONS_[(int) Math.floor(digitCount / 2)];
			// Do the latitude - gets the digit for this place and subtracts that for
			// the next digit.
			int digitValue = (int) Math.floor(adjustedLatitude / placeValue);
			adjustedLatitude -= digitValue * placeValue;
			code += CODE_ALPHABET_.charAt(digitValue);
			digitCount += 1;
			// And do the longitude - gets the digit for this place and subtracts that
			// for the next digit.
			digitValue = (int) Math.floor(adjustedLongitude / placeValue);
			adjustedLongitude -= digitValue * placeValue;
			code += CODE_ALPHABET_.charAt(digitValue);
			digitCount += 1;
			// Should we add a separator here?
			if (digitCount == SEPARATOR_POSITION_ && digitCount < codeLength) {
				code += SEPARATOR_;
			}
		}
		while (code.length() < SEPARATOR_POSITION_) {
			code = code + PADDING_CHARACTER_;
		}

		if (code.length() == SEPARATOR_POSITION_) {
			code = code + SEPARATOR_;
		}
		return code;
	}

	/**
	 * Clip a latitude into the range -90 to 90.
	 * 
	 * Args: latitude: A latitude in signed decimal degrees.
	 */
	static double clipLatitude(double latitude) {
		return Math.min(90, Math.max(-90, latitude));
	}

	/**
	 * Normalize a longitude into the range -180 to 180, not including 180.
	 * 
	 * Args: longitude: A longitude in signed decimal degrees.
	 */
	static double normalizeLongitude(double longitude) {
		while (longitude < -180) {
			longitude = longitude + 360;
		}
		while (longitude >= 180) {
			longitude = longitude - 360;
		}
		return longitude;
	}

	/**
	 * Compute the latitude precision value for a given code length. Lengths <= 10
	 * have the same precision for latitude and longitude, but lengths > 10 have
	 * different precisions due to the grid method having fewer columns than rows.
	 */
	static double computeLatitudePrecision(int codeLength) {
		if (codeLength <= 10) {
			return Math.pow(20, Math.floor(codeLength / -2 + 2));
		}
		return Math.pow(20, -3) / Math.pow(GRID_ROWS_, codeLength - 10);
	}

	public static String encode(Point p) {
		// TODO Auto-generated method stub
		return encode(p.getX(), p.getY(), PAIR_CODE_LENGTH_);
	};

	public static String encode(Point p, int length) {
		// TODO Auto-generated method stub
		return encode(p.getX(), p.getY(), length);
	}

	/**
	 * Recover the nearest matching code to a specified location.
	 * 
	 * Given a short Open Location Code of between four and seven characters, this
	 * recovers the nearest matching full code to the specified location.
	 * 
	 * The number of characters that will be prepended to the short code, depends
	 * on the length of the short code and whether it starts with the separator.
	 * 
	 * If it starts with the separator, four characters will be prepended. If it
	 * does not, the characters that will be prepended to the short code, where S
	 * is the supplied short code and R are the computed characters, are as
	 * follows: SSSS -> RRRR.RRSSSS SSSSS -> RRRR.RRSSSSS SSSSSS -> RRRR.SSSSSS
	 * SSSSSSS -> RRRR.SSSSSSS Note that short codes with an odd number of
	 * characters will have their last character decoded using the grid refinement
	 * algorithm.
	 * 
	 * Args: shortCode: A valid short OLC character sequence. referenceLatitude:
	 * The latitude (in signed decimal degrees) to use to find the nearest
	 * matching full code. referenceLongitude: The longitude (in signed decimal
	 * degrees) to use to find the nearest matching full code.
	 * 
	 * Returns: The nearest full Open Location Code to the reference location that
	 * matches the short code. Note that the returned code may not have the same
	 * computed characters as the reference location. This is because it returns
	 * the nearest match, not necessarily the match within the same cell. If the
	 * passed code was not a valid short code, but was a valid full code, it is
	 * returned unchanged.
	 */
	static public String recoverNearest(String shortCode, double referenceLatitude, double referenceLongitude) {
		LOGGER.fine("recovering Nearest to "+shortCode+" "+referenceLatitude+","+referenceLongitude);
		if (!isShort(shortCode)) {
			if (isFull(shortCode)) {
				return shortCode;
			} else {
				throw new IllegalArgumentException("Passed short code is not valid: " + shortCode);
			}
		}
		// Ensure that latitude and longitude are valid.
		referenceLatitude = clipLatitude(referenceLatitude);
		referenceLongitude = normalizeLongitude(referenceLongitude);

		// Clean up the passed code.
		shortCode = shortCode.toUpperCase();
		// Compute the number of digits we need to recover.
		int paddingLength = SEPARATOR_POSITION_ - shortCode.indexOf(SEPARATOR_);
		LOGGER.fine("Padding length to recover "+paddingLength );
		// The resolution (height and width) of the padded area in degrees.
		double resolution =  Math.pow(20, 2 - (paddingLength / 2));
		LOGGER.fine("gives a resolution of "+resolution);
		// Distance from the center to an edge (in degrees).
		double areaToEdge = (resolution / 2.0);
		LOGGER.fine("and an areaToEdge "+areaToEdge);

		// Now round down the reference latitude and longitude to the resolution.
		double roundedLatitude = (Math.floor(referenceLatitude / resolution) * resolution);
		double roundedLongitude = (Math.floor(referenceLongitude / resolution) * resolution);

		LOGGER.fine("lat "+referenceLatitude+" rounded to "+roundedLatitude);
		LOGGER.fine("lon "+referenceLongitude+" rounded to "+roundedLongitude);
		// Use the reference location to pad the supplied short code and decode it.
		CodeArea codeArea = decode(encode(roundedLatitude, roundedLongitude, 0).substring(0, paddingLength) + shortCode);
		// How many degrees latitude is the code from the reference? If it is more
		// than half the resolution, we need to move it east or west.
		double degreesDifference = codeArea.getLatitudeCenter() - referenceLatitude;
		LOGGER.fine("E/W degrees difference "+degreesDifference);
		if (degreesDifference > areaToEdge) {
			// If the center of the short code is more than half a cell east,
			// then the best match will be one position west.
			LOGGER.fine("moving "+resolution+" degrees west");
			codeArea.setLatitudeCenter(codeArea.getLatitudeCenter() - resolution);
		} else if (degreesDifference < -areaToEdge) {
			// If the center of the short code is more than half a cell west,
			// then the best match will be one position east.
			LOGGER.fine("moving "+resolution+" degrees east");
			codeArea.setLatitudeCenter(codeArea.getLatitudeCenter() + resolution);
		}

		// How many degrees longitude is the code from the reference?
		degreesDifference = codeArea.getLongitudeCenter() - referenceLongitude;
		LOGGER.fine("N/S degrees difference "+degreesDifference);
		if (degreesDifference > areaToEdge) {
			LOGGER.fine("moving "+resolution+" degrees south");
			codeArea.setLongitudeCenter(codeArea.getLongitudeCenter() - resolution);
		} else if (degreesDifference < -areaToEdge) {
			LOGGER.fine("moving "+resolution+" degrees north");
			codeArea.setLongitudeCenter(codeArea.getLongitudeCenter() + resolution);
		}

		return encode(codeArea.getLatitudeCenter(), codeArea.getLongitudeCenter(), codeArea.getCodeLength());
	}

	/**
	 * Remove characters from the start of an OLC code.
	 * 
	 * This uses a reference location to determine how many initial characters can
	 * be removed from the OLC code. The number of characters that can be removed
	 * depends on the distance between the code center and the reference location.
	 * 
	 * The minimum number of characters that will be removed is four. If more than
	 * four characters can be removed, the additional characters will be replaced
	 * with the padding character. At most eight characters will be removed.
	 * 
	 * The reference location must be within 50% of the maximum range. This
	 * ensures that the shortened code will be able to be recovered using slightly
	 * different locations.
	 * 
	 * Args: code: A full, valid code to shorten. latitude: A latitude, in signed
	 * decimal degrees, to use as the reference point. longitude: A longitude, in
	 * signed decimal degrees, to use as the reference point.
	 * 
	 * Returns: Either the original code, if the reference location was not close
	 * enough, or the short code.
	 */
	public static String shorten(String code, double latitude, double longitude) {
		if (!isFull(code)) {
			throw new IllegalArgumentException("Passed code is not valid and full: " + code);
		}
		if (code.indexOf(PADDING_CHARACTER_) != -1) {
			throw new IllegalArgumentException("Cannot shorten padded codes: " + code);

		}
		code = code.toUpperCase();
		CodeArea codeArea = decode(code);
		if (codeArea.getCodeLength() < MIN_TRIMMABLE_CODE_LEN_) {
			throw new IllegalArgumentException("Code length must be at least " + MIN_TRIMMABLE_CODE_LEN_);
		}
		// Ensure that latitude and longitude are valid.
		latitude = clipLatitude(latitude);
		longitude = normalizeLongitude(longitude);
		// How close are the latitude and longitude to the code center.
		double range = Math.max(Math.abs(codeArea.getLatitudeCenter() - latitude),
		    Math.abs(codeArea.getLongitudeCenter() - longitude));
		for (int i = PAIR_RESOLUTIONS_.length - 2; i >= 1; i--) {
			// Check if we're close enough to shorten. The range must be less than 1/2
			// the resolution to shorten at all, and we want to allow some safety, so
			// use 0.3 instead of 0.5 as a multiplier.
			if (range < (PAIR_RESOLUTIONS_[i] * 0.3)) {
				// Trim it.
				return code.substring((i + 1) * 2);
			}
		}
		return code;
	}

}
