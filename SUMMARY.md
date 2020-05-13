# rCore 教学实验文档

* [实验简介](README.md)

## 开发笔记
* [文档代码划分](docs/format/partition.md)
* [文档格式规范](docs/format/doc.md)
* [代码格式规范](docs/format/code.md)

## 实验之前
<!-- TODO * [Rust 基础介绍](docs/pre-lab/rust.md)  -->
<!-- TODO * [操作系统背景知识](docs/pre-lab/os.md) -->
* [环境部署](docs/pre-lab/env.md)

## 实验指导
* 实验指导零
  * [摘要](docs/lab-0/guide/intro.md)
  * [创建项目](docs/lab-0/guide/part-1.md)
  * [移除标准库依赖](docs/lab-0/guide/part-2.md)
  * [移除运行时环境依赖](docs/lab-0/guide/part-3.md)
  * [编译为裸机目标](docs/lab-0/guide/part-4.md)
  * [生成内核镜像](docs/lab-0/guide/part-5.md)
  * [调整内存布局](docs/lab-0/guide/part-6.md)
  * [重写程序入口点](docs/lab-0/guide/part-7.md)
  * [使用 QEMU 运行](docs/lab-0/guide/part-8.md)
  * [接口封装和代码整理](docs/lab-0/guide/part-9.md)
  * [小结](docs/lab-0/guide/summary.md)
* 实验指导一
  * [摘要](docs/lab-1/guide/intro.md)
  * [什么是中断](docs/lab-1/guide/part-1.md)
  * [RISC-V 中的中断](docs/lab-1/guide/part-2.md)
  * [程序运行状态](docs/lab-1/guide/part-3.md)
  * [状态的保存与恢复](docs/lab-1/guide/part-4.md)
  * [进入中断处理流程](docs/lab-1/guide/part-5.md)
  * [时钟中断](docs/lab-1/guide/part-6.md)
  * [小结](docs/lab-1/guide/summary.md)
* 实验指导二
  * [摘要](docs/lab-2/guide/intro.md)
  * [动态内存分配](docs/lab-2/guide/part-1.md)
  * [物理内存探测](docs/lab-2/guide/part-2.md)
  * [物理内存管理](docs/lab-2/guide/part-3.md)
  * [小结](docs/lab-2/guide/summary.md)
* 实验指导三
  * [摘要](docs/lab-3/guide/intro.md)
  * [从虚拟地址到物理地址](docs/lab-3/guide/part-1.md)
  * [修改内核](docs/lab-3/guide/part-2.md)
  * [实现页表](docs/lab-3/guide/part-3.md)
  * [实现内核重映射](docs/lab-3/guide/part-4.md)
  * [小结](docs/lab-3/guide/summary.md)
* 实验指导四
  * [摘要](docs/lab-4/guide/intro.md)
  * [线程和进程](docs/lab-4/guide/part-1.md)
  * [线程的创建](docs/lab-4/guide/part-2.md)
  * [线程的切换](docs/lab-4/guide/part-3.md)
  * [内核栈](docs/lab-4/guide/part-4.md)
  * [线程调度](docs/lab-4/guide/part-5.md)
  * [小结](docs/lab-4/guide/summary.md)
* 实验指导五
  * [摘要](docs/lab-5/guide/intro.md)
  * [设备树](docs/lab-5/guide/part-1.md)
  * [virtio](docs/lab-5/guide/part-2.md)
  * [驱动和块设备驱动](docs/lab-5/guide/part-3.md)
  * [文件系统](docs/lab-5/guide/part-4.md)
  * [小结](docs/lab-5/guide/summary.md)
