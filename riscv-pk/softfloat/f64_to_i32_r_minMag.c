
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "softfloat.h"

int_fast32_t f64_to_i32_r_minMag( float64_t a, bool exact )
{
    union ui64_f64 uA;
    uint_fast64_t uiA;
    int_fast16_t exp;
    uint_fast64_t sig;
    bool sign;
    int_fast16_t shiftCount;
    uint_fast32_t absZ;
    union { uint32_t ui; int32_t i; } uZ;
    int_fast32_t z;

    uA.f = a;
    uiA = uA.ui;
    exp = expF64UI( uiA );
    sig = fracF64UI( uiA );
    if ( exp < 0x3FF ) {
        if ( exact && ( exp | sig ) ) {
            softfloat_raiseFlags( softfloat_flag_inexact );
        }
        return 0;
    }
    sign = signF64UI( uiA );
    if ( 0x41E < exp ) {
        if ( ( exp == 0x7FF ) && sig ) sign = 0;
        goto invalid;
    }
    sig |= UINT64_C( 0x0010000000000000 );
    shiftCount = 0x433 - exp;
    absZ = sig>>shiftCount;
    uZ.ui = sign ? - absZ : absZ;
    z = uZ.i;
    if ( ( z < 0 ) != sign ) goto invalid;
    if ( exact && ( (uint_fast64_t) absZ<<shiftCount != sig ) ) {
        softfloat_raiseFlags( softfloat_flag_inexact );
    }
    return z;
 invalid:
    softfloat_raiseFlags( softfloat_flag_invalid );
    return sign ? -0x7FFFFFFF - 1 : 0x7FFFFFFF;

}

