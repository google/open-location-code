#include <sys/time.h>
#include "openlocationcode.h"

#include "shared.c"

int main(int argc, char* argv[])
{
    return run(argc, argv);
}

static void encode(void)
{
    // Encodes latitude and longitude into a Plus+Code.
    std::string code = openlocationcode::Encode({data_pos_lat, data_pos_lon});

    ASSERT_STR_EQ(code.c_str(), "8FVC2222+22");
    ASSERT_INT_EQ(code.length(), 11);
}

static void encode_len(void)
{
    // Encodes latitude and longitude into a Plus+Code with a preferred length.
    std::string code = openlocationcode::Encode({data_pos_lat, data_pos_lon}, data_pos_len);

    ASSERT_STR_EQ(code.c_str(), "8FVC2222+22GCCCC");
    ASSERT_INT_EQ(code.length(), 16);
}

static void decode(void)
{
    // Decodes a Plus+Code back into coordinates.
    openlocationcode::CodeArea code_area = openlocationcode::Decode(data_code_16);

    ASSERT_FLT_EQ(code_area.GetLatitudeLo(), 47.000062496);
    ASSERT_FLT_EQ(code_area.GetLongitudeLo(), 8.00006250000001);
    ASSERT_FLT_EQ(code_area.GetLatitudeHi(), 47.000062504);
    ASSERT_FLT_EQ(code_area.GetLongitudeHi(), 8.0000625305176);
    ASSERT_INT_EQ(code_area.GetCodeLength(), 15);
}

static void is_valid(void)
{
    // Checks if a Plus+Code is valid.
    int ok = openlocationcode::IsValid(data_code_16);

    ASSERT_INT_EQ(ok, 1);
}

static void is_full(void)
{
    // Checks if a Plus+Code is full.
    int ok = openlocationcode::IsFull(data_code_16);

    ASSERT_INT_EQ(ok, 1);
}

static void is_short(void)
{
    // Checks if a Plus+Code is short.
    int ok = openlocationcode::IsShort(data_code_16);

    ASSERT_INT_EQ(ok, 0);
}

static void shorten(void)
{
    // Shorten a Plus+Codes if possible by the given reference latitude and
    // longitude.
    std::string short_code =
        openlocationcode::Shorten(data_code_12, {data_ref_lat, data_ref_lon});

    ASSERT_STR_EQ(short_code.c_str(), "CJ+2VX");
    ASSERT_INT_EQ(short_code.length(), 6);
}

static void recover(void)
{
    // Extends a Plus+Code by the given reference latitude and longitude.
    std::string recovered_code =
        openlocationcode::RecoverNearest(data_code_6, {data_ref_lat, data_ref_lon});

    ASSERT_STR_EQ(recovered_code.c_str(), "9C3W9QCJ+2VX");
    ASSERT_INT_EQ(recovered_code.length(), 12);
}
