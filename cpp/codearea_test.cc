#include "codearea.h"
#include "gtest/gtest.h"

namespace openlocationcode {
namespace {

TEST(CodeAreaChecks, Accessors) {
  const CodeArea area(1.0, 2.0, 3.0, 4.0, 6);
  // Check accessor methods return what we expect.
  EXPECT_EQ(area.GetLatitudeLo(), 1.0);
  EXPECT_EQ(area.GetLongitudeLo(), 2.0);
  EXPECT_EQ(area.GetLatitudeHi(), 3.0);
  EXPECT_EQ(area.GetLongitudeHi(), 4.0);
  EXPECT_EQ(area.GetCodeLength(), 6);
}

TEST(CodeAreaChecks, GetCenter) {
  // Simple case.
  const CodeArea area1(0.0, 0.0, 1.0, 2.0, 8);
  EXPECT_EQ(area1.GetCenter().latitude, 0.5);
  EXPECT_EQ(area1.GetCenter().longitude, 1.0);
  // Negative latitudes & longitudes.
  const CodeArea area2(-10.0, -30.0, -24.0, -84.0, 4);
  EXPECT_EQ(area2.GetCenter().latitude, -17.0);
  EXPECT_EQ(area2.GetCenter().longitude, -57.0);
  // Latitude & longitude ranges crossing zero.
  const CodeArea area3(-30.0, -17.0, 5.0, 21.0, 4);
  EXPECT_EQ(area3.GetCenter().latitude, -12.5);
  EXPECT_EQ(area3.GetCenter().longitude, 2.0);
  // Zero-sized area (not strictly valid, but center is still well-defined).
  const CodeArea area4(-65.0, 117.0, -65.0, 117.0, 2);
  EXPECT_EQ(area4.GetCenter().latitude, -65.0);
  EXPECT_EQ(area4.GetCenter().longitude, 117.0);
}

TEST(CodeAreaChecks, IsValid) {
  // All zeroes: invalid.
  EXPECT_FALSE(CodeArea(0.0, 0.0, 0.0, 0.0, 0).IsValid());
  // Whole-world area: valid.
  EXPECT_TRUE(CodeArea(-90.0, -180.0, 90.0, 180.0, 1).IsValid());
  // Typical area: valid.
  EXPECT_TRUE(CodeArea(-1.0, -1.0, 1.0, 1.0, 10).IsValid());
  // Zero code length: invalid.
  EXPECT_FALSE(CodeArea(-1.0, -1.0, 1.0, 1.0, 0).IsValid());
  // Low latitude >= high latitude: invalid.
  EXPECT_FALSE(CodeArea(1.0, -1.0, 1.0, 1.0, 10).IsValid());
  EXPECT_FALSE(CodeArea(2.0, -1.0, 1.0, 1.0, 10).IsValid());
  // Low longitude >= high longitude: invalid.
  EXPECT_FALSE(CodeArea(-1.0, 1.0, 1.0, 1.0, 10).IsValid());
  EXPECT_FALSE(CodeArea(-1.0, 2.0, 1.0, 1.0, 10).IsValid());
}

TEST(CodeAreaChecks, InvalidCodeArea) {
  // CodeArea::InvalideCodeArea() must return an invalid code area, obviously.
  EXPECT_FALSE(CodeArea::InvalidCodeArea().IsValid());
}

}  // namespace
}  // namespace openlocationcode
