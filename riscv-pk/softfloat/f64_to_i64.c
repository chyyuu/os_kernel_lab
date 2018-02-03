
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "softfloat.h"

int_fast64_t f64_to_i64( float64_t a, int_fast8_t roundingMode, bool exact )
{
    union ui64_f64 uA;
    uint_fast64_t uiA;
    bool sign;
    int_fast16_t exp;
    uint_fast64_t sig;
    int_fast16_t shiftCount;
    struct uint64_extra sigExtra;

    uA.f = a;
    uiA = uA.ui;
    sign = signF64UI( uiA );
    exp = expF64UI( uiA );
    sig = fracF64UI( uiA );
    if ( exp ) sig |= UINT64_C( 0x0010000000000000 );
    shiftCount = 0x433 - exp;
    if ( shiftCount <= 0 ) {
        if ( 0x43E < exp ) {
            softfloat_raiseFlags( softfloat_flag_invalid );
            return
                ! sign
                    ? INT64_C( 0x7FFFFFFFFFFFFFFF )
                    : - INT64_C( 0x7FFFFFFFFFFFFFFF ) - 1;
        }
        sigExtra.v = sig<<( - shiftCount );
        sigExtra.extra = 0;
    } else {
        sigExtra = softfloat_shift64ExtraRightJam( sig, 0, shiftCount );
    }
    return
        softfloat_roundPackToI64(
            sign, sigExtra.v, sigExtra.extra, roundingMode, exact );

}

