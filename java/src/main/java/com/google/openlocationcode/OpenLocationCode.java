// Copyright 2014 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package com.google.openlocationcode;

import java.util.Objects;

/**
 * Convert locations to and from convenient short codes.
 *
 * <p>Plus Codes are short, ~10 character codes that can be used instead of street addresses. The
 * codes can be generated and decoded offline, and use a reduced character set that minimises the
 * chance of codes including words.
 *
 * <p>This provides both object and static methods.
 *
 * <p>Create an object with: OpenLocationCode code = new OpenLocationCode("7JVW52GR+2V");
 * OpenLocationCode code = new OpenLocationCode("52GR+2V"); OpenLocationCode code = new
 * OpenLocationCode(27.175063, 78.042188); OpenLocationCode code = new OpenLocationCode(27.175063,
 * 78.042188, 11);
 *
 * <p>Once you have a code object, you can apply the other methods to it, such as to shorten:
 * code.shorten(27.176, 78.05)
 *
 * <p>Recover the nearest match (if the code was a short code): code.recover(27.176, 78.05)
 *
 * <p>Or decode a code into its coordinates, returning a CodeArea object. code.decode()
 *
 * @author Jiri Semecky
 * @author Doug Rinckes
 */
public final class OpenLocationCode {

  // Provides a normal precision code, approximately 14x14 meters.
  public static final int CODE_PRECISION_NORMAL = 10;

  // The character set used to encode the values.
  public static final String CODE_ALPHABET = "23456789CFGHJMPQRVWX";

  // A separator used to break the code into two parts to aid memorability.
  public static final char SEPARATOR = '+';

  // The character used to pad codes.
  public static final char PADDING_CHARACTER = '0';

  // The number of characters to place before the separator.
  private static final int SEPARATOR_POSITION = 8;

  // The minimum number of digits in a Plus Code.
  public static final int MIN_DIGIT_COUNT = 2;

  // The max number of digits to process in a Plus Code.
  public static final int MAX_DIGIT_COUNT = 15;

  // Maximum code length using just lat/lng pair encoding.
  private static final int PAIR_CODE_LENGTH = 10;

  // Number of digits in the grid coding section.
  private static final int GRID_CODE_LENGTH = MAX_DIGIT_COUNT - PAIR_CODE_LENGTH;

  // The base to use to convert numbers to/from.
  private static final int ENCODING_BASE = CODE_ALPHABET.length();

  // The maximum value for latitude in degrees.
  private static final long LATITUDE_MAX = 90;

  // The maximum value for longitude in degrees.
  private static final long LONGITUDE_MAX = 180;

  // Number of columns in the grid refinement method.
  private static final int GRID_COLUMNS = 4;

  // Number of rows in the grid refinement method.
  private static final int GRID_ROWS = 5;

  // Value to multiple latitude degrees to convert it to an integer with the maximum encoding
  // precision. I.e. ENCODING_BASE**3 * GRID_ROWS**GRID_CODE_LENGTH
  private static final long LAT_INTEGER_MULTIPLIER = 8000 * 3125;

  // Value to multiple longitude degrees to convert it to an integer with the maximum encoding
  // precision. I.e. ENCODING_BASE**3 * GRID_COLUMNS**GRID_CODE_LENGTH
  private static final long LNG_INTEGER_MULTIPLIER = 8000 * 1024;

  // Value of the most significant latitude digit after it has been converted to an integer.
  private static final long LAT_MSP_VALUE = LAT_INTEGER_MULTIPLIER * ENCODING_BASE * ENCODING_BASE;

  // Value of the most significant longitude digit after it has been converted to an integer.
  private static final long LNG_MSP_VALUE = LNG_INTEGER_MULTIPLIER * ENCODING_BASE * ENCODING_BASE;

  /**
   * Coordinates of a decoded Open Location Code.
   *
   * <p>The coordinates include the latitude and longitude of the lower left and upper right corners
   * and the center of the bounding box for the area the code represents.
   */
  public static class CodeArea {

    private final double southLatitude;
    private final double westLongitude;
    private final double northLatitude;
    private final double eastLongitude;
    private final int length;

