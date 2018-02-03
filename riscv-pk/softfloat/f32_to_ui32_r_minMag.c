
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "softfloat.h"

uint_fast32_t f32_to_ui32_r_minMag( float32_t a, bool exact )
{
    union ui32_f32 uA;
    uint_fast32_t uiA;
    int_fast16_t exp;
    uint_fast32_t sig;
    int_fast16_t shiftCount;
    uint_fast32_t z;

    uA.f = a;
    uiA = uA.ui;
    exp = expF32UI( uiA );
    sig = fracF32UI( uiA );
    if ( exp < 0x7F ) {
        if ( exact && ( exp | sig ) ) {
            softfloat_raiseFlags( softfloat_flag_inexact );
        }
        return 0;
    }
    if ( signF32UI( uiA ) ) goto invalid;
    shiftCount = 0x9E - exp;
    if ( shiftCount < 0 ) goto invalid;
    sig = ( sig | 0x00800000 )<<8;
    z = sig>>shiftCount;
    if ( exact && ( sig & ( ( (uint_fast32_t) 1<<shiftCount ) - 1 ) ) ) {
        softfloat_raiseFlags( softfloat_flag_inexact );
    }
    return z;
 invalid:
    softfloat_raiseFlags( softfloat_flag_invalid );
    return 0xFFFFFFFF;

}

