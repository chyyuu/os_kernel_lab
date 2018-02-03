
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

struct uint64_extra
 softfloat_shift64ExtraRightJam(
     uint64_t a, uint64_t extra, unsigned int count )
{
    struct uint64_extra z;

    if ( count < 64 ) {
        z.v = a>>count;
        z.extra = a<<( ( - count ) & 63 );
    } else {
        z.v = 0;
        z.extra = ( count == 64 ) ? a : ( a != 0 );
    }
    z.extra |= ( extra != 0 );
    return z;

}

