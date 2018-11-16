#include <stdio.h>

/*
 * A program to generate OLC's lookup table.
 */

#define MAX_ROW 16
#define MAX_COL 16

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

int main(int argc, char* argv[])
{
    printf("// THIS FILE WAS GENERATED AUTOMATICALLY\n");
    printf("// DO NOT EDIT IT UNLESS YOU KNOW WHAT YOU ARE DOING\n");
    printf("\n");
    printf("static int kAlphabetPositionLUT[%d] = {\n", MAX_ROW * MAX_COL);
    printf("/");
    for (int c = 0; c < MAX_COL; ++c) {
        printf("%c %3x", c == 0 ? '/' : ' ', c);
    }
    printf("\n");
    for (int r = 0; r < MAX_ROW; ++r) {
        printf("  ");
        for (int c = 0; c < MAX_COL; ++c) {
            int character = r * MAX_COL + c;
            int position = get_alphabet_position(character);
            printf(" %3d,", position);
        }
        printf(" // %3x: %02x ~ %02x\n", r, r*MAX_COL, (r+1)*MAX_COL - 1);
    }
    printf("};\n");
    printf("\n");
    printf("#define get_alphabet_position(c) kAlphabetPositionLUT[c]\n");
    return 0;
}
