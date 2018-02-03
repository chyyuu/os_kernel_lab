# Lab 3

lab 2的移植中，主要改动如下

* 使用静态存储区代替交换区
  * `kern/driver/ide.c`
* 缺页中断的处理
  * `kern/trap/trap.c`
  * `kern/mm/vmm.c`

## Faking a Swap

由于现有工具链并不提供真正的I/O功能，我们只能在内存里做文章。这里的实现非常简单

```c
#define MAX_DISK_NSECS 128
static char ide[MAX_DISK_NSECS * SECTSIZE];

int ide_read_secs(unsigned short ideno, uint32_t secno, void* dst,
                  size_t nsecs) {
  int iobase = secno * SECTSIZE;
  memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
  return 0;
}

int ide_write_secs(unsigned short ideno, uint32_t secno, const void* src,
                   size_t nsecs) {
  int iobase = secno * SECTSIZE;
  memcpy(&ide[iobase], src, nsecs * SECTSIZE);
  return 0;
}
```

## Handling Page Fault

这部分的修改比较零碎，首先是在ISR中增加相关代码

```c
void exception_handler(struct trapframe *tf) {
  int ret = 0;
  switch (tf->cause) {
    case CAUSE_FAULT_LOAD:
    case CAUSE_FAULT_STORE:
      if ((ret = pgfault_handler(tf)) != 0) {
        print_trapframe(tf);
        panic("handle pgfault failed. %e\n", ret);
      }
      break;
    default:
      print_trapframe(tf);
      break;
  }
}
```

`pagefault_handler`只起到转发的作用，无需特别关注

```c
static int pgfault_handler(struct trapframe *tf) {
  extern struct mm_struct *check_mm_struct;
  print_pgfault(tf);
  if (check_mm_struct != NULL) {
    return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
  }
  panic("unhandled page fault.\n");
}
```

`do_pgfault`才是实际进行缺页中断处理的地方，与x86下的实现相比，去除了涉及`error_code`的部分

```c
/**
 * @brief      interrupt handler to process the page fault execption
 *
 * @param      mm          The control struct for a set of vma using the same PDT
 * @param[in]  error_code  The error code recorded in trapframe->cause
 * @param[in]  addr        The addr which causes a memory access exception
 *
 * @return     0 for sucess, otherwise an error code
 * 
 * CALL GRAPH: trap-->trap_dispatch-->pgfault_handler-->do_pgfault
 * The processor provides ucore's do_pgfault function with two pieces of 
 * information to aid in diagnosing the exception and recovering from it.
 *   (1) The content of the sbadvaddr register. The processor loads the
 *   sbadvaddr register with the 32-bit linear address that generated the
 *   exception. The do_pgfault fun can use this address to locate the
 *   corresponding page directory and page-table entries.
 *   (2) An error code in the scause register. Useless here.
 */
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
  int ret = -E_INVAL;
  // try to find a vma which include addr
  struct vma_struct *vma = find_vma(mm, addr);

  pgfault_num++;
  // If the addr is in the range of a mm's vma?
  if (vma == NULL || vma->vm_start > addr) {
    cprintf("not valid addr %x, and  can not find it in vma\n", addr);
    goto failed;
  }

  uint32_t perm = PTE_U;
  if (vma->vm_flags & VM_WRITE) {
    perm |= (PTE_R | PTE_W);
  }
  addr = ROUNDDOWN(addr, PGSIZE);

  ret = -E_NO_MEM;

  pte_t *ptep = get_pte(mm->pgdir, addr, 1);
  if (*ptep == 0) {
    if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
      cprintf("pgdir_alloc_page in do_pgfault failed\n");
      goto failed;
    }
  } else {
    if (swap_init_ok) {
      struct Page *page = NULL;
      swap_in(mm, addr, &page);
      page_insert(mm->pgdir, page, addr, perm);
      swap_map_swappable(mm, addr, page, 1);
      page->pra_vaddr = addr;
    } else {
      cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
      goto failed;
    }
  }

  ret = 0;
failed:
  return ret;
}
```

由于有了物理内存管理后，虚拟内存管理与硬件关系不是非常密切，所以这个lab的移植较为简单。