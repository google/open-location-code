// Copyright 2017 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/**
  @fileoverview Convert locations to and from short codes.

  Plus Codes are short, 10-11 character codes that can be used instead
  of street addresses. The codes can be generated and decoded offline, and use
  a reduced character set that minimises the chance of codes including words.

  Codes are able to be shortened relative to a nearby location. This means that
  in many cases, only four to seven characters of the code are needed.
  To recover the original code, the same location is not required, as long as
  a nearby location is provided.

  Codes represent rectangular areas rather than points, and the longer the
  code, the smaller the area. A 10 character code represents a 13.5x13.5
  meter area (at the equator). An 11 character code represents approximately
  a 2.8x3.5 meter area.

  Two encoding algorithms are used. The first 10 characters are pairs of
  characters, one for latitude and one for latitude, using base 20. Each pair
  reduces the area of the code by a factor of 400. Only even code lengths are
  sensible, since an odd-numbered length would have sides in a ratio of 20:1.

  At position 11, the algorithm changes so that each character selects one
  position from a 4x5 grid. This allows single-character refinements.

  Examples:

    Encode a location, default accuracy:
    var code = OpenLocationCode.encode(47.365590, 8.524997);

    Encode a location using one stage of additional refinement:
    var code = OpenLocationCode.encode(47.365590, 8.524997, 11);

    Decode a full code:
    var coord = OpenLocationCode.decode(code);
    var msg = 'Center is ' + coord.latitudeCenter + ',' + coord.longitudeCenter;

    Attempt to trim the first characters from a code:
    var shortCode = OpenLocationCode.shorten('8FVC9G8F+6X', 47.5, 8.5);

    Recover the full code from a short code:
    var code = OpenLocationCode.recoverNearest('9G8F+6X', 47.4, 8.6);
    var code = OpenLocationCode.recoverNearest('8F+6X', 47.4, 8.6);
 */

goog.module('openlocationcode.OpenLocationCode');

/**
 * A separator used to break the code into two parts to aid memorability.
 * @const {string}
 */
var SEPARATOR = '+';

/**
 * The number of characters to place before the separator.
 * @const {number}
 */
var SEPARATOR_POSITION = 8;

/**
 * The character used to pad codes.
 * @const {string}
 */
var PADDING_CHARACTER = '0';

/**
 * The character set used to encode the values.
 * @const {string}
 */
var CODE_ALPHABET = '23456789CFGHJMPQRVWX';

/**
 * The base to use to convert numbers to/from.
 * @const {number}
 */
var ENCODING_BASE = CODE_ALPHABET.length;

/**
 * The maximum value for latitude in degrees.
 * @const {number}
 */
var LATITUDE_MAX = 90;

/**
 * The maximum value for longitude in degrees.
 * @const {number}
 */
var LONGITUDE_MAX = 180;

/**
 * Minimum length of a code.
 */
var MIN_CODE_LEN = 2;

/**
 * Maximum length of a code.
 */
var MAX_CODE_LEN = 15;

/**
 * Maximum code length using lat/lng pair encoding. The area of such a
 * code is approximately 13x13 meters (at the equator), and should be suitable
 * for identifying buildings. This excludes prefix and separator characters.
 * @const {number}
 */
var PAIR_CODE_LENGTH = 10;

/**
 * First place value of the pairs (if the last pair value is 1).
 * @const {number}
 */
var PAIR_FIRST_PLACE_VALUE = ENCODING_BASE**(PAIR_CODE_LENGTH / 2 - 1);

/**
 * Inverse of the precision of the pair section of the code.
 * @const {number}
 */
var PAIR_PRECISION = ENCODING_BASE**3;

/**
 * The resolution values in degrees for each position in the lat/lng pair
 * encoding. These give the place value of each position, and therefore the
 * dimensions of the resulting area.
 * @const {!Array<number>}
 */
var PAIR_RESOLUTIONS = [20.0, 1.0, .05, .0025, .000125];

/**
 * Number of digits in the grid precision part of the code.
 * @const {number}
 */
var GRID_CODE_LENGTH = MAX_CODE_LEN - PAIR_CODE_LENGTH;

/**
 * Number of columns in the grid refinement method.
 * @const {number}
 */
var GRID_COLUMNS = 4;

