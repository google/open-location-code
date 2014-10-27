// Copyright 2014 Google Inc. All rights reserved.
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
  Convert locations to and from short codes.

  Open Location Codes are short, 10-11 character codes that can be used instead
  of street addresses. The codes can be generated and decoded offline, and use
  a reduced character set that minimises the chance of codes including words.

  Codes are able to be shortened relative to a nearby location. This means that
  in many cases, only four to seven characters of the code are needed.
  To recover the original code, the same location is not required, as long as
  a nearby location is provided.

  Codes represent rectangular areas rather than points, and the longer the
  code, the smaller the area. A 10 character code represents a 13.5x13.5
  meter area (at the equator. An 11 character code represents approximately
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

    Attempt to trim the first four characters from a code:
    var shortCode = OpenLocationCode.shortenBy4('+8FVC.9G8F6X', 47.5, 8.5);

    Recover the full code from a short code:
    var code = OpenLocationCode.recoverNearest('+9G8F6X', 47.4, 8.6);
 */
(function(window) {
  var OpenLocationCode = window.OpenLocationCode = {};

  // The prefix char. Used to help disambiguate OLC codes from postcodes.
  var PREFIX_ = '+';

  // A separator used to break the code into two parts to aid memorability.
  var SEPARATOR_ = '.';

  // The number of characters to place before the separator.
  var SEPARATOR_POSITION_ = 4;

  // The character set used to encode the values.
  var CODE_ALPHABET_ = '23456789CFGHJMPQRVWX';

  // The base to use to convert numbers to/from.
  var ENCODING_BASE_ = CODE_ALPHABET_.length;

  // The maximum value for latitude in degrees.
  var LATITUDE_MAX_ = 90;

  // The maximum value for longitude in degrees.
  var LONGITUDE_MAX_ = 180;

  // Maxiumum code length using lat/lng pair encoding. The area of such a
  // code is approximately 13x13 meters (at the equator), and should be suitable
  // for identifying buildings. This excludes prefix and separator characters.
  var PAIR_CODE_LENGTH_ = 10;

  // The resolution values in degrees for each position in the lat/lng pair
  // encoding. These give the place value of each position, and therefore the
  // dimensions of the resulting area.
  var PAIR_RESOLUTIONS_ = [20.0, 1.0, .05, .0025, .000125];

  // Number of columns in the grid refinement method.
  var GRID_COLUMNS_ = 4;

  // Number of rows in the grid refinement method.
  var GRID_ROWS_ = 5;

  // Size of the initial grid in degrees.
  var GRID_SIZE_DEGREES_ = 0.000125;

  // Minimum length of a short code.
  var MIN_SHORT_CODE_LEN_ = 4;

  // Maximum length of a short code.
  var MAX_SHORT_CODE_LEN_ = 7;

  // Minimum length of a code that can be shortened.
  var MIN_TRIMMABLE_CODE_LEN_ = 10;

  // Maximum length of a code that can be shortened.
  var MAX_TRIMMABLE_CODE_LEN_ = 11;

  /**
    Returns the OLC alphabet.
   */
  var getAlphabet = OpenLocationCode.getAlphabet = function() {
    return CODE_ALPHABET_;
  };

  /**
    Determines if a code is valid.

    To be valid, all characters must be from the Open Location Code character
    set with at most one separator. If the prefix character is present, it
    must be the first character. If the separator character is present,
    it must be after four characters.
   */
  var isValid = OpenLocationCode.isValid = function(code) {
    if (!code) {
      return false;
    }
    // If the code includes more than one prefix character, it is not valid.
    if (code.indexOf(PREFIX_) != code.lastIndexOf(PREFIX_)) {
      return false;
    }
    // If the code includes the prefix character but not in the first position,
    // it is not valid.
    if (code.indexOf(PREFIX_) > 0) {
      return false;
    }
    // Strip off the prefix if it was provided.
    code = code.replace(PREFIX_, '');
    // If the code includes more than one separator, it is not valid.
    if (code.indexOf(SEPARATOR_) >= 0) {
      if (code.indexOf(SEPARATOR_) != code.lastIndexOf(SEPARATOR_)) {
        return false;
      }
      // If there is a separator, and it is in a position != SEPARATOR_POSITION,
      // the code is not valid.
      if (code.indexOf(SEPARATOR_) != SEPARATOR_POSITION_) {
        return false;
      }
    }
    // Check the code contains only valid characters.
    for (var i = 0, len = code.length; i < len; i++) {
      var character = code.charAt(i).toUpperCase();
      if (character != SEPARATOR_ && CODE_ALPHABET_.indexOf(character) == -1) {
        return false;
      }
    }
    return true;
  };

  /**
    Determines if a code is a valid short code.

    A short Open Location Code is a sequence created by removing the first
    four or six characters from a full Open Location Code.

    A code must be a possible sub-string of a generated Open Location Code, at
    least four and at most seven characters long and not include a separator
    character. If the prefix character is present, it must be the first
    character.
   */
  var isShort = OpenLocationCode.isShort = function(code) {
    if (!isValid(code)) {
      return false;
    }
    if (code.indexOf(SEPARATOR_) != -1) {
      return false;
    }
    // Strip off the prefix if it was provided.
    code = code.replace(PREFIX_, '');
    if (code.length < MIN_SHORT_CODE_LEN_) {
      return false;
    }
    if (code.length > MAX_SHORT_CODE_LEN_) {
      return false;
    }
    return true;
  };

  /**
    Determines if a code is a valid full Open Location Code.

    Not all possible combinations of Open Location Code characters decode to
    valid latitude and longitude values. This checks that a code is valid
    and also that the latitude and longitude values are legal. If the prefix
    character is present, it must be the first character. If the separator
    character is present, it must be after four characters.
   */
  var isFull = OpenLocationCode.isFull = function(code) {
    if (!isValid(code)) {
      return false;
    }
    // Strip off the prefix if it was provided.
    code = code.replace(PREFIX_, '');

    // Work out what the first latitude character indicates for latitude.
    var firstLatValue = CODE_ALPHABET_.indexOf(
        code.charAt(0).toUpperCase()) * ENCODING_BASE_;
    if (firstLatValue >= LATITUDE_MAX_ * 2) {
      // The code would decode to a latitude of >= 90 degrees.
      return false;
    }
    if (code.length > 1) {
      // Work out what the first longitude character indicates for longitude.
      var firstLngValue = CODE_ALPHABET_.indexOf(
          code.charAt(1).toUpperCase()) * ENCODING_BASE_;
      if (firstLngValue >= LONGITUDE_MAX_ * 2) {
        // The code would decode to a longitude of >= 180 degrees.
        return false;
      }
    }
    return true;
  };

  /**
    Encode a location into an Open Location Code.

    Produces a code of the specified length, or the default length if no length
    is provided.

    The length determines the accuracy of the code. The default length is
    10 characters, returning a code of approximately 13.5x13.5 meters. Longer
    codes represent smaller areas, but lengths > 14 are sub-centimetre and so
    11 or 12 are probably the limit of useful codes.

    Args:
      latitude: A latitude in signed decimal degrees. Will be clipped to the
          range -90 to 90.
      longitude: A longitude in signed decimal degrees. Will be normalised to
          the range -180 to 180.
      codeLength: The number of significant digits in the output code, not
          including any separator characters.
   */
  var encode = OpenLocationCode.encode = function(latitude,
      longitude, codeLength) {
    if (typeof codeLength == 'undefined') {
      codeLength = PAIR_CODE_LENGTH_;
    }
    if (codeLength < 2) {
      throw 'IllegalArgumentException: Invalid Open Location Code length';
    }
    // Ensure that latitude and longitude are valid.
    latitude = clipLatitude(latitude);
    longitude = normalizeLongitude(longitude);
    // Latitude 90 needs to be adjusted to be just less, so the returned code
    // can also be decoded.
    if (latitude == 90) {
      latitude = latitude - computeLatitudePrecision(codeLength);
    }
    var code = PREFIX_ + encodePairs(
        latitude, longitude, Math.min(codeLength, PAIR_CODE_LENGTH_));
    // If the requested length indicates we want grid refined codes.
    if (codeLength > PAIR_CODE_LENGTH_) {
      code += encodeGrid(
          latitude, longitude, codeLength - PAIR_CODE_LENGTH_);
    }
    return code;
  };

  /**
    Decodes an Open Location Code into the location coordinates.

    Returns a CodeArea object that includes the coordinates of the bounding
    box - the lower left, center and upper right.

    Args:
      code: The Open Location Code to decode.

    Returns:
      A CodeArea object that provides the latitude and longitude of two of the
      corners of the area, the center, and the length of the original code.
   */
  var decode = OpenLocationCode.decode = function(code) {
    if (!isFull(code)) {
      throw ('IllegalArgumentException: ' +
          'Passed Open Location Code is not a valid full code: ' + code);
    }
    // Strip off the prefix if it was provided.
    code = code.replace(PREFIX_, '');
    // Strip out separator character (we've already established the code is
    // valid so the maximum is one) and convert to upper case.
    code = code.replace(SEPARATOR_, '').toUpperCase();
    // Decode the lat/lng pair component.
    var codeArea = decodePairs(code.substring(0, PAIR_CODE_LENGTH_));
    // If there is a grid refinement component, decode that.
    if (code.length <= PAIR_CODE_LENGTH_) {
      return codeArea;
    }
    var gridArea = decodeGrid(code.substring(PAIR_CODE_LENGTH_));
    return CodeArea(
      codeArea.latitudeLo + gridArea.latitudeLo,
      codeArea.longitudeLo + gridArea.longitudeLo,
      codeArea.latitudeLo + gridArea.latitudeHi,
      codeArea.longitudeLo + gridArea.longitudeHi,
      codeArea.codeLength + gridArea.codeLength);
  };

  /**
    Recover the nearest matching code to a specified location.

    Given a short Open Location Code of between four and seven characters,
    this recovers the nearest matching full code to the specified location.

    The number of characters that will be prepended to the short code, where S
    is the supplied short code and R are the computed characters, are:
    SSSS    -> RRRR.RRSSSS
    SSSSS   -> RRRR.RRSSSSS
    SSSSSS  -> RRRR.SSSSSS
    SSSSSSS -> RRRR.SSSSSSS
    Note that short codes with an odd number of characters will have their
    last character decoded using the grid refinement algorithm.

    Args:
      shortCode: A valid short OLC character sequence.
      referenceLatitude: The latitude (in signed decimal degrees) to use to
          find the nearest matching full code.
      referenceLongitude: The longitude (in signed decimal degrees) to use
          to find the nearest matching full code.

    Returns:
      The nearest full Open Location Code to the reference location that matches
      the short code. Note that the returned code may not have the same
      computed characters as the reference location. This is because it returns
      the nearest match, not necessarily the match within the same cell. If the
      passed code was not a valid short code, but was a valid full code, it is
      returned unchanged.
   */
  var recoverNearest = OpenLocationCode.recoverNearest = function(
      shortCode, referenceLatitude, referenceLongitude) {
    if (!isShort(shortCode)) {
      if (isFull(shortCode)) {
        return shortCode;
      } else {
        throw 'ValueError: Passed short code is not valid: ' + shortCode;
      }
    }
    // Ensure that latitude and longitude are valid.
    referenceLatitude = clipLatitude(referenceLatitude);
    referenceLongitude = normalizeLongitude(referenceLongitude);
    // Strip off the prefix if it was provided.
    shortCode = shortCode.replace(PREFIX_, '');

    // Compute padding length and adjust for odd-length short codes.
    var paddingLength = PAIR_CODE_LENGTH_ - shortCode.length;
    if (shortCode.length % 2 == 1) {
      paddingLength += 1;
    }
    // The resolution (height and width) of the padded area in degrees.
    var resolution = Math.pow(20, 2 - (paddingLength / 2));
    // Distance from the center to an edge (in degrees).
    var areaToEdge = resolution / 2.0;

    // Now round down the reference latitude and longitude to the resolution.
    var roundedLatitude = Math.floor(referenceLatitude / resolution) *
        resolution;
    var roundedLongitude = Math.floor(referenceLongitude / resolution) *
        resolution;

    // Pad the short code with the rounded reference location.
    var codeArea = decode(
        encode(roundedLatitude, roundedLongitude, paddingLength) + shortCode);
    // How many degrees latitude is the code from the reference? If it is more
    // than half the resolution, we need to move it east or west.
    var degreesDifference = codeArea.latitudeCenter - referenceLatitude;
    if (degreesDifference > areaToEdge) {
      // If the center of the short code is more than half a cell east,
      // then the best match will be one position west.
      codeArea.latitudeCenter -= resolution;
    } else if (degreesDifference < -areaToEdge) {
      // If the center of the short code is more than half a cell west,
      // then the best match will be one position east.
      codeArea.latitudeCenter += resolution;
    }

    // How many degrees longitude is the code from the reference?
    degreesDifference = codeArea.longitudeCenter - referenceLongitude;
    if (degreesDifference > areaToEdge) {
      codeArea.longitudeCenter -= resolution;
    } else if (degreesDifference < -areaToEdge) {
      codeArea.longitudeCenter += resolution;
    }

    return encode(
        codeArea.latitudeCenter, codeArea.longitudeCenter, codeArea.codeLength);
  };

  /**
    Try to remove the first four characters from an OLC code.

    This uses a reference location to determine if the first four characters
    can be removed from the OLC code. The reference location must be within
    +/- 0.25 degrees of the code center. This allows the original code to be
    recovered using this location, with a safety margin.

    Args:
      code: A full, valid code to shorten.
      latitude: A latitude, in signed decimal degrees, to use as the reference
          point.
      longitude: A longitude, in signed decimal degrees, to use as the reference
          point.

    Returns:
      The OLC code with the first four characters removed. If the reference
      location is not close enough, the passed code is returned unchanged.
   */
  var shortenBy4 = OpenLocationCode.shortenBy4 = function(
      code, latitude, longitude) {
    return shortenBy(4, code, latitude, longitude, 0.25);
  };

  /**
    Try to remove the first six characters from an OLC code.

    This uses a reference location to determine if the first six characters
    can be removed from the OLC code. The reference location must be within
    +/- 0.0125 degrees of the code center. This allows the original code to be
    recovered using this location, with a safety margin.

    Args:
      code: A full, valid code to shorten.
      latitude: A latitude, in signed decimal degrees, to use as the reference
          point.
      longitude: A longitude, in signed decimal degrees, to use as the reference
          point.

    Returns:
      The OLC code with the first six characters removed. If the reference
      location is not close enough, the passed code is returned unchanged.
   */
  var shortenBy6 = OpenLocationCode.shortenBy6 = function(
      code, latitude, longitude) {
    return shortenBy(6, code, latitude, longitude, 0.0125);
  };

  /**
    Try to remove the first few characters from an OLC code.

    This uses a reference location to determine if the first few characters
    can be removed from the OLC code. The reference location must be within
    the passed range (in degrees) of the code center. This allows the original
    code to be recovered using this location, with a safety margin.

    Args:
      trimLength: The number of characters to try to remove.
      code: A full, valid code to shorten.
      latitude: A latitude, in signed decimal degrees, to use as the reference
          point.
      longitude: A longitude, in signed decimal degrees, to use as the reference
          point.
      range: The maximum acceptable difference in either latitude or longitude.

    Returns:
      The OLC code with leading characters removed. If the reference
      location is not close enough, the passed code is returned unchanged.
   */
  var shortenBy = function(trimLength, code, latitude, longitude, range) {
    if (!isFull(code)) {
      throw 'ValueError: Passed code is not valid and full: ' + code;
    }
    var codeArea = decode(code);
    if (codeArea.codeLength < MIN_TRIMMABLE_CODE_LEN_ ||
        codeArea.codeLength > MAX_TRIMMABLE_CODE_LEN_) {
      throw 'ValueError: Code length must be between ' +
          MIN_TRIMMABLE_CODE_LEN_ + ' and ' + MAX_TRIMMABLE_CODE_LEN_;
    }
    // Ensure that latitude and longitude are valid.
    latitude = clipLatitude(latitude);
    longitude = normalizeLongitude(longitude);
    // Are the latitude and longitude close enough?
    if (Math.abs(codeArea.latitudeCenter - latitude) > range ||
        Math.abs(codeArea.longitudeCenter - longitude) > range) {
      // No they're not, so return the original code.
      return code;
    }
    // They are, so we can trim the required number of characters from the
    // code. But first we strip the prefix and separator and convert to upper
    // case.
    var newCode = code.replace(PREFIX_, '').
        replace(SEPARATOR_, '').toUpperCase();
    // And trim the characters, adding one to avoid the prefix.
    return PREFIX_ + newCode.substring(trimLength);
  };

  /**
    Clip a latitude into the range -90 to 90.

    Args:
      latitude: A latitude in signed decimal degrees.
   */
  var clipLatitude = function(latitude) {
    return Math.min(90, Math.max(-90, latitude));
  };

  /**
    Compute the latitude precision value for a given code length. Lengths <=
    10 have the same precision for latitude and longitude, but lengths > 10
    have different precisions due to the grid method having fewer columns than
    rows.
   */
  var computeLatitudePrecision = function(codeLength) {
    if (codeLength <= 10) {
      return Math.pow(20, Math.floor(codeLength / -2 + 2));
    }
    return Math.pow(20, -3) / Math.pow(GRID_ROWS_, codeLength - 10);
  };

  /**
    Normalize a longitude into the range -180 to 180, not including 180.

    Args:
      longitude: A longitude in signed decimal degrees.
   */
  var normalizeLongitude = function(longitude) {
    while (longitude < -180) {
      longitude = longitude + 360;
    }
    while (longitude >= 180) {
      longitude = longitude - 360;
    }
    return longitude;
  };

  /**
    Encode a location into a sequence of OLC lat/lng pairs.

    This uses pairs of characters (longitude and latitude in that order) to
    represent each step in a 20x20 grid. Each code, therefore, has 1/400th
    the area of the previous code.

    Args:
      latitude: A latitude in signed decimal degrees.
      longitude: A longitude in signed decimal degrees.
      codeLength: The number of significant digits in the output code, not
          including any separator characters.
   */
  var encodePairs = function(latitude, longitude, codeLength) {
    var code = '';
    // Adjust latitude and longitude so they fall into positive ranges.
    var adjustedLatitude = latitude + LATITUDE_MAX_;
    var adjustedLongitude = longitude + LONGITUDE_MAX_;
    // Count digits - can't use string length because it may include a separator
    // character.
    var digitCount = 0;
    while (digitCount < codeLength) {
      // Provides the value of digits in this place in decimal degrees.
      var placeValue = PAIR_RESOLUTIONS_[Math.floor(digitCount / 2)];
      // Do the latitude - gets the digit for this place and subtracts that for
      // the next digit.
      var digitValue = Math.floor(adjustedLatitude / placeValue);
      adjustedLatitude -= digitValue * placeValue;
      code += CODE_ALPHABET_.charAt(digitValue);
      digitCount += 1;
      if (digitCount == codeLength) {
        break;
      }
      // And do the longitude - gets the digit for this place and subtracts that
      // for the next digit.
      digitValue = Math.floor(adjustedLongitude / placeValue);
      adjustedLongitude -= digitValue * placeValue;
      code += CODE_ALPHABET_.charAt(digitValue);
      digitCount += 1;
      // Should we add a separator here?
      if (digitCount == SEPARATOR_POSITION_ && digitCount < codeLength) {
        code += SEPARATOR_;
      }
    }
    return code;
  };

  /**
    Encode a location using the grid refinement method into an OLC string.

    The grid refinement method divides the area into a grid of 4x5, and uses a
    single character to refine the area. This allows default accuracy OLC codes
    to be refined with just a single character.

    Args:
      latitude: A latitude in signed decimal degrees.
      longitude: A longitude in signed decimal degrees.
      codeLength: The number of characters required.
   */
  var encodeGrid = function(latitude, longitude, codeLength) {
    var code = '';
    var latPlaceValue = GRID_SIZE_DEGREES_;
    var lngPlaceValue = GRID_SIZE_DEGREES_;
    // Adjust latitude and longitude so they fall into positive ranges and
    // get the offset for the required places.
    var adjustedLatitude = (latitude + LATITUDE_MAX_) % latPlaceValue;
    var adjustedLongitude = (longitude + LONGITUDE_MAX_) % lngPlaceValue;
    for (var i = 0; i < codeLength; i++) {
      // Work out the row and column.
      var row = Math.floor(adjustedLatitude / (latPlaceValue / GRID_ROWS_));
      var col = Math.floor(adjustedLongitude / (lngPlaceValue / GRID_COLUMNS_));
      latPlaceValue /= GRID_ROWS_;
      lngPlaceValue /= GRID_COLUMNS_;
      adjustedLatitude -= row * latPlaceValue;
      adjustedLongitude -= col * lngPlaceValue;
      code += CODE_ALPHABET_.charAt(row * GRID_COLUMNS_ + col);
    }
    return code;
  };

  /**
    Decode an OLC code made up of lat/lng pairs.

    This decodes an OLC code made up of alternating latitude and longitude
    characters, encoded using base 20.

    Args:
      code: A valid OLC code, presumed to be full, but with the separator
      removed.
   */
  var decodePairs = function(code) {
    // Get the latitude and longitude values. These will need correcting from
    // positive ranges.
    var latitude = decodePairsSequence(code, 0);
    var longitude = decodePairsSequence(code, 1);
    // Correct the values and set them into the CodeArea object.
    return new CodeArea(
        latitude[0] - LATITUDE_MAX_,
        longitude[0] - LONGITUDE_MAX_,
        latitude[1] - LATITUDE_MAX_,
        longitude[1] - LONGITUDE_MAX_,
        code.length);
  };

  /**
    Decode either a latitude or longitude sequence.

    This decodes the latitude or longitude sequence of a lat/lng pair encoding.
    Starting at the character at position offset, every second character is
    decoded and the value returned.

    Args:
      code: A valid OLC code, presumed to be full, with the separator removed.
      offset: The character to start from.

    Returns:
      A pair of the low and high values. The low value comes from decoding the
      characters. The high value is the low value plus the resolution of the
      last position. Both values are offset into positive ranges and will need
      to be corrected before use.
   */
  var decodePairsSequence = function(code, offset) {
    var i = 0;
    var value = 0;
    while (i * 2 + offset < code.length) {
      value += CODE_ALPHABET_.indexOf(code.charAt(i * 2 + offset)) *
          PAIR_RESOLUTIONS_[i];
      i += 1;
    }
    return [value, value + PAIR_RESOLUTIONS_[i - 1]];
  };

  /**
    Decode the grid refinement portion of an OLC code.

    This decodes an OLC code using the grid refinement method.

    Args:
      code: A valid OLC code sequence that is only the grid refinement
          portion. This is the portion of a code starting at position 11.
   */
  var decodeGrid = function(code) {
    var latitudeLo = 0.0;
    var longitudeLo = 0.0;
    var latPlaceValue = GRID_SIZE_DEGREES_;
    var lngPlaceValue = GRID_SIZE_DEGREES_;
    var i = 0;
    while (i < code.length) {
      var codeIndex = CODE_ALPHABET_.indexOf(code.charAt(i));
      var row = Math.floor(codeIndex / GRID_COLUMNS_);
      var col = codeIndex % GRID_COLUMNS_;

      latPlaceValue /= GRID_ROWS_;
      lngPlaceValue /= GRID_COLUMNS_;

      latitudeLo += row * latPlaceValue;
      longitudeLo += col * lngPlaceValue;
      i += 1;
    }
    return CodeArea(
        latitudeLo, longitudeLo, latitudeLo + latPlaceValue,
        longitudeLo + lngPlaceValue, code.length);
  };

  /**
    Coordinates of a decoded Open Location Code.

    The coordinates include the latitude and longitude of the lower left and
    upper right corners and the center of the bounding box for the area the
    code represents.

    Attributes:
      latitude_lo: The latitude of the SW corner in degrees.
      longitude_lo: The longitude of the SW corner in degrees.
      latitude_hi: The latitude of the NE corner in degrees.
      longitude_hi: The longitude of the NE corner in degrees.
      latitude_center: The latitude of the center in degrees.
      longitude_center: The longitude of the center in degrees.
      code_length: The number of significant characters that were in the code.
          This excludes the separator.
   */
  var CodeArea = OpenLocationCode.CodeArea = function(
    latitudeLo, longitudeLo, latitudeHi, longitudeHi, codeLength) {
    return new OpenLocationCode.CodeArea.fn.init(
        latitudeLo, longitudeLo, latitudeHi, longitudeHi, codeLength);
  };
  CodeArea.fn = CodeArea.prototype = {
    init: function(
        latitudeLo, longitudeLo, latitudeHi, longitudeHi, codeLength) {
      this.latitudeLo = latitudeLo;
      this.longitudeLo = longitudeLo;
      this.latitudeHi = latitudeHi;
      this.longitudeHi = longitudeHi;
      this.codeLength = codeLength;
      this.latitudeCenter = Math.min(
          latitudeLo + (latitudeHi - latitudeLo) / 2, LATITUDE_MAX_);
      this.longitudeCenter = Math.min(
          longitudeLo + (longitudeHi - longitudeLo) / 2, LONGITUDE_MAX_);
    }
  };
  CodeArea.fn.init.prototype = CodeArea.fn;
})(window || this);
