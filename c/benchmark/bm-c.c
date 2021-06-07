#include <sys/time.h>
#include "olc.h"

#include "shared.c"

int main(int argc, char* argv[]) { return run(argc, argv); }

static void encode(void) {
  char code[256];
  int len;
  OLC_LatLon location;

  // Encodes latitude and longitude into a Plus+Code.
  location.lat = data_pos_lat;
  location.lon = data_pos_lon;
  len = OLC_EncodeDefault(&location, code, 256);

  ASSERT_STR_EQ(code, "8FVC2222+22");
  ASSERT_INT_EQ(len, 11);
}

static void encode_len(void) {
  char code[256];
  int len;
  OLC_LatLon location;

  // Encodes latitude and longitude into a Plus+Code with a preferred length.
  location.lat = data_pos_lat;
  location.lon = data_pos_lon;
  len = OLC_Encode(&location, data_pos_len, code, 256);

  ASSERT_STR_EQ(code, "8FVC2222+22GCCCC");
  ASSERT_INT_EQ(len, 16);
}

static void decode(void) {
  OLC_CodeArea code_area;

  // Decodes a Plus+Code back into coordinates.
  OLC_Decode(data_code_16, 0, &code_area);

  ASSERT_FLT_EQ(code_area.lo.lat, 47.000062496);
  ASSERT_FLT_EQ(code_area.lo.lon, 8.00006250000001);
  ASSERT_FLT_EQ(code_area.hi.lat, 47.000062504);
  ASSERT_FLT_EQ(code_area.hi.lon, 8.0000625305176);
  ASSERT_INT_EQ(code_area.len, 15);
}

static void is_valid(void) {
  // Checks if a Plus+Code is valid.
  int ok = !!OLC_IsValid(data_code_16, 0);
  ASSERT_INT_EQ(ok, 1);
}

static void is_full(void) {
  // Checks if a Plus+Code is full.
  int ok = !!OLC_IsFull(data_code_16, 0);
  ASSERT_INT_EQ(ok, 1);
}

static void is_short(void) {
  // Checks if a Plus+Code is short.
  int ok = !!OLC_IsShort(data_code_16, 0);
  ASSERT_INT_EQ(ok, 0);
}

static void shorten(void) {
  // Shorten a Plus+Codes if possible by the given reference latitude and
  // longitude.
  char code[256];
  OLC_LatLon location;
  location.lat = data_ref_lat;
  location.lon = data_ref_lon;
  int len = OLC_Shorten(data_code_12, 0, &location, code, 256);

  ASSERT_STR_EQ(code, "CJ+2VX");
  ASSERT_INT_EQ(len, 6);
}

static void recover(void) {
  char code[256];
  OLC_LatLon location;
  location.lat = data_ref_lat;
  location.lon = data_ref_lon;
  // Extends a Plus+Code by the given reference latitude and longitude.
  int len = OLC_RecoverNearest(data_code_6, 0, &location, code, 256);

  ASSERT_STR_EQ(code, "9C3W9QCJ+2VX");
  ASSERT_INT_EQ(len, 12);
}