/**
 * Number of rows in the grid refinement method.
 * @const {number}
 */
var GRID_ROWS = 5;

/**
 * First place value of the latitude grid (if the last place is 1).
 * @const {number}
 */
var GRID_LAT_FIRST_PLACE_VALUE = GRID_ROWS**(GRID_CODE_LENGTH - 1);

/**
 * First place value of the longitude grid (if the last place is 1).
 * @const {number}
 */
var GRID_LNG_FIRST_PLACE_VALUE = GRID_COLUMNS**(GRID_CODE_LENGTH - 1);

/**
 * Multiply latitude by this much to make it a multiple of the finest
 * precision.
 * @const {number}
 */
var FINAL_LAT_PRECISION = PAIR_PRECISION *
    GRID_ROWS**(MAX_CODE_LEN - PAIR_CODE_LENGTH);

/**
 * Multiply longitude by this much to make it a multiple of the finest
 * precision.
 * @const {number}
 */
var FINAL_LNG_PRECISION = PAIR_PRECISION *
    GRID_COLUMNS**(MAX_CODE_LEN - PAIR_CODE_LENGTH);

/**
 * Minimum length of a code that can be shortened.
 * @const {number}
 */
var MIN_TRIMMABLE_CODE_LEN = 6;

/**
 * Returns the characters used to produce the codes.
 * @return {string} the OLC alphabet.
 */
exports.getAlphabet = function() {
  return CODE_ALPHABET;
};

/**
  Determines if a code is valid.

  To be valid, all characters must be from the Open Location Code character
  set with at most one separator. The separator can be in any even-numbered
  position up to the eighth digit.
  @param {string} code A possible code.
  @return {boolean} true If the string is valid, otherwise false.
 */
function isValid(code) {
  if (!code) {
    return false;
  }
  // The separator is required.
  if (code.indexOf(SEPARATOR) == -1) {
    return false;
  }
  if (code.indexOf(SEPARATOR) != code.lastIndexOf(SEPARATOR)) {
    return false;
  }
  // Is it the only character?
  if (code.length == 1) {
    return false;
  }
  // Is it in an illegal position?
  if (code.indexOf(SEPARATOR) > SEPARATOR_POSITION ||
      code.indexOf(SEPARATOR) % 2 == 1) {
    return false;
  }
  // We can have an even number of padding characters before the separator,
  // but then it must be the final character.
  if (code.indexOf(PADDING_CHARACTER) > -1) {
    // Short codes cannot have padding
    if (code.indexOf(SEPARATOR) < SEPARATOR_POSITION) {
      return false;
    }
    // Not allowed to start with them!
    if (code.indexOf(PADDING_CHARACTER) == 0) {
      return false;
    }
    // There can only be one group and it must have even length.
    var padMatch = code.match(new RegExp('(' + PADDING_CHARACTER + '+)', 'g'));
    if (padMatch.length > 1 || padMatch[0].length % 2 == 1 ||
        padMatch[0].length > SEPARATOR_POSITION - 2) {
      return false;
    }
    // If the code is long enough to end with a separator, make sure it does.
    if (code.charAt(code.length - 1) != SEPARATOR) {
      return false;
    }
  }
  // If there are characters after the separator, make sure there isn't just
  // one of them (not legal).
  if (code.length - code.indexOf(SEPARATOR) - 1 == 1) {
    return false;
  }

  // Strip the separator and any padding characters.
  code = code.replace(new RegExp('\\' + SEPARATOR + '+'), '')
      .replace(new RegExp(PADDING_CHARACTER + '+'), '');
  // Check the code contains only valid characters.
  for (var i = 0, len = code.length; i < len; i++) {
    var character = code.charAt(i).toUpperCase();
    if (character != SEPARATOR && CODE_ALPHABET.indexOf(character) == -1) {
      return false;
    }
  }
  return true;
}
exports.isValid = isValid;

/**
  Determines if a code is a valid short code.

  A short Open Location Code is a sequence created by removing four or more
  digits from an Open Location Code. It must include a separator
  character.
  @param {string} code A possible code.
  @return {boolean} True if the code is valid and short, otherwise false.
 */
