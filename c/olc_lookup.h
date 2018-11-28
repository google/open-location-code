// THIS FILE WAS GENERATED AUTOMATICALLY.
// DO NOT EDIT IT UNLESS YOU KNOW WHAT YOU ARE DOING.
//
// Original code had a series of 'if' checks for certain character ranges;
// depending on the range, it used a specific offset in a lookup table.
// We unroll all of that and create a direct lookup table,
// with precomputes the explicit values for all characters.
//
// For the original algorithm, please see function get_alphabet_position()
// in file tools/lug.c (C implementation).

static int kAlphabetPositionLUT[256] = {
//   0    1    2    3    4    5    6    7    8    9    a    b    c    d    e    f
    -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1, //   0: 00 ~ 0f
    -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1, //   1: 10 ~ 1f
    -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1, //   2: 20 ~ 2f
    -1,  -1,   0,   1,   2,   3,   4,   5,   6,   7,  -1,  -1,  -1,  -1,  -1,  -1, //   3: 30 ~ 3f
    -1,  -1,  -1,   8,  -1,  -1,   9,  10,  11,  -1,  12,  -1,  -1,  13,  -1,  -1, //   4: 40 ~ 4f
    14,  15,  16,  -1,  -1,  -1,  17,  18,  19,  -1,  -1,  -1,  -1,  -1,  -1,  -1, //   5: 50 ~ 5f
    -1,  -1,  -1,   8,  -1,  -1,   9,  10,  11,  -1,  12,  -1,  -1,  13,  -1,  -1, //   6: 60 ~ 6f
    14,  15,  16,  -1,  -1,  -1,  17,  18,  19,  -1,  -1,  -1,  -1,  -1,  -1,  -1, //   7: 70 ~ 7f
    -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1, //   8: 80 ~ 8f
    -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1, //   9: 90 ~ 9f
    -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1, //   a: a0 ~ af
    -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1, //   b: b0 ~ bf
    -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1, //   c: c0 ~ cf
    -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1, //   d: d0 ~ df
    -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1, //   e: e0 ~ ef
    -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1, //   f: f0 ~ ff
};

#define get_alphabet_position(c) kAlphabetPositionLUT[c]
