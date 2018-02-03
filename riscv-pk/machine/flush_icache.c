void __riscv_flush_icache(void) {
  __asm__ volatile ("fence.i");
}
