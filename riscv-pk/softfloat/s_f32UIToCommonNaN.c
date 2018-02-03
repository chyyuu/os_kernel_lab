
#include <stdint.h>
#include "platform.h"
#include "specialize.h"
#include "softfloat.h"

/*----------------------------------------------------------------------------
| Returns the result of converting the single-precision floating-point NaN
| `a' to the canonical NaN format.  If `a' is a signaling NaN, the invalid
| exception is raised.
*----------------------------------------------------------------------------*/
struct commonNaN softfloat_f32UIToCommonNaN( uint_fast32_t uiA )
{
    struct commonNaN z;

    if ( softfloat_isSigNaNF32UI( uiA ) ) {
        softfloat_raiseFlags( softfloat_flag_invalid );
    }
    z.sign = uiA>>31;
    z.v64 = (uint_fast64_t) 0x7FFFF <<41;
    z.v0 = 0;
    return z;

}

