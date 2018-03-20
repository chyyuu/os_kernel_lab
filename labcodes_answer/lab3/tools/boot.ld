OUTPUT_FORMAT("elf64-rv64")
OUTPUT_ARCH(rv64)

SECTIONS {
    . = 0x7C00;

    .startup : {
        *bootasm.o(.text)
    }

    .text : { *(.text) }
    .data : { *(.data .rodata) }
    
    /DISCARD/ : { *(.eh_*) }
}
