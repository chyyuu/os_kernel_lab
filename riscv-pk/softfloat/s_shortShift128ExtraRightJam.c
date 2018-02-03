
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

struct uint128_extra
 softfloat_shortShift128ExtraRightJam(
     uint64_t a64, uint64_t a0, uint64_t extra, unsigned int count )
{
    unsigned int negCount;
    struct uint128_extra z;

    negCount = - count;
    z.v64 = a64>>count;
    z.v0 = a64<<( negCount & 63 ) | a0>>count;
    z.extra = a0<<( negCount & 63 ) | ( extra != 0 );
    return z;

}

