
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

uint_fast16_t f32_classify( float32_t a )
{
    union ui32_f32 uA;
    uint_fast32_t uiA;

    uA.f = a;
    uiA = uA.ui;

    uint_fast16_t infOrNaN = expF32UI( uiA ) == 0xFF;
    uint_fast16_t subnormalOrZero = expF32UI( uiA ) == 0;
    bool sign = signF32UI( uiA );

    return
        (  sign && infOrNaN && fracF32UI( uiA ) == 0 )          << 0 |
        (  sign && !infOrNaN && !subnormalOrZero )              << 1 |
        (  sign && subnormalOrZero && fracF32UI( uiA ) )        << 2 |
        (  sign && subnormalOrZero && fracF32UI( uiA ) == 0 )   << 3 |
        ( !sign && infOrNaN && fracF32UI( uiA ) == 0 )          << 7 |
        ( !sign && !infOrNaN && !subnormalOrZero )              << 6 |
        ( !sign && subnormalOrZero && fracF32UI( uiA ) )        << 5 |
        ( !sign && subnormalOrZero && fracF32UI( uiA ) == 0 )   << 4 |
        ( isNaNF32UI( uiA ) &&  softfloat_isSigNaNF32UI( uiA )) << 8 |
        ( isNaNF32UI( uiA ) && !softfloat_isSigNaNF32UI( uiA )) << 9;
}

