#include <ctype.h>
#include <float.h>
#include <math.h>
#include <memory.h>
#include "olc.h"
#include "olc_private.h"

#define CORRECT_IF_SEPARATOR(var, info) \
    do { (var) += (info)->sep_first >= 0 ? 1 : 0; } while (0)

typedef struct CodeInfo {
    const char* code;
    int size;
    int len;
    int sep_first;
    int sep_last;
    int pad_first;
    int pad_last;
} CodeInfo;

// Helper functions
static int analyse(const char* code, size_t size, CodeInfo* info);
static int is_short(CodeInfo* info);
static int is_full(CodeInfo* info);
static int decode(CodeInfo* info, OLC_CodeArea* decoded);
static size_t code_length(CodeInfo* info);

static void init_constants(void);
static double pow_neg(double base, double exponent);
static double compute_precision_for_length(int length);
static double normalize_longitude(double lon_degrees);
static double adjust_latitude(double lat_degrees, size_t length);
static int encode_pairs(double lat, double lon, size_t length,
                        char* code, int maxlen);
static int encode_grid(double lat, double lon, size_t length,
                       char* code, int maxlen);


void OLC_GetCenter(const OLC_CodeArea* area, OLC_LatLon* center)
{
    center->lat = area->lo.lat + (area->hi.lat - area->lo.lat) / 2.0;
    if (center->lat > kLatMaxDegrees) {
        center->lat = kLatMaxDegrees;
    }

    center->lon = area->lo.lon + (area->hi.lon - area->lo.lon) / 2.0;
    if (center->lon > kLonMaxDegrees) {
        center->lon = kLonMaxDegrees;
    }
}

size_t OLC_CodeLength(const char* code, size_t size)
{
    CodeInfo info;
    analyse(code, size, &info);
    return code_length(&info);
}

int OLC_IsValid(const char* code, size_t size)
{
    CodeInfo info;
    return analyse(code, size, &info) > 0;
}

int OLC_IsShort(const char* code, size_t size)
{
    CodeInfo info;
    if (analyse(code, size, &info) <= 0) {
        return 0;
    }
    return is_short(&info);
}

int OLC_IsFull(const char* code, size_t size)
{
    CodeInfo info;
    if (analyse(code, size, &info) <= 0) {
        return 0;
    }
    return is_full(&info);
}

int OLC_Encode(const OLC_LatLon* location, size_t length,
               char* code, int maxlen)
{
    int pos = 0;

    // Limit the maximum number of digits in the code.
    if (length > kMaximumDigitCount) {
        length = kMaximumDigitCount;
    }

    // Adjust latitude and longitude so they fall into positive ranges.
    double lat = adjust_latitude(location->lat, length) + kLatMaxDegrees;
    double lon = normalize_longitude(location->lon) + kLonMaxDegrees;
    size_t len = length;
    if (len > kPairCodeLength) {
        len = kPairCodeLength;
    }
    pos += encode_pairs(lat, lon, len, code + pos, maxlen - pos);
    // If the requested length indicates we want grid refined codes.
    if (length > kPairCodeLength) {
        pos += encode_grid(lat, lon, length - kPairCodeLength, code + pos, maxlen - pos);
    }
    code[pos] = '\0';
    return pos;
}

int OLC_EncodeDefault(const OLC_LatLon* location,
                      char* code, int maxlen)
{
    return OLC_Encode(location, kPairCodeLength, code, maxlen);
}

int OLC_Decode(const char* code, size_t size, OLC_CodeArea* decoded)
{
    CodeInfo info;
    if (analyse(code, size, &info) <= 0) {
        return 0;
    }
    return decode(&info, decoded);
}

