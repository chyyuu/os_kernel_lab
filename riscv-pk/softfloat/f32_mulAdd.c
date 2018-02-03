
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "softfloat.h"

float32_t f32_mulAdd( float32_t a, float32_t b, float32_t c )
{
    union ui32_f32 uA;
    uint_fast32_t uiA;
    union ui32_f32 uB;
    uint_fast32_t uiB;
    union ui32_f32 uC;
    uint_fast32_t uiC;

    uA.f = a;
    uiA = uA.ui;
    uB.f = b;
    uiB = uB.ui;
    uC.f = c;
    uiC = uC.ui;
    return softfloat_mulAddF32( 0, uiA, uiB, uiC );

}

