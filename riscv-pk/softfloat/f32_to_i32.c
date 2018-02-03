
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "softfloat.h"

int_fast32_t f32_to_i32( float32_t a, int_fast8_t roundingMode, bool exact )
{
    union ui32_f32 uA;
    uint_fast32_t uiA;
    bool sign;
    int_fast16_t exp;
    uint_fast32_t sig;
    uint_fast64_t sig64;
    int_fast16_t shiftCount;

    uA.f = a;
    uiA = uA.ui;
    sign = signF32UI( uiA );
    exp = expF32UI( uiA );
    sig = fracF32UI( uiA );
    if ( exp ) sig |= 0x00800000;
    sig64 = (uint_fast64_t) sig<<32;
    shiftCount = 0xAF - exp;
    if ( 0 < shiftCount ) {
        sig64 = softfloat_shift64RightJam( sig64, shiftCount );
    }
    return softfloat_roundPackToI32( sign, sig64, roundingMode, exact );

}

