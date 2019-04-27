#include <ctype.h>
#include <math.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include "olc.h"
#include "olc_private.h"
#include "tests.h"

#define OLC_BASE_PATH "test_data"

#define CHECK_COLUMNS(name, needed, cp, cn) \
    do { \
        if (cn != needed) { \
            printf("%s needs %d columns per row, not %d\n", name, needed, cn); \
            for (int j = 0; j < cn; ++j) { \
                printf(" column %2d: [%s]\n", j, cp[j]); \
            } \
            return 0; /* or maybe abort() */ \
        } \
    } while (0)

typedef int (TestFunc)(char* cp[], int cn);

TEST(ParameterChecks, PairCodeLengthIsEven)
{
    EXPECT_NUM_EQ(0, kPairCodeLength % 2);
}

TEST(ParameterChecks, AlphabetIsOrdered)
{
    char last = 0;
    for (size_t i = 0; i < kEncodingBase; i++) {
        EXPECT_NUM_GT(kAlphabet[i], last);
        last = kAlphabet[i];
    }
}

TEST(ParameterChecks, PositionLUTMatchesAlphabet)
{
    // Loop over all elements of the lookup table.
    for (size_t i = 0;
            i < sizeof(kPositionLUT) / sizeof(kPositionLUT[0]);
            ++i) {
        const int pos = kPositionLUT[i];
        const char c = 'C' + i;
        if (pos != -1) {
            // If the LUT entry indicates this character is in kAlphabet, verify it.
            EXPECT_NUM_LT(pos, kEncodingBase);
            EXPECT_NUM_EQ(c, kAlphabet[pos]);
        } else {
            // Otherwise, verify this character is not in kAlphabet.
            EXPECT_NUM_EQ(strchr(kAlphabet, c), 0);
        }
    }
}

TEST(ParameterChecks, SeparatorPositionValid)
{
    EXPECT_NUM_LE(kSeparatorPosition, kPairCodeLength);
}

TEST(Extra, LongCodes)
{
    char code[256];
    int len;
    OLC_LatLon location;

    // Encodes latitude and longitude into a Plus+Code.
    location.lat = 47.0000625;
    location.lon =  8.0000625;
    len = OLC_EncodeDefault(&location, code, 256);
    EXPECT_NUM_EQ(len, 11);
    EXPECT_STR_EQ(code, "8FVC2222+22");

    // Encodes latitude and longitude into a Plus+Code with a preferred length.
    len = OLC_Encode(&location, 15, code, 256);
    EXPECT_NUM_EQ(len, 16);
    EXPECT_STR_EQ(code, "8FVC2222+22GCCCC");

    len = OLC_CodeLength(code, 256);
    EXPECT_NUM_EQ(len, 15);

    // Decodes a Plus+Code back into coordinates.
    OLC_CodeArea code_area;
    len = OLC_Decode(code, 0, &code_area);
    EXPECT_NUM_EQ(len, 15);
    EXPECT_NUM_EQ(code_area.lo.lat, 47.000062479999997);
    EXPECT_NUM_EQ(code_area.lo.lon,  8.000062500000013);
    EXPECT_NUM_EQ(code_area.hi.lat, 47.000062520000000);
    EXPECT_NUM_EQ(code_area.hi.lon,  8.000062622070317);
}

TEST(Extra, Version)
{
    int current_version = OLC_VERSION_NUM;
    int minimum_version = OLC_MAKE_VERSION_NUM(1, 0, 0);
    EXPECT_NUM_GE(current_version, minimum_version);
}

TEST(ParameterChecks, SilenceWarningsForConstants)
{
  EXPECT_NUM_EQ(kInitialExponent, 0);
  EXPECT_NUM_EQ(kGridSizeDegrees, 0.0);
  EXPECT_NUM_EQ(kInitialResolutionDegrees, 0.0);
}

/**
 * Process a CSV file and run it's data through the test function.
 * Returns true (0) if all tests pass, false (1) if there is a failure.
 */