    public CodeArea(
        double southLatitude,
        double westLongitude,
        double northLatitude,
        double eastLongitude,
        int length) {
      this.southLatitude = southLatitude;
      this.westLongitude = westLongitude;
      this.northLatitude = northLatitude;
      this.eastLongitude = eastLongitude;
      this.length = length;
    }

    public double getSouthLatitude() {
      return southLatitude;
    }

    public double getWestLongitude() {
      return westLongitude;
    }

    public double getLatitudeHeight() {
      return northLatitude - southLatitude;
    }

    public double getLongitudeWidth() {
      return eastLongitude - westLongitude;
    }

    public double getCenterLatitude() {
      return (southLatitude + northLatitude) / 2;
    }

    public double getCenterLongitude() {
      return (westLongitude + eastLongitude) / 2;
    }

    public double getNorthLatitude() {
      return northLatitude;
    }

    public double getEastLongitude() {
      return eastLongitude;
    }

    public int getLength() {
      return length;
    }
  }

  /** The current code for objects. */
  private final String code;

  /**
   * Creates Open Location Code object for the provided code.
   *
   * @param code A valid OLC code. Can be a full code or a shortened code.
   * @throws IllegalArgumentException when the passed code is not valid.
   */
  public OpenLocationCode(String code) {
    if (!isValidCode(code.toUpperCase())) {
      throw new IllegalArgumentException(
          "The provided code '" + code + "' is not a valid Open Location Code.");
    }
    this.code = code.toUpperCase();
  }

  /**
   * Creates Open Location Code.
   *
   * @param latitude The latitude in decimal degrees.
   * @param longitude The longitude in decimal degrees.
   * @param codeLength The desired number of digits in the code.
   * @throws IllegalArgumentException if the code length is not valid.
   */
  public OpenLocationCode(double latitude, double longitude, int codeLength) {
    // Limit the maximum number of digits in the code.
    codeLength = Math.min(codeLength, MAX_DIGIT_COUNT);
    // Check that the code length requested is valid.
    if (codeLength < PAIR_CODE_LENGTH && codeLength % 2 == 1 || codeLength < MIN_DIGIT_COUNT) {
      throw new IllegalArgumentException("Illegal code length " + codeLength);
    }
    // Ensure that latitude and longitude are valid.
    latitude = clipLatitude(latitude);
    longitude = normalizeLongitude(longitude);

    // Latitude 90 needs to be adjusted to be just less, so the returned code can also be decoded.
    if (latitude == LATITUDE_MAX) {
      latitude = latitude - 0.9 * computeLatitudePrecision(codeLength);
    }

    // Store the code - we build it in reverse and reorder it afterwards.
    StringBuilder revCodeBuilder = new StringBuilder();

    // Compute the code.
    // This approach converts each value to an integer after multiplying it by
    // the final precision. This allows us to use only integer operations, so
    // avoiding any accumulation of floating point representation errors.

    // Multiply values by their precision and convert to positive. Rounding
    // avoids/minimises errors due to floating point precision.
    long latVal =
        (long) (Math.round((latitude + LATITUDE_MAX) * LAT_INTEGER_MULTIPLIER * 1e6) / 1e6);
    long lngVal =
        (long) (Math.round((longitude + LONGITUDE_MAX) * LNG_INTEGER_MULTIPLIER * 1e6) / 1e6);

    // Compute the grid part of the code if necessary.
    if (codeLength > PAIR_CODE_LENGTH) {
      for (int i = 0; i < GRID_CODE_LENGTH; i++) {
        long latDigit = latVal % GRID_ROWS;
        long lngDigit = lngVal % GRID_COLUMNS;
        int ndx = (int) (latDigit * GRID_COLUMNS + lngDigit);
        revCodeBuilder.append(CODE_ALPHABET.charAt(ndx));
        latVal /= GRID_ROWS;
        lngVal /= GRID_COLUMNS;
      }
    } else {
      latVal = (long) (latVal / Math.pow(GRID_ROWS, GRID_CODE_LENGTH));
      lngVal = (long) (lngVal / Math.pow(GRID_COLUMNS, GRID_CODE_LENGTH));
    }
    // Compute the pair section of the code.
    for (int i = 0; i < PAIR_CODE_LENGTH / 2; i++) {
      revCodeBuilder.append(CODE_ALPHABET.charAt((int) (lngVal % ENCODING_BASE)));
      revCodeBuilder.append(CODE_ALPHABET.charAt((int) (latVal % ENCODING_BASE)));
      latVal /= ENCODING_BASE;
      lngVal /= ENCODING_BASE;
      // If we are at the separator position, add the separator.
      if (i == 0) {
        revCodeBuilder.append(SEPARATOR);
      }
    }
    // Reverse the code.
    StringBuilder codeBuilder = revCodeBuilder.reverse();

    // If we need to pad the code, replace some of the digits.
    if (codeLength < SEPARATOR_POSITION) {
      for (int i = codeLength; i < SEPARATOR_POSITION; i++) {
        codeBuilder.setCharAt(i, PADDING_CHARACTER);
      }
    }
    this.code =
        codeBuilder.subSequence(0, Math.max(SEPARATOR_POSITION + 1, codeLength + 1)).toString();
  }

