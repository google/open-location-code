/*
 * We place these static definitions on a separate header file so that we can
 * include the file in both the library and the tests.
 */

static const char   kSeparator         = '+';
static const size_t kSeparatorPosition = 8;
static const char   kPaddingCharacter  = '0';
static const char   kAlphabet[]        = "23456789CFGHJMPQRVWX";
static const size_t kEncodingBase      = 20;
static const size_t kPairCodeLength    = 10;
static const size_t kGridCols          = 4;
static const size_t kGridRows          = kEncodingBase / kGridCols;

// The max number of digits returned in a plus code. Roughly 1 x 0.5 cm.
static const size_t kMaximumDigitCount = 15;

// Latitude bounds are -kLatMaxDegrees degrees and +kLatMaxDegrees degrees
// which we transpose to 0 and 180 degrees.
static const double kLatMaxDegrees     = 90;
static const double kLatMaxDegreesT2   = 2 * kLatMaxDegrees;

// Longitude bounds are -kLonMaxDegrees degrees and +kLonMaxDegrees degrees
// which we transpose to 0 and 360 degrees.
static const double kLonMaxDegrees     = 180;
static const double kLonMaxDegreesT2   = 2 * kLonMaxDegrees;

// These will be defined later, during runtime.
static size_t kInitialExponent          = 0;
static double kGridSizeDegrees          = 0.0;
static double kInitialResolutionDegrees = 0.0;

// Lookup table of the alphabet positions of characters 'C' through 'X',
// inclusive. A value of -1 means the character isn't part of the alphabet.
static const int kPositionLUT['X' - 'C' + 1] = {
    8, -1, -1, 9, 10, 11, -1, 12, -1, -1,
    13, -1, -1, 14, 15, 16, -1, -1, -1, 17, 18, 19,
};
