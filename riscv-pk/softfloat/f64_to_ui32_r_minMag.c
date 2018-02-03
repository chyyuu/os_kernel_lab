
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "softfloat.h"

uint_fast32_t f64_to_ui32_r_minMag( float64_t a, bool exact )
{
    union ui64_f64 uA;
    uint_fast64_t uiA;
    int_fast16_t exp;
    uint_fast64_t sig;
    int_fast16_t shiftCount;
    uint_fast32_t z;

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
    if ( signF64UI( uiA ) || ( 0x41E < exp ) ) {
        softfloat_raiseFlags( softfloat_flag_invalid );
        return 0xFFFFFFFF;
    }
    sig |= UINT64_C( 0x0010000000000000 );
    shiftCount = 0x433 - exp;
    z = sig>>shiftCount;
    if ( exact && ( (uint_fast64_t) z<<shiftCount != sig ) ) {
        softfloat_raiseFlags( softfloat_flag_inexact );
    }
    return z;

}

