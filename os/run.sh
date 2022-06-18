qemu-system-riscv64 -M 128m -machine virt  \
-bios ../bootloader/rustsbi-qemu.bin  \
-device loader,file=target/riscv64gc-unknown-none-elf/release/os.bin,addr=0x80200000  \
-drive file=../user/target/riscv64gc-unknown-none-elf/release/fs.img,if=none,format=raw,id=x0  \
-device virtio-blk-device,drive=x0  \
-device virtio-gpu-device  \
-device virtio-keyboard-device  \
-device virtio-mouse-device \
-serial stdio  
