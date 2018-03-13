#ifndef __LIBS_ELF_H__
#define __LIBS_ELF_H__

#include <defs.h>

#define ELF_MAGIC   0x464C457FU         // "\x7FELF" in little endian,U stands for an unsigned number

/* file header */
struct elfhdr {
    uint32_t e_magic;     // must equal ELF_MAGIC
    uint8_t e_elf[12];
    uint16_t e_type;      // 1=relocatable, 2=executable, 3=shared object, 4=core image
    uint16_t e_machine;   // 3=x86, 4=68K, etc.
    uint32_t e_version;   // file version, always 1
    uint_t e_entry;     // entry point if executable
    uint_t e_phoff;     // file position of program header or 0
    uint_t e_shoff;     // file position of section header or 0
    uint32_t e_flags;     // architecture-specific flags, usually 0
    uint16_t e_ehsize;    // size of this elf header
    uint16_t e_phentsize; // size of an entry in program header
    uint16_t e_phnum;     // number of entries in program header or 0
    uint16_t e_shentsize; // size of an entry in section header
    uint16_t e_shnum;     // number of entries in section header or 0
    uint16_t e_shstrndx;  // section number that contains section name strings
};

/* program section header */
struct proghdr {
    uint32_t p_type;   // loadable code or data, dynamic linking info,etc.
#if __riscv_xlen==64
    uint32_t p_flags;
#endif
    uint_t p_offset; // file offset of segment
    uint_t p_va;     // virtual address to map segment
    uint_t p_pa;     // physical address, not used
    uint_t p_filesz; // size of segment in file
    uint_t p_memsz;  // size of segment in memory (bigger if contains bss）
#if __riscv_xlen==32
    uint32_t p_flags;  // read/write/execute bits
#endif
    uint_t p_align;  // required alignment, invariably hardware page size
};

#endif /* !__LIBS_ELF_H__ */

