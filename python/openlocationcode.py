#  -*- coding: utf-8 -*-
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================
#
#
# Convert locations to and from short codes.
#
# Open Location Codes are short, 10-11 character codes that can be used instead
# of street addresses. The codes can be generated and decoded offline, and use
# a reduced character set that minimises the chance of codes including words.
#
# Codes are able to be shortened relative to a nearby location. This means that
# in many cases, only four to seven characters of the code are needed.
# To recover the original code, the same location is not required, as long as
# a nearby location is provided.
#
# Codes represent rectangular areas rather than points, and the longer the
# code, the smaller the area. A 10 character code represents a 13.5x13.5
# meter area (at the equator. An 11 character code represents approximately
# a 2.8x3.5 meter area.
#
# Two encoding algorithms are used. The first 10 characters are pairs of
# characters, one for latitude and one for longitude, using base 20. Each pair
# reduces the area of the code by a factor of 400. Only even code lengths are
# sensible, since an odd-numbered length would have sides in a ratio of 20:1.
#
# At position 11, the algorithm changes so that each character selects one
# position from a 4x5 grid. This allows single-character refinements.
#
# Examples:
#
#   Encode a location, default accuracy:
#   encode(47.365590, 8.524997)
#
#   Encode a location using one stage of additional refinement:
#   encode(47.365590, 8.524997, 11)
#
#   Decode a full code:
#   coord = decode(code)
#   msg = "Center is {lat}, {lon}".format(lat=coord.latitudeCenter, lon=coord.longitudeCenter)
#
#   Attempt to trim the first characters from a code:
#   shorten('8FVC9G8F+6X', 47.5, 8.5)
#
#   Recover the full code from a short code:
#   recoverNearest('9G8F+6X', 47.4, 8.6)
#   recoverNearest('8F+6X', 47.4, 8.6)

import re
import math

# A separator used to break the code into two parts to aid memorability.
SEPARATOR_ = '+'

# The number of characters to place before the separator.
SEPARATOR_POSITION_ = 8

# The character used to pad codes.
PADDING_CHARACTER_ = '0'

# The character set used to encode the values.
CODE_ALPHABET_ = '23456789CFGHJMPQRVWX'

# The base to use to convert numbers to/from.
ENCODING_BASE_ = len(CODE_ALPHABET_)

# The maximum value for latitude in degrees.
LATITUDE_MAX_ = 90

# The maximum value for longitude in degrees.
LONGITUDE_MAX_ = 180

# The max number of digits to process in a plus code.
MAX_DIGIT_COUNT_ = 15

# Maximum code length using lat/lng pair encoding. The area of such a
# code is approximately 13x13 meters (at the equator), and should be suitable
# for identifying buildings. This excludes prefix and separator characters.
PAIR_CODE_LENGTH_ = 10

# First place value of the pairs (if the last pair value is 1).
PAIR_FIRST_PLACE_VALUE_ = ENCODING_BASE_**(PAIR_CODE_LENGTH_ / 2 - 1)

# Inverse of the precision of the pair section of the code.
PAIR_PRECISION_ = ENCODING_BASE_**3

# The resolution values in degrees for each position in the lat/lng pair
# encoding. These give the place value of each position, and therefore the
# dimensions of the resulting area.
PAIR_RESOLUTIONS_ = [20.0, 1.0, .05, .0025, .000125]

# Number of digits in the grid precision part of the code.
GRID_CODE_LENGTH_ = MAX_DIGIT_COUNT_ - PAIR_CODE_LENGTH_

# Number of columns in the grid refinement method.
GRID_COLUMNS_ = 4

# Number of rows in the grid refinement method.
GRID_ROWS_ = 5

# First place value of the latitude grid (if the last place is 1).
GRID_LAT_FIRST_PLACE_VALUE_ = GRID_ROWS_**(GRID_CODE_LENGTH_ - 1)

# First place value of the longitude grid (if the last place is 1).
GRID_LNG_FIRST_PLACE_VALUE_ = GRID_COLUMNS_**(GRID_CODE_LENGTH_ - 1)

