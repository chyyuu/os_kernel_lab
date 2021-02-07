OUTPUT_ARCH(riscv)
ENTRY(_start)
BASE_ADDRESS = 0x80020000;
USER_ADDR = 0x80600000;
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
    . = USER_ADDR;
    user_begin = .;
    .text : {
        *(.usrapp.entry)
        *(.usrapp)
    }
    /DISCARD/ : {
        *(.eh_frame)
        *(.debug*)
    }
}

