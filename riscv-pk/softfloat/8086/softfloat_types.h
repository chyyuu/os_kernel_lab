
#ifndef softfloat_types_h
#define softfloat_types_h

/*** COMMENTS. ***/

#include <stdbool.h>
#include <stdint.h>

typedef struct { uint32_t v; } float32_t;
typedef struct { uint64_t v; } float64_t;
typedef struct { uint64_t v; uint16_t x; } floatx80_t;
typedef struct { uint64_t v[ 2 ]; } float128_t;

#endif