int OLC_Shorten(const char* code, size_t size, const OLC_LatLon* reference,
                char* shortened, int maxlen)
{
    CodeInfo info;
    if (analyse(code, size, &info) <= 0) {
        return 0;
    }
    if (info.pad_first > 0) {
        return 0;
    }
    if (!is_full(&info)) {
        return 0;
    }

    OLC_CodeArea code_area;
    decode(&info, &code_area);
    OLC_LatLon center;
    OLC_GetCenter(&code_area, &center);

    // Ensure that latitude and longitude are valid.
    double lat = adjust_latitude(reference->lat, info.len);
    double lon = normalize_longitude(reference->lon);

    // How close are the latitude and longitude to the code center.
    double alat = fabs(center.lat - lat);
    double alon = fabs(center.lon - lon);
    double range = alat > alon ? alat : alon;

    // Yes, magic numbers... sob.
    int start = 0;
    const double safety_factor = 0.3;
    const int removal_lengths[3] = { 8, 6, 4 };
    for (int j = 0; j < sizeof(removal_lengths) / sizeof(removal_lengths[0]); ++j) {
        // Check if we're close enough to shorten. The range must be less than
        // 1/2 the resolution to shorten at all, and we want to allow some
        // safety, so use 0.3 instead of 0.5 as a multiplier.
        int removal_length = removal_lengths[j];
        double area_edge = compute_precision_for_length(removal_length) * safety_factor;
        if (range < area_edge) {
            start = removal_length;
            break;
        }
    }
    int pos = 0;
    for (int j = start; j < info.size && code[j] != '\0'; ++j) {
        shortened[pos++] = code[j];
    }
    shortened[pos] = '\0';
    return pos;
}

int OLC_RecoverNearest(const char* short_code, size_t size, const OLC_LatLon* reference,
                       char* code, int maxlen)
{
    CodeInfo info;
    if (analyse(short_code, size, &info) <= 0) {
        return 0;
    }
    if (!is_short(&info)) {
        return 0;
    }
    int len = code_length(&info);

    // Ensure that latitude and longitude are valid.
    double lat = adjust_latitude(reference->lat, len);
    double lon = normalize_longitude(reference->lon);

    // Compute the number of digits we need to recover.
    size_t padding_length = kSeparatorPosition;
    if (info.sep_first >= 0) {
        padding_length -= info.sep_first;
    }

    // The resolution (height and width) of the padded area in degrees.
    double resolution = pow_neg(kEncodingBase, 2.0 - (padding_length / 2.0));

    // Distance from the center to an edge (in degrees).
    double half_res = resolution / 2.0;

    // Use the reference location to pad the supplied short code and decode it.
    OLC_LatLon latlon = {lat, lon};
    char encoded[256];
    OLC_EncodeDefault(&latlon, encoded, 256);

    char new_code[256];
    int pos = 0;
    for (int j = 0; encoded[j] != '\0'; ++j) {
        if (j >= padding_length) {
            break;
        }
        new_code[pos++] = encoded[j];
    }
    for (int j = 0; j < info.size && short_code[j] != '\0'; ++j) {
        new_code[pos++] = short_code[j];
    }
    new_code[pos] = '\0';
    if (analyse(new_code, pos, &info) <= 0) {
        return 0;
    }

    OLC_CodeArea code_area;
    decode(&info, &code_area);
    OLC_LatLon center;
    OLC_GetCenter(&code_area, &center);

    // How many degrees latitude is the code from the reference?
    if (lat + half_res < center.lat && center.lat - resolution > -kLatMaxDegrees) {
        // If the proposed code is more than half a cell north of the reference
        // location, it's too far, and the best match will be one cell south.
        center.lat -= resolution;
    } else if (lat - half_res > center.lat && center.lat + resolution < kLatMaxDegrees) {
        // If the proposed code is more than half a cell south of the reference
        // location, it's too far, and the best match will be one cell north.
        center.lat += resolution;
    }

    // How many degrees longitude is the code from the reference?
    if (lon + half_res < center.lon) {
        center.lon -= resolution;
    } else if (lon - half_res > center.lon) {
        center.lon += resolution;
    }

    return OLC_Encode(&center, len + padding_length, code, maxlen);
}


// private functions