function isShort(code) {
  // Check it's valid.
  if (!isValid(code)) {
    return false;
  }
  // If there are less characters than expected before the SEPARATOR.
  if (code.indexOf(SEPARATOR) >= 0 &&
      code.indexOf(SEPARATOR) < SEPARATOR_POSITION) {
    return true;
  }
  return false;
}
exports.isShort = isShort;

/**
  Determines if a code is a valid full Open Location Code.

  Not all possible combinations of Open Location Code characters decode to
  valid latitude and longitude values. This checks that a code is valid
  and also that the latitude and longitude values are legal. If the prefix
  character is present, it must be the first character. If the separator
  character is present, it must be after four characters.
  @param {string} code A possible code.
  @return {boolean} True if the code is a valid full code, false otherwise.
 */
function isFull(code) {
  if (!isValid(code)) {
    return false;
  }
  // If it's short, it's not full.
  if (isShort(code)) {
    return false;
  }

  // Work out what the first latitude character indicates for latitude.
  var firstLatValue =
      CODE_ALPHABET.indexOf(code.charAt(0).toUpperCase()) * ENCODING_BASE;
  if (firstLatValue >= LATITUDE_MAX * 2) {
    // The code would decode to a latitude of >= 90 degrees.
    return false;
  }
  if (code.length > 1) {
    // Work out what the first longitude character indicates for longitude.
    var firstLngValue =
        CODE_ALPHABET.indexOf(code.charAt(1).toUpperCase()) * ENCODING_BASE;
    if (firstLngValue >= LONGITUDE_MAX * 2) {
      // The code would decode to a longitude of >= 180 degrees.
      return false;
    }
  }
  return true;
}
exports.isFull = isFull;

/**
  Encode a location into an Open Location Code.

  Produces a code of the specified length, or the default length if no length
  is provided.

  The length determines the accuracy of the code. The default length is
  10 characters, returning a code of approximately 13.5x13.5 meters. Longer
  codes represent smaller areas, but lengths > 14 are sub-centimetre and so
  11 or 12 are probably the limit of useful codes.

  @param {number} latitude A latitude in signed decimal degrees. Will be
      clipped to the range -90 to 90.
  @param {number} longitude A longitude in signed decimal degrees. Will be
      normalised to the range -180 to 180.
  @param {number=} optLength The number of significant digits in the output
      code, not including any separator characters.
  @return {string} A code of the specified length or the default length if not
      specified.
 */
function encode(latitude, longitude, optLength) {
  if (typeof optLength == 'undefined') {
    optLength = PAIR_CODE_LENGTH;
  }
  if (optLength < MIN_CODE_LEN ||
      (optLength < PAIR_CODE_LENGTH && optLength % 2 == 1)) {
    throw new Error(
        'IllegalArgumentException: Invalid Plus Code length');
  }
  optLength = Math.min(optLength, MAX_CODE_LEN);
  // Ensure that latitude and longitude are valid.
  latitude = clipLatitude(latitude);
  longitude = normalizeLongitude(longitude);
  // Latitude 90 needs to be adjusted to be just less, so the returned code
  // can also be decoded.
  if (latitude == 90) {
    latitude = latitude - computeLatitudePrecision(optLength);
  }
  var code = '';

  // Compute the code.
  // This approach converts each value to an integer after multiplying it by
  // the final precision. This allows us to use only integer operations, so
  // avoiding any accumulation of floating point representation errors.

  // Multiply values by their precision and convert to positive.
  // Force to integers so the division operations will have integer results.
  // Note: JavaScript requires rounding before truncating to ensure precision!
  var latVal =
      Math.floor(Math.round((latitude + LATITUDE_MAX) * FINAL_LAT_PRECISION * 1e6) / 1e6);
  var lngVal =
      Math.floor(Math.round((longitude + LONGITUDE_MAX) * FINAL_LNG_PRECISION * 1e6) / 1e6);

  // Compute the grid part of the code if necessary.
  if (optLength > PAIR_CODE_LENGTH) {
    for (var i = 0; i < MAX_CODE_LEN - PAIR_CODE_LENGTH; i++) {
      var latDigit = latVal % GRID_ROWS;
      var lngDigit = lngVal % GRID_COLUMNS;
      var ndx = latDigit * GRID_COLUMNS + lngDigit;
      code = CODE_ALPHABET.charAt(ndx) + code;
      // Note! Integer division.
      latVal = Math.floor(latVal / GRID_ROWS);
      lngVal = Math.floor(lngVal / GRID_COLUMNS);
    }
  } else {
    latVal = Math.floor(latVal / GRID_ROWS**GRID_CODE_LENGTH);
    lngVal = Math.floor(lngVal / GRID_COLUMNS**GRID_CODE_LENGTH);
  }
  // Compute the pair section of the code.
  for (var i = 0; i < PAIR_CODE_LENGTH / 2; i++) {
    code = CODE_ALPHABET.charAt(lngVal % ENCODING_BASE) + code;
    code = CODE_ALPHABET.charAt(latVal % ENCODING_BASE) + code;
    latVal = Math.floor(latVal / ENCODING_BASE);
    lngVal = Math.floor(lngVal / ENCODING_BASE);
  }

  // Add the separator character.
  code = code.substring(0, SEPARATOR_POSITION) +
      SEPARATOR +
      code.substring(SEPARATOR_POSITION);

  // If we don't need to pad the code, return the requested section.
  if (optLength >= SEPARATOR_POSITION) {
    return code.substring(0, optLength + 1);
  }
  // Pad and return the code.
  return code.substring(0, optLength) +
      Array(SEPARATOR_POSITION - optLength + 1).join('0') + SEPARATOR;
}
exports.encode = encode;