  /**
   * Creates Open Location Code with the default precision length.
   *
   * @param latitude The latitude in decimal degrees.
   * @param longitude The longitude in decimal degrees.
   */
  public OpenLocationCode(double latitude, double longitude) {
    this(latitude, longitude, CODE_PRECISION_NORMAL);
  }

  /**
   * Returns the string representation of the code.
   *
   * @return The code.
   */
  public String getCode() {
    return code;
  }

  /**
   * Encodes latitude/longitude into 10 digit Open Location Code. This method is equivalent to
   * creating the OpenLocationCode object and getting the code from it.
   *
   * @param latitude The latitude in decimal degrees.
   * @param longitude The longitude in decimal degrees.
   * @return The code.
   */
  public static String encode(double latitude, double longitude) {
    return new OpenLocationCode(latitude, longitude).getCode();
  }

  /**
   * Encodes latitude/longitude into Open Location Code of the provided length. This method is
   * equivalent to creating the OpenLocationCode object and getting the code from it.
   *
   * @param latitude The latitude in decimal degrees.
   * @param longitude The longitude in decimal degrees.
   * @param codeLength The number of digits in the returned code.
   * @return The code.
   */
  public static String encode(double latitude, double longitude, int codeLength) {
    return new OpenLocationCode(latitude, longitude, codeLength).getCode();
  }

  /**
   * Decodes {@link OpenLocationCode} object into {@link CodeArea} object encapsulating
   * latitude/longitude bounding box.
   *
   * @return A CodeArea object.
   */
  public CodeArea decode() {
    if (!isFullCode(code)) {
      throw new IllegalStateException(
          "Method decode() could only be called on valid full codes, code was " + code + ".");
    }
    // Strip padding and separator characters out of the code.
    String clean =
        code.replace(String.valueOf(SEPARATOR), "").replace(String.valueOf(PADDING_CHARACTER), "");

    // Initialise the values. We work them out as integers and convert them to doubles at the end.
    long latVal = -LATITUDE_MAX * LAT_INTEGER_MULTIPLIER;
    long lngVal = -LONGITUDE_MAX * LNG_INTEGER_MULTIPLIER;
    // Define the place value for the digits. We'll divide this down as we work through the code.
    long latPlaceVal = LAT_MSP_VALUE;
    long lngPlaceVal = LNG_MSP_VALUE;
    for (int i = 0; i < Math.min(clean.length(), PAIR_CODE_LENGTH); i += 2) {
      latPlaceVal /= ENCODING_BASE;
      lngPlaceVal /= ENCODING_BASE;
      latVal += CODE_ALPHABET.indexOf(clean.charAt(i)) * latPlaceVal;
      lngVal += CODE_ALPHABET.indexOf(clean.charAt(i + 1)) * lngPlaceVal;
    }
    for (int i = PAIR_CODE_LENGTH; i < Math.min(clean.length(), MAX_DIGIT_COUNT); i++) {
      latPlaceVal /= GRID_ROWS;
      lngPlaceVal /= GRID_COLUMNS;
      int digit = CODE_ALPHABET.indexOf(clean.charAt(i));
      int row = digit / GRID_COLUMNS;
      int col = digit % GRID_COLUMNS;
      latVal += row * latPlaceVal;
      lngVal += col * lngPlaceVal;
    }
    double latitudeLo = (double) latVal / LAT_INTEGER_MULTIPLIER;
    double longitudeLo = (double) lngVal / LNG_INTEGER_MULTIPLIER;
    double latitudeHi = (double) (latVal + latPlaceVal) / LAT_INTEGER_MULTIPLIER;
    double longitudeHi = (double) (lngVal + lngPlaceVal) / LNG_INTEGER_MULTIPLIER;
    return new CodeArea(
        latitudeLo,
        longitudeLo,
        latitudeHi,
        longitudeHi,
        Math.min(clean.length(), MAX_DIGIT_COUNT));
  }