static int analyse(const char* code, size_t size, CodeInfo* info)
{
    memset(info, 0, sizeof(CodeInfo));

    // null code is not valid
    if (!code) {
        return 0;
    }
    if (!size || size > kMaximumDigitCount) {
        size = kMaximumDigitCount;
    }

    info->code = code;
    info->size = size;
    info->sep_first = -1;
    info->sep_last = -1;
    info->pad_first = -1;
    info->pad_last = -1;
    int j = 0;
    for (j = 0; j <= size && code[j] != '\0'; ++j) {
        int ok = 0;

        // if this is a padding character, remember it
        if (!ok && code[j] == kPaddingCharacter) {
            if (info->pad_first < 0) {
                info->pad_first = j;
            }
            info->pad_last = j;
            ok = 1;
        }

        // if this is a separator character, remember it
        if (!ok && code[j] == kSeparator) {
            if (info->sep_first < 0) {
                info->sep_first = j;
            }
            info->sep_last = j;
            ok = 1;
        }

        // only accept characters in the valid character set
        if (!ok && get_alphabet_position(toupper(code[j])) >= 0) {
            ok = 1;
        }

        // didn't find anything expected => bail out
        if (!ok) {
            return 0;
        }
    }

    // so far, code only has valid characters -- good
    info->len = j;

    // Cannot be empty
    if (info->len <= 0) {
        return 0;
    }

    // The separator is required.
    if (info->sep_first < 0) {
        return 0;
    }

    // There can be only one... separator.
    if (info->sep_last > info->sep_first) {
        return 0;
    }

    // separator cannot be the only character
    if (info->len == 1) {
        return 0;
    }

    // Is the separator in an illegal position?
    if (info->sep_first > kSeparatorPosition || (info->sep_first % 2)) {
        return 0;
    }

    // padding cannot be at the initial position
    if (info->pad_first == 0) {
        return 0;
    }

    // We can have an even number of padding characters before the separator,
    // but then it must be the final character.
    if (info->pad_first > 0) {
        // Short codes cannot have padding
        if (info->sep_first < kSeparatorPosition) {
            return 0;
        }

        // The first padding character needs to be in an odd position.
        if (info->pad_first % 2) {
            return 0;
        }

        // With padding, the separator must be the final character
        if (info->sep_last < info->len - 1) {
            return 0;
        }

        // After removing padding characters, we mustn't have anything left.
        if (info->pad_last < info->sep_first - 1) {
            return 0;
        }
    }

    // If there are characters after the separator, make sure there isn't just
    // one of them (not legal).
    if (info->len - info->sep_first - 1 == 1) {
        return 0;
    }

    return info->len;
}

static int is_short(CodeInfo* info)
{
    if (info->len <= 0) {
        return 0;
    }

    // if there is a separator, it cannot be beyond the valid position
    if (info->sep_first >= kSeparatorPosition) {
        return 0;
    }

    return 1;
}

// checks that the first character of latitude or longitude is valid
static int valid_first_character(CodeInfo* info, int pos, double kMax)
{
    if (info->len <= pos) {
        return 1;
    }

    // Work out what the first character indicates
    size_t firstValue = get_alphabet_position(toupper(info->code[pos]));
    firstValue *= kEncodingBase;
    return firstValue < kMax;
}

static int is_full(CodeInfo* info)
{
    if (info->len <= 0) {
        return 0;
    }

    // If there are less characters than expected before the separator.
    if (info->sep_first < kSeparatorPosition) {
        return 0;
    }

    // check first latitude character, if any
    if (! valid_first_character(info, 0, kLatMaxDegreesT2)) {
        return 0;
    }

    // check first longitude character, if any
    if (! valid_first_character(info, 1, kLonMaxDegreesT2)) {
        return 0;
    }

    return 1;
}

