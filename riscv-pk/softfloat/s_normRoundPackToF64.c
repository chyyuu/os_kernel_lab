
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"

float64_t
 softfloat_normRoundPackToF64( bool sign, int_fast16_t exp, uint_fast64_t sig )
{
    int shiftCount;
    union ui64_f64 uZ;

    shiftCount = softfloat_countLeadingZeros64( sig ) - 1;
    exp -= shiftCount;
    if ( ( 10 <= shiftCount ) && ( (uint16_t) exp < 0x7FD ) ) {
        uZ.ui = packToF64UI( sign, sig ? exp : 0, sig<<( shiftCount - 10 ) );
        return uZ.f;
    } else {
        return softfloat_roundPackToF64( sign, exp, sig<<shiftCount );
    }

}

