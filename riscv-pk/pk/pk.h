// See LICENSE for license details.

#ifndef _PK_H
#define _PK_H

#ifndef __ASSEMBLER__

#include "encoding.h"
#include <stdint.h>
#include <string.h>
#include <stdarg.h>

typedef struct
{
  long gpr[32];
  long status;
  long epc;
  long badvaddr;
  long cause;
  long insn;
} trapframe_t;

#define panic(s,...) do { do_panic(s"\n", ##__VA_ARGS__); } while(0)
#define kassert(cond) do { if(!(cond)) kassert_fail(""#cond); } while(0)
void do_panic(const char* s, ...) __attribute__((noreturn));
void kassert_fail(const char* s) __attribute__((noreturn));

#ifdef __cplusplus
extern "C" {
#endif

void printk(const char* s, ...);
void printm(const char* s, ...);
int vsnprintf(char* out, size_t n, const char* s, va_list vl);
int snprintf(char* out, size_t n, const char* s, ...);
void start_user(trapframe_t* tf) __attribute__((noreturn));
void dump_tf(trapframe_t*);

static inline int insn_len(long insn)
{
  return (insn & 0x3) < 0x3 ? 2 : 4;
}

#define ARRAY_SIZE(x) (sizeof(x)/sizeof((x)[0]))

#ifdef __cplusplus
}
#endif

#endif // !__ASSEMBLER__

#endif
