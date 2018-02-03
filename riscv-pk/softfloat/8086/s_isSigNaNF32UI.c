
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "specialize.h"

bool softfloat_isSigNaNF32UI( uint_fast32_t ui )
{

    return ( ( ui>>22 & 0x1FF ) == 0x1FE ) && ( ui & 0x003FFFFF );

}

