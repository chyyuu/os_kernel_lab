
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"

float32_t
 softfloat_normRoundPackToF32( bool sign, int_fast16_t exp, uint_fast32_t sig )
{
    int shiftCount;
    union ui32_f32 uZ;

    shiftCount = softfloat_countLeadingZeros32( sig ) - 1;
    exp -= shiftCount;
    if ( ( 7 <= shiftCount ) && ( (uint16_t) exp < 0xFD ) ) {
        uZ.ui = packToF32UI( sign, sig ? exp : 0, sig<<( shiftCount - 7 ) );
        return uZ.f;
    } else {
        return softfloat_roundPackToF32( sign, exp, sig<<shiftCount );
    }

}

