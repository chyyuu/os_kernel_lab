// See LICENSE for license details.

#ifndef _BOOT_H
#define _BOOT_H

#ifndef __ASSEMBLER__

#include <stddef.h>

typedef struct {
  int phent;
  int phnum;
  int is_supervisor;
  size_t phdr;
  size_t phdr_size;
  size_t bias;
  size_t entry;
  size_t brk_min;
  size_t brk;
  size_t brk_max;
  size_t mmap_max;
  size_t stack_top;
  size_t time0;
  size_t cycle0;
  size_t instret0;
} elf_info;

extern elf_info current;

void load_elf(const char* fn, elf_info* info);

#endif // !__ASSEMBLER__

#endif
