
#include <stdint.h>
#include "primitives.h"
#include "platform.h"

int softfloat_countLeadingZeros64( uint64_t a )
{
    int count;
    uint32_t a32;

    count = 32;
    a32 = a;
    if ( UINT64_C( 0x100000000 ) <= a ) {
        count = 0;
        a32 = a>>32;
    }
    /*------------------------------------------------------------------------
    | From here, result is current count + count leading zeros of `a32'.
    *------------------------------------------------------------------------*/
    if ( a32 < 0x10000 ) {
        count += 16;
        a32 <<= 16;
    }
    if ( a32 < 0x1000000 ) {
        count += 8;
        a32 <<= 8;
    }
    count += softfloat_countLeadingZeros8[ a32>>24 ];
    return count;

}

