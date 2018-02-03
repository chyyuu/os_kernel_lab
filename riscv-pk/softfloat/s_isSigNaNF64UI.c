
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "specialize.h"

bool softfloat_isSigNaNF64UI( uint_fast64_t ui )
{

    return
        ( ( ui>>51 & 0xFFF ) == 0xFFE )
            && ( ui & UINT64_C( 0x0007FFFFFFFFFFFF ) );

}

