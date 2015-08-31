library open_location_code.base;

import 'dart:math';

/// A separator used to break the code into two parts to aid memorability.
const SEPARATOR = '+'; // 43 Ascii

/// The number of characters to place before the separator.
const int SEPARATOR_POSITION = 8;

/// The character used to pad codes.
const String PADDING = '0'; // 48 in Ascii

/// The character set used to encode the values.
const String CODE_ALPHABET = '23456789CFGHJMPQRVWX';

/// The base to use to convert numbers to/from.
const int ENCODING_BASE = CODE_ALPHABET.length;

/// The maximum value for latitude in degrees.
const int LATITUDE_MAX = 90;

/// The maximum value for longitude in degrees.
const int LONGITUDE_MAX = 180;

/// Maximum code length using lat/lng pair encoding. The area of such a
/// code is approximately 13x13 meters (at the equator), and should be suitable
/// for identifying buildings. This excludes prefix and separator characters.
const int PAIR_CODE_LENGTH = 10;

/// The resolution values in degrees for each position in the lat/lng pair
/// encoding. These give the place value of each position, and therefore the
/// dimensions of the resulting area.
List<double> PAIR_RESOLUTIONS = [20.0, 1.0, .05, .0025, .000125];

/// Number of columns in the grid refinement method.
const int GRID_COLUMNS = 4;

/// Number of rows in the grid refinement method.
const int GRID_ROWS = 5;

/// Size of the initial grid in degrees.
const double GRID_SIZE_DEGREES = 0.000125;

/// Minimum length of a code that can be shortened.
const int MIN_TRIMMABLE_CODE_LEN = 6;

/// Decoder lookup table.
///
/// * -2: illegal.
/// * -1: Padding or Separator
/// * >= 0: index in the alphabet.
const List<int> decode_ = const [
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -2, -2, -2, -2,  //
    -1, -2,  0,  1,  2,  3,  4,  5,  6,  7, -2, -2, -2, -2, -2, -2,  //
    -2, -2, -2,  8, -2, -2,  9, 10, 11, -2, 12, -2, -2, 13, -2, -2,  //
    14, 15, 16, -2, -2, -2, 17, 18, 19, -2, -2, -2, -2, -2, -2, -2,  //
    -2, -2, -2,  8, -2, -2,  9, 10, 11, -2, 12, -2, -2, 13, -2, -2,  //
    14, 15, 16, -2, -2, -2, 17, 18, 19, -2, -2, -2, -2, -2, -2, -2,];//

class OpenLocationCode {

  bool isValid(String code) {
    if (code == null || code.length == 1) {
      return false;
    }

    int separatorIndex = code.indexOf(SEPARATOR);
    // There must be a single separator at an even index and position should be < SEPARATOR_POSITION.
    if (separatorIndex == -1 ||
        separatorIndex != code.lastIndexOf(SEPARATOR) ||
        separatorIndex > SEPARATOR_POSITION ||
        separatorIndex % 2 == 1) {
      return false;
    }

    // We can have an even number of padding characters before the separator,
    // but then it must be the final character.
    if (code.indexOf(PADDING) > -1) {
      // Not allowed to start with them!
      if (code.indexOf(PADDING) == 0) {
        return false;
      }
      // There can only be one group and it must have even length.
      List<Match> padMatch = new RegExp('($PADDING+)').allMatches(code).toList();
      if (padMatch.length != 1) {
        return false;
      }
      String match = padMatch[0].group(0);
      if (match.length % 2 == 1 || match.length > SEPARATOR_POSITION - 2) {
        return false;
      }
      // If the code is long enough to end with a separator, make sure it does.
      if (code[code.length - 1] != SEPARATOR) {
        return false;
      }
    }
    // If there are characters after the separator, make sure there isn't just
    // one of them (not legal).
    if (code.length - separatorIndex - 1 == 1) {
      return false;
    }

    // Check code contains only valid characters.
    for (int ch in code.codeUnits) {
      if (ch > decode_.length || decode_[ch] < -1) {
        return false;
      }
    }
    return true;
  }

  double clipLatitude(double latitude) => min(90.0, max(-90.0, latitude));

