OUTPUT_ARCH(riscv)
ENTRY(_start)
BASE_ADDRESS = 0x80020000;

SECTIONS
{
    . = BASE_ADDRESS;
    skernel = .;

    stext = .;
    .text : {
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
    .bss : {
        start_bss = .;
        *(.bss)
        end_bss = .;
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
