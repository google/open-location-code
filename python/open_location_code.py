from math import floor
import re
OLC_CHARACTER_SET = "23456789CFGHJMPQRVWX"
SEPARATOR = '+'
SEPARATOR_POSITION = 8
HEIGHT_AND_WIDTH_DEGREES = [20.0, 1.0, .05, .0025, .000125]
LATITUDE_MAXIMUM = 90
LONGITUDE_MAXIMUM = 180
PAD_CHAR = '0'
GRID_SIZE_DEGREES_ = 0.000125
GRID_ROWS_ = 5
GRID_COLUMNS_ = 4
DEFAULT_LENGTH = 10
MIN_CODE_LENGTH = 6


class OpenLocationCode(object):

    """Calculations of open location code"""

    def isValid(self, olc_code):

        """Returns whether the provided string is a valid Open Location code."""

        if olc_code.find(PAD_CHAR) != -1:
            char_after_sep = olc_code[olc_code.index(SEPARATOR) + len(SEPARATOR):]
            if len(char_after_sep) > 0:
                return False

        if olc_code.find(SEPARATOR) == -1:
            return False 

        if olc_code.find(SEPARATOR) != olc_code.rfind(SEPARATOR):
            return False

        if olc_code.find(SEPARATOR) > SEPARATOR_POSITION:
            return False

        if olc_code.find(SEPARATOR) % 2 != 0:
            return False

        char_after_sep = olc_code[olc_code.index(SEPARATOR) + len(SEPARATOR):]
        if len(char_after_sep) == 1:
            return False

        if len(olc_code) == 1:
            return False

        olc_code = olc_code.replace(SEPARATOR, '')
        olc_code = re.sub(PAD_CHAR, '', olc_code)
        data = list(olc_code.upper())
        countt = 0

        for x in range(len(data)):
            if data[x] in OLC_CHARACTER_SET:
                countt += 1

        if countt != len(olc_code):
            return False
        return True


    def isShort(self, olc_code):

        """Returns if the code is a valid short Open Location Code."""

        olc_code = olc_code.upper()
        
        if OpenLocationCode().isValid(olc_code) == False:
            return False

        if olc_code.find(SEPARATOR) >= 0 and olc_code.find(SEPARATOR) < SEPARATOR_POSITION:
            return True

        
    def isFull(self, olc_code):

        """Returns if the code is a valid full Open Location Code"""

        olc_code = olc_code.upper()
        if OpenLocationCode().isValid(olc_code) == False:
            return False

        if olc_code.find(SEPARATOR) != SEPARATOR_POSITION:
            return False
        return True


    def encode1(self, latitude, longitude, code_length):

        """Encode a location into a sequence of OLC lat/lng pairs."""

        code = ''
        positive_latitude = latitude + LATITUDE_MAXIMUM
        positive_longitude = longitude + LONGITUDE_MAXIMUM
        count = 0
        while count < code_length:
            place_value = HEIGHT_AND_WIDTH_DEGREES[int(floor(count / 2))]
            digit_value = int(floor(positive_latitude / place_value))
            positive_latitude = positive_latitude - (digit_value * place_value)
            code = code + OLC_CHARACTER_SET[digit_value]
            count = count + 1

            digit_value = int(floor(positive_longitude / place_value))
            positive_longitude = positive_longitude - (digit_value * place_value)
            code = code + OLC_CHARACTER_SET[digit_value]
            count = count + 1
            if count == SEPARATOR_POSITION and count < code_length:
                code = code + SEPARATOR
        
        if len(code) < SEPARATOR_POSITION:
            code = code + (PAD_CHAR * (SEPARATOR_POSITION - len(code)))

        if len(code) == SEPARATOR_POSITION:
            code = code + SEPARATOR
        
        return code


    def encodeCode(self, latitude, longitude, code_length):

        """Encode a location using the grid refinement method into an OLC string.
        The grid refinement method divides the area into a grid of 4x5, and uses a
        single character to refine the area."""

        code = ''
        latplace_value = GRID_SIZE_DEGREES_
        lngplace_value = GRID_SIZE_DEGREES_
   
        positive_latitude = (latitude + LATITUDE_MAXIMUM) % latplace_value
        positive_longitude = (longitude + LONGITUDE_MAXIMUM) % lngplace_value
        for i in range(code_length):
            grid_row = int(floor(positive_latitude / (latplace_value / GRID_ROWS_)))
            grid_col = int(floor(positive_longitude / (lngplace_value / GRID_COLUMNS_)))
            latplace_value = latplace_value / GRID_ROWS_
            lngplace_value = lngplace_value / GRID_COLUMNS_
            positive_latitude = positive_latitude - (grid_row * latplace_value)
            positive_longitude = positive_longitude - (grid_col * lngplace_value)
            code = code + OLC_CHARACTER_SET[grid_row * GRID_COLUMNS_ + grid_col]
        return code

  
    def clipLatitude(self, latitude):

        """Clippling the latitude to the range of -90 to 90"""

        return min(90, max(-90, latitude))

    def computeLatitudePrecision(self, code_length):

        """Calculating the area based on the Code Length"""

        if code_length <= 10:
            return pow(20, floor(code_length / -2 + 2))
        return pow(20, -3) / pow(GRID_ROWS_, code_length - 10)

    def normalizeLongitude(self, longitude):

        """Normalising the longitude to the range of -180 to 180"""

        while longitude < -180:
            longitude = longitude + 360
        while longitude >= 180:
            longitude = longitude - 360
        return longitude

    def encode(self, latitude, longitude, *args):

        """Encodes latitude and longitude into Open Location Code of the provided length."""

        empty_args = "()"
        if str(args) == empty_args:
            args = "10"
        code_length = args

        code_length = int(''. join(map(str, code_length)))
        if code_length < 4 or (code_length < SEPARATOR_POSITION and code_length % 2 == 1):
            print 'Invalid Open Location Code length'

        latitude = OpenLocationCode().clipLatitude(latitude)
        longitude = OpenLocationCode().normalizeLongitude(longitude)
        if latitude == 90:
            latitude = latitude - OpenLocationCode().computeLatitudePrecision(code_length)

        code = OpenLocationCode().encode1(latitude, longitude, min(code_length, DEFAULT_LENGTH))
        
        if code_length > DEFAULT_LENGTH:
            code = code + OpenLocationCode().\
                   encodeCode(latitude, longitude, code_length - DEFAULT_LENGTH)

        return code


    def decode(self, code):

        """Return the Decoded Open Location Code."""

        code = code.replace(SEPARATOR, '')
        code = re.sub(PAD_CHAR, '', code)
        code = code.upper()
        code_area = OpenLocationCode().decodeLatLong(code[0: DEFAULT_LENGTH])
        if len(code) <= DEFAULT_LENGTH:
            return  code_area

        grid_area = OpenLocationCode().decodeCode(code[DEFAULT_LENGTH:])

        latitude_sw = code_area[0] + grid_area[0] 
        longitude_sw = code_area[1] + grid_area[1]
        latitude_ne = code_area[2] + grid_area[2]
        longitude_ne = code_area[3] + grid_area[3]
        code_length = code_area[4] + grid_area[4]
        
        return latitude_sw, longitude_sw, latitude_ne, longitude_ne, code_length
        

    def decodeLatLong(self, code):

        """Validating latitude and longitude values into positive values"""

        latitude = OpenLocationCode().decodeSequenceCode(code, 0)
        longitude = OpenLocationCode().decodeSequenceCode(code, 1)
        
        latitude_sw = latitude[0] - LATITUDE_MAXIMUM
        longitude_sw = longitude[0] - LONGITUDE_MAXIMUM
        latitude_ne = latitude[1] - LATITUDE_MAXIMUM
        longitude_ne = longitude[1] - LONGITUDE_MAXIMUM
        code_length = len(code)

        return latitude_sw, longitude_sw, latitude_ne, longitude_ne, code_length
      


    def decodeSequenceCode(self, code, offset):

        """Decode either a latitude or longitude sequence.
        This decodes the latitude or longitude sequence of a lat/lng pair encoding.
        Starting at the character at position offset, every second character is
        decoded and the value returned."""

        i = 0
        value = 0
        while i * 2 + offset < len(code):
            value += OLC_CHARACTER_SET.find(code[i * 2 + offset])*HEIGHT_AND_WIDTH_DEGREES[i]
            i += 1
        data = value + HEIGHT_AND_WIDTH_DEGREES[i - 1]
        return value, data


    def decodeCode(self, code):

        """Decode the grid refinement portion of an OLC code.
        This decodes an OLC code using the grid refinement method."""

        latitude_sw = 0.0
        longitude_sw = 0.0
        latplace_value = GRID_SIZE_DEGREES_
        lngplace_value = GRID_SIZE_DEGREES_
        i = 0
        while i < len(code):

            code_index = OLC_CHARACTER_SET.find(code[i])
            row = int(floor(code_index / GRID_COLUMNS_))
            col = code_index % GRID_COLUMNS_

            latplace_value = latplace_value / GRID_ROWS_
            lngplace_value = lngplace_value / GRID_COLUMNS_

            latitude_sw = latitude_sw + (row * latplace_value)
            longitude_sw = longitude_sw + (col * lngplace_value)
            i += 1

        return latitude_sw, longitude_sw, latitude_sw + latplace_value, \
               longitude_sw + lngplace_value, len(code)


    def shortencode(self, code, latitude, longitude):

        """Returns shorten open location code"""

        limit = 0
        if OpenLocationCode().isFull(code) == False:
            limit = limit + 1
            

        if code.find(PAD_CHAR) != -1:
            limit = limit + 1


        if limit == 0:
            decoded_code = OpenLocationCode().decode(code)

            latitude_diff = abs(latitude - (decoded_code[0] + \
                            (decoded_code[2] - decoded_code[0]) / 2))
            longitude_diff = abs(longitude - (decoded_code[1] \
                             + (decoded_code[3] - decoded_code[1]) / 2))

            if latitude_diff < 0.0125 and longitude_diff < 0.0125:
                return code[6:]
            
            if latitude_diff < 0.25 and longitude_diff < 0.25:
                return code[4:]
        else:
            return "Invalid Full OLC or OLC is Padded"





    def recoverNearest(self, code, latitude, longitude):

        """returns the nearest
           matching full Open Location Code 
           to the specified location."""

        latitude = OpenLocationCode().clipLatitude(latitude)
        longitude = OpenLocationCode().normalizeLongitude(longitude)

        code = code.upper()
        pad_length = SEPARATOR_POSITION - code.find(SEPARATOR)
        pad_area_resolution = pow(20, 2 - (pad_length / 2))
        center_to_edge_dis = pad_area_resolution / 2.0

        floor_latitude = floor(latitude / pad_area_resolution) * pad_area_resolution
        floor_longitude = floor(longitude / pad_area_resolution) * pad_area_resolution

        decoded_lat_long = OpenLocationCode().decode(OpenLocationCode().\
                        encode(floor_latitude, floor_longitude, 10)[0:pad_length] + code)
        
        latitude_center = min(decoded_lat_long[0] + (decoded_lat_long[2] \
                                                  - decoded_lat_long[0]) / 2, LATITUDE_MAXIMUM)
        longitude_center = min(decoded_lat_long[1] + (decoded_lat_long[3] \
                                                  - decoded_lat_long[1]) / 2, LONGITUDE_MAXIMUM)

        degrees_difference = latitude_center - latitude

        if degrees_difference > center_to_edge_dis:

            latitude_center = latitude_center - pad_area_resolution
        elif degrees_difference < -center_to_edge_dis:

            latitude_center = latitude_center + pad_area_resolution

        degrees_difference = longitude_center - longitude
        if degrees_difference > center_to_edge_dis:
            longitude_center = longitude_center - pad_area_resolution
        elif degrees_difference < -center_to_edge_dis:
            longitude_center = longitude_center + pad_area_resolution

        return OpenLocationCode().encode(latitude_center, longitude_center, decoded_lat_long[4])


