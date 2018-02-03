
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "softfloat.h"

int_fast32_t f64_to_i32( float64_t a, int_fast8_t roundingMode, bool exact )
{
    union ui64_f64 uA;
    uint_fast64_t uiA;
    bool sign;
    int_fast16_t exp;
    uint_fast64_t sig;
    int_fast16_t shiftCount;

    uA.f = a;
    uiA = uA.ui;
    sign = signF64UI( uiA );
    exp = expF64UI( uiA );
    sig = fracF64UI( uiA );
    if ( exp ) sig |= UINT64_C( 0x0010000000000000 );
    shiftCount = 0x42C - exp;
    if ( 0 < shiftCount ) sig = softfloat_shift64RightJam( sig, shiftCount );
    return softfloat_roundPackToI32( sign, sig, roundingMode, exact );

}

