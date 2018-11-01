#include <ctype.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "olc.h"

#define BASE_PATH "../test_data"

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

static int test_short_code(char* cp[], int cn);
static int test_encoding(char* cp[], int cn);
static int test_validity(char* cp[], int cn);

static int process_file(const char* file, TestFunc func);
static int to_boolean(const char* s);

int main(int argc, char* argv[])
{
    struct Data {
        const char* file;
        TestFunc* func;
    } data[] = {
        { "shortCodeTests.csv", test_short_code },
        { "encodingTests.csv" , test_encoding   },
        { "validityTests.csv" , test_validity   },
    };
    for (int j = 0; j < sizeof(data) / sizeof(data[0]); ++j) {
        process_file(data[j].file, data[j].func);
    }

    return 0;
}

static int process_file(const char* file, TestFunc func)
{
    char full[1024];
    sprintf(full, "%s/%s", BASE_PATH, file);
    FILE* fp = fopen(full, "r");
    if (!fp) {
        printf("Could not open [%s]\n", full);
        return 0;
    }
    int total = 0;
    int valid = 0;
    while (1) {
        char line[1024];
        if (!fgets(line, 1024, fp)) {
            break;
        }
        int blanks = 1;
        char* cp[100];
        int cn = 0;
        int first = -1;
        for (int j = 0; line[j] != '\0'; ++j) {
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
    return total;
}

static int test_encoding(char* cp[], int cn)
{
    CHECK_COLUMNS("test_encoding", 7, cp, cn);

    // code,lat,lng,latLo,lngLo,latHi,lngHi
    int valid = 1;
    int ok = 0;

    char* code = cp[0];
    int len = OLC_CodeLength(code, 0);

    OLC_LatLon data_pos = { strtod(cp[1], 0), strtod(cp[2], 0) };

    // Encode the test location and make sure we get the expected code.
    char encoded[256];
    OLC_Encode(&data_pos, len, encoded, 256);
    ok = strcmp(code, encoded) == 0;
    valid = valid && ok;
    fprintf(stderr, "%-3.3s ENC_CODE [%s:%s] [%s] [%s]\n", ok ? "OK" : "BAD", cp[1], cp[2], encoded, code);

    // Now decode the code and check we get the correct coordinates.
    OLC_CodeArea data_area = {
        { strtod(cp[3], 0), strtod(cp[4], 0) },
        { strtod(cp[5], 0), strtod(cp[6], 0) },
        len,
    };

    OLC_LatLon data_center;
    OLC_GetCenter(&data_area, &data_center);

    OLC_CodeArea decoded_area;
    OLC_Decode(code, 0, &decoded_area);

    OLC_LatLon decoded_center;
    OLC_GetCenter(&decoded_area, &decoded_center);

    ok = fabs(data_center.lat - decoded_center.lat) < 1e-10;
    valid = valid && ok;
    fprintf(stderr, "%-3.3s ENC_LAT [%f:%f]\n", ok ? "OK" : "BAD", decoded_center.lat, data_center.lat);
    ok = fabs(data_center.lon - decoded_center.lon) < 1e-10;
    valid = valid && ok;
    fprintf(stderr, "%-3.3s ENC_LON [%f:%f]\n", ok ? "OK" : "BAD", decoded_center.lon, data_center.lon);

    return valid;
}

static int test_short_code(char* cp[], int cn)
{
    CHECK_COLUMNS("test_short_code", 5, cp, cn);

    // full code,lat,lng,shortcode,test_type
    // test_type is R for recovery only, S for shorten only, or B for both.
    int valid = 1;
    int ok = 0;
    char code[256];
    char* full_code = cp[0];
    char* short_code = cp[3];
    char* type = cp[4];

    OLC_LatLon reference = { strtod(cp[1], 0), strtod(cp[2], 0) };

    // Shorten the code using the reference location and check.
    if (strcmp(type, "B") == 0 || strcmp(type, "S") == 0) {
        OLC_Shorten(full_code, 0, &reference, code, 256);
        ok = strcmp(short_code, code) == 0;
        valid = valid && ok;
        fprintf(stderr, "%-3.3s SHORTEN [%s] [%s:%s]: [%s] [%s]\n", ok ? "OK" : "BAD", full_code, cp[1], cp[2], code, short_code);
    }

    // Now extend the code using the reference location and check.
    if (strcmp(type, "B") == 0 || strcmp(type, "R") == 0) {
        OLC_RecoverNearest(short_code, 0, &reference, code, 256);
        ok = strcmp(full_code, code) == 0;
        valid = valid && ok;
        fprintf(stderr, "%-3.3s RECOVER [%s] [%s:%s]: [%s] [%s]\n", ok ? "OK" : "BAD", short_code, cp[1], cp[2], code, full_code);
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
    fprintf(stderr, "%-3.3s IsValid [%s]: [%d] [%d]\n", ok ? "OK" : "BAD", code, got, is_valid);

    got = OLC_IsFull(code, 0);
    ok = got == is_full;
    valid = valid && ok;
    fprintf(stderr, "%-3.3s IsFull [%s]: [%d] [%d]\n", ok ? "OK" : "BAD", code, got, is_full);

    got = OLC_IsShort(code, 0);
    ok = got == is_short;
    valid = valid && ok;
    fprintf(stderr, "%-3.3s IsShort [%s]: [%d] [%d]\n", ok ? "OK" : "BAD", code, got, is_short);

    return valid;
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
