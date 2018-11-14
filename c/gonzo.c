#include <stdio.h>
#include "olc_private.h"

int main(int argc, char* argv[])
{
    for (int j = 0; j < 0xff; ++j) {
        int p = get_alphabet_position(j);
        printf("%3d %d\n", j, p);
    }
    return 0;
}