# Multiply latitude by this much to make it a multiple of the finest
# precision.
FINAL_LAT_PRECISION_ = PAIR_PRECISION_ * GRID_ROWS_**(MAX_DIGIT_COUNT_ -
                                                      PAIR_CODE_LENGTH_)

# Multiply longitude by this much to make it a multiple of the finest
# precision.
FINAL_LNG_PRECISION_ = PAIR_PRECISION_ * GRID_COLUMNS_**(MAX_DIGIT_COUNT_ -
                                                         PAIR_CODE_LENGTH_)

# Minimum length of a code that can be shortened.
MIN_TRIMMABLE_CODE_LEN_ = 6

GRID_SIZE_DEGREES_ = 0.000125
"""
Determines if a code is valid.
To be valid, all characters must be from the Open Location Code character
set with at most one separator. The separator can be in any even-numbered
position up to the eighth digit.
"""


def isValid(code):
    # The separator is required.
    sep = code.find(SEPARATOR_)
    if code.count(SEPARATOR_) > 1:
        return False
    # Is it the only character?
    if len(code) == 1:
        return False
    # Is it in an illegal position?
    if sep == -1 or sep > SEPARATOR_POSITION_ or sep % 2 == 1:
        return False
    # We can have an even number of padding characters before the separator,
    # but then it must be the final character.
    pad = code.find(PADDING_CHARACTER_)
    if pad != -1:
        # Short codes cannot have padding
        if sep < SEPARATOR_POSITION_:
            return False
        # Not allowed to start with them!
        if pad == 0:
            return False

        # There can only be one group and it must have even length.
        rpad = code.rfind(PADDING_CHARACTER_) + 1
        pads = code[pad:rpad]
        if len(pads) % 2 == 1 or pads.count(PADDING_CHARACTER_) != len(pads):
            return False
        # If the code is long enough to end with a separator, make sure it does.
        if not code.endswith(SEPARATOR_):
            return False
    # If there are characters after the separator, make sure there isn't just
    # one of them (not legal).
    if len(code) - sep - 1 == 1:
        return False
    # Check the code contains only valid characters.
    sepPad = SEPARATOR_ + PADDING_CHARACTER_
    for ch in code:
        if ch.upper() not in CODE_ALPHABET_ and ch not in sepPad:
            return False
    return True


"""
Determines if a code is a valid short code.
A short Open Location Code is a sequence created by removing four or more
digits from an Open Location Code. It must include a separator
character.
"""


def isShort(code):
    # Check it's valid.
    if not isValid(code):
        return False
    # If there are less characters than expected before the SEPARATOR.
    sep = code.find(SEPARATOR_)
    if sep >= 0 and sep < SEPARATOR_POSITION_:
        return True
    return False


"""
 Determines if a code is a valid full Open Location Code.
 Not all possible combinations of Open Location Code characters decode to
 valid latitude and longitude values. This checks that a code is valid
 and also that the latitude and longitude values are legal. If the prefix
 character is present, it must be the first character. If the separator
 character is present, it must be after four characters.
"""


def isFull(code):
    if not isValid(code):
        return False
    # If it's short, it's not full
    if isShort(code):
        return False
    # Work out what the first latitude character indicates for latitude.
    firstLatValue = CODE_ALPHABET_.find(code[0].upper()) * ENCODING_BASE_
    if firstLatValue >= LATITUDE_MAX_ * 2:
        # The code would decode to a latitude of >= 90 degrees.
        return False
    if len(code) > 1:
        # Work out what the first longitude character indicates for longitude.
        firstLngValue = CODE_ALPHABET_.find(code[1].upper()) * ENCODING_BASE_
    if firstLngValue >= LONGITUDE_MAX_ * 2:
        # The code would decode to a longitude of >= 180 degrees.
        return False
    return True


"""
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
"""


