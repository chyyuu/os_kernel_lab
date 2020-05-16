## 打包为磁盘镜像

在上一章我们已经实现了文件系统，并且可以让操作系统加载磁盘镜像。现在，我们只需要利用工具将编译后的用户程序打包为镜像，就可以使用了。

### 工具安装

通过 cargo 来安装 `rcore-fs-fuse` 工具：

{% label %}运行命令{% endlabel %}
```bash
cargo install rcore-fs-fuse --git https://github.com/rcore-os/rcore-fs
```

### 打包

这个工具可以将一个目录打包成 SimpleFileSystem 格式的磁盘镜像。为此，我们需要将编译得到的 ELF 文件单独放在一个导出目录中，即 `user/build/disk`。

{% label %}user/Makefile{% endlabel %}
```makefile
build: dependency
	# 编译
	@cargo build
	@echo Targets: $(patsubst $(SRC_DIR)/%.rs, %, $(SRC_FILES))
	# 移除原有的所有文件
	@rm -rf $(OUT_DIR)
	@mkdir -p $(OUT_DIR)
	# 复制编译生成的 ELF 至目标目录
	@cp $(BIN_FILES) $(OUT_DIR)
	# 使用 rcore-fs-fuse 工具进行打包
	@rcore-fs-fuse --fs sfs $(IMG_FILE) $(OUT_DIR) zip
	# 将镜像文件的格式转换为 QEMU 使用的高级格式
	@qemu-img convert -f raw $(IMG_FILE) -O qcow2 $(QCOW_FILE)
	# 提升镜像文件的容量（并非实际大小），来允许更多数据写入
	@qemu-img resize $(QCOW_FILE) +1G
```

在 `os/Makefile` 中指定我们新生成的 `QCOW_FILE` 为加载镜像，就可以在操作系统中看到打包好的目录了。
