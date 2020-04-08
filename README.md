# rCore 教学实验（开发中）

*（介绍）*

## 仓库目录

- `docs/`：教学实验指导分实验内容
- `notes/`：开发日志
- `os/`：操作系统代码
- `SUMMARY.md`：GitBook 目录页
- `book.json`：GitBook 配置文件
- `rust-toolchain`：限定 Rust 工具链版本  
  *note 目前使用比较旧的，整体完成之后在考虑更新*


## 实验指导

基于 GitBook，目前尚未部署到服务器

*部署好像需要一些特殊的配置，需要 Tsinghua Git 提供域名，以及添加服务器（在 gitlab.io 上的话似乎可以直接搞）*

### 本地使用方法

```shell
npm install -g gitbook-cli
gitbook install
gitbook serve
```
