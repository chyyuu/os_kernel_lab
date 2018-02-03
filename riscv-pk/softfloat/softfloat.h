
#ifndef softfloat_h
#define softfloat_h

#ifdef __cplusplus
extern "C" {
#endif

/*** UPDATE COMMENTS. ***/

/*============================================================================

This C header file is part of the SoftFloat IEEE Floating-point Arithmetic
Package, Release 2b.

Written by John R. Hauser.  This work was made possible in part by the
International Computer Science Institute, located at Suite 600, 1947 Center
Street, Berkeley, California 94704.  Funding was partially provided by the
National Science Foundation under grant MIP-9311980.  The original version
of this code was written as part of a project to build a fixed-point vector
processor in collaboration with the University of California at Berkeley,
overseen by Profs. Nelson Morgan and John Wawrzynek.  More information
is available through the Web page `http://www.cs.berkeley.edu/~jhauser/
arithmetic/SoftFloat.html'.

THIS SOFTWARE IS DISTRIBUTED AS IS, FOR FREE.  Although reasonable effort has
been made to avoid it, THIS SOFTWARE MAY CONTAIN FAULTS THAT WILL AT TIMES
RESULT IN INCORRECT BEHAVIOR.  USE OF THIS SOFTWARE IS RESTRICTED TO PERSONS
AND ORGANIZATIONS WHO CAN AND WILL TAKE FULL RESPONSIBILITY FOR ALL LOSSES,
COSTS, OR OTHER PROBLEMS THEY INCUR DUE TO THE SOFTWARE, AND WHO FURTHERMORE
EFFECTIVELY INDEMNIFY JOHN HAUSER AND THE INTERNATIONAL COMPUTER SCIENCE
INSTITUTE (possibly via similar legal warning) AGAINST ALL LOSSES, COSTS, OR
OTHER PROBLEMS INCURRED BY THEIR CUSTOMERS AND CLIENTS DUE TO THE SOFTWARE.

Derivative works are acceptable, even for commercial purposes, so long as
(1) the source code for the derivative work includes prominent notice that
the work is derivative, and (2) the source code includes prominent notice with
these four paragraphs for those parts of this code that are retained.

=============================================================================*/

#include "softfloat_types.h"

/*----------------------------------------------------------------------------
| Software floating-point underflow tininess-detection mode.
*----------------------------------------------------------------------------*/
enum {
    softfloat_tininess_beforeRounding = 0,
    softfloat_tininess_afterRounding  = 1
};

/*----------------------------------------------------------------------------
| Software floating-point rounding mode.
*----------------------------------------------------------------------------*/
enum {
    softfloat_round_nearest_even   = 0,
    softfloat_round_minMag         = 1,
    softfloat_round_min            = 2,
    softfloat_round_max            = 3,
    softfloat_round_nearest_maxMag = 4
};

/*----------------------------------------------------------------------------
| Software floating-point exception flags.
*----------------------------------------------------------------------------*/
extern int_fast8_t softfloat_exceptionFlags;
enum {
    softfloat_flag_inexact   =  1,
    softfloat_flag_underflow =  2,
    softfloat_flag_overflow  =  4,
    softfloat_flag_infinity  =  8,
    softfloat_flag_invalid   = 16
};

/*----------------------------------------------------------------------------
| Integer-to-floating-point conversion routines.
*----------------------------------------------------------------------------*/
float32_t ui32_to_f32( uint_fast32_t );
float64_t ui32_to_f64( uint_fast32_t );
floatx80_t ui32_to_fx80( uint_fast32_t );
float128_t ui32_to_f128( uint_fast32_t );
float32_t ui64_to_f32( uint_fast64_t );
float64_t ui64_to_f64( uint_fast64_t );
floatx80_t ui64_to_fx80( uint_fast64_t );
float128_t ui64_to_f128( uint_fast64_t );
float32_t i32_to_f32( int_fast32_t );
float64_t i32_to_f64( int_fast32_t );
floatx80_t i32_to_fx80( int_fast32_t );
float128_t i32_to_f128( int_fast32_t );
float32_t i64_to_f32( int_fast64_t );
float64_t i64_to_f64( int_fast64_t );
floatx80_t i64_to_fx80( int_fast64_t );
float128_t i64_to_f128( int_fast64_t );

/*----------------------------------------------------------------------------
| 32-bit (single-precision) floating-point operations.
*----------------------------------------------------------------------------*/
uint_fast32_t f32_to_ui32( float32_t, int_fast8_t, bool );
uint_fast64_t f32_to_ui64( float32_t, int_fast8_t, bool );
int_fast32_t f32_to_i32( float32_t, int_fast8_t, bool );
int_fast64_t f32_to_i64( float32_t, int_fast8_t, bool );
uint_fast32_t f32_to_ui32_r_minMag( float32_t, bool );
uint_fast64_t f32_to_ui64_r_minMag( float32_t, bool );
int_fast32_t f32_to_i32_r_minMag( float32_t, bool );
int_fast64_t f32_to_i64_r_minMag( float32_t, bool );
float64_t f32_to_f64( float32_t );
floatx80_t f32_to_fx80( float32_t );
float128_t f32_to_f128( float32_t );
float32_t f32_roundToInt( float32_t, int_fast8_t, bool );
float32_t f32_add( float32_t, float32_t );
float32_t f32_sub( float32_t, float32_t );
float32_t f32_mul( float32_t, float32_t );
float32_t f32_mulAdd( float32_t, float32_t, float32_t );
float32_t f32_div( float32_t, float32_t );
float32_t f32_rem( float32_t, float32_t );
float32_t f32_sqrt( float32_t );
bool f32_eq( float32_t, float32_t );
bool f32_le( float32_t, float32_t );
bool f32_lt( float32_t, float32_t );
bool f32_eq_signaling( float32_t, float32_t );
bool f32_le_quiet( float32_t, float32_t );
bool f32_lt_quiet( float32_t, float32_t );
bool f32_isSignalingNaN( float32_t );
uint_fast16_t f32_classify( float32_t a );

/*----------------------------------------------------------------------------
| 64-bit (double-precision) floating-point operations.
*----------------------------------------------------------------------------*/
uint_fast32_t f64_to_ui32( float64_t, int_fast8_t, bool );
uint_fast64_t f64_to_ui64( float64_t, int_fast8_t, bool );
int_fast32_t f64_to_i32( float64_t, int_fast8_t, bool );
int_fast64_t f64_to_i64( float64_t, int_fast8_t, bool );
uint_fast32_t f64_to_ui32_r_minMag( float64_t, bool );
uint_fast64_t f64_to_ui64_r_minMag( float64_t, bool );
int_fast32_t f64_to_i32_r_minMag( float64_t, bool );
int_fast64_t f64_to_i64_r_minMag( float64_t, bool );
float32_t f64_to_f32( float64_t );
floatx80_t f64_to_fx80( float64_t );
float128_t f64_to_f128( float64_t );
float64_t f64_roundToInt( float64_t, int_fast8_t, bool );
float64_t f64_add( float64_t, float64_t );
float64_t f64_sub( float64_t, float64_t );
float64_t f64_mul( float64_t, float64_t );
float64_t f64_mulAdd( float64_t, float64_t, float64_t );
float64_t f64_div( float64_t, float64_t );
float64_t f64_rem( float64_t, float64_t );
float64_t f64_sqrt( float64_t );
bool f64_eq( float64_t, float64_t );
bool f64_le( float64_t, float64_t );
bool f64_lt( float64_t, float64_t );
bool f64_eq_signaling( float64_t, float64_t );
bool f64_le_quiet( float64_t, float64_t );
bool f64_lt_quiet( float64_t, float64_t );
bool f64_isSignalingNaN( float64_t );
uint_fast16_t f64_classify( float64_t a );

/*----------------------------------------------------------------------------
| Extended double-precision rounding precision.  Valid values are 32, 64, and
| 80.
*----------------------------------------------------------------------------*/
extern int_fast8_t floatx80_roundingPrecision;

/*----------------------------------------------------------------------------
| Extended double-precision floating-point operations.
*----------------------------------------------------------------------------*/
uint_fast32_t fx80_to_ui32( floatx80_t, int_fast8_t, bool );
uint_fast64_t fx80_to_ui64( floatx80_t, int_fast8_t, bool );
int_fast32_t fx80_to_i32( floatx80_t, int_fast8_t, bool );
int_fast64_t fx80_to_i64( floatx80_t, int_fast8_t, bool );
uint_fast32_t fx80_to_ui32_r_minMag( floatx80_t, bool );
uint_fast64_t fx80_to_ui64_r_minMag( floatx80_t, bool );
int_fast32_t fx80_to_i32_r_minMag( floatx80_t, bool );
int_fast64_t fx80_to_i64_r_minMag( floatx80_t, bool );
float32_t fx80_to_f32( floatx80_t );
float64_t fx80_to_f64( floatx80_t );
float128_t fx80_to_f128( floatx80_t );
floatx80_t fx80_roundToInt( floatx80_t, int_fast8_t, bool );
floatx80_t fx80_add( floatx80_t, floatx80_t );
floatx80_t fx80_sub( floatx80_t, floatx80_t );
floatx80_t fx80_mul( floatx80_t, floatx80_t );
floatx80_t fx80_mulAdd( floatx80_t, floatx80_t, floatx80_t );
floatx80_t fx80_div( floatx80_t, floatx80_t );
floatx80_t fx80_rem( floatx80_t, floatx80_t );
floatx80_t fx80_sqrt( floatx80_t );
bool fx80_eq( floatx80_t, floatx80_t );
bool fx80_le( floatx80_t, floatx80_t );
bool fx80_lt( floatx80_t, floatx80_t );
bool fx80_eq_signaling( floatx80_t, floatx80_t );
bool fx80_le_quiet( floatx80_t, floatx80_t );
bool fx80_lt_quiet( floatx80_t, floatx80_t );
bool fx80_isSignalingNaN( floatx80_t );

/*----------------------------------------------------------------------------
| 128-bit (quadruple-precision) floating-point operations.
*----------------------------------------------------------------------------*/
uint_fast32_t f128_to_ui32( float128_t, int_fast8_t, bool );
uint_fast64_t f128_to_ui64( float128_t, int_fast8_t, bool );
int_fast32_t f128_to_i32( float128_t, int_fast8_t, bool );
int_fast64_t f128_to_i64( float128_t, int_fast8_t, bool );
uint_fast32_t f128_to_ui32_r_minMag( float128_t, bool );
uint_fast64_t f128_to_ui64_r_minMag( float128_t, bool );
int_fast32_t f128_to_i32_r_minMag( float128_t, bool );
int_fast64_t f128_to_i64_r_minMag( float128_t, bool );
float32_t f128_to_f32( float128_t );
float64_t f128_to_f64( float128_t );
floatx80_t f128_to_fx80( float128_t );
float128_t f128_roundToInt( float128_t, int_fast8_t, bool );
float128_t f128_add( float128_t, float128_t );
float128_t f128_sub( float128_t, float128_t );
float128_t f128_mul( float128_t, float128_t );
float128_t f128_mulAdd( float128_t, float128_t, float128_t );
float128_t f128_div( float128_t, float128_t );
float128_t f128_rem( float128_t, float128_t );
float128_t f128_sqrt( float128_t );
bool f128_eq( float128_t, float128_t );
bool f128_le( float128_t, float128_t );
bool f128_lt( float128_t, float128_t );
bool f128_eq_signaling( float128_t, float128_t );
bool f128_le_quiet( float128_t, float128_t );
bool f128_lt_quiet( float128_t, float128_t );
bool f128_isSignalingNaN( float128_t );

#include "specialize.h"

/*----------------------------------------------------------------------------
| Returns 1 if the single-precision floating-point value `a' is a NaN;
| otherwise, returns 0.
*----------------------------------------------------------------------------*/
#define isNaNF32UI( ui ) (0xFF000000<(uint32_t)((uint_fast32_t)(ui)<<1))
/*----------------------------------------------------------------------------
| Returns 1 if the double-precision floating-point value `a' is a NaN;
| otherwise, returns 0.
*----------------------------------------------------------------------------*/
#define isNaNF64UI( ui ) (UINT64_C(0xFFE0000000000000)<(uint64_t)((uint_fast64_t)(ui)<<1))

enum {
    softfloat_mulAdd_subC    = 1,
    softfloat_mulAdd_subProd = 2
};

float32_t
 softfloat_mulAddF32( int, uint_fast32_t, uint_fast32_t, uint_fast32_t );

float64_t
 softfloat_mulAddF64( int, uint_fast64_t, uint_fast64_t, uint_fast64_t );

#ifdef __cplusplus
}
#endif

#endif

