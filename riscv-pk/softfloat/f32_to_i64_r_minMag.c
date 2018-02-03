
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "softfloat.h"

int_fast64_t f32_to_i64_r_minMag( float32_t a, bool exact )
{
    union ui32_f32 uA;
    uint_fast32_t uiA;
    int_fast16_t exp;
    uint_fast32_t sig;
    bool sign;
    int_fast16_t shiftCount;
    uint_fast64_t sig64;
    int_fast64_t absZ;

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
    sign = signF32UI( uiA );
    shiftCount = 0xBE - exp;
    if ( shiftCount <= 0 ) {
        if ( uiA != packToF32UI( 1, 0xBE, 0 ) ) {
            softfloat_raiseFlags( softfloat_flag_invalid );
            if ( ! sign || ( ( exp == 0xFF ) && sig ) ) {
                return INT64_C( 0x7FFFFFFFFFFFFFFF );
            }
        }
        return - INT64_C( 0x7FFFFFFFFFFFFFFF ) - 1;
    }
    sig |= 0x00800000;
    sig64 = (uint_fast64_t) sig<<40;
    absZ = sig64>>shiftCount;
    shiftCount = 40 - shiftCount;
    if (
        exact && ( shiftCount < 0 ) && (uint32_t) ( sig<<( shiftCount & 31 ) )
    ) {
        softfloat_raiseFlags( softfloat_flag_inexact );
    }
    return sign ? - absZ : absZ;

}

