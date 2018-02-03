
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "softfloat.h"

int_fast64_t f32_to_i64( float32_t a, int_fast8_t roundingMode, bool exact )
{
    union ui32_f32 uA;
    uint_fast32_t uiA;
    bool sign;
    int_fast16_t exp;
    uint_fast32_t sig;
    int_fast16_t shiftCount;
    uint_fast64_t sig64, extra;
    struct uint64_extra sig64Extra;

    uA.f = a;
    uiA = uA.ui;
    sign = signF32UI( uiA );
    exp = expF32UI( uiA );
    sig = fracF32UI( uiA );
    shiftCount = 0xBE - exp;
    if ( shiftCount < 0 ) {
        softfloat_raiseFlags( softfloat_flag_invalid );
        if ( ! sign ) {
            return INT64_C( 0x7FFFFFFFFFFFFFFF );
        }
        return - INT64_C( 0x7FFFFFFFFFFFFFFF ) - 1;
    }
    if ( exp ) sig |= 0x00800000;
    sig64 = (uint_fast64_t) sig<<40;
    extra = 0;
    if ( shiftCount ) {
        sig64Extra = softfloat_shift64ExtraRightJam( sig64, 0, shiftCount );
        sig64 = sig64Extra.v;
        extra = sig64Extra.extra;
    }
    return softfloat_roundPackToI64( sign, sig64, extra, roundingMode, exact );

}