static int decode(CodeInfo* info, OLC_CodeArea* decoded)
{
    double resolution_degrees = kEncodingBase;
    OLC_LatLon lo = { 0, 0 };
    OLC_LatLon hi = { 0, 0 };

    // Up to the first 10 characters are encoded in pairs. Subsequent
    // characters represent grid squares.
    int top = info->len;
    if (info->pad_first >= 0) {
        top = info->pad_first;
    }
    if (top > kPairCodeLength) {
        top = kPairCodeLength;
        CORRECT_IF_SEPARATOR(top, info);
    }
    if (top > info->size) {
        top = info->size;
    }

    for (size_t j = 0; j < top && info->code[j] != '\0'; ) {
        // skip separator if necessary
        if (j == info->sep_first) {
            ++j;
            continue;
        }

        // Current character represents latitude. Retrieve it and convert to
        // degrees (positive range).
        lo.lat += get_alphabet_position(toupper(info->code[j])) * resolution_degrees;
        hi.lat = lo.lat + resolution_degrees;
        ++j;
        if (j == top) {
            break;
        }

        // Current character represents longitude. Retrieve it and convert to
        // degrees (positive range).
        lo.lon += get_alphabet_position(toupper(info->code[j])) * resolution_degrees;
        hi.lon = lo.lon + resolution_degrees;
        ++j;
        if (j == top) {
            break;
        }

        resolution_degrees /= kEncodingBase;
    }

    if (info->pad_first > kPairCodeLength) {
        // Now do any grid square characters.  Adjust the resolution back a
        // step because we need the resolution of the entire grid, not a single
        // grid square.
        // resolution_degrees *= kEncodingBase;

        // With a grid, the latitude and longitude resolutions are no longer
        // equal.
        OLC_LatLon resolution = { resolution_degrees, resolution_degrees };

        // Decode only up to the maximum digit count.
        top = info->len;
        if (top > kMaximumDigitCount) {
            top = kMaximumDigitCount;
            CORRECT_IF_SEPARATOR(top, info);
        }
        int bot = kPairCodeLength;
        CORRECT_IF_SEPARATOR(bot, info);
        for (size_t j = bot; j < top; ++j) {
            // skip separator if necessary
            if (j == info->sep_first) {
                continue;
            }

            // Get the value of the current character and convert it to the
            // degree value.
            size_t value = get_alphabet_position(toupper(info->code[j]));
            size_t row = value / kGridCols;
            size_t col = value % kGridCols;

            // Lat and lon grid sizes shouldn't underflow due to maximum code
            // length enforcement, but a hypothetical underflow won't cause
            // fatal errors here.
            resolution.lat /= kGridRows;
            resolution.lon /= kGridCols;
            lo.lat += row * resolution.lat;
            lo.lon += col * resolution.lon;
            hi.lat = lo.lat + resolution.lat;
            hi.lon = lo.lon + resolution.lon;
        }
    }
    decoded->lo.lat = lo.lat - kLatMaxDegrees;
    decoded->lo.lon = lo.lon - kLonMaxDegrees;
    decoded->hi.lat = hi.lat - kLatMaxDegrees;
    decoded->hi.lon = hi.lon - kLonMaxDegrees;
    decoded->len = code_length(info);
    return decoded->len;
}

static size_t code_length(CodeInfo* info)
{
    int len = info->len;
    if (info->sep_first >= 0) {
        --len;
    }
    if (info->pad_first >= 0) {
        len = info->pad_first;
    }
    return len;
}

static void init_constants(void)
{
    static int inited = 0;
    if (inited) {
        return;
    }
    inited = 1;

    // Work out the encoding base exponent necessary to represent 360 degrees.
    kInitialExponent = floor(log(kLonMaxDegreesT2) / log(kEncodingBase));

    // Work out the enclosing resolution (in degrees) for the grid algorithm.
    kGridSizeDegrees = 1 / pow(kEncodingBase, kPairCodeLength / 2 - (kInitialExponent + 1));

    // Work out the initial resolution
    kInitialResolutionDegrees = pow(kEncodingBase, kInitialExponent);
}

// Raises a number to an exponent, handling negative exponents.
static double pow_neg(double base, double exponent)
{
    if (exponent == 0) {
        return 1;
    }

    if (exponent > 0) {
        return pow(base, exponent);
    }

    return 1 / pow(base, -exponent);
}

// Compute the latitude precision value for a given code length.  Lengths <= 10
// have the same precision for latitude and longitude, but lengths > 10 have
// different precisions due to the grid method having fewer columns than rows.
static double compute_precision_for_length(int length)
{
    // Magic numbers!
    if (length <= kPairCodeLength) {
        return pow_neg(kEncodingBase, floor((length / -2) + 2));
    }

    return pow_neg(kEncodingBase, -3) / pow(5, length - kPairCodeLength);
}

// Normalize a longitude into the range -180 to 180, not including 180.
static double normalize_longitude(double lon_degrees)
{
    while (lon_degrees < -kLonMaxDegrees) {
        lon_degrees += kLonMaxDegreesT2;
    }
    while (lon_degrees >= kLonMaxDegrees) {
        lon_degrees -= kLonMaxDegreesT2;
    }
    return lon_degrees;
}