static int process_file(const char* file, TestFunc func)
{
    static char* base_dir[] = {
        "..",
        ".",
    };
    FILE* fp = 0;
    for (int j = 0; j < sizeof(base_dir) / sizeof(base_dir[0]); ++j) {
        char full[1024];
        sprintf(full, "%s/%s/%s", base_dir[j], OLC_BASE_PATH, file);
        fp = fopen(full, "r");
        if (fp) {
            break;
        }
    }
    if (!fp) {
        printf("Could not open [%s]\n", file);
        return 0;
    }
    int total = 0;
    int valid = 0;
    while (1) {
        char line[1024];
        if (!fgets(line, 1024, fp)) {
            break;
        }
        if (line[0] == '\n') {
          continue;
        }
        int blanks = 1;
        char* cp[100];
        int cn = 0;
        int first = -1;
        for (int j = 0; ; ++j) {
            if (isspace(line[j]) && blanks) {
                continue;
            }
            if (line[j] == '#' && blanks) {
                break;
            }
            blanks = 0;
            if (first < 0) {
                first = j;
            }
            if (line[j] == ',') {
                line[j] = '\0';
                cp[cn++] = line + first;
                first = j + 1;
                continue;
            }
            if (line[j] == '\n') {
                line[j] = '\0';
            }
            if (line[j] == '\0') {
                cp[cn++] = line + first;
                first = -1;
                break;
            }
        }
        if (cn <= 0) {
            continue;
        }
        valid += func(cp, cn);
        ++total;
    }
    fclose(fp);
    printf("%30.30s => %3d records, %3d OK, %3d BAD\n",
           file, total, valid, total - valid);
    return total - valid == 0;
}

static int to_boolean(const char* s)
{
    if (!s || s[0] == '\0') {
        return 0;
    }
    if (strcasecmp(s, "false") == 0 ||
        strcasecmp(s, "no") == 0 ||
        strcasecmp(s, "f") == 0 ||
        strcasecmp(s, ".f.") == 0 ||
        strcasecmp(s, "n") == 0) {
        return 0;
    }
    return 1;
}

static int test_encoding(char* cp[], int cn)
{
    CHECK_COLUMNS("test_encoding", 4, cp, cn);

    // Encode the test location and make sure we get the expected code.
    // lat,lng,len,code
    OLC_LatLon data_pos = { strtod(cp[0], 0), strtod(cp[1], 0) };
    char encoded[256];
    OLC_Encode(&data_pos, atoi(cp[2]), encoded, 256);

    int ok = strcmp(cp[3], encoded) == 0;
    if (!ok) {
      fprintf(stderr, "test_encoding [%s:%s:%s] [%s] [%s]\n", cp[0], cp[1], cp[2], encoded, cp[3]);
    }

    return ok;
}

static int test_decoding(char* cp[], int cn)
{
    CHECK_COLUMNS("test_decoding", 6, cp, cn);

    // code,length,latLo,lngLo,latHi,lngHi
    int valid = 1;

    // Check the length function.
    int len = OLC_CodeLength(cp[0], 0);
    valid = valid && len == atoi(cp[1]);
    if (!valid) {
      fprintf(stderr, "test_decoding length [%s] [%d] [%d]\n", cp[0], atoi(cp[1]), len);
    }

    // Now decode the code and check we get the correct coordinates.
    OLC_CodeArea want = {
        { strtod(cp[2], 0), strtod(cp[3], 0) },
        { strtod(cp[4], 0), strtod(cp[5], 0) },
        len,
    };
    OLC_CodeArea got;
    OLC_Decode(cp[0], 0, &got);

    valid = valid && fabs(want.lo.lat - got.lo.lat) < 1e-10;
    valid = valid && fabs(want.lo.lon - got.lo.lon) < 1e-10;
    valid = valid && fabs(want.hi.lat - got.hi.lat) < 1e-10;
    valid = valid && fabs(want.hi.lon - got.hi.lon) < 1e-10;
    valid = valid && want.len == got.len;
    if (!valid) {
      fprintf(stderr, "test_decoding [%s] [%f:%f:%f:%f:%li] [%f:%f:%f:%f:%li]\n", cp[0],
          want.lo.lat, want.lo.lon, want.hi.lat, want.hi.lon, want.len,
          got.lo.lat, got.lo.lon, got.hi.lat, got.hi.lon, got.len);
    }

    return valid;
}