  /**
   * Decodes code representing Open Location Code into {@link CodeArea} object encapsulating
   * latitude/longitude bounding box.
   *
   * @param code Open Location Code to be decoded.
   * @return A CodeArea object.
   * @throws IllegalArgumentException if the provided code is not a valid Open Location Code.
   */
  public static CodeArea decode(String code) throws IllegalArgumentException {
    return new OpenLocationCode(code).decode();
  }

  /**
   * Returns whether this {@link OpenLocationCode} is a full Open Location Code.
   *
   * @return True if it is a full code.
   */
  public boolean isFull() {
    return code.indexOf(SEPARATOR) == SEPARATOR_POSITION;
  }

  /**
   * Returns whether the provided Open Location Code is a full Open Location Code.
   *
   * @param code The code to check.
   * @return True if it is a full code.
   */
  public static boolean isFull(String code) throws IllegalArgumentException {
    return new OpenLocationCode(code).isFull();
  }

  /**
   * Returns whether this {@link OpenLocationCode} is a short Open Location Code.
   *
   * @return True if it is short.
   */
  public boolean isShort() {
    return code.indexOf(SEPARATOR) >= 0 && code.indexOf(SEPARATOR) < SEPARATOR_POSITION;
  }

  /**
   * Returns whether the provided Open Location Code is a short Open Location Code.
   *
   * @param code The code to check.
   * @return True if it is short.
   */
  public static boolean isShort(String code) throws IllegalArgumentException {
    return new OpenLocationCode(code).isShort();
  }

  /**
   * Returns whether this {@link OpenLocationCode} is a padded Open Location Code, meaning that it
   * contains less than 8 valid digits.
   *
   * @return True if this code is padded.
   */
  private boolean isPadded() {
    return code.indexOf(PADDING_CHARACTER) >= 0;
  }

  /**
   * Returns whether the provided Open Location Code is a padded Open Location Code, meaning that it
   * contains less than 8 valid digits.
   *
   * @param code The code to check.
   * @return True if it is padded.
   */
  public static boolean isPadded(String code) throws IllegalArgumentException {
    return new OpenLocationCode(code).isPadded();
  }

  /**
   * Returns short {@link OpenLocationCode} from the full Open Location Code created by removing
   * four or six digits, depending on the provided reference point. It removes as many digits as
   * possible.
   *
   * @param referenceLatitude Degrees.
   * @param referenceLongitude Degrees.
   * @return A short code if possible.
   */
  public OpenLocationCode shorten(double referenceLatitude, double referenceLongitude) {
    if (!isFull()) {
      throw new IllegalStateException("shorten() method could only be called on a full code.");
    }
    if (isPadded()) {
      throw new IllegalStateException("shorten() method can not be called on a padded code.");
    }

    CodeArea codeArea = decode();
    double range =
        Math.max(
            Math.abs(referenceLatitude - codeArea.getCenterLatitude()),
            Math.abs(referenceLongitude - codeArea.getCenterLongitude()));
    // We are going to check to see if we can remove three pairs, two pairs or just one pair of
    // digits from the code.
    for (int i = 4; i >= 1; i--) {
      // Check if we're close enough to shorten. The range must be less than 1/2
      // the precision to shorten at all, and we want to allow some safety, so
      // use 0.3 instead of 0.5 as a multiplier.
      if (range < (computeLatitudePrecision(i * 2) * 0.3)) {
        // We're done.
        return new OpenLocationCode(code.substring(i * 2));
      }
    }
    throw new IllegalArgumentException(
        "Reference location is too far from the Open Location Code center.");
  }

