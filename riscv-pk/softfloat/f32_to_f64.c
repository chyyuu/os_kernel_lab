
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

float64_t f32_to_f64( float32_t a )
{
    union ui32_f32 uA;
    uint_fast32_t uiA;
    bool sign;
    int_fast16_t exp;
    uint_fast32_t sig;
    uint_fast64_t uiZ;
    struct exp16_sig32 normExpSig;
    union ui64_f64 uZ;

    uA.f = a;
    uiA = uA.ui;
    sign = signF32UI( uiA );
    exp = expF32UI( uiA );
    sig = fracF32UI( uiA );
    if ( exp == 0xFF ) {
        uiZ =
            sig ? softfloat_commonNaNToF64UI(
                      softfloat_f32UIToCommonNaN( uiA ) )
                : packToF64UI( sign, 0x7FF, 0 );
        goto uiZ;
    }
    if ( ! exp ) {
        if ( ! sig ) {
            uiZ = packToF64UI( sign, 0, 0 );
            goto uiZ;
        }
        normExpSig = softfloat_normSubnormalF32Sig( sig );
        exp = normExpSig.exp - 1;
        sig = normExpSig.sig;
    }
    uiZ = packToF64UI( sign, exp + 0x380, (uint_fast64_t) sig<<29 );
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

