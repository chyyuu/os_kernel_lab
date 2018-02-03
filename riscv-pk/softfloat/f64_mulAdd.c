
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "softfloat.h"

float64_t f64_mulAdd( float64_t a, float64_t b, float64_t c )
{
    union ui64_f64 uA;
    uint_fast64_t uiA;
    union ui64_f64 uB;
    uint_fast64_t uiB;
    union ui64_f64 uC;
    uint_fast64_t uiC;

    uA.f = a;
    uiA = uA.ui;
    uB.f = b;
    uiB = uB.ui;
    uC.f = c;
    uiC = uC.ui;
    return softfloat_mulAddF64( 0, uiA, uiB, uiC );

}