  /**
   * Returns an {@link OpenLocationCode} object representing a full Open Location Code from this
   * (short) Open Location Code, given the reference location.
   *
   * @param referenceLatitude Degrees.
   * @param referenceLongitude Degrees.
   * @return The nearest matching full code.
   */
  public OpenLocationCode recover(double referenceLatitude, double referenceLongitude) {
    if (isFull()) {
      // Note: each code is either full xor short, no other option.
      return this;
    }
    referenceLatitude = clipLatitude(referenceLatitude);
    referenceLongitude = normalizeLongitude(referenceLongitude);

    int digitsToRecover = SEPARATOR_POSITION - code.indexOf(SEPARATOR);
    // The precision (height and width) of the missing prefix in degrees.
    double prefixPrecision = Math.pow(ENCODING_BASE, 2 - (digitsToRecover / 2));

    // Use the reference location to generate the prefix.
    String recoveredPrefix =
        new OpenLocationCode(referenceLatitude, referenceLongitude)
            .getCode()
            .substring(0, digitsToRecover);
    // Combine the prefix with the short code and decode it.
    OpenLocationCode recovered = new OpenLocationCode(recoveredPrefix + code);
    CodeArea recoveredCodeArea = recovered.decode();
    // Work out whether the new code area is too far from the reference location. If it is, we
    // move it. It can only be out by a single precision step.
    double recoveredLatitude = recoveredCodeArea.getCenterLatitude();
    double recoveredLongitude = recoveredCodeArea.getCenterLongitude();

    // Move the recovered latitude by one precision up or down if it is too far from the reference,
    // unless doing so would lead to an invalid latitude.
    double latitudeDiff = recoveredLatitude - referenceLatitude;
    if (latitudeDiff > prefixPrecision / 2 && recoveredLatitude - prefixPrecision > -LATITUDE_MAX) {
      recoveredLatitude -= prefixPrecision;
    } else if (latitudeDiff < -prefixPrecision / 2
        && recoveredLatitude + prefixPrecision < LATITUDE_MAX) {
      recoveredLatitude += prefixPrecision;
    }

    // Move the recovered longitude by one precision up or down if it is too far from the
    // reference.
    double longitudeDiff = recoveredCodeArea.getCenterLongitude() - referenceLongitude;
    if (longitudeDiff > prefixPrecision / 2) {
      recoveredLongitude -= prefixPrecision;
    } else if (longitudeDiff < -prefixPrecision / 2) {
      recoveredLongitude += prefixPrecision;
    }

    return new OpenLocationCode(
        recoveredLatitude, recoveredLongitude, recovered.getCode().length() - 1);
  }

