TARGET := riscv64gc-unknown-none-elf
MODE := release
APP_DIR := src/bin
TARGET_DIR := target/$(TARGET)/$(MODE)
ELFS := $(patsubst $(APP_DIR)/*.rs, $(TARGET_DIR)/*, $(wildcard $(APP_DIR)/*.rs))
BINS := $(patsubst $(APP_DIR)/*.rs, $(TARGET_DIR)/*.bin, $(wildcard $(APP_DIR)/*.rs))

OBJDUMP := rust-objdump --arch-name=riscv64
OBJCOPY := rust-objcopy --binary-architecture=riscv64

elf:
	@cargo build --release

binary: elf
	$(foreach elf, $(ELFS), $(OBJCOPY) $(elf) --strip-all -O binary $(patsubst $(TARGET_DIR)/*, $(TARGET_DIR)/*.bin, $(elf)))

build: binary
