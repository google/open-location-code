// Include the C library into this C++ test file.
extern "C" {
  #include "src/olc.h"
}

#include <chrono>
#include <cstring>
#include <cmath>
#include <fstream>
#include <stdio.h>
#include <stdlib.h>
#include <string>

#include "gtest/gtest.h"

namespace openlocationcode {

namespace {

std::vector<std::vector<std::string>> ParseCsv(
    const std::string& path_to_file) {
  std::vector<std::vector<std::string>> csv_records;
  std::string line;

  std::ifstream input_stream(path_to_file, std::ifstream::binary);
  while (std::getline(input_stream, line)) {
    // Ignore blank lines and comments in the file
    if (line.length() == 0 || line.at(0) == '#') {
      continue;
    }
    std::vector<std::string> line_records;
    std::stringstream lineStream(line);
    std::string cell;
    while (std::getline(lineStream, cell, ',')) {
      line_records.push_back(cell);
    }
    csv_records.push_back(line_records);
  }
  EXPECT_GT(csv_records.size(), (size_t)0);
  return csv_records;
}

struct DecodingTestData {
  std::string code;
  size_t length;
  double lo_lat_deg;
  double lo_lng_deg;
  double hi_lat_deg;
  double hi_lng_deg;
};

class DecodingChecks : public ::testing::TestWithParam<DecodingTestData> {};

const std::string kDecodingTestsFile = "test_data/decoding.csv";

std::vector<DecodingTestData> GetDecodingDataFromCsv() {
  std::vector<DecodingTestData> data_results;
  std::vector<std::vector<std::string>> csv_records =
      ParseCsv(kDecodingTestsFile);
  for (size_t i = 0; i < csv_records.size(); i++) {
    DecodingTestData test_data = {};
    test_data.code = csv_records[i][0];
    test_data.length = atoi(csv_records[i][1].c_str());
    test_data.lo_lat_deg = strtod(csv_records[i][2].c_str(), nullptr);
    test_data.lo_lng_deg = strtod(csv_records[i][3].c_str(), nullptr);
    test_data.hi_lat_deg = strtod(csv_records[i][4].c_str(), nullptr);
    test_data.hi_lng_deg = strtod(csv_records[i][5].c_str(), nullptr);
    data_results.push_back(test_data);
  }
  return data_results;
}

TEST_P(DecodingChecks, Decode) {
  DecodingTestData test_data = GetParam();
  OLC_CodeArea expected_area =
      OLC_CodeArea{
        OLC_LatLon{test_data.lo_lat_deg, test_data.lo_lng_deg},
        OLC_LatLon{test_data.hi_lat_deg, test_data.hi_lng_deg},
        test_data.length};
  OLC_LatLon expected_center = OLC_LatLon{
    (test_data.lo_lat_deg + test_data.hi_lat_deg)/2,
    (test_data.lo_lng_deg + test_data.hi_lng_deg)/2};
  OLC_CodeArea got_area;
  OLC_LatLon got_center;
  OLC_Decode(test_data.code.c_str(), 0, &got_area);
  OLC_GetCenter(&got_area, &got_center);
  EXPECT_EQ(expected_area.len, got_area.len);
  EXPECT_NEAR(expected_area.lo.lat, got_area.lo.lat, 1e-10);
  EXPECT_NEAR(expected_area.lo.lon, got_area.lo.lon, 1e-10);
  EXPECT_NEAR(expected_area.hi.lat, got_area.hi.lat, 1e-10);
  EXPECT_NEAR(expected_area.hi.lon, got_area.hi.lon, 1e-10);
  EXPECT_NEAR(expected_center.lat, got_center.lat, 1e-10);
  EXPECT_NEAR(expected_center.lon, got_center.lon, 1e-10);
}

INSTANTIATE_TEST_SUITE_P(OLC_Tests, DecodingChecks,
                         ::testing::ValuesIn(GetDecodingDataFromCsv()));

struct EncodingTestData {
  double lat_deg;
  double lng_deg;
  size_t length;
  std::string code;
};

class EncodingChecks : public ::testing::TestWithParam<EncodingTestData> {};

const std::string kEncodingTestsFile = "test_data/encoding.csv";

std::vector<EncodingTestData> GetEncodingDataFromCsv() {
  std::vector<EncodingTestData> data_results;
  std::vector<std::vector<std::string>> csv_records =
      ParseCsv(kEncodingTestsFile);
  for (size_t i = 0; i < csv_records.size(); i++) {
    EncodingTestData test_data = {};
    test_data.lat_deg = strtod(csv_records[i][0].c_str(), nullptr);
    test_data.lng_deg = strtod(csv_records[i][1].c_str(), nullptr);
    test_data.length = atoi(csv_records[i][2].c_str());
    test_data.code = csv_records[i][3];
    data_results.push_back(test_data);
  }
  return data_results;
}

TEST_P(EncodingChecks, Encode) {
  EncodingTestData test_data = GetParam();
  OLC_LatLon loc = OLC_LatLon{test_data.lat_deg, test_data.lng_deg};
  char got_code[18];
  // Encode the test location and make sure we get the expected code.
  OLC_Encode(&loc, test_data.length, got_code, 18);
  EXPECT_EQ(test_data.code, got_code);
}

INSTANTIATE_TEST_SUITE_P(OLC_Tests, EncodingChecks,
                         ::testing::ValuesIn(GetEncodingDataFromCsv()));

struct ValidityTestData {
  std::string code;
  bool is_valid;
  bool is_short;
  bool is_full;
};

class ValidityChecks : public ::testing::TestWithParam<ValidityTestData> {};

const std::string kValidityTestsFile = "test_data/validityTests.csv";

std::vector<ValidityTestData> GetValidityDataFromCsv() {
  std::vector<ValidityTestData> data_results;
  std::vector<std::vector<std::string>> csv_records =
      ParseCsv(kValidityTestsFile);
  for (size_t i = 0; i < csv_records.size(); i++) {
    ValidityTestData test_data = {};
    test_data.code = csv_records[i][0];
    test_data.is_valid = csv_records[i][1] == "true";
    test_data.is_short = csv_records[i][2] == "true";
    test_data.is_full = csv_records[i][3] == "true";
    data_results.push_back(test_data);
  }
  return data_results;
}

TEST_P(ValidityChecks, Validity) {
  ValidityTestData test_data = GetParam();
  EXPECT_EQ(test_data.is_valid, OLC_IsValid(test_data.code.c_str(), 0));
  EXPECT_EQ(test_data.is_full, OLC_IsFull(test_data.code.c_str(), 0));
  EXPECT_EQ(test_data.is_short, OLC_IsShort(test_data.code.c_str(), 0));
}

INSTANTIATE_TEST_SUITE_P(OLC_Tests, ValidityChecks,
                         ::testing::ValuesIn(GetValidityDataFromCsv()));

struct ShortCodeTestData {
  std::string full_code;
  double reference_lat;
  double reference_lng;
  std::string short_code;
  std::string test_type;
};

class ShortCodeChecks : public ::testing::TestWithParam<ShortCodeTestData> {};

const std::string kShortCodeTestsFile = "test_data/shortCodeTests.csv";

std::vector<ShortCodeTestData> GetShortCodeDataFromCsv() {
  std::vector<ShortCodeTestData> data_results;
  std::vector<std::vector<std::string>> csv_records =
      ParseCsv(kShortCodeTestsFile);
  for (size_t i = 0; i < csv_records.size(); i++) {
    ShortCodeTestData test_data = {};
    test_data.full_code = csv_records[i][0];
    test_data.reference_lat = strtod(csv_records[i][1].c_str(), nullptr);
    test_data.reference_lng = strtod(csv_records[i][2].c_str(), nullptr);
    test_data.short_code = csv_records[i][3];
    test_data.test_type = csv_records[i][4];
    data_results.push_back(test_data);
  }
  return data_results;
}

TEST_P(ShortCodeChecks, ShortCode) {
  ShortCodeTestData test_data = GetParam();
  OLC_LatLon reference_loc =
      OLC_LatLon{test_data.reference_lat, test_data.reference_lng};
  // Shorten the code using the reference location and check.
  if (test_data.test_type == "B" || test_data.test_type == "S") {
    char got[18];
    OLC_Shorten(test_data.full_code.c_str(), 0, &reference_loc, got, 18);
    EXPECT_EQ(test_data.short_code, got);
  }
  // Now extend the code using the reference location and check.
  if (test_data.test_type == "B" || test_data.test_type == "R") {
    char got[18];
    OLC_RecoverNearest(test_data.short_code.c_str(), 0, &reference_loc, got, 18);
    EXPECT_EQ(test_data.full_code, got);
  }
}

INSTANTIATE_TEST_SUITE_P(OLC_Tests, ShortCodeChecks,
                         ::testing::ValuesIn(GetShortCodeDataFromCsv()));

TEST(MaxCodeLengthChecks, MaxCodeLength) {
  std::string long_code = "8FVC9G8F+6W23456";
  EXPECT_TRUE(OLC_IsValid(long_code.c_str(), 0));
  // Extend the code with a valid character and make sure it is still valid.
  std::string too_long_code = long_code + "W";
  EXPECT_TRUE(OLC_IsValid(too_long_code.c_str(), 0));
  // Extend the code with an invalid character and make sure it is invalid.
  too_long_code = long_code + "U";
  EXPECT_FALSE(OLC_IsValid(too_long_code.c_str(), 0));
}

struct BenchmarkTestData {
  OLC_LatLon latlon;
  size_t len;
  char code[18];
};

TEST(BenchmarkChecks, BenchmarkEncodeDecode) {
  std::srand(std::time(0));
  std::vector<BenchmarkTestData> tests;
  const size_t loops = 1000000;
  for (size_t i = 0; i < loops; i++) {
    BenchmarkTestData test_data = {};
    double lat = (double)rand() / RAND_MAX * 180 - 90;
    double lon = (double)rand() / RAND_MAX * 360 - 180;
    size_t rounding = pow(10, round((double)rand() / RAND_MAX * 10));
    lat = round(lat * rounding) / rounding;
    lon = round(lon * rounding) / rounding;
    size_t len = round((double)rand() / RAND_MAX * 15);
    if (len < 10 && len % 2 == 1) {
      len += 1;
    }
    test_data.latlon.lat = lat;
    test_data.latlon.lon = lon;
    test_data.len = len;
    OLC_Encode(&test_data.latlon, test_data.len, test_data.code, 18);
    tests.push_back(test_data);
  }
  char code[18];
  auto start = std::chrono::high_resolution_clock::now();
  for (auto td : tests) {
    OLC_Encode(&td.latlon, td.len, code, 18);
  }
  auto duration = std::chrono::duration_cast<std::chrono::microseconds>(
                      std::chrono::high_resolution_clock::now() - start)
                      .count();
  std::cout << "Encoding " << loops << " locations took " << duration
            << " usecs total, " << (float)duration / loops
            << " usecs per call\n";

  OLC_CodeArea code_area;
  start = std::chrono::high_resolution_clock::now();
  for (auto td : tests) {
    OLC_Decode(td.code, 0, &code_area);
  }
  duration = std::chrono::duration_cast<std::chrono::microseconds>(
                 std::chrono::high_resolution_clock::now() - start)
                 .count();
  std::cout << "Decoding " << loops << " locations took " << duration
            << " usecs total, " << (float)duration / loops
            << " usecs per call\n";
}

}  // namespace
}  // namespace openlocationcode
