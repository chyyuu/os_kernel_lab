#!/bin/bash
riscv64-unknown-elf-gcc -MMD -MP -march=rv32g -mabi=ilp32d -Wall -Werror -D__NO_INLINE__ -mcmodel=medany -O2 -std=gnu99 -Wno-unused -Wno-attributes -fno-delete-null-pointer-checks  -I.  -c htif.c
riscv64-unknown-elf-gcc -MMD -MP -march=rv32g -mabi=ilp32d -Wall -Werror -D__NO_INLINE__ -mcmodel=medany -O2 -std=gnu99 -Wno-unused -Wno-attributes -fno-delete-null-pointer-checks  -I.  -c mentry.S
riscv64-unknown-elf-gcc -MMD -MP -march=rv32g -mabi=ilp32d -Wall -Werror -D__NO_INLINE__ -mcmodel=medany -O2 -std=gnu99 -Wno-unused -Wno-attributes -fno-delete-null-pointer-checks  -I.  -c bbl.c
riscv64-unknown-elf-gcc -march=rv32g -mabi=ilp32d -nostartfiles -nostdlib -static  -o bbl bbl.o mentry.o htif.o  -lgcc -T bbl.lds
riscv64-unknown-elf-objcopy -O binary bbl bbl.bin
riscv64-unknown-elf-objdump -S bbl > bbl.s
