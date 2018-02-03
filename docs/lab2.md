# Lab 2

lab 2的移植中，主要改动如下

* 内存管理相关的宏定义
  * `kern/mm/memlayout.h`
  * `kern/mm/mmu.h`
* 内存管理的建立
  * `kern/mm/pmm.h`
  * `kern/mm/pmm.c`

让我们先介绍一下RISC-V中的32位页式寻址

## Sv32

Sv32是RISC-V提供的32位页式内存管理模式，一个Sv32虚拟地址的结构如下

```
31                 22 21                12 11                     0
+--------------------+--------------------+------------------------+
|       VPN[1]       |       VPN[0]       |      page offset       |
+---------10---------+---------10---------+----------12------------+
```

一个SV32物理地址的结构如下

```
33                     22 21                12 11                     0
+------------------------+--------------------+------------------------+
|         PPN[1]         |       PPN[0]       |       page offset      |
+-----------12-----------+---------10---------+-----------12-----------+
```

容易看出，Sv32通过32位虚拟地址来管理34位物理地址，bbl-ucore中只考虑了物理地址的低32位，一方面是为了简化实现，一方面是bbl提供的SBI并不支持34位物理地址。

页式寻址的过程就是借助`VPN[1]`和`VPN[0]`来从页表中找到`PPN[1]`和`PPN[0]`的过程，Sv32中一个页表项结构如下

```
31                     20 19                10 9      8 7 6 5 4 3 2 1 0
+------------------------+--------------------+--------+---------------+
|         PPN[1]         |       PPN[0]       |Reserved|D|A|G|U|X|W|R|V|
+-----------12-----------+---------10---------+----2---+-------8-------+
```

页表项中低8位的意思如下

| Abbreviation | Meaning    |
| :----------: | :--------- |
|      D       | Dirty      |
|      A       | Accessed   |
|      G       | Global     |
|      U       | User       |
|      X       | Executable |
|      W       | Writable   |
|      R       | Readable   |
|      V       | Valid      |

其中X、W、R三位有以下组合，其中*Reserved*的组合都是非法的

|  X   |  W   |  R   | Meaning                             |
| :--: | :--: | :--: | ----------------------------------- |
|  0   |  0   |  0   | Pointer to next level of page table |
|  0   |  0   |  1   | Read-only page                      |
|  0   |  1   |  0   | *Reserved for future use*           |
|  0   |  1   |  1   | Read-write page                     |
|  1   |  0   |  0   | Execute-only page                   |
|  1   |  0   |  1   | Read-execute page                   |
|  1   |  1   |  0   | *Reserved for future use*           |
|  1   |  1   |  1   | Read-write-execute page             |

## Virtual Address Translation Process

将虚拟地址*va*转换为物理地址*pa*的过程如下

1. Let *a* be *sptbr.ppn* × **PAGESIZE**, and let *i* = **LEVELS** − 1. (For Sv32, **PAGESIZE** = 4K and **LEVELS** = 2.)
2. Let *pte* be the value of the PTE at address *a* + *va.vpn*[*i*] × **PTESIZE**. (For Sv32, **PTESIZE**=4.)
3. If *pte.v* = 0, or if *pte.r* = 0 and *pte.w* = 1, stop and raise an access exception.
4. Otherwise, the PTE is valid. If *pte.r* = 1 or *pte.x* = 1, go to step 5. Otherwise, this PTE is a pointer to the next level of the page table. Let *i* = *i* − 1. If *i* < 0, stop and raise an access exception. Otherwise, let *a* = *pte.ppn* × **PAGESIZE** and go to step 2.
5. A leaf PTE has been found. Determine if the requested memory access is allowed by the *pte.r*, *pte.w*, and *pte.x* bits. If not, stop and raise an access exception. Otherwise, the translation is successful. Set *pte.a* to 1, and, if the memory access is a store, set *pte.d* to 1. The translated physical address is given as follows:
  * *pa.pgoff* = *va.pgoff*.
  * If *i* > 0, then this is a superpage translation and *pa.ppn*[*i* − 1 : 0] = *va.vpn*[*i* − 1 : 0].
  * *pa.ppn*[**LEVELS** − 1 : *i*] = *pte.ppn*[**LEVELS** − 1 : *i*].

## Useful Marcos

`PADDR`和`KADDR`时两个很重要的宏，能够实现内核空间中虚拟地址和物理地址的转换，而为了完成这些转换，我们首先要知道虚拟地址相对物理地址的偏移量

