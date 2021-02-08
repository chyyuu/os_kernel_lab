cargo clean && \
cargo build --release && \
rust-objdump -S target/riscv64gc-unknown-none-elf/release/os > target/riscv64gc-unknown-none-elf/release/os.s
gedit target/riscv64gc-unknown-none-elf/release/os.s
tmux new-session -d \
"qemu-system-riscv64 -machine virt -m 8 -nographic -bios ../bootloader/rustsbi-qemu.bin  -kernel target/riscv64gc-unknown-none-elf/release/os -S -s" && \
tmux split-window -h "riscv64-unknown-elf-gdb -ex 'file target/riscv64gc-unknown-none-elf/release/os' -ex 'set arch riscv:rv64' -ex 'target remote localhost:1234'" && \
tmux -2 attach-session -d
 
 
 
