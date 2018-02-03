
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

struct uint128
 softfloat_shift128RightJam( uint64_t a64, uint64_t a0, unsigned int count )
{
    unsigned int negCount;
    struct uint128 z;

    if ( count < 64 ) {
        negCount = - count;
        z.v64 = a64>>( count & 63 );
        z.v0 =
            a64<<( negCount & 63 ) | a0>>count
                | ( (uint64_t) ( a0<<( negCount & 63 ) ) != 0 );
    } else {
        z.v64 = 0;
        z.v0 =
            ( count < 128 )
                ? a64>>( count & 63 )
                      | ( ( ( a64 & ( ( (uint64_t) 1<<( count & 63 ) ) - 1 ) )
                                | a0 )
                              != 0 )
                : ( ( a64 | a0 ) != 0 );
    }
    return z;

}