```c
extern uint32_t va_pa_offset; // virtual address - physical address
```

我们不妨先假设我们已经知道了这个变量的值，那么`PADDR`和`KADDR`可实现如下

```c
/* *
 * PADDR - takes a kernel virtual address (an address that points above
 * KERNBASE), where the machine's maximum 256MB of physical memory is mapped and
 * returns the corresponding physical address.  It panics if you pass it a
 * non-kernel virtual address.
 * */
#define PADDR(kva)                                           \
  ({                                                         \
    uintptr_t __m_kva = (uintptr_t)(kva);                    \
    if (__m_kva < KERNBASE) {                                \
      panic("PADDR called with invalid kva %08lx", __m_kva); \
    }                                                        \
    __m_kva - va_pa_offset;                                  \
  })
```

```c
/* *
 * KADDR - takes a physical address and returns the corresponding kernel virtual
 * address. It panics if you pass an invalid physical address.
 * */
#define KADDR(pa)                                          \
  ({                                                       \
    uintptr_t __m_pa = (pa);                               \
    size_t __m_ppn = PPN(__m_pa);                          \
    if (__m_ppn >= npage) {                                \
      panic("KADDR called with invalid pa %08lx", __m_pa); \
    }                                                      \
    (void*)(__m_pa + va_pa_offset);                        \
  })
```

进一步在`kern/mm/mmu.h`中添加以下宏定义

```c
// page table entry (PTE) fields
#define PTE_V     0x001 // Valid
#define PTE_R     0x002 // Read
#define PTE_W     0x004 // Write
#define PTE_X     0x008 // Execute
#define PTE_U     0x010 // User
#define PTE_G     0x020 // Global
#define PTE_A     0x040 // Accessed
#define PTE_D     0x080 // Dirty
#define PTE_SOFT  0x300 // Reserved for Software

#define PAGE_TABLE_DIR (PTE_V)
#define READ_ONLY (PTE_R | PTE_V)
#define READ_WRITE (PTE_R | PTE_W | PTE_V)
#define EXEC_ONLY (PTE_X | PTE_V)
#define READ_EXEC (PTE_R | PTE_X | PTE_V)
#define READ_WRITE_EXEC (PTE_R | PTE_W | PTE_X | PTE_V)

#define PTE_USER (PTE_R | PTE_W | PTE_X | PTE_U | PTE_V)
```

由于Sv32使用了34位物理地址，原有的部分宏也需要修改

```c
#define PTXSHIFT 12       // offset of PTX in a linear address
#define PDXSHIFT 22       // offset of PDX in a linear address
#define PTE_PPN_SHIFT 10  // offset of PPN in a physical address

// address in page table or page directory entry
#define PTE_ADDR(pte) (((uintptr_t)(pte) & ~0x3FF) << (PTXSHIFT - PTE_PPN_SHIFT))
#define PDE_ADDR(pde) PTE_ADDR(pde)
```

再定义一些helper function

```c
// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
}

static inline pte_t ptd_create(uintptr_t ppn) {
  return pte_create(ppn, PTE_V);
}
```

主要的准备工作完成，只要对`kern/mm/pmm.c`做些许修改即可。

## Physical Memory Management

我们先将探测物理内存的函数`page_init`和获取页表项的`get_pte`两个函数放在一边，直接分析最重要的`pmm_init`函数

```c
/**
 * pmm_init
 * - setup a pmm to manage physical memory, build PDT&PT to setup paging
 * mechanism
 * - check the correctness of pmm & paging mechanism, print PDT&PT
 */
void pmm_init(void) {
  init_pmm_manager();

  // detect physical memory space, reserve already used memory,
  // then use pmm->init_memmap to create free page list
  page_init();

  // use pmm->check to verify the correctness of the alloc/free function in a
  // pmm
  check_alloc_page();

  // create boot_pgdir, an initial page directory(Page Directory Table, PDT)
  boot_pgdir = boot_alloc_page();
  memset(boot_pgdir, 0, PGSIZE);
  boot_cr3 = PADDR(boot_pgdir);

  check_pgdir();

  static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

  // recursively insert boot_pgdir in itself
  // to form a virtual page table at virtual address VPT
  boot_pgdir[PDX(VPT)] = pte_create(PPN(boot_cr3), READ_WRITE);

  // map all physical memory to linear memory with base linear addr KERNBASE
  // KERNBASE~KERNBASE+KMEMSIZE => PADDR(KERNBASE)~PADDR(KERNBASE)+KMEMSIZE
  boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, PADDR(KERNBASE),
                   READ_WRITE_EXEC);

  // map last page to make SBI happy
  pde_t* sptbr = KADDR(read_csr(sptbr) << PGSHIFT);
  pte_t* sbi_pte = get_pte(sptbr, 0xFFFFFFFF, 0);
  boot_map_segment(boot_pgdir, (uintptr_t)(-PGSIZE), PGSIZE, PTE_ADDR(*sbi_pte),
                   READ_EXEC);

  enable_paging();

  // now the basic virtual memory map(see memalyout.h) is established.
  // check the correctness of the basic virtual memory map.
  check_boot_pgdir();

  print_pgdir();
}

```

