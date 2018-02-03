
#ifndef softfloat_types_h
#define softfloat_types_h

/*** COMMENTS. ***/

#include <stdbool.h>
#include <stdint.h>

typedef uint32_t float32_t;
typedef uint64_t float64_t;
typedef struct { uint64_t v; uint16_t x; } floatx80_t;
typedef struct { uint64_t v[ 2 ]; } float128_t;

#define INLINE inline
#define INLINE_LEVEL 1

#endif

