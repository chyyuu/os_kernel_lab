
#include <stdint.h>
#include "primitives.h"

int softfloat_countLeadingZeros32( uint32_t a )
{
    int count;

    count = 0;
    if ( a < 0x10000 ) {
        count = 16;
        a <<= 16;
    }
    if ( a < 0x1000000 ) {
        count += 8;
        a <<= 8;
    }
    count += softfloat_countLeadingZeros8[ a>>24 ];
    return count;

}