比较值得关注的地方有三处

```c
  // map all physical memory to linear memory with base linear addr KERNBASE
  // KERNBASE~KERNBASE+KMEMSIZE => PADDR(KERNBASE)~PADDR(KERNBASE)+KMEMSIZE
  boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, PADDR(KERNBASE), READ_WRITE_EXEC);
```

由于RISC-V下物理地址不再是从`0x00000000`开始，我们需要建立`KERNBASE~KERNBASE+KMEMSIZE => PADDR(KERNBASE)~PADDR(KERNBASE)+KMEMSIZE`的映射，这不难理解。

另外一点其实也不复杂

```c
  // map last page to make SBI happy
  pde_t* sptbr = KADDR(read_csr(sptbr) << PGSHIFT);
  pte_t* sbi_pte = get_pte(sptbr, 0xFFFFFFFF, 0);
  boot_map_segment(boot_pgdir, (uintptr_t)(-PGSIZE), PGSIZE, PTE_ADDR(*sbi_pte), READ_EXEC);
```

之前介绍[SBI](toolchain-overview.md)时已经提到，SBI函数被bbl预先放置在虚拟地址的最后一个页上，这里我们利用`get_pte`从bbl为我们建立的页表中取出SBI对应的页表项，然后再次建立虚拟地址最后一个页到SBI函数所在物理页的映射关系。

最后就是`enable_paging`的实现，因为Supervisor没有权限修改内存管理模式，所以该函数实际上只修改`sptbr`

```c
static void enable_paging(void) {
  write_csr(sptbr, boot_cr3 >> PGSHIFT);
}
```

## Detecting Physical Memory

由于`sbi_query_memory`的存在，探测物理内存的过程反而简化了

```c
/* pmm_init - initialize the physical memory management */
static void page_init(void) {
  memory_block_info info;
  uint32_t hart_id = sbi_hart_id();
  if (sbi_query_memory(hart_id, &info) != 0) {
    panic("failed to get physical memory size info!\n");
  }

  va_pa_offset = KERNBASE - info.base;

  uint32_t mem_begin = info.base;
  uint32_t mem_size = info.size;
  uint32_t mem_end = mem_begin + mem_size;

  cprintf("physcial memory map:\n");
  cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
          mem_end - 1);

  uint64_t maxpa = mem_end;

  if (maxpa > KERNTOP) {
    maxpa = KERNTOP;
  }

  extern char end[];

  npage = maxpa / PGSIZE;
  pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

  for (size_t i = 0; i < npage; i++) {
    SetPageReserved(pages + i);
  }

  uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);

  mem_begin = ROUNDUP(freemem, PGSIZE);
  mem_end = ROUNDDOWN(mem_end, PGSIZE);
  if (freemem < mem_end) {
    init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
  }
}
```

唯一要注意的是

```c
va_pa_offset = KERNBASE - info.base;
```

这就是之前说的虚拟地址相对物理地址的偏移量，`info.base`就是kernel的入口点的物理地址

## Getting Page Table Entry

`get_pte`函数几乎无变化，只需修改一下用到的宏即可

```c
/**
 * @param pgdir the kernel virtual base address of PDT
 * @param la the linear address need to map
 * @param create a logical value to decide if alloc a page for PT
 * @return the kernel virtual address of this pte
 */
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
  pde_t *pdep = &pgdir[PDX(la)];
  if (!(*pdep & PTE_V)) {
    struct Page *page;
    if (!create || (page = alloc_page()) == NULL) {
      return NULL;
    }
    set_page_ref(page, 1);
    uintptr_t pa = page2pa(page);
    memset(KADDR(pa), 0, PGSIZE);
    *pdep = pte_create(page2ppn(page), PTE_U | PTE_V);
  }
  return &((pte_t *)KADDR(PDE_ADDR(*pdep)))[PTX(la)];
}
```

