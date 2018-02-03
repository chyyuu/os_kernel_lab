
#include <stdint.h>
#include "platform.h"
#include "specialize.h"
#include "softfloat.h"

/*----------------------------------------------------------------------------
| Returns the result of converting the double-precision floating-point NaN
| `a' to the canonical NaN format.  If `a' is a signaling NaN, the invalid
| exception is raised.
*----------------------------------------------------------------------------*/
struct commonNaN softfloat_f64UIToCommonNaN( uint_fast64_t uiA )
{
    struct commonNaN z;

    if ( softfloat_isSigNaNF64UI( uiA ) ) {
        softfloat_raiseFlags( softfloat_flag_invalid );
    }
    z.sign = uiA>>63;
    z.v64 = uiA<<12;
    z.v0 = 0;
    return z;

}