/**
  Decodes an Open Location Code into the location coordinates.

  Returns a CodeArea object that includes the coordinates of the bounding
  box - the lower left, center and upper right.

  @param {string} code The Open Location Code to decode.
  @return {!CodeArea} An object that provides the latitude and longitude of two
  of the corners of the area, the center, and the length of the original code.
 */
function decode(code) {
  if (!isFull(code)) {
    throw new Error(
        'IllegalArgumentException: ' +
        'Passed Plus Code is not a valid full code: ' + code);
  }
  // Strip the '+' and '0' characters from the code and convert to upper case.
  code = code.replace('+', '').replace(/0/g, '').toUpperCase();
  // Initialise the values for each section. We work them out as integers and
  // convert them to floats at the end.
  var normalLat = -LATITUDE_MAX * PAIR_PRECISION;
  var normalLng = -LONGITUDE_MAX * PAIR_PRECISION;
  var gridLat = 0;
  var gridLng = 0;
  // How many digits do we have to process?
  var digits = Math.min(code.length, PAIR_CODE_LENGTH);
  // Define the place value for the most significant pair.
  var pv = PAIR_FIRST_PLACE_VALUE;
  // Decode the paired digits.
  for (var i = 0; i < digits; i += 2) {
    normalLat += CODE_ALPHABET.indexOf(code.charAt(i)) * pv;
    normalLng += CODE_ALPHABET.indexOf(code.charAt(i + 1)) * pv;
    if (i < digits - 2) {
      pv /= ENCODING_BASE;
    }
  }
  // Convert the place value to a float in degrees.
  var latPrecision = pv / PAIR_PRECISION;
  var lngPrecision = pv / PAIR_PRECISION;
  // Process any extra precision digits.
  if (code.length > PAIR_CODE_LENGTH) {
    // Initialise the place values for the grid.
    var rowpv = GRID_LAT_FIRST_PLACE_VALUE;
    var colpv = GRID_LNG_FIRST_PLACE_VALUE;
    // How many digits do we have to process?
    digits = Math.min(code.length, MAX_CODE_LEN);
    for (var i = PAIR_CODE_LENGTH; i < digits; i++) {
      var digitVal = CODE_ALPHABET.indexOf(code.charAt(i));
      var row = Math.floor(digitVal / GRID_COLUMNS);
      var col = digitVal % GRID_COLUMNS;
      gridLat += row * rowpv;
      gridLng += col * colpv;
      if (i < digits - 1) {
        rowpv /= GRID_ROWS;
        colpv /= GRID_COLUMNS;
      }
    }
    // Adjust the precisions from the integer values to degrees.
    latPrecision = rowpv / FINAL_LAT_PRECISION;
    lngPrecision = colpv / FINAL_LNG_PRECISION;
  }
  // Merge the values from the normal and extra precision parts of the code.
  var lat = normalLat / PAIR_PRECISION + gridLat / FINAL_LAT_PRECISION;
  var lng = normalLng / PAIR_PRECISION + gridLng / FINAL_LNG_PRECISION;
  // Multiple values by 1e14, round and then divide. This reduces errors due
  // to floating point precision.
  return new CodeArea(
      Math.round(lat * 1e14) / 1e14, Math.round(lng * 1e14) / 1e14,
      Math.round((lat + latPrecision) * 1e14) / 1e14,
      Math.round((lng + lngPrecision) * 1e14) / 1e14,
      Math.min(code.length, MAX_CODE_LEN));
}
exports.decode = decode;

