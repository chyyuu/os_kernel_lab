
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

struct uint64_extra
 softfloat_shortShift64ExtraRightJam(
     uint64_t a, uint64_t extra, unsigned int count )
{
    struct uint64_extra z;

    z.v = a>>count;
    z.extra = a<<( ( - count ) & 63 ) | ( extra != 0 );
    return z;

}

