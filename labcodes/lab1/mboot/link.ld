OUTPUT_FORMAT("elf32-i386")
OUTPUT_ARCH("i386")
ENTRY(start)
phys = 0x00100000;

SECTIONS
{
  kernel_start = phys;
  .mboot phys : AT(ADDR(.mboot)) {
    *(.mboot)
  }
  .text ALIGN(4096) : AT(ADDR(.text)) {
    *(.text)
  }
  PROVIDE(etext = .);
  .rodata ALIGN(4096) : AT(ADDR(.rodata)) {
    *(.rodata)
    *(.rodata.*)
  }
  /* Include debugging information in kernel memory */
  .stab : {
     PROVIDE(__STAB_BEGIN__ = .);
     *(.stab);
     PROVIDE(__STAB_END__ = .);
     BYTE(0)     /* Force the linker to allocate space
                 for this section */
  }
  .stabstr : {
     PROVIDE(__STABSTR_BEGIN__ = .);
     *(.stabstr);
     PROVIDE(__STABSTR_END__ = .);
     BYTE(0)     /* Force the linker to allocate space
                 for this section */
  }

  /* Adjust the address for the data segment to the next page */
  . = ALIGN(0x1000);
	  
  .data ALIGN(4096) : AT(ADDR(.data)) {
    *(.data)
  }
  PROVIDE(edata = .);
  bss_start = .;
  .bss ALIGN(4096) : AT(ADDR(.bss)) {
    *(.bss)
  }
  PROVIDE(end = .);
}
