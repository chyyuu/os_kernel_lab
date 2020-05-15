.PHONY: build

TARGET      := riscv64imac-unknown-none-elf
MODE        := debug

# 用户程序目录
SRC_DIR		:= src/bin
# 编译后执行文件目录
TARGET_DIR	:= target/$(TARGET)/$(MODE)
# 用户程序源文件
SRC_FILES	:= $(wildcard $(SRC_DIR)/*.rs)
# 根据源文件取得编译后的执行文件
BIN_FILES	:= $(patsubst $(SRC_DIR)/%.rs, $(TARGET_DIR)/%, $(SRC_FILES))

OUT_DIR		:= build/disk
IMG_FILE	:= build/disk.img

# 安装 rcore-fs-fuse 工具
dependency:
ifeq ($(shell which rcore-fs-fuse),)
	@echo Installing rcore-fs-fuse
	@cargo install rcore-fs-fuse --git https://github.com/rcore-os/rcore-fs
endif

build: dependency
	@cargo build
	@echo Targets: $(patsubst $(SRC_DIR)/%.rs, %, $(SRC_FILES))
	@rm -rf $(OUT_DIR)
	@mkdir -p $(OUT_DIR)/rust
	@cp $(BIN_FILES) $(OUT_DIR)/rust
	@dd if=/dev/zero of=$(OUT_DIR)/temp bs=1k count=2
	@rcore-fs-fuse --fs sfs $(IMG_FILE) $(OUT_DIR) zip