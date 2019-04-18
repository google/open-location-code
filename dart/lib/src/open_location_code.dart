/*
 Copyright 2015 Google Inc. All rights reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

library open_location_code.src.open_location_code;

import 'dart:math';

/// A separator used to break the code into two parts to aid memorability.
const separator = '+'; // 43 Ascii

/// The number of characters to place before the separator.
const separatorPosition = 8;

/// The character used to pad codes.
const padding = '0'; // 48 in Ascii

/// The character set used to encode the values.
const codeAlphabet = '23456789CFGHJMPQRVWX';

/// The base to use to convert numbers to/from.
const encodingBase = codeAlphabet.length;

/// The maximum value for latitude in degrees.
const latitudeMax = 90;

/// The maximum value for longitude in degrees.
const longitudeMax = 180;

// The max number of digits to process in a plus code.
const maxDigitCount = 15;

/// Maximum code length using lat/lng pair encoding. The area of such a
/// code is approximately 13x13 meters (at the equator), and should be suitable
/// for identifying buildings. This excludes prefix and separator characters.
const pairCodeLength = 10;

/// The resolution values in degrees for each position in the lat/lng pair
/// encoding. These give the place value of each position, and therefore the
/// dimensions of the resulting area.
const pairResolutions = const <double>[20.0, 1.0, .05, .0025, .000125];

/// Number of columns in the grid refinement method.
const gridColumns = 4;

/// Number of rows in the grid refinement method.
const gridRows = 5;

/// Size of the initial grid in degrees.
const gridSizeDegrees = 0.000125;

/// Minimum length of a code that can be shortened.
const minTrimmableCodeLen = 6;

/// Decoder lookup table.
///
/// * -2: illegal.
/// * -1: Padding or Separator
/// * >= 0: index in the alphabet.
const _decode = const <int>[
  -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, //
  -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, //
  -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -2, -2, -2, -2, //
  -1, -2, 0, 1, 2, 3, 4, 5, 6, 7, -2, -2, -2, -2, -2, -2, //
  -2, -2, -2, 8, -2, -2, 9, 10, 11, -2, 12, -2, -2, 13, -2, -2, //
  14, 15, 16, -2, -2, -2, 17, 18, 19, -2, -2, -2, -2, -2, -2, -2, //
  -2, -2, -2, 8, -2, -2, 9, 10, 11, -2, 12, -2, -2, 13, -2, -2, //
  14, 15, 16, -2, -2, -2, 17, 18, 19, -2, -2, -2, -2, -2, -2, -2,
]; //

bool _matchesPattern(String string, Pattern pattern) =>
    string.indexOf(pattern) >= 0;

bool isValid(String code) {
  if (code == null || code.length == 1) {
    return false;
  }

  int separatorIndex = code.indexOf(separator);
  // There must be a single separator at an even index and position should be < SEPARATOR_POSITION.
  if (separatorIndex == -1 ||
      separatorIndex != code.lastIndexOf(separator) ||
      separatorIndex > separatorPosition ||
      separatorIndex.isOdd) {
    return false;
  }

  // We can have an even number of padding characters before the separator,
  // but then it must be the final character.
  if (_matchesPattern(code, padding)) {
    // Not allowed to start with them!
    if (code.indexOf(padding) == 0) {
      return false;
    }
    // There can only be one group and it must have even length.
    var padMatch = RegExp('($padding+)').allMatches(code).toList();
    if (padMatch.length != 1) {
      return false;
    }
    var matchLength = padMatch.first.group(0).length;
    if (matchLength.isOdd || matchLength > separatorPosition - 2) {
      return false;
    }
    // If the code is long enough to end with a separator, make sure it does.
    if (!code.endsWith(separator)) {
      return false;
    }
  }
  // If there are characters after the separator, make sure there isn't just
  // one of them (not legal).
  if (code.length - separatorIndex - 1 == 1) {
    return false;
  }

  // Check code contains only valid characters.
  var filterCallback = (ch) => !(ch > _decode.length || _decode[ch] < -1);
  return code.codeUnits.every(filterCallback);
}

num clipLatitude(num latitude) => latitude.clamp(-90.0, 90.0);

/// Compute the latitude precision value for a given code length.
///
/// Lengths <= 10 have the same precision for latitude and longitude, but
/// lengths > 10 have different precisions due to the grid method having fewer
/// columns than rows.
num computeLatitudePrecision(int codeLength) {
  if (codeLength <= 10) {
    return pow(encodingBase, (codeLength ~/ -2) + 2);
  }
  return pow(encodingBase, -3) ~/ pow(gridRows, codeLength - 10);
}

/// Normalize a [longitude] into the range -180 to 180, not including 180.
num normalizeLongitude(num longitude) {
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
  if (_matchesPattern(code, separator) &&
      code.indexOf(separator) < separatorPosition) {
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
  var firstLatValue = _decode[code.codeUnitAt(0)] * encodingBase;
  if (firstLatValue >= latitudeMax * 2) {
    // The code would decode to a latitude of >= 90 degrees.
    return false;
  }
  if (code.length > 1) {
    // Work out what the first longitude character indicates for longitude.
    var firstLngValue = _decode[code.codeUnitAt(1)] * encodingBase;
    if (firstLngValue >= longitudeMax * 2) {
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
String encode(num latitude, num longitude, {int codeLength = pairCodeLength}) {
  if (codeLength < 2 || (codeLength < pairCodeLength && codeLength.isOdd)) {
    throw ArgumentError('Invalid Open Location Code length: $codeLength');
  }
  codeLength = min(maxDigitCount, codeLength);
  // Ensure that latitude and longitude are valid.
  latitude = clipLatitude(latitude);
  longitude = normalizeLongitude(longitude);
  // Latitude 90 needs to be adjusted to be just less, so the returned code
  // can also be decoded.
  if (latitude == 90) {
    latitude -= computeLatitudePrecision(codeLength).toDouble();
  }
  var code = encodePairs(latitude, longitude, min(codeLength, pairCodeLength));
  // If the requested length indicates we want grid refined codes.
  if (codeLength > pairCodeLength) {
    code += encodeGrid(latitude, longitude, codeLength - pairCodeLength);
  }
  return code;
}

/// Decodes an Open Location Code into the location coordinates.
///
/// Returns a [CodeArea] object that includes the coordinates of the bounding
/// box - the lower left, center and upper right.
CodeArea decode(String code) {
  if (!isFull(code)) {
    throw ArgumentError(
        'Passed Open Location Code is not a valid full code: $code');
  }
  // Strip out separator character (we've already established the code is
  // valid so the maximum is one), padding characters and convert to upper
  // case.
  code = code.replaceAll(separator, '');
  code = code.replaceAll(RegExp('$padding+'), '');
  code = code.toUpperCase();
  // Decode the lat/lng pair component.
  var codeArea =
      decodePairs(code.substring(0, min(code.length, pairCodeLength)));
  // If there is a grid refinement component, decode that.
  if (code.length <= pairCodeLength) {
    return codeArea;
  }
  var gridArea = decodeGrid(
      code.substring(pairCodeLength, min(code.length, maxDigitCount)));
  return CodeArea(
      codeArea.south + gridArea.south,
      codeArea.west + gridArea.west,
      codeArea.south + gridArea.north,
      codeArea.west + gridArea.east,
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
    String shortCode, num referenceLatitude, num referenceLongitude) {
  if (!isShort(shortCode)) {
    if (isFull(shortCode)) {
      return shortCode.toUpperCase();
    } else {
      throw ArgumentError('Passed short code is not valid: $shortCode');
    }
  }
  // Ensure that latitude and longitude are valid.
  referenceLatitude = clipLatitude(referenceLatitude);
  referenceLongitude = normalizeLongitude(referenceLongitude);

  // Clean up the passed code.
  shortCode = shortCode.toUpperCase();
  // Compute the number of digits we need to recover.
  var paddingLength = separatorPosition - shortCode.indexOf(separator);
  // The resolution (height and width) of the padded area in degrees.
  var resolution = pow(encodingBase, 2 - (paddingLength / 2));
  // Distance from the center to an edge (in degrees).
  var halfResolution = resolution / 2.0;

  // Use the reference location to pad the supplied short code and decode it.
  var codeArea = decode(encode(referenceLatitude, referenceLongitude)
          .substring(0, paddingLength) +
      shortCode);
  var centerLatitude = codeArea.center.latitude;
  var centerLongitude = codeArea.center.longitude;

  // How many degrees latitude is the code from the reference? If it is more
  // than half the resolution, we need to move it north or south but keep it
  // within -90 to 90 degrees.
  if (referenceLatitude + halfResolution < centerLatitude &&
      centerLatitude - resolution >= -latitudeMax) {
    // If the proposed code is more than half a cell north of the reference location,
    // it's too far, and the best match will be one cell south.
    centerLatitude -= resolution;
  } else if (referenceLatitude - halfResolution > centerLatitude &&
      centerLatitude + resolution <= latitudeMax) {
    // If the proposed code is more than half a cell south of the reference location,
    // it's too far, and the best match will be one cell north.
    centerLatitude += resolution;
  }

  // How many degrees longitude is the code from the reference?
  if (referenceLongitude + halfResolution < centerLongitude) {
    centerLongitude -= resolution;
  } else if (referenceLongitude - halfResolution > centerLongitude) {
    centerLongitude += resolution;
  }

  return encode(centerLatitude, centerLongitude,
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
String shorten(String code, num latitude, num longitude) {
  if (!isFull(code)) {
    throw ArgumentError('Passed code is not valid and full: $code');
  }
  if (_matchesPattern(code, padding)) {
    throw ArgumentError('Cannot shorten padded codes: $code');
  }
  code = code.toUpperCase();
  var codeArea = decode(code);
  if (codeArea.codeLength < minTrimmableCodeLen) {
    throw RangeError('Code length must be at least $minTrimmableCodeLen');
  }
  // Ensure that latitude and longitude are valid.
  latitude = clipLatitude(latitude);
  longitude = normalizeLongitude(longitude);
  // How close are the latitude and longitude to the code center.
  var range = max((codeArea.center.latitude - latitude).abs(),
      (codeArea.center.longitude - longitude).abs());
  for (var i = pairResolutions.length - 2; i >= 1; i--) {
    // Check if we're close enough to shorten. The range must be less than 1/2
    // the resolution to shorten at all, and we want to allow some safety, so
    // use 0.3 instead of 0.5 as a multiplier.
    if (range < (pairResolutions[i] * 0.3)) {
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
String encodePairs(num latitude, num longitude, int codeLength) {
  var code = '';
  // Adjust latitude and longitude so they fall into positive ranges.
  var adjustedLatitude = latitude + latitudeMax;
  var adjustedLongitude = longitude + longitudeMax;
  // Count digits - can't use string length because it may include a separator
  // character.
  var digitCount = 0;
  while (digitCount < codeLength) {
    // Provides the value of digits in this place in decimal degrees.
    var placeValue = pairResolutions[digitCount ~/ 2];
    // Do the latitude - gets the digit for this place and subtracts that for
    // the next digit.
    var digitValue = adjustedLatitude ~/ placeValue;
    adjustedLatitude -= digitValue * placeValue;
    code += codeAlphabet[digitValue];
    digitCount++;
    // And do the longitude - gets the digit for this place and subtracts that
    // for the next digit.
    digitValue = adjustedLongitude ~/ placeValue;
    adjustedLongitude -= digitValue * placeValue;
    code += codeAlphabet[digitValue];
    digitCount++;
    // Should we add a separator here?
    if (digitCount == separatorPosition && digitCount < codeLength) {
      code += separator;
    }
  }
  // If necessary, Add padding.
  if (code.length < separatorPosition) {
    code += (padding * (separatorPosition - code.length));
  }
  if (code.length == separatorPosition) {
    code += separator;
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
String encodeGrid(num latitude, num longitude, int codeLength) {
  var code = '';
  var latPlaceValue = gridSizeDegrees;
  var lngPlaceValue = gridSizeDegrees;
  // Adjust latitude and longitude so they fall into positive ranges and
  // get the offset for the required places.
  latitude += latitudeMax;
  longitude += longitudeMax;
  // To avoid problems with floating point, get rid of the degrees.
  latitude %= 1.0;
  longitude %= 1.0;
  var adjustedLatitude = latitude % latPlaceValue;
  var adjustedLongitude = longitude % lngPlaceValue;
  for (var i = 0; i < codeLength; i++) {
    // Work out the row and column.
    var row = (adjustedLatitude / (latPlaceValue / gridRows)).floor();
    var col = (adjustedLongitude / (lngPlaceValue / gridColumns)).floor();
    latPlaceValue /= gridRows;
    lngPlaceValue /= gridColumns;
    adjustedLatitude -= row * latPlaceValue;
    adjustedLongitude -= col * lngPlaceValue;
    code += codeAlphabet[row * gridColumns + col];
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
  var latitude = decodePairsSequence(code, 0);
  var longitude = decodePairsSequence(code, 1);
  // Correct the values and set them into the CodeArea object.
  return CodeArea(latitude[0] - latitudeMax, longitude[0] - longitudeMax,
      latitude[1] - latitudeMax, longitude[1] - longitudeMax, code.length);
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
List<double> decodePairsSequence(String code, int offset) {
  int i = 0;
  num value = 0;
  while (i * 2 + offset < code.length) {
    value += _decode[code.codeUnitAt(i * 2 + offset)] * pairResolutions[i];
    i += 1;
  }
  return [value, value + pairResolutions[i - 1]];
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
  var south = 0.0;
  var west = 0.0;
  var latPlaceValue = gridSizeDegrees;
  var lngPlaceValue = gridSizeDegrees;
  var i = 0;
  while (i < code.length) {
    var codeIndex = _decode[code.codeUnitAt(i)];
    var row = (codeIndex / gridColumns).floor();
    var col = codeIndex % gridColumns;

    latPlaceValue /= gridRows;
    lngPlaceValue /= gridColumns;

    south += row * latPlaceValue;
    west += col * lngPlaceValue;
    i += 1;
  }
  return CodeArea(
      south, west, south + latPlaceValue, west + lngPlaceValue, code.length);
}

/// Coordinates of a decoded Open Location Code.
///
/// The coordinates include the latitude and longitude of the lower left and
/// upper right corners and the center of the bounding box for the area the
/// code represents.
class CodeArea {
  final num south, west, north, east;
  final LatLng center;
  final int codeLength;

  /// Create a [CodeArea].
  ///
  /// Args:
  ///
  /// *[south]: The south in degrees.
  /// *[west]: The west in degrees.
  /// *[north]: The north in degrees.
  /// *[east]: The east in degrees.
  /// *[code_length]: The number of significant characters that were in the code.
  /// This excludes the separator.
  CodeArea(num south, num west, num north, num east, this.codeLength)
      : south = south,
        west = west,
        north = north,
        east = east,
        center = LatLng((south + north) / 2, (west + east) / 2);

  @override
  String toString() =>
      'CodeArea(south:$south, west:$west, north:$north, east:$east, codelen: $codeLength)';
}

/// Coordinates of a point identified by its [latitude] and [longitude] in
/// degrees.
class LatLng {
  final num latitude, longitude;
  LatLng(this.latitude, this.longitude);
  @override
  String toString() => 'LatLng($latitude, $longitude)';
}
