OUTPUT_ARCH(riscv)
ENTRY(_start)
BASE_ADDRESS = 0x80200000;

SECTIONS
{
    . = ALIGN(4K);
    . = BASE_ADDRESS;
    skernel = .;
    stext = .;
    .text : {
        *(.text.entry)
        *(.text)
    }

    . = ALIGN(4K);
    etext = .;
    srodata = .;
    .rodata : {
        *(.rodata)
        *(.rodata*)
    }

    . = ALIGN(4K);
    erodata = .;
    sdata = .;
    .data : {
        *(.data)
    }

    . = ALIGN(4K);
    edata = .;
    sbss = .;
    sbss_with_stack = .;
    .bss : {
        start_bss = .;
        *(.bss)
        end_bss = .;
        *(.bss.stack)
        sbss = .;
        *(.bss .bss.*)
    }

    . = ALIGN(4K);
    ebss = .;
    .stack : {
        *(.bss.stack)
    }

    ekernel = .;

    /DISCARD/ : {
        *(.eh_frame)
        *(.debug*)
    }
}

