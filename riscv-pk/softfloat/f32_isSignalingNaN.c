
#include <stdbool.h>
#include "platform.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

bool f32_isSignalingNaN( float32_t a )
{
    union ui32_f32 uA;

    uA.f = a;
    return softfloat_isSigNaNF32UI( uA.ui );

}