  /// Compute the latitude precision value for a given code length.
  ///
  /// Lengths <= 10 have the same precision for latitude and longitude, but
  /// lengths > 10 have different precisions due to the grid method having fewer
  /// columns than rows.
  int computeLatitudePrecision(int codeLength) {
    if (codeLength <= 10) {
      return pow(20, (codeLength ~/ -2) + 2);
    }
    return pow(20, -3) ~/ pow(GRID_ROWS, codeLength - 10);
  }

  /// Normalize a [longitude] into the range -180 to 180, not including 180.
  double normalizeLongitude(double longitude) {
    while (longitude < -180) {
      longitude += 360;
    }
    while (longitude >= 180) {
      longitude -= 360;
    }
    return longitude;
  }

  /// Determines if a [code] is a valid short code.
  ///
  /// A short Open Location Code is a sequence created by removing four or more
  /// digits from an Open Location Code. It must include a separator character.
  bool isShort(String code) {
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

  /// Determines if a [code] is a valid full Open Location Code.
  ///
  /// Not all possible combinations of Open Location Code characters decode to
  /// valid latitude and longitude values. This checks that a code is valid
  /// and also that the latitude and longitude values are legal. If the prefix
  /// character is present, it must be the first character. If the separator
  /// character is present, it must be after four characters.
  bool isFull(String code) {
    if (!isValid(code)) {
      return false;
    }
    // If it's short, it's not full.
    if (isShort(code)) {
      return false;
    }
    // Work out what the first latitude character indicates for latitude.
    var firstLatValue = decode_[code.codeUnitAt(0)] * ENCODING_BASE;
    if (firstLatValue >= LATITUDE_MAX * 2) {
      // The code would decode to a latitude of >= 90 degrees.
      return false;
    }
    if (code.length > 1) {
      // Work out what the first longitude character indicates for longitude.
      var firstLngValue = decode_[code.codeUnitAt(1)] * ENCODING_BASE;
      if (firstLngValue >= LONGITUDE_MAX * 2) {
        // The code would decode to a longitude of >= 180 degrees.
        return false;
      }
    }
    return true;
  }

  /// Encode a location into an Open Location Code.
  ///
  /// Produces a code of the specified length, or the default length if no
  /// length is provided.
  /// The length determines the accuracy of the code. The default length is
  /// 10 characters, returning a code of approximately 13.5x13.5 meters. Longer
  /// codes represent smaller areas, but lengths > 14 are sub-centimetre and so
  /// 11 or 12 are probably the limit of useful codes.
  ///
  /// Args:
  ///
  /// * [latitude]: A latitude in signed decimal degrees. Will be clipped to the
  /// range -90 to 90.
  /// * [longitude]: A longitude in signed decimal degrees. Will be normalised
  /// to the range -180 to 180.
  /// * [codeLength]: The number of significant digits in the output code, not
  /// including any separator characters.

  String encode(double latitude, double longitude,
      {int codeLength: PAIR_CODE_LENGTH}) {
    if (codeLength < 2 ||
        (codeLength < SEPARATOR_POSITION && codeLength % 2 == 1)) {
      throw new ArgumentError('Invalid Open Location Code length: $codeLength');
    }
    // Ensure that latitude and longitude are valid.
    latitude = clipLatitude(latitude);
    longitude = normalizeLongitude(longitude);
    // Latitude 90 needs to be adjusted to be just less, so the returned code
    // can also be decoded.
    if (latitude == 90) {
      latitude = latitude - computeLatitudePrecision(codeLength).toDouble();
    }
    var code =
        encodePairs(latitude, longitude, min(codeLength, PAIR_CODE_LENGTH));
    // If the requested length indicates we want grid refined codes.
    if (codeLength > PAIR_CODE_LENGTH) {
      code += encodeGrid(latitude, longitude, codeLength - PAIR_CODE_LENGTH);
    }
    return code;
  }

  /// Decodes an Open Location Code into the location coordinates.
  ///
  /// Returns a [CodeArea] object that includes the coordinates of the bounding
  /// box - the lower left, center and upper right.
  CodeArea decode(String code) {
    if (!isFull(code)) {
      throw new ArgumentError(
          'Passed Open Location Code is not a valid full code: $code');
    }
    // Strip out separator character (we've already established the code is
    // valid so the maximum is one), padding characters and convert to upper
    // case.
    code = code.replaceAll(SEPARATOR, '');
    code = code.replaceAll(new RegExp('$PADDING+'), '');
    code = code.toUpperCase();
    // Decode the lat/lng pair component.
    var codeArea = decodePairs(code.substring(0, min(code.length, PAIR_CODE_LENGTH)));
    // If there is a grid refinement component, decode that.
    if (code.length <= PAIR_CODE_LENGTH) {
      return codeArea;
    }
    var gridArea = decodeGrid(code.substring(PAIR_CODE_LENGTH));
    return new CodeArea(codeArea.latitudeLo + gridArea.latitudeLo,
        codeArea.longitudeLo + gridArea.longitudeLo,
        codeArea.latitudeLo + gridArea.latitudeHi,
        codeArea.longitudeLo + gridArea.longitudeHi,
        codeArea.codeLength + gridArea.codeLength);
  }

  /// Recover the nearest matching code to a specified location.
  ///
  /// Given a short Open Location Code of between four and seven characters,
  /// this recovers the nearest matching full code to the specified location.
  /// The number of characters that will be prepended to the short code, depends
  /// on the length of the short code and whether it starts with the separator.
  /// If it starts with the separator, four characters will be prepended. If it
  /// does not, the characters that will be prepended to the short code, where S
  /// is the supplied short code and R are the computed characters, are as
  /// follows:
  ///
  /// * SSSS    -> RRRR.RRSSSS
  /// * SSSSS   -> RRRR.RRSSSSS
  /// * SSSSSS  -> RRRR.SSSSSS
  /// * SSSSSSS -> RRRR.SSSSSSS
  ///
  /// Note that short codes with an odd number of characters will have their
  /// last character decoded using the grid refinement algorithm.
  ///
  /// Args:
  ///
  /// * [shortCode]: A valid short OLC character sequence.
  /// * [referenceLatitude]: The latitude (in signed decimal degrees) to use to
  /// find the nearest matching full code.
  /// * [referenceLongitude]: The longitude (in signed decimal degrees) to use
  ///  to find the nearest matching full code.
  ///
  /// It returns the nearest full Open Location Code to the reference location
  /// that matches the [shortCode]. Note that the returned code may not have the
  /// same computed characters as the reference location (provided by
  /// [referenceLatitude] and [referenceLongitude]). This is because it returns
  /// the nearest match, not necessarily the match within the same cell. If the
  /// passed code was not a valid short code, but was a valid full code, it is
  /// returned unchanged.
  String recoverNearest(
      String shortCode, double referenceLatitude, double referenceLongitude) {
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

    // Clean up the passed code.
    shortCode = shortCode.toUpperCase();
    // Compute the number of digits we need to recover.
    var paddingLength = SEPARATOR_POSITION - shortCode.indexOf(SEPARATOR);
    // The resolution (height and width) of the padded area in degrees.
    var resolution = pow(20, 2 - (paddingLength / 2));
    // Distance from the center to an edge (in degrees).
    var areaToEdge = resolution / 2.0;

    // Now round down the reference latitude and longitude to the resolution.
    var roundedLatitude = (referenceLatitude / resolution).floor() * resolution;
    var roundedLongitude =
        (referenceLongitude / resolution).floor() * resolution;

    // Use the reference location to pad the supplied short code and decode it.
    CodeArea codeArea = decode(
        encode(roundedLatitude, roundedLongitude).substring(0, paddingLength) +
            shortCode);
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

    return encode(codeArea.latitudeCenter, codeArea.longitudeCenter,
        codeLength: codeArea.codeLength);
  }

  /// Remove characters from the start of an OLC [code].
  ///
  /// This uses a reference location to determine how many initial characters
  /// can be removed from the OLC code. The number of characters that can be
  /// removed depends on the distance between the code center and the reference
  /// location.
  /// The minimum number of characters that will be removed is four. If more
  /// than four characters can be removed, the additional characters will be
  /// replaced with the padding character. At most eight characters will be
  /// removed.
  /// The reference location must be within 50% of the maximum range. This
  /// ensures that the shortened code will be able to be recovered using
  /// slightly different locations.
  ///
  /// It returns either the original code, if the reference location was not
  /// close enough, or the .
  String shorten(String code, double latitude, double longitude) {
    if (!isFull(code)) {
      throw new ArgumentError(
          'ValueError: Passed code is not valid and full: $code');
    }
    if (code.indexOf(PADDING) != -1) {
      throw new ArgumentError('ValueError: Cannot shorten padded codes: $code');
    }
    code = code.toUpperCase();
    var codeArea = decode(code);
    if (codeArea.codeLength < MIN_TRIMMABLE_CODE_LEN) {
      throw new RangeError(
          'ValueError: Code length must be at least $MIN_TRIMMABLE_CODE_LEN');
    }
    // Ensure that latitude and longitude are valid.
    latitude = clipLatitude(latitude);
    longitude = normalizeLongitude(longitude);
    // How close are the latitude and longitude to the code center.
    var range = max((codeArea.latitudeCenter - latitude).abs(),
        (codeArea.longitudeCenter - longitude).abs());
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

  /// Encode a location into a sequence of OLC lat/lng pairs.
  ///
  /// This uses pairs of characters (longitude and latitude in that order) to
  /// represent each step in a 20x20 grid. Each code, therefore, has 1/400th
  /// the area of the previous code.
  ///
  /// Args:
  ///
  /// * [latitude]: A latitude in signed decimal degrees.
  /// * [longitude]: A longitude in signed decimal degrees.
  /// * [codeLength]: The number of significant digits in the output code, not
  ///  including any separator characters.
  String encodePairs(double latitude, double longitude, int codeLength) {
    var code = '';
    // Adjust latitude and longitude so they fall into positive ranges.
    var adjustedLatitude = latitude + LATITUDE_MAX;
    var adjustedLongitude = longitude + LONGITUDE_MAX;
    // Count digits - can't use string length because it may include a separator
    // character.
    var digitCount = 0;
    while (digitCount < codeLength) {
      // Provides the value of digits in this place in decimal degrees.
      var placeValue = PAIR_RESOLUTIONS[digitCount ~/ 2];
      // Do the latitude - gets the digit for this place and subtracts that for
      // the next digit.
      var digitValue = adjustedLatitude ~/ placeValue;
      adjustedLatitude -= digitValue * placeValue;
      code += CODE_ALPHABET[digitValue];
      digitCount++;
      // And do the longitude - gets the digit for this place and subtracts that
      // for the next digit.
      digitValue = adjustedLongitude ~/ placeValue;
      adjustedLongitude -= digitValue * placeValue;
      code += CODE_ALPHABET[digitValue];
      digitCount++;
      // Should we add a separator here?
      if (digitCount == SEPARATOR_POSITION && digitCount < codeLength) {
        code += SEPARATOR;
      }
    }
    // If necessary, Add padding.
    if (code.length < SEPARATOR_POSITION) {
      code = code + (PADDING * (SEPARATOR_POSITION - code.length));
    }
    if (code.length == SEPARATOR_POSITION) {
      code = code + SEPARATOR;
    }
    return code;
  }

  /// Encode a location using the grid refinement method into an OLC string.
  ///
  /// The grid refinement method divides the area into a grid of 4x5, and uses a
  /// single character to refine the area. This allows default accuracy OLC
  /// codes to be refined with just a single character.
  ///
  /// Args:
  ///
  /// * [latitude]: A latitude in signed decimal degrees.
  /// * [longitude]: A longitude in signed decimal degrees.
  /// * [codeLength]: The number of characters required.
  String encodeGrid(double latitude, double longitude, int codeLength) {
    var code = '';
    var latPlaceValue = GRID_SIZE_DEGREES;
    var lngPlaceValue = GRID_SIZE_DEGREES;
    // Adjust latitude and longitude so they fall into positive ranges and
    // get the offset for the required places.
    var adjustedLatitude = (latitude + LATITUDE_MAX) % latPlaceValue;
    var adjustedLongitude = (longitude + LONGITUDE_MAX) % lngPlaceValue;
    for (var i = 0; i < codeLength; i++) {
      // Work out the row and column.
      var row = (adjustedLatitude / (latPlaceValue / GRID_ROWS)).floor();
      var col = (adjustedLongitude / (lngPlaceValue / GRID_COLUMNS)).floor();
      latPlaceValue /= GRID_ROWS;
      lngPlaceValue /= GRID_COLUMNS;
      adjustedLatitude -= row * latPlaceValue;
      adjustedLongitude -= col * lngPlaceValue;
      code += CODE_ALPHABET[row * GRID_COLUMNS + col];
    }
    return code;
  }

  /// Decode an OLC code made up of lat/lng pairs.
  ///
  /// This decodes an OLC code made up of alternating latitude and longitude
  /// characters, encoded using base 20.
  ///
  /// Args:
  ///
  /// * [code]: A valid OLC code, presumed to be full, but with the separator
  /// removed.
  CodeArea decodePairs(String code) {
    // Get the latitude and longitude values. These will need correcting from
    // positive ranges.
    var latitude = decodePairsSequence(code, 0.0);
    var longitude = decodePairsSequence(code, 1.0);
    // Correct the values and set them into the CodeArea object.
    return new CodeArea(latitude[0] - LATITUDE_MAX,
        longitude[0] - LONGITUDE_MAX, latitude[1] - LATITUDE_MAX,
        longitude[1] - LONGITUDE_MAX, code.length);
  }

  /// Decode either a latitude or longitude sequence.
  ///
  /// This decodes the latitude or longitude sequence of a lat/lng pair
  /// encoding. Starting at the character at position offset, every second
  /// character is decoded and the value returned.
  ///
  /// Args:
  ///
  /// * [code]: A valid OLC code, presumed to be full, with the separator
  /// removed.
  /// * [offset]: The character to start from.
  ///
  /// It returns a pair of the low and high values. The low value comes from
  /// decoding the characters. The high value is the low value plus the
  /// resolution of the last position. Both values are offset into positive
  /// ranges and will need to be corrected before use.
  List<double> decodePairsSequence(String code, double offset) {
    int i = 0;
    num value = 0;
    while (i * 2 + offset < code.length) {
      value += decode_[code.codeUnitAt(i * 2 + offset.floor())] * PAIR_RESOLUTIONS[i];
      i += 1;
    }
    return [value, value + PAIR_RESOLUTIONS[i - 1]];
  }

  /// Decode the grid refinement portion of an OLC code.
  ///
  /// This decodes an OLC code using the grid refinement method.
  ///
  /// Args:
  ///
  /// * [code]: A valid OLC code sequence that is only the grid refinement
  /// portion. This is the portion of a code starting at position 11.
  CodeArea decodeGrid(String code) {
    var latitudeLo = 0.0;
    var longitudeLo = 0.0;
    var latPlaceValue = GRID_SIZE_DEGREES;
    var lngPlaceValue = GRID_SIZE_DEGREES;
    var i = 0;
    while (i < code.length) {
      var codeIndex = decode_[code.codeUnitAt(i)];
      var row = (codeIndex / GRID_COLUMNS).floor();
      var col = codeIndex % GRID_COLUMNS;

      latPlaceValue /= GRID_ROWS;
      lngPlaceValue /= GRID_COLUMNS;

      latitudeLo += row * latPlaceValue;
      longitudeLo += col * lngPlaceValue;
      i += 1;
    }
    return new CodeArea(latitudeLo, longitudeLo, latitudeLo + latPlaceValue,
        longitudeLo + lngPlaceValue, code.length);
  }
}

/// Coordinates of a decoded Open Location Code.
///
/// The coordinates include the latitude and longitude of the lower left and
/// upper right corners and the center of the bounding box for the area the
/// code represents.
class CodeArea {
  double latitudeLo;
  double longitudeLo;
  double latitudeHi;
  double longitudeHi;
  double latitudeCenter;
  double longitudeCenter;
  int codeLength;

  /// Create a [CodeArea].
  ///
  /// Args:
  ///
  /// *[latitude_lo]: The latitude of the SW corner in degrees.
  /// *[longitude_lo]: The longitude of the SW corner in degrees.
  /// *[latitude_hi]: The latitude of the NE corner in degrees.
  /// *[longitude_hi]: The longitude of the NE corner in degrees.
  /// *[latitude_center]: The latitude of the center in degrees.
  /// *[longitude_center]: The longitude of the center in degrees.
  /// *[code_length]: The number of significant characters that were in the code.
  /// This excludes the separator.
  CodeArea(this.latitudeLo, this.longitudeLo, this.latitudeHi, this.longitudeHi,
      this.codeLength) {
    latitudeCenter =
        min(latitudeLo + (latitudeHi - latitudeLo) / 2, LATITUDE_MAX);
    longitudeCenter =
        min(longitudeLo + (longitudeHi - longitudeLo) / 2, LONGITUDE_MAX);
  }

  String toString() {
    return "latLo: $latitudeLo longLo: $longitudeLo latHi: $latitudeHi longHi: $longitudeHi codelen: $codeLength";
  }
}