// Adjusts 90 degree latitude to be lower so that a legal OLC code can be
// generated.
static double adjust_latitude(double lat_degrees, size_t length)
{
    if (lat_degrees < -kLatMaxDegrees) {
        lat_degrees = -kLatMaxDegrees;
    }
    if (lat_degrees >  kLatMaxDegrees) {
        lat_degrees =  kLatMaxDegrees;
    }
    if (lat_degrees < kLatMaxDegrees) {
        return lat_degrees;
    }
    // Subtract half the code precision to get the latitude into the code area.
    double precision = compute_precision_for_length(length);
    return lat_degrees - precision / 2;
}

// Encodes positive range lat,lon into a sequence of OLC lat/lon pairs.  This
// uses pairs of characters (latitude and longitude in that order) to represent
// each step in a 20x20 grid.  Each code, therefore, has 1/400th the area of
// the previous code.
static int encode_pairs(double lat, double lon, size_t length, char* code, int maxlen)
{
    if ((length + 1) >= maxlen) {
        code[0] = '\0';
        return 0;
    }

    init_constants();

    int pos = 0;
    double resolution_degrees = kInitialResolutionDegrees;
    // Add two digits on each pass.
    for (size_t digit_count = 0;
         digit_count < length;
         digit_count += 2, resolution_degrees /= kEncodingBase) {
        size_t digit_value;

        // Do the latitude - gets the digit for this place and subtracts that
        // for the next digit.
        digit_value = floor(lat / resolution_degrees);
        lat -= digit_value * resolution_degrees;
        code[pos++] = kAlphabet[digit_value];

        // Do the longitude - gets the digit for this place and subtracts that
        // for the next digit.
        digit_value = floor(lon / resolution_degrees);
        lon -= digit_value * resolution_degrees;
        code[pos++] = kAlphabet[digit_value];

        // Should we add a separator here?
        if (pos == kSeparatorPosition && pos < length) {
            code[pos++] = kSeparator;
        }
    }
    while (pos < kSeparatorPosition) {
        code[pos++] = kPaddingCharacter;
    }
    if (pos == kSeparatorPosition) {
        code[pos++] = kSeparator;
    }
    code[pos] = '\0';
    return pos;
}

// Encodes a location using the grid refinement method into an OLC string.  The
// grid refinement method divides the area into a grid of 4x5, and uses a
// single character to refine the area.  The grid squares use the OLC
// characters in order to number the squares as follows:
//
//   R V W X
//   J M P Q
//   C F G H
//   6 7 8 9
//   2 3 4 5
//
// This allows default accuracy OLC codes to be refined with just a single
// character.
static int encode_grid(double lat, double lon, size_t length,
                       char* code, int maxlen)
{
    if ((length + 1) >= maxlen) {
        code[0] = '\0';
        return 0;
    }

    init_constants();

    int pos = 0;
    double lat_grid_size = kGridSizeDegrees;
    double lon_grid_size = kGridSizeDegrees;

    // To avoid problems with floating point, get rid of the degrees.
    lat = fmod(lat, 1);
    lon = fmod(lon, 1);
    lat = fmod(lat, lat_grid_size);
    lon = fmod(lon, lon_grid_size);
    for (size_t i = 0; i < length; i++) {
        // The following clause should never execute because of maximum code
        // length enforcement in other functions, but is here to prevent
        // division-by-zero crash from underflow.
        if ((lat_grid_size / kGridRows) <= DBL_MIN ||
            (lon_grid_size / kGridCols) <= DBL_MIN) {
            continue;
        }

        // Work out the row and column.
        size_t row = floor(lat / (lat_grid_size / kGridRows));
        size_t col = floor(lon / (lon_grid_size / kGridCols));
        lat_grid_size /= kGridRows;
        lon_grid_size /= kGridCols;
        lat -= row * lat_grid_size;
        lon -= col * lon_grid_size;
        code[pos++] = kAlphabet[row * kGridCols + col];
    }
    code[pos] = '\0';
    return pos;
}
