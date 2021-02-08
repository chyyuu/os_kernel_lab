OUTPUT_ARCH(riscv)
ENTRY(_start)
BASE_ADDRESS = 0x80020000;
USER1_ADDR = 0x80600000;
USER2_ADDR = 0x80700000;
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
    .bss : {
        start_bss = .;
        *(.bss)
        end_bss = .;
    }

    . = ALIGN(4K);
    ebss = .;
    stack_begin = .;
    .stack : {
        *(.bss.stack)
    }
    stack_end = .;
    ekernel = .;

    . = ALIGN(4K);
    . = USER1_ADDR;
    user1_begin = .;
    .text : {
        *(.usrapp1.entry)
    }
    .data : {
        *(.usrapp1.data)
    }

    . = ALIGN(4K);
    . = USER2_ADDR;
    user2_begin = .;
    .text : {
        *(.usrapp2.entry)
    }
    .data : {
        *(.usrapp2.data)
    }

    /DISCARD/ : {
        *(.eh_frame)
        *(.debug*)
    }
}

