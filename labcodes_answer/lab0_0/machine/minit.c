#include "mtrap.h"
#include "atomic.h"
#include "vm.h"
//#include "fp_emulation.h"
#include "bits.h"
#include "fdt.h"
#include "uart.h"
#include "uart16550.h"
#include "finisher.h"
#include "disabled_hart_mask.h"
#include "htif.h"
#include <string.h>
#include <limits.h>

pte_t* root_page_table;
uintptr_t mem_size;
volatile uint64_t* mtime;
volatile uint32_t* plic_priorities;
size_t plic_ndevs;

static void mstatus_init()
{
  // Enable FPU
  if (supports_extension('D') || supports_extension('F'))
    write_csr(mstatus, MSTATUS_FS);

  // Enable user/supervisor use of perf counters
  if (supports_extension('S'))
    write_csr(scounteren, -1);
  write_csr(mcounteren, -1);

  // Enable software interrupts
  write_csr(mie, MIP_MSIP);

  // Disable paging
  if (supports_extension('S'))
    write_csr(sptbr, 0);
}

// send S-mode interrupts and most exceptions straight to S-mode
static void delegate_traps()
{
  if (!supports_extension('S'))
    return;

  uintptr_t interrupts = MIP_SSIP | MIP_STIP | MIP_SEIP;
  uintptr_t exceptions =
    (1U << CAUSE_MISALIGNED_FETCH) |
    (1U << CAUSE_FETCH_PAGE_FAULT) |
    (1U << CAUSE_BREAKPOINT) |
    (1U << CAUSE_LOAD_PAGE_FAULT) |
    (1U << CAUSE_STORE_PAGE_FAULT) |
    (1U << CAUSE_USER_ECALL);

  write_csr(mideleg, interrupts);
  write_csr(medeleg, exceptions);
  assert(read_csr(mideleg) == interrupts);
  assert(read_csr(medeleg) == exceptions);
}

static void fp_init()
{
  if (!supports_extension('D') && !supports_extension('F'))
    return;

  assert(read_csr(mstatus) & MSTATUS_FS);

#ifdef __riscv_flen
//  for (int i = 0; i < 32; i++)
//    init_fp_reg(i);
//  write_csr(fcsr, 0);
#else
  uintptr_t fd_mask = (1 << ('F' - 'A')) | (1 << ('D' - 'A'));
  clear_csr(misa, fd_mask);
  assert(!(read_csr(misa) & fd_mask));
#endif
}

hls_t* hls_init(uintptr_t id)
{
  hls_t* hls = OTHER_HLS(id);
  memset(hls, 0, sizeof(*hls));
  return hls;
}

static void memory_init()
{
  mem_size = mem_size / MEGAPAGE_SIZE * MEGAPAGE_SIZE;
}

static void hart_init()
{
  mstatus_init();
  fp_init();
  delegate_traps();
}

static void plic_init()
{
  for (size_t i = 1; i <= plic_ndevs; i++)
    plic_priorities[i] = 1;
}

static void prci_test()
{
  assert(!(read_csr(mip) & MIP_MSIP));
  *HLS()->ipi = 1;
  assert(read_csr(mip) & MIP_MSIP);
  *HLS()->ipi = 0;

  assert(!(read_csr(mip) & MIP_MTIP));
  *HLS()->timecmp = 0;
  assert(read_csr(mip) & MIP_MTIP);
  *HLS()->timecmp = -1ULL;
}

static void hart_plic_init()
{
  // clear pending interrupts
  *HLS()->ipi = 0;
  *HLS()->timecmp = -1ULL;
  write_csr(mip, 0);

  if (!plic_ndevs)
    return;

  size_t ie_words = plic_ndevs / sizeof(uintptr_t) + 1;
  for (size_t i = 0; i < ie_words; i++)
    HLS()->plic_s_ie[i] = ULONG_MAX;
  *HLS()->plic_m_thresh = 1;
  *HLS()->plic_s_thresh = 0;
}

static void wake_harts()
{
  for (int hart = 0; hart < MAX_HARTS; ++hart)
    if ((((~disabled_hart_mask & hart_mask) >> hart) & 1))
      *OTHER_HLS(hart)->ipi = 1; // wakeup the hart
}

void print_logo();

void init_first_hart(uintptr_t hartid, uintptr_t dtb)
{
  // Confirm console as early as possible
  //query_uart(dtb);
  //query_uart16550(dtb);
  query_htif(dtb);

  hart_init();
  hls_init(0); // this might get called again from parse_config_string

  // Find the power button early as well so die() works
  query_finisher(dtb);

  query_mem(dtb);
  query_harts(dtb);
  query_clint(dtb);
  query_plic(dtb);

  wake_harts();

  plic_init();
  hart_plic_init();
  //prci_test();
  memory_init();
  boot_loader(dtb);
}

void init_other_hart(uintptr_t hartid, uintptr_t dtb)
{
  hart_init();
  hart_plic_init();
  boot_other_hart(dtb);
}

void enter_supervisor_mode(void (*fn)(uintptr_t), uintptr_t arg0, uintptr_t arg1)
{
  // Set up a PMP to permit access to all of memory.
  // Ignore the illegal-instruction trap if PMPs aren't supported.
  uintptr_t pmpc = PMP_NAPOT | PMP_R | PMP_W | PMP_X;
  asm volatile ("la t0, 1f\n\t"
                "csrrw t0, mtvec, t0\n\t"
                "csrw pmpaddr0, %1\n\t"
                "csrw pmpcfg0, %0\n\t"
                ".align 2\n\t"
                "1: csrw mtvec, t0"
                : : "r" (pmpc), "r" (-1UL) : "t0");

  uintptr_t mstatus = read_csr(mstatus);
  mstatus = INSERT_FIELD(mstatus, MSTATUS_MPP, PRV_S);
  mstatus = INSERT_FIELD(mstatus, MSTATUS_MPIE, 0);
  write_csr(mstatus, mstatus);
  write_csr(mscratch, MACHINE_STACK_TOP() - MENTRY_FRAME_SIZE);
  write_csr(mepc, fn);

  register uintptr_t a0 asm ("a0") = arg0;
  register uintptr_t a1 asm ("a1") = arg1;
  asm volatile ("mret" : : "r" (a0), "r" (a1));
  __builtin_unreachable();
}
