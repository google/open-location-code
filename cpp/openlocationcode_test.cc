#include "openlocationcode.h"

#include <stdio.h>
#include <stdlib.h>
#include <fstream>
#include <string>

#include "codearea.h"
#include "gtest/gtest.h"

namespace openlocationcode {
namespace internal {
namespace {

TEST(ParameterChecks, PairCodeLengthIsEven) {
  EXPECT_EQ(0, internal::kPairCodeLength % 2);
}

TEST(ParameterChecks, AlphabetIsOrdered) {
  char last = 0;
  for (size_t i = 0; i < internal::kEncodingBase; i++) {
    EXPECT_TRUE(internal::kAlphabet[i] > last);
    last = internal::kAlphabet[i];
  }
}

TEST(ParameterChecks, SeparatorPositionValid) {
  EXPECT_TRUE(internal::kSeparatorPosition <= internal::kPairCodeLength);
}

TEST(ParameterChecks, ShortenDegreesValid) {
  EXPECT_TRUE(internal::kMinShortenDegrees >= internal::kGridSizeDegrees);
}

}  // namespace
}  // namespace internal

namespace {

std::vector<std::vector<std::string>> ParseCsv(
    const std::string& path_to_file) {
  std::vector<std::vector<std::string>> csv_records;
  std::string line;

  std::ifstream input_stream(path_to_file, std::ifstream::binary);
  while (std::getline(input_stream, line)) {
    // Ignore comments in the file
    if (line.at(0) == '#') {
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
  EXPECT_GT(csv_records.size(), 0);
  return csv_records;
}

struct EncodingTestData {
  std::string code;
  double lat_deg;
  double lng_deg;
  double lo_lat_deg;
  double lo_lng_deg;
  double hi_lat_deg;
  double hi_lng_deg;
};

class EncodingChecks : public ::testing::TestWithParam<EncodingTestData> {};

const std::string kEncodingTestsFile = "test_data/encodingTests.csv";

std::vector<EncodingTestData> GetEncodingDataFromCsv() {
  std::vector<EncodingTestData> data_results;
  std::vector<std::vector<std::string>> csv_records =
      ParseCsv(kEncodingTestsFile);
  for (size_t i = 0; i < csv_records.size(); i++) {
    EncodingTestData test_data = {};
    test_data.code = csv_records[i][0];
    test_data.lat_deg = strtod(csv_records[i][1].c_str(), nullptr);
    test_data.lng_deg = strtod(csv_records[i][2].c_str(), nullptr);
    test_data.lo_lat_deg = strtod(csv_records[i][3].c_str(), nullptr);
    test_data.lo_lng_deg = strtod(csv_records[i][4].c_str(), nullptr);
    test_data.hi_lat_deg = strtod(csv_records[i][5].c_str(), nullptr);
    test_data.hi_lng_deg = strtod(csv_records[i][6].c_str(), nullptr);
    data_results.push_back(test_data);
  }
  return data_results;
}

TEST_P(EncodingChecks, Encode) {
  EncodingTestData test_data = GetParam();
  CodeArea expected_rect =
      CodeArea(test_data.lo_lat_deg, test_data.lo_lng_deg, test_data.hi_lat_deg,
               test_data.hi_lng_deg, CodeLength(test_data.code));
  LatLng lat_lng = LatLng{test_data.lat_deg, test_data.lng_deg};
  // Encode the test location and make sure we get the expected code.
  std::string actual_code = Encode(lat_lng, CodeLength(test_data.code));
  EXPECT_EQ(test_data.code, actual_code);
  // Now decode the code and check we get the correct coordinates.
  CodeArea actual_rect = Decode(test_data.code);
  EXPECT_NEAR(expected_rect.GetCenter().latitude,
              actual_rect.GetCenter().latitude, 1e-10);
  EXPECT_NEAR(expected_rect.GetCenter().longitude,
              actual_rect.GetCenter().longitude, 1e-10);
}

INSTANTIATE_TEST_CASE_P(OLC_Tests, EncodingChecks,
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
  EXPECT_EQ(test_data.is_valid, IsValid(test_data.code));
  EXPECT_EQ(test_data.is_full, IsFull(test_data.code));
  EXPECT_EQ(test_data.is_short, IsShort(test_data.code));
}

INSTANTIATE_TEST_CASE_P(OLC_Tests, ValidityChecks,
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
  LatLng reference_loc =
      LatLng{test_data.reference_lat, test_data.reference_lng};
  // Shorten the code using the reference location and check.
  if (test_data.test_type == "B" || test_data.test_type == "S") {
    std::string actual_short = Shorten(test_data.full_code, reference_loc);
    EXPECT_EQ(test_data.short_code, actual_short);
  }
  // Now extend the code using the reference location and check.
  if (test_data.test_type == "B" || test_data.test_type == "R") {
    std::string actual_full = RecoverNearest(test_data.short_code, reference_loc);
    EXPECT_EQ(test_data.full_code, actual_full);
  }
}

INSTANTIATE_TEST_CASE_P(OLC_Tests, ShortCodeChecks,
                        ::testing::ValuesIn(GetShortCodeDataFromCsv()));

TEST(MaxCodeLengthChecks, MaxCodeLength) {
  LatLng loc = LatLng{51.3701125, -10.202665625};
  // Check we do not return a code longer than is valid.
  std::string long_code = Encode(loc, 1000000);
  // The code length is the maximum digit count plus one for the separator.
  EXPECT_EQ(long_code.size(), 1 + internal::kMaximumDigitCount);
  EXPECT_TRUE(IsValid(long_code));
  Decode(long_code);
  // Extend the code and make sure it is no longer valid.
  std::string too_long_code = long_code + "W";
  EXPECT_FALSE(IsValid(too_long_code));
  // Ensure too many characters after the separator also causes a fail, even if
  // the total number of characters is ok.
  too_long_code = long_code.substr(6) + "WW";
  EXPECT_TRUE(too_long_code.size() < internal::kMaximumDigitCount);
  EXPECT_FALSE(IsValid(too_long_code));
}

}  // namespace
}  // namespace openlocationcode
