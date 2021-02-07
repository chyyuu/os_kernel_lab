cargo clean
cargo build --release 
qemu-system-riscv64 -machine virt -m 8 -nographic -bios ../bootloader/rustsbi-qemu.bin  -kernel target/riscv64gc-unknown-none-elf/release/os
 
 
 