/**
  Recover the nearest matching code to a specified location.

  Given a valid short Open Location Code this recovers the nearest matching
  full code to the specified location.

  Short codes will have characters prepended so that there are a total of
  eight characters before the separator.

  @param {string} shortCode A valid short OLC character sequence.
  @param {number} referenceLatitude The latitude (in signed decimal degrees) to
  use to find the nearest matching full code.
  @param {number} referenceLongitude The longitude (in signed decimal degrees)
  to use to find the nearest matching full code.
  @return {string} The nearest full Open Location Code to the reference location
  that matches the short code.

  Note that the returned code may not have the same computed characters as the
  reference location. This is because it returns the nearest match, not
  necessarily the match within the same cell. If the passed code was not a valid
  short code, but was a valid full code, it is returned unchanged.
 */
function recoverNearest(
    shortCode, referenceLatitude, referenceLongitude) {
  if (!isShort(shortCode)) {
    if (isFull(shortCode)) {
      return shortCode.toUpperCase();
    } else {
      throw new Error(
          'ValueError: Passed short code is not valid: ' + shortCode);
    }
  }
  // Ensure that latitude and longitude are valid.
  referenceLatitude = clipLatitude(referenceLatitude);
  referenceLongitude = normalizeLongitude(referenceLongitude);

  // Clean up the passed code.
  shortCode = shortCode.toUpperCase();
  // Compute the number of digits we need to recover.
  var paddingLength = SEPARATOR_POSITION - shortCode.indexOf(SEPARATOR);
  // The resolution (height and width) of the padded area in degrees.
  var resolution = Math.pow(20, 2 - (paddingLength / 2));
  // Distance from the center to an edge (in degrees).
  var halfResolution = resolution / 2.0;

  // Use the reference location to pad the supplied short code and decode it.
  var /** @type {!CodeArea} */ codeArea = decode(
      encode(referenceLatitude, referenceLongitude).substr(0, paddingLength) + shortCode);
  // How many degrees latitude is the code from the reference? If it is more
  // than half the resolution, we need to move it north or south but keep it
  // within -90 to 90 degrees.
  if (referenceLatitude + halfResolution < codeArea.latitudeCenter &&
      codeArea.latitudeCenter - resolution >= -LATITUDE_MAX) {
    // If the proposed code is more than half a cell north of the reference location,
    // it's too far, and the best match will be one cell south.
    codeArea.latitudeCenter -= resolution;
  } else if (referenceLatitude - halfResolution > codeArea.latitudeCenter &&
             codeArea.latitudeCenter + resolution <= LATITUDE_MAX) {
    // If the proposed code is more than half a cell south of the reference location,
    // it's too far, and the best match will be one cell north.
    codeArea.latitudeCenter += resolution;
  }

  // How many degrees longitude is the code from the reference?
  if (referenceLongitude + halfResolution < codeArea.longitudeCenter) {
    codeArea.longitudeCenter -= resolution;
  } else if (referenceLongitude - halfResolution > codeArea.longitudeCenter) {
    codeArea.longitudeCenter += resolution;
  }

  return encode(
      codeArea.latitudeCenter, codeArea.longitudeCenter, codeArea.codeLength);
}
exports.recoverNearest = recoverNearest;

/**
  Remove characters from the start of an OLC code.

  This uses a reference location to determine how many initial characters
  can be removed from the OLC code. The number of characters that can be
  removed depends on the distance between the code center and the reference
  location.

  The minimum number of characters that will be removed is four. If more than
  four characters can be removed, the additional characters will be replaced
  with the padding character. At most eight characters will be removed.

  The reference location must be within 50% of the maximum range. This ensures
  that the shortened code will be able to be recovered using slightly different
  locations.

  @param {string} code A full, valid code to shorten.
  @param {number} latitude A latitude, in signed decimal degrees, to use as the
  reference point.
  @param {number} longitude A longitude, in signed decimal degrees, to use as
  the reference point.
  @return {string} Either the original code, if the reference location was not
  close enough, or the shortened code.
 */
