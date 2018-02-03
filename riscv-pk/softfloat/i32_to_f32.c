
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "softfloat.h"

float32_t i32_to_f32( int_fast32_t a )
{
    bool sign;
    union ui32_f32 uZ;

    sign = ( a < 0 );
    if ( ! ( a & 0x7FFFFFFF ) ) {
        uZ.ui = sign ? packToF32UI( 1, 0x9E, 0 ) : 0;
        return uZ.f;
    }
    return softfloat_normRoundPackToF32( sign, 0x9C, sign ? - a : a );

}

