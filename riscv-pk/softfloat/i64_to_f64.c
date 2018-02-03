
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "softfloat.h"

float64_t i64_to_f64( int_fast64_t a )
{
    bool sign;
    union ui64_f64 uZ;

    sign = ( a < 0 );
    if ( ! ( a & UINT64_C( 0x7FFFFFFFFFFFFFFF ) ) ) {
        uZ.ui = sign ? packToF64UI( 1, 0x43E, 0 ) : 0;
        return uZ.f;
    }
    return softfloat_normRoundPackToF64( sign, 0x43C, sign ? - a : a );

}

