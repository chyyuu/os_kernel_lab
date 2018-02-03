
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

uint32_t softfloat_shortShift32Right1Jam( uint32_t a )
{

    return a>>1 | ( a & 1 );

}

