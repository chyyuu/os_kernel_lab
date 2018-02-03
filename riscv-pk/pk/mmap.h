#ifndef _MMAP_H
#define _MMAP_H

#include "vm.h"
#include "syscall.h"
#include "encoding.h"
#include "file.h"
#include "mtrap.h"
#include <stddef.h>

#define PROT_NONE 0
#define PROT_READ 1
#define PROT_WRITE 2
#define PROT_EXEC 4

#define MAP_PRIVATE 0x2
#define MAP_FIXED 0x10
#define MAP_ANONYMOUS 0x20
#define MAP_POPULATE 0x8000
#define MREMAP_FIXED 0x2

extern int demand_paging;
uintptr_t pk_vm_init();
int handle_page_fault(uintptr_t vaddr, int prot);
void populate_mapping(const void* start, size_t size, int prot);
void __map_kernel_range(uintptr_t va, uintptr_t pa, size_t len, int prot);
int __valid_user_range(uintptr_t vaddr, size_t len);
uintptr_t __do_mmap(uintptr_t addr, size_t length, int prot, int flags, file_t* file, off_t offset);
uintptr_t do_mmap(uintptr_t addr, size_t length, int prot, int flags, int fd, off_t offset);
int do_munmap(uintptr_t addr, size_t length);
uintptr_t do_mremap(uintptr_t addr, size_t old_size, size_t new_size, int flags);
uintptr_t do_mprotect(uintptr_t addr, size_t length, int prot);
uintptr_t do_brk(uintptr_t addr);

#define va2pa(va) ({ uintptr_t __va = (uintptr_t)(va); \
  extern uintptr_t first_free_paddr; \
  __va >= DRAM_BASE ? __va : __va + first_free_paddr; })

#endif