static int test_short_code(char* cp[], int cn)
{
    CHECK_COLUMNS("test_short_code", 5, cp, cn);

    // full code,lat,lng,shortcode,test_type
    // test_type is R for recovery only, S for shorten only, or B for both.
    int valid = 1;
    int ok = 0;
    char got[256];
    char* full_code = cp[0];
    char* short_code = cp[3];
    char* type = cp[4];

    OLC_LatLon reference = { strtod(cp[1], 0), strtod(cp[2], 0) };

    // Shorten the code using the reference location and check.
    if (strcmp(type, "B") == 0 || strcmp(type, "S") == 0) {
        OLC_Shorten(full_code, 0, &reference, got, 256);
        ok = strcmp(short_code, got) == 0;
        valid = valid && ok;
        if (!ok) {
          fprintf(stderr, "shorten [%s] [%s:%s]: [%s] [%s]\n", full_code, cp[1], cp[2], got, short_code);
        }
    }

    // Now extend the code using the reference location and check.
    if (strcmp(type, "B") == 0 || strcmp(type, "R") == 0) {
        OLC_RecoverNearest(short_code, 0, &reference, got, 256);
        ok = strcmp(full_code, got) == 0;
        valid = valid && ok;
        if (!ok) {
          fprintf(stderr, "recover [%s] [%s:%s]: [%s] [%s]\n", short_code, cp[1], cp[2], got, full_code);
        }
    }

    return valid;
}

static int test_validity(char* cp[], int cn)
{
    CHECK_COLUMNS("test_validity", 4, cp, cn);

    // code,isValid,isShort,isFull
    int valid = 1;
    int ok = 0;
    int got;
    char* code = cp[0];
    int is_valid = to_boolean(cp[1]);
    int is_short = to_boolean(cp[2]);
    int is_full = to_boolean(cp[3]);

    got = OLC_IsValid(code, 0);
    ok = got == is_valid;
    valid = valid && ok;
    if (!ok) {
      fprintf(stderr, "IsValid [%s]: [%d] [%d]\n", code, got, is_valid);
    }

    got = OLC_IsFull(code, 0);
    ok = got == is_full;
    valid = valid && ok;
    if (!ok) {
      fprintf(stderr, "IsFull [%s]: [%d] [%d]\n", code, got, is_full);
    }

    got = OLC_IsShort(code, 0);
    ok = got == is_short;
    valid = valid && ok;
    if (!ok) {
      fprintf(stderr, "IsShort [%s]: [%d] [%d]\n", code, got, is_short);
    }

    return valid;
}

static int test_csv_files(void)
{
    struct Data {
        const char* file;
        TestFunc* func;
    } data[] = {
        { "shortCodeTests.csv", test_short_code },
        { "encoding.csv" , test_encoding },
        { "decoding.csv" , test_decoding },
        { "validityTests.csv" , test_validity },
    };
    int valid = 1;
    for (int j = 0; j < sizeof(data) / sizeof(data[0]); ++j) {
        valid = valid && process_file(data[j].file, data[j].func);
    }
    return valid;
}

int main(int argc, char* argv[])
{
    test_Extra_Version();
    test_ParameterChecks_PairCodeLengthIsEven();
    test_ParameterChecks_AlphabetIsOrdered();
    test_ParameterChecks_PositionLUTMatchesAlphabet();
    test_ParameterChecks_SeparatorPositionValid();
    test_ParameterChecks_SilenceWarningsForConstants();
    test_Extra_LongCodes();

    if (test_csv_files()) {
      return 0;
    }
    return 1;
}