function shorten(code, latitude, longitude) {
  if (!isFull(code)) {
    throw new Error('ValueError: Passed code is not valid and full: ' + code);
  }
  if (code.indexOf(PADDING_CHARACTER) != -1) {
    throw new Error('ValueError: Cannot shorten padded codes: ' + code);
  }
  code = code.toUpperCase();
  var codeArea = decode(code);
  if (codeArea.codeLength < MIN_TRIMMABLE_CODE_LEN) {
    throw new Error(
        'ValueError: Code length must be at least ' + MIN_TRIMMABLE_CODE_LEN);
  }
  // Ensure that latitude and longitude are valid.
  latitude = clipLatitude(latitude);
  longitude = normalizeLongitude(longitude);
  // How close are the latitude and longitude to the code center.
  var range = Math.max(
      Math.abs(codeArea.latitudeCenter - latitude),
      Math.abs(codeArea.longitudeCenter - longitude));
  for (var i = PAIR_RESOLUTIONS.length - 2; i >= 1; i--) {
    // Check if we're close enough to shorten. The range must be less than 1/2
    // the resolution to shorten at all, and we want to allow some safety, so
    // use 0.3 instead of 0.5 as a multiplier.
    if (range < (PAIR_RESOLUTIONS[i] * 0.3)) {
      // Trim it.
      return code.substring((i + 1) * 2);
    }
  }
  return code;
}
exports.shorten = shorten;

/**
  Clip a latitude into the range -90 to 90.
  @param {number} latitude A latitude in signed decimal degrees.
  @return {number} the clipped latitude in the range -90 to 90.
 */
function clipLatitude(latitude) {
  return Math.min(90, Math.max(-90, latitude));
}

/**
  Compute the latitude precision value for a given code length. Lengths <=
  10 have the same precision for latitude and longitude, but lengths > 10
  have different precisions due to the grid method having fewer columns than
  rows.
  @param {number} codeLength A number representing the length (digits) in a
  code.
  @return {number} The height of the code area in degrees latitude.
 */
function computeLatitudePrecision(codeLength) {
  if (codeLength <= 10) {
    return Math.pow(20, Math.floor(codeLength / -2 + 2));
  }
  return Math.pow(20, -3) / Math.pow(GRID_ROWS, codeLength - 10);
}

/**
  Normalize a longitude into the range -180 to 180, not including 180.

  @param {number} longitude A longitude in signed decimal degrees.
  @return {number} the normalized longitude.
 */
function normalizeLongitude(longitude) {
  while (longitude < -180) {
    longitude = longitude + 360;
  }
  while (longitude >= 180) {
    longitude = longitude - 360;
  }
  return longitude;
}

/**
  Coordinates of a decoded Open Location Code.

  The coordinates include the latitude and longitude of the lower left and
  upper right corners and the center of the bounding box for the area the
  code represents.
  @param {number} latitudeLo: The latitude of the SW corner in degrees.
  @param {number} longitudeLo: The longitude of the SW corner in degrees.
  @param {number} latitudeHi: The latitude of the NE corner in degrees.
  @param {number} longitudeHi: The longitude of the NE corner in degrees.
  @param {number} codeLength: The number of significant characters that were in
  the code. (This excludes the separator.)

  @constructor
 */
function CodeArea(
    latitudeLo, longitudeLo, latitudeHi, longitudeHi, codeLength) {
  /** @type {number} */ this.latitudeLo = latitudeLo;
  /** @type {number} */ this.longitudeLo = longitudeLo;
  /** @type {number} */ this.latitudeHi = latitudeHi;
  /** @type {number} */ this.longitudeHi = longitudeHi;
  /** @type {number} */ this.codeLength = codeLength;
  /** @type {number} */ this.latitudeCenter =
      Math.min(latitudeLo + (latitudeHi - latitudeLo) / 2, LATITUDE_MAX);
  /** @type {number} */ this.longitudeCenter =
      Math.min(longitudeLo + (longitudeHi - longitudeLo) / 2, LONGITUDE_MAX);
}
exports.CodeArea = CodeArea;
