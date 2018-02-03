
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "softfloat.h"

bool f32_lt( float32_t a, float32_t b )
{
    union ui32_f32 uA;
    uint_fast32_t uiA;
    union ui32_f32 uB;
    uint_fast32_t uiB;
    bool signA, signB;

    uA.f = a;
    uiA = uA.ui;
    uB.f = b;
    uiB = uB.ui;
    if (
           ( ( expF32UI( uiA ) == 0xFF ) && fracF32UI( uiA ) )
        || ( ( expF32UI( uiB ) == 0xFF ) && fracF32UI( uiB ) )
    ) {
        softfloat_raiseFlags( softfloat_flag_invalid );
        return false;
    }
    signA = signF32UI( uiA );
    signB = signF32UI( uiB );
    return
        ( signA != signB ) ? signA && ( (uint32_t) ( ( uiA | uiB )<<1 ) != 0 )
            : ( uiA != uiB ) && ( signA ^ ( uiA < uiB ) );

}

