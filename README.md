# rCore 教学实验（开发中）

本教学仓库是继 [rCore_tutorial](https://rcore-os.github.io/rCore_tutorial_doc/) 后重构的版本。

## 仓库目录

- `docs/`：教学实验指导分实验内容和开发规范
- `notes/`：开题报告和若干讨论
- `os/`：操作系统代码
- `SUMMARY.md`：GitBook 目录页
- `book.json`：GitBook 配置文件
- `rust-toolchain`：限定 Rust 工具链版本
<!-- Rust 工具链版本需要根据时间更新 -->

## 实验指导

基于 GitBook，目前已经部署到了 [GitHub Pages](https://os20-rcore-tutorial.github.io/rCore-Tutorial-deploy)
 上面。

### 本地使用方法

```bash
npm install -g gitbook-cli
gitbook install
gitbook serve
```

## 代码

### 操作系统代码
基于 cargo 项目，进入 `os` 目录通过相关命令可以运行：
```bash
cd os
# 编译并运行
make run
# 根据代码注释生成文档
cargo doc
```

### 参考和感谢

本文档和代码大量参考了：
- [rCore_tutorial](https://rcore-os.github.io/rCore_tutorial_doc/)
- [使用Rust编写操作系统](https://github.com/rustcc/writing-an-os-in-rust)

在此对仓库的开发和维护者表示感谢，同时也感谢很多在本项目开发中一起讨论和勘误的老师和同学们。

<!-- TODO LICENSE -->