  /**
   * Returns whether the bounding box specified by the Open Location Code contains provided point.
   *
   * @param latitude Degrees.
   * @param longitude Degrees.
   * @return True if the coordinates are contained by the code.
   */
  public boolean contains(double latitude, double longitude) {
    CodeArea codeArea = decode();
    return codeArea.getSouthLatitude() <= latitude
        && latitude < codeArea.getNorthLatitude()
        && codeArea.getWestLongitude() <= longitude
        && longitude < codeArea.getEastLongitude();
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }
    OpenLocationCode that = (OpenLocationCode) o;
    return Objects.equals(code, that.code);
  }

  @Override
  public int hashCode() {
    return code != null ? code.hashCode() : 0;
  }

  @Override
  public String toString() {
    return getCode();
  }

  // Exposed static helper methods.

  /**
   * Returns whether the provided string is a valid Open Location code.
   *
   * @param code The code to check.
   * @return True if it is a valid full or short code.
   */
  public static boolean isValidCode(String code) {
    if (code == null || code.length() < 2) {
      return false;
    }
    code = code.toUpperCase();

    // There must be exactly one separator.
    int separatorPosition = code.indexOf(SEPARATOR);
    if (separatorPosition == -1) {
      return false;
    }
    if (separatorPosition != code.lastIndexOf(SEPARATOR)) {
      return false;
    }
    // There must be an even number of at most 8 characters before the separator.
    if (separatorPosition % 2 != 0 || separatorPosition > SEPARATOR_POSITION) {
      return false;
    }

    // Check first two characters: only some values from the alphabet are permitted.
    if (separatorPosition == SEPARATOR_POSITION) {
      // First latitude character can only have first 9 values.
      if (CODE_ALPHABET.indexOf(code.charAt(0)) > 8) {
        return false;
      }

      // First longitude character can only have first 18 values.
      if (CODE_ALPHABET.indexOf(code.charAt(1)) > 17) {
        return false;
      }
    }

    // Check the characters before the separator.
    boolean paddingStarted = false;
    for (int i = 0; i < separatorPosition; i++) {
      if (CODE_ALPHABET.indexOf(code.charAt(i)) == -1 && code.charAt(i) != PADDING_CHARACTER) {
        // Invalid character.
        return false;
      }
      if (paddingStarted) {
        // Once padding starts, there must not be anything but padding.
        if (code.charAt(i) != PADDING_CHARACTER) {
          return false;
        }
      } else if (code.charAt(i) == PADDING_CHARACTER) {
        paddingStarted = true;
        // Short codes cannot have padding
        if (separatorPosition < SEPARATOR_POSITION) {
          return false;
        }
        // Padding can start on even character: 2, 4 or 6.
        if (i != 2 && i != 4 && i != 6) {
          return false;
        }
      }
    }

    // Check the characters after the separator.
    if (code.length() > separatorPosition + 1) {
      if (paddingStarted) {
        return false;
      }
      // Only one character after separator is forbidden.
      if (code.length() == separatorPosition + 2) {
        return false;
      }
      for (int i = separatorPosition + 1; i < code.length(); i++) {
        if (CODE_ALPHABET.indexOf(code.charAt(i)) == -1) {
          return false;
        }
      }
    }

    return true;
  }

  /**
   * Returns if the code is a valid full Open Location Code.
   *
   * @param code The code to check.
   * @return True if it is a valid full code.
   */
  public static boolean isFullCode(String code) {
    try {
      return new OpenLocationCode(code).isFull();
    } catch (IllegalArgumentException e) {
      return false;
    }
  }

  /**
   * Returns if the code is a valid short Open Location Code.
   *
   * @param code The code to check.
   * @return True if it is a valid short code.
   */
  public static boolean isShortCode(String code) {
    try {
      return new OpenLocationCode(code).isShort();
    } catch (IllegalArgumentException e) {
      return false;
    }
  }

  // Private static methods.

  private static double clipLatitude(double latitude) {
    return Math.min(Math.max(latitude, -LATITUDE_MAX), LATITUDE_MAX);
  }

  private static double normalizeLongitude(double longitude) {
    if (longitude >= -LONGITUDE_MAX && longitude < LONGITUDE_MAX) {
      // longitude is within proper range, no normalization necessary
      return longitude;
    }

    // % in Java uses truncated division with the remainder having the same sign as
    // the dividend. For any input longitude < -360, the result of longitude%CIRCLE_DEG
    // will still be negative but > -360, so we need to add 360 and apply % a second time.
    final long CIRCLE_DEG = 2 * LONGITUDE_MAX; // 360 degrees
    return (longitude % CIRCLE_DEG + CIRCLE_DEG + LONGITUDE_MAX) % CIRCLE_DEG - LONGITUDE_MAX;
  }

  /**
   * Compute the latitude precision value for a given code length. Lengths <= 10 have the same
   * precision for latitude and longitude, but lengths > 10 have different precisions due to the
   * grid method having fewer columns than rows. Copied from the JS implementation.
   */
  private static double computeLatitudePrecision(int codeLength) {
    if (codeLength <= CODE_PRECISION_NORMAL) {
      return Math.pow(ENCODING_BASE, (double) (codeLength / -2 + 2));
    }
    return Math.pow(ENCODING_BASE, -3) / Math.pow(GRID_ROWS, codeLength - PAIR_CODE_LENGTH);
  }
}