def encode(latitude, longitude, codeLength=PAIR_CODE_LENGTH_):
    if codeLength < 2 or (codeLength < PAIR_CODE_LENGTH_ and
                          codeLength % 2 == 1):
        raise ValueError('Invalid Open Location Code length - ' +
                         str(codeLength))
    codeLength = min(codeLength, MAX_DIGIT_COUNT_)
    # Ensure that latitude and longitude are valid.
    latitude = clipLatitude(latitude)
    longitude = normalizeLongitude(longitude)
    # Latitude 90 needs to be adjusted to be just less, so the returned code
    # can also be decoded.
    if latitude == 90:
        latitude = latitude - computeLatitudePrecision(codeLength)
    code = ''

    # Compute the code.
    # This approach converts each value to an integer after multiplying it by
    # the final precision. This allows us to use only integer operations, so
    # avoiding any accumulation of floating point representation errors.

    # Multiply values by their precision and convert to positive.
    # Force to integers so the division operations will have integer results.
    # Note: Python requires rounding before truncating to ensure precision!
    latVal = int(round((latitude + LATITUDE_MAX_) * FINAL_LAT_PRECISION_, 6))
    lngVal = int(round((longitude + LONGITUDE_MAX_) * FINAL_LNG_PRECISION_, 6))

    # Compute the grid part of the code if necessary.
    if codeLength > PAIR_CODE_LENGTH_:
        for i in range(0, MAX_DIGIT_COUNT_ - PAIR_CODE_LENGTH_):
            latDigit = latVal % GRID_ROWS_
            lngDigit = lngVal % GRID_COLUMNS_
            ndx = latDigit * GRID_COLUMNS_ + lngDigit
            code = CODE_ALPHABET_[ndx] + code
            latVal //= GRID_ROWS_
            lngVal //= GRID_COLUMNS_
    else:
        latVal //= pow(GRID_ROWS_, GRID_CODE_LENGTH_)
        lngVal //= pow(GRID_COLUMNS_, GRID_CODE_LENGTH_)
    # Compute the pair section of the code.
    for i in range(0, PAIR_CODE_LENGTH_ // 2):
        code = CODE_ALPHABET_[lngVal % ENCODING_BASE_] + code
        code = CODE_ALPHABET_[latVal % ENCODING_BASE_] + code
        latVal //= ENCODING_BASE_
        lngVal //= ENCODING_BASE_

    # Add the separator character.
    code = code[:SEPARATOR_POSITION_] + SEPARATOR_ + code[SEPARATOR_POSITION_:]

    # If we don't need to pad the code, return the requested section.
    if codeLength >= SEPARATOR_POSITION_:
        return code[0:codeLength + 1]

    # Pad and return the code.
    return code[0:codeLength] + ''.zfill(SEPARATOR_POSITION_ -
                                         codeLength) + SEPARATOR_


"""
 Decodes an Open Location Code into the location coordinates.
 Returns a CodeArea object that includes the coordinates of the bounding
 box - the lower left, center and upper right.
 Args:
   code: The Open Location Code to decode.
 Returns:
   A CodeArea object that provides the latitude and longitude of two of the
   corners of the area, the center, and the length of the original code.
"""


def decode(code):
    if not isFull(code):
        raise ValueError(
            'Passed Open Location Code is not a valid full code - ' + str(code))
    # Strip out separator character (we've already established the code is
    # valid so the maximum is one), and padding characters. Convert to upper
    # case and constrain to the maximum number of digits.
    code = re.sub('[+0]', '', code)
    code = code.upper()
    code = code[:MAX_DIGIT_COUNT_]
    # Initialise the values for each section. We work them out as integers and
    # convert them to floats at the end.
    normalLat = -LATITUDE_MAX_ * PAIR_PRECISION_
    normalLng = -LONGITUDE_MAX_ * PAIR_PRECISION_
    gridLat = 0
    gridLng = 0
    # How many digits do we have to process?
    digits = min(len(code), PAIR_CODE_LENGTH_)
    # Define the place value for the most significant pair.
    pv = PAIR_FIRST_PLACE_VALUE_
    # Decode the paired digits.
    for i in range(0, digits, 2):
        normalLat += CODE_ALPHABET_.find(code[i]) * pv
        normalLng += CODE_ALPHABET_.find(code[i + 1]) * pv
        if i < digits - 2:
            pv //= ENCODING_BASE_

    # Convert the place value to a float in degrees.
    latPrecision = float(pv) / PAIR_PRECISION_
    lngPrecision = float(pv) / PAIR_PRECISION_
    # Process any extra precision digits.
    if len(code) > PAIR_CODE_LENGTH_:
        # Initialise the place values for the grid.
        rowpv = GRID_LAT_FIRST_PLACE_VALUE_
        colpv = GRID_LNG_FIRST_PLACE_VALUE_
        # How many digits do we have to process?
        digits = min(len(code), MAX_DIGIT_COUNT_)
        for i in range(PAIR_CODE_LENGTH_, digits):
            digitVal = CODE_ALPHABET_.find(code[i])
            row = digitVal // GRID_COLUMNS_
            col = digitVal % GRID_COLUMNS_
            gridLat += row * rowpv
            gridLng += col * colpv
            if i < digits - 1:
                rowpv //= GRID_ROWS_
                colpv //= GRID_COLUMNS_

        # Adjust the precisions from the integer values to degrees.
        latPrecision = float(rowpv) / FINAL_LAT_PRECISION_
        lngPrecision = float(colpv) / FINAL_LNG_PRECISION_

    # Merge the values from the normal and extra precision parts of the code.
    lat = float(normalLat) / PAIR_PRECISION_ + float(
        gridLat) / FINAL_LAT_PRECISION_
    lng = float(normalLng) / PAIR_PRECISION_ + float(
        gridLng) / FINAL_LNG_PRECISION_
    # Multiple values by 1e14, round and then divide. This reduces errors due
    # to floating point precision.
    return CodeArea(round(lat, 14), round(lng,
                                          14), round(lat + latPrecision, 14),
                    round(lng + lngPrecision, 14),
                    min(len(code), MAX_DIGIT_COUNT_))


"""
 Recover the nearest matching code to a specified location.
 Given a short Open Location Code of between four and seven characters,
 this recovers the nearest matching full code to the specified location.
 The number of characters that will be prepended to the short code, depends
 on the length of the short code and whether it starts with the separator.
 If it starts with the separator, four characters will be prepended. If it
 does not, the characters that will be prepended to the short code, where S
 is the supplied short code and R are the computed characters, are as
 follows:
 SSSS    -> RRRR.RRSSSS
 SSSSS   -> RRRR.RRSSSSS
 SSSSSS  -> RRRR.SSSSSS
 SSSSSSS -> RRRR.SSSSSSS
 Note that short codes with an odd number of characters will have their
 last character decoded using the grid refinement algorithm.
 Args:
   code: A valid OLC character sequence.
   referenceLatitude: The latitude (in signed decimal degrees) to use to
       find the nearest matching full code.
   referenceLongitude: The longitude (in signed decimal degrees) to use
       to find the nearest matching full code.
 Returns:
   The nearest full Open Location Code to the reference location that matches
   the short code. If the passed code was not a valid short code, but was a
   valid full code, it is returned with proper capitalization but otherwise
   unchanged.
"""


def recoverNearest(code, referenceLatitude, referenceLongitude):
    # if code is a valid full code, return it properly capitalized
    if isFull(code):
        return code.upper()
    if not isShort(code):
        raise ValueError('Passed short code is not valid - ' + str(code))
    # Ensure that latitude and longitude are valid.
    referenceLatitude = clipLatitude(referenceLatitude)
    referenceLongitude = normalizeLongitude(referenceLongitude)
    # Clean up the passed code.
    code = code.upper()
    # Compute the number of digits we need to recover.
    paddingLength = SEPARATOR_POSITION_ - code.find(SEPARATOR_)
    # The resolution (height and width) of the padded area in degrees.
    resolution = pow(20, 2 - (paddingLength / 2))
    # Distance from the center to an edge (in degrees).
    halfResolution = resolution / 2.0
    # Use the reference location to pad the supplied short code and decode it.
    codeArea = decode(
        encode(referenceLatitude, referenceLongitude)[0:paddingLength] + code)
    # How many degrees latitude is the code from the reference? If it is more
    # than half the resolution, we need to move it north or south but keep it
    # within -90 to 90 degrees.
    if (referenceLatitude + halfResolution < codeArea.latitudeCenter and
            codeArea.latitudeCenter - resolution >= -LATITUDE_MAX_):
        # If the proposed code is more than half a cell north of the reference location,
        # it's too far, and the best match will be one cell south.
        codeArea.latitudeCenter -= resolution
    elif (referenceLatitude - halfResolution > codeArea.latitudeCenter and
          codeArea.latitudeCenter + resolution <= LATITUDE_MAX_):
        # If the proposed code is more than half a cell south of the reference location,
        # it's too far, and the best match will be one cell north.
        codeArea.latitudeCenter += resolution
    # Adjust longitude if necessary.
    if referenceLongitude + halfResolution < codeArea.longitudeCenter:
        codeArea.longitudeCenter -= resolution
    elif referenceLongitude - halfResolution > codeArea.longitudeCenter:
        codeArea.longitudeCenter += resolution
    return encode(codeArea.latitudeCenter, codeArea.longitudeCenter,
                  codeArea.codeLength)


"""
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
 Args:
   code: A full, valid code to shorten.
   latitude: A latitude, in signed decimal degrees, to use as the reference
       point.
   longitude: A longitude, in signed decimal degrees, to use as the reference
       point.
 Returns:
   Either the original code, if the reference location was not close enough,
   or the .
"""


def shorten(code, latitude, longitude):
    if not isFull(code):
        raise ValueError('Passed code is not valid and full: ' + str(code))
    if code.find(PADDING_CHARACTER_) != -1:
        raise ValueError('Cannot shorten padded codes: ' + str(code))
    code = code.upper()
    codeArea = decode(code)
    if codeArea.codeLength < MIN_TRIMMABLE_CODE_LEN_:
        raise ValueError('Code length must be at least ' +
                         MIN_TRIMMABLE_CODE_LEN_)
    # Ensure that latitude and longitude are valid.
    latitude = clipLatitude(latitude)
    longitude = normalizeLongitude(longitude)
    # How close are the latitude and longitude to the code center.
    coderange = max(abs(codeArea.latitudeCenter - latitude),
                    abs(codeArea.longitudeCenter - longitude))
    for i in range(len(PAIR_RESOLUTIONS_) - 2, 0, -1):
        # Check if we're close enough to shorten. The range must be less than 1/2
        # the resolution to shorten at all, and we want to allow some safety, so
        # use 0.3 instead of 0.5 as a multiplier.
        if coderange < (PAIR_RESOLUTIONS_[i] * 0.3):
            # Trim it.
            return code[(i + 1) * 2:]
    return code


"""
 Clip a latitude into the range -90 to 90.
 Args:
   latitude: A latitude in signed decimal degrees.
"""


def clipLatitude(latitude):
    return min(90, max(-90, latitude))


"""
 Compute the latitude precision value for a given code length. Lengths <=
 10 have the same precision for latitude and longitude, but lengths > 10
 have different precisions due to the grid method having fewer columns than
 rows.
"""


def computeLatitudePrecision(codeLength):
    if codeLength <= 10:
        return pow(20, math.floor((codeLength / -2) + 2))
    return pow(20, -3) / pow(GRID_ROWS_, codeLength - 10)


"""
 Normalize a longitude into the range -180 to 180, not including 180.
 Args:
   longitude: A longitude in signed decimal degrees.
"""


def normalizeLongitude(longitude):
    while longitude < -180:
        longitude = longitude + 360
    while longitude >= 180:
        longitude = longitude - 360
    return longitude


"""
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
"""


class CodeArea(object):

    def __init__(self, latitudeLo, longitudeLo, latitudeHi, longitudeHi,
                 codeLength):
        self.latitudeLo = latitudeLo
        self.longitudeLo = longitudeLo
        self.latitudeHi = latitudeHi
        self.longitudeHi = longitudeHi
        self.codeLength = codeLength
        self.latitudeCenter = min(latitudeLo + (latitudeHi - latitudeLo) / 2,
                                  LATITUDE_MAX_)
        self.longitudeCenter = min(
            longitudeLo + (longitudeHi - longitudeLo) / 2, LONGITUDE_MAX_)

    def __repr__(self):
        return str([
            self.latitudeLo, self.longitudeLo, self.latitudeHi,
            self.longitudeHi, self.latitudeCenter, self.longitudeCenter,
            self.codeLength
        ])

    def latlng(self):
        return [self.latitudeCenter, self.longitudeCenter]
