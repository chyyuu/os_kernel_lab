// See LICENSE for license details.

#ifndef _RISCV_FRONTEND_H
#define _RISCV_FRONTEND_H

#include <stdint.h>
#include <sys/stat.h>

void shutdown(int) __attribute__((noreturn));
long frontend_syscall(long n, uint64_t a0, uint64_t a1, uint64_t a2, uint64_t a3, uint64_t a4, uint64_t a5, uint64_t a6);

struct frontend_stat {
  uint64_t dev;
  uint64_t ino;
  uint32_t mode;
  uint32_t nlink;
  uint32_t uid;
  uint32_t gid;
  uint64_t rdev;
  uint64_t __pad1;
  uint64_t size;
  uint32_t blksize;
  uint32_t __pad2;
  uint64_t blocks;
  uint64_t atime;
  uint64_t __pad3;
  uint64_t mtime;
  uint64_t __pad4;
  uint64_t ctime;
  uint64_t __pad5;
  uint32_t __unused4;
  uint32_t __unused5;
};

void copy_stat(struct stat* dest, struct frontend_stat* src);

#endif
