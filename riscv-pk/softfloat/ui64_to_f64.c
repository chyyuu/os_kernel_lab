
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "softfloat.h"

float64_t ui64_to_f64( uint_fast64_t a )
{
    union ui64_f64 uZ;

    if ( ! a ) {
        uZ.ui = 0;
        return uZ.f;
    }
    if ( a & UINT64_C( 0x8000000000000000 ) ) {
        return
            softfloat_roundPackToF64(
                0, 0x43D, softfloat_shortShift64RightJam( a, 1 ) );
    } else {
        return softfloat_normRoundPackToF64( 0, 0x43C, a );
    }

}

