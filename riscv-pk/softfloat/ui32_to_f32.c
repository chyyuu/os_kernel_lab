
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "softfloat.h"

float32_t ui32_to_f32( uint_fast32_t a )
{
    union ui32_f32 uZ;

    if ( ! a ) {
        uZ.ui = 0;
        return uZ.f;
    }
    if ( a & 0x80000000 ) {
        return
            softfloat_roundPackToF32(
                0, 0x9D, softfloat_shortShift32Right1Jam( a ) );
    } else {
        return softfloat_normRoundPackToF32( 0, 0x9C, a );
    }

}

