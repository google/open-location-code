/*
 * We place these static definitions on a separate header file so that we can
 * include the file in both the library and the tests.
 */

#include <ctype.h>
#include <float.h>
#include <math.h>
#include <memory.h>

#define OLC_kEncodingBase      20
#define OLC_kGridCols          4
#define OLC_kLatMaxDegrees     90
#define OLC_kLonMaxDegrees     180

static const char   kSeparator         = '+';
static const size_t kSeparatorPosition = 8;
static const char   kPaddingCharacter  = '0';
static const char   kAlphabet[]        = "23456789CFGHJMPQRVWX";
static const size_t kEncodingBase      = OLC_kEncodingBase;
static const size_t kPairCodeLength    = 10;
static const size_t kGridCols          = OLC_kGridCols;
static const size_t kGridRows          = OLC_kEncodingBase / OLC_kGridCols;

// The max number of digits returned in a plus code. Roughly 1 x 0.5 cm.
static const size_t kMaximumDigitCount = 15;

// Latitude bounds are -kLatMaxDegrees degrees and +kLatMaxDegrees degrees
// which we transpose to 0 and 180 degrees.
static const double kLatMaxDegrees     = OLC_kLatMaxDegrees;
static const double kLatMaxDegreesT2   = 2 * OLC_kLatMaxDegrees;

// Longitude bounds are -kLonMaxDegrees degrees and +kLonMaxDegrees degrees
// which we transpose to 0 and 360 degrees.
static const double kLonMaxDegrees     = OLC_kLonMaxDegrees;
static const double kLonMaxDegreesT2   = 2 * OLC_kLonMaxDegrees;

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

// Returns the position of a char in the encoding alphabet, or -1 if invalid.
static int get_alphabet_position(char c)
{
  // We use a lookup table for performance reasons.
  if (c >= 'C' && c <= 'X') return kPositionLUT[c - 'C'];
  if (c >= 'c' && c <= 'x') return kPositionLUT[c - 'c'];
  if (c >= '2' && c <= '9') return c - '2';
  return -1;
}
