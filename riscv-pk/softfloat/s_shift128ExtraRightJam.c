
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

struct uint128_extra
 softfloat_shift128ExtraRightJam(
     uint64_t a64, uint64_t a0, uint64_t extra, unsigned int count )
{
    unsigned int negCount;
    struct uint128_extra z;

    negCount = - count;
    if ( count < 64 ) {
        z.v64 = a64>>count;
        z.v0 = a64<<( negCount & 63 ) | a0>>count;
        z.extra = a0<<( negCount & 63 );
    } else {
        z.v64 = 0;
        if ( count == 64 ) {
            z.v0 = a64;
            z.extra = a0;
        } else {
            extra |= a0;
            if ( count < 128 ) {
                z.v0 = a64>>( count & 63 );
                z.extra = a64<<( negCount & 63 );
            } else {
                z.v0 = 0;
                z.extra = ( count == 128 ) ? a64 : ( a64 != 0 );
            }
        }
    }
    z.extra |= ( extra != 0 );
    return z;

}

