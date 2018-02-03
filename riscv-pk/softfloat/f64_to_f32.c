
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

float32_t f64_to_f32( float64_t a )
{
    union ui64_f64 uA;
    uint_fast64_t uiA;
    bool sign;
    int_fast16_t exp;
    uint_fast64_t sig;
    uint_fast32_t uiZ, sig32;
    union ui32_f32 uZ;

    uA.f = a;
    uiA = uA.ui;
    sign = signF64UI( uiA );
    exp = expF64UI( uiA );
    sig = fracF64UI( uiA );
    if ( exp == 0x7FF ) {
        uiZ =
            sig ? softfloat_commonNaNToF32UI(
                      softfloat_f64UIToCommonNaN( uiA ) )
                : packToF32UI( sign, 0xFF, 0 );
        goto uiZ;
    }
    sig32 = softfloat_shortShift64RightJam( sig, 22 );
    if ( ! ( exp | sig32 ) ) {
        uiZ = packToF32UI( sign, 0, 0 );
        goto uiZ;
    }
    return softfloat_roundPackToF32( sign, exp - 0x381, sig32 | 0x40000000 );
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

