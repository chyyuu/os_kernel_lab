#ifndef __KERN_MM_MEMLAYOUT_H__
#define __KERN_MM_MEMLAYOUT_H__

/* *
 * Virtual memory map:                                          Permissions
 *                                                              kernel/user
 *
 *     4G ------------------> +---------------------------------+
 *                            |                                 |
 *                            |         Empty Memory (*)        |
 *                            |                                 |
 *                            +---------------------------------+ 0xFB000000
 *                            |   Cur. Page Table (Kern, RW)    | RW/-- PTSIZE
 *     VPT -----------------> +---------------------------------+ 0xFAC00000
 *                            |        Invalid Memory (*)       | --/--
 *     KERNTOP -------------> +---------------------------------+ 0xF8000000
 *                            |                                 |
 *                            |    Remapped Physical Memory     | RW/-- KMEMSIZE
 *                            |                                 |
 *     KERNBASE ------------> +---------------------------------+ 0xC0000000
 *                            |                                 |
 *                            |                                 |
 *                            |                                 |
 *                            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * (*) Note: The kernel ensures that "Invalid Memory" is *never* mapped.
 *     "Empty Memory" is normally unmapped, but user programs may map pages
 *     there if desired.
 *
 * */

/* All physical memory mapped at this address */
// #define KERNBASE            0xC0000000
#define KERNBASE            0x80200000
#define KMEMSIZE            0x38000000                  // the maximum amount of physical memory
#define KERNTOP             (KERNBASE + KMEMSIZE)

/* *
 * Virtual page table. Entry PDX[VPT] in the PD (Page Directory) contains
 * a pointer to the page directory itself, thereby turning the PD into a page
 * table, which maps all the PTEs (Page Table Entry) containing the page mappings
 * for the entire virtual address space into that 4 Meg region starting at VPT.
 * */
#define VPT                 0xFAC00000

#define KSTACKPAGE          2                           // # of pages in kernel stack
#define KSTACKSIZE          (KSTACKPAGE * PGSIZE)       // sizeof kernel stack

#ifndef __ASSEMBLER__

#include <defs.h>
#include <atomic.h>
#include <list.h>

typedef uintptr_t pte_t;
typedef uintptr_t pde_t;

/* *
 * struct Page - Page descriptor structures. Each Page describes one
 * physical page. In kern/mm/pmm.h, you can find lots of useful functions
 * that convert Page to other data types, such as physical address.
 * */
struct Page {
    sint_t ref;                        // page frame's reference counter
    uint_t flags;                 // array of flags that describe the status of the page frame
    uint_t property;          // the num of free block, used in first fit pm manager
    list_entry_t page_link;         // free list link
};

/* Flags describing the status of a page frame */
#define PG_reserved                 0       // if this bit=1: the Page is reserved for kernel, cannot be used in alloc/free_pages; otherwise, this bit=0 
#define PG_property                 1       // if this bit=1: the Page is the head page of a free memory block(contains some continuous_addrress pages), and can be used in alloc_pages; if this bit=0: if the Page is the the head page of a free memory block, then this Page and the memory block is alloced. Or this Page isn't the head page.

#define SetPageReserved(page)       set_bit(PG_reserved, &((page)->flags))
#define ClearPageReserved(page)     clear_bit(PG_reserved, &((page)->flags))
#define PageReserved(page)          test_bit(PG_reserved, &((page)->flags))
#define SetPageProperty(page)       set_bit(PG_property, &((page)->flags))
#define ClearPageProperty(page)     clear_bit(PG_property, &((page)->flags))
#define PageProperty(page)          test_bit(PG_property, &((page)->flags))

// convert list entry to page
#define le2page(le, member)                 \
    to_struct((le), struct Page, member)

/* free_area_t - maintains a doubly linked list to record free (unused) pages */
typedef struct {
    list_entry_t free_list;         // the list header
    unsigned int nr_free;           // # of free pages in this free list
} free_area_t;

#endif /* !__ASSEMBLER__ */

#endif /* !__KERN_MM_MEMLAYOUT_H__ */
