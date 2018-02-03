
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

uint32_t softfloat_estimateSqrt32( unsigned int expA, uint32_t a )
{
    static const uint16_t sqrtOddAdjustments[] = {
        0x0004, 0x0022, 0x005D, 0x00B1, 0x011D, 0x019F, 0x0236, 0x02E0,
        0x039C, 0x0468, 0x0545, 0x0631, 0x072B, 0x0832, 0x0946, 0x0A67
    };
    static const uint16_t sqrtEvenAdjustments[] = {
        0x0A2D, 0x08AF, 0x075A, 0x0629, 0x051A, 0x0429, 0x0356, 0x029E,
        0x0200, 0x0179, 0x0109, 0x00AF, 0x0068, 0x0034, 0x0012, 0x0002
    };
    int index;
    uint32_t z;
    union { uint32_t ui; int32_t i; } u32;

    index = ( a>>27 ) & 15;
    if ( expA & 1 ) {
        z = 0x4000 + ( a>>17 ) - sqrtOddAdjustments[ index ];
        z = ( ( a / z )<<14 ) + ( z<<15 );
        a >>= 1;
    } else {
        z = 0x8000 + ( a>>17 ) - sqrtEvenAdjustments[ index ];
        z = a / z + z;
        z = ( 0x20000 <= z ) ? 0xFFFF8000 : z<<15;
        if ( z <= a ) {
            u32.ui = a;
            return u32.i>>1;
        }
    }
    return (uint32_t) ( ( (uint64_t) a<<31 ) / z ) + ( z>>1 );

}

