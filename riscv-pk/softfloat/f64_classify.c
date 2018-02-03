
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

uint_fast16_t f64_classify( float64_t a )
{
    union ui64_f64 uA;
    uint_fast64_t uiA;

    uA.f = a;
    uiA = uA.ui;

    uint_fast16_t infOrNaN = expF64UI( uiA ) == 0x7FF;
    uint_fast16_t subnormalOrZero = expF64UI( uiA ) == 0;
    bool sign = signF64UI( uiA );

    return
        (  sign && infOrNaN && fracF64UI( uiA ) == 0 )          << 0 |
        (  sign && !infOrNaN && !subnormalOrZero )              << 1 |
        (  sign && subnormalOrZero && fracF64UI( uiA ) )        << 2 |
        (  sign && subnormalOrZero && fracF64UI( uiA ) == 0 )   << 3 |
        ( !sign && infOrNaN && fracF64UI( uiA ) == 0 )          << 7 |
        ( !sign && !infOrNaN && !subnormalOrZero )              << 6 |
        ( !sign && subnormalOrZero && fracF64UI( uiA ) )        << 5 |
        ( !sign && subnormalOrZero && fracF64UI( uiA ) == 0 )   << 4 |
        ( isNaNF64UI( uiA ) &&  softfloat_isSigNaNF64UI( uiA )) << 8 |
        ( isNaNF64UI( uiA ) && !softfloat_isSigNaNF64UI( uiA )) << 9;
}

