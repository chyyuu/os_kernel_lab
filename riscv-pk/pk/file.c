// See LICENSE for license details.

#include "file.h"
#include "atomic.h"
#include "mmap.h"
#include "frontend.h"
#include "syscall.h"
#include "pk.h"
#include <string.h>
#include <errno.h>

#define MAX_FDS 128
static file_t* fds[MAX_FDS];
#define MAX_FILES 128
file_t files[MAX_FILES] = {[0 ... MAX_FILES-1] = {-1,0}};

void file_incref(file_t* f)
{
  long prev = atomic_add(&f->refcnt, 1);
  kassert(prev > 0);
}

void file_decref(file_t* f)
{
  if (atomic_add(&f->refcnt, -1) == 2)
  {
    int kfd = f->kfd;
    mb();
    atomic_set(&f->refcnt, 0);

    frontend_syscall(SYS_close, kfd, 0, 0, 0, 0, 0, 0);
  }
}

static file_t* file_get_free()
{
  for (file_t* f = files; f < files + MAX_FILES; f++)
    if (atomic_read(&f->refcnt) == 0 && atomic_cas(&f->refcnt, 0, 2) == 0)
      return f;
  return NULL;
}

int file_dup(file_t* f)
{
  for (int i = 0; i < MAX_FDS; i++)
  {
    if (atomic_cas(&fds[i], 0, f) == 0)
    {
      file_incref(f);
      return i;
    }
  }
  return -1;
}

void file_init()
{
  // create stdin, stdout, stderr and FDs 0-2
  for (int i = 0; i < 3; i++) {
    file_t* f = file_get_free();
    f->kfd = i;
    file_dup(f);
  }
}

file_t* file_get(int fd)
{
  file_t* f;
  if (fd < 0 || fd >= MAX_FDS || (f = atomic_read(&fds[fd])) == NULL)
    return 0;

  long old_cnt;
  do {
    old_cnt = atomic_read(&f->refcnt);
    if (old_cnt == 0)
      return 0;
  } while (atomic_cas(&f->refcnt, old_cnt, old_cnt+1) != old_cnt);

  return f;
}

file_t* file_open(const char* fn, int flags, int mode)
{
  return file_openat(AT_FDCWD, fn, flags, mode);
}

file_t* file_openat(int dirfd, const char* fn, int flags, int mode)
{
  file_t* f = file_get_free();
  if (f == NULL)
    return ERR_PTR(-ENOMEM);

  size_t fn_size = strlen(fn)+1;
  long ret = frontend_syscall(SYS_openat, dirfd, va2pa(fn), fn_size, flags, mode, 0, 0);
  if (ret >= 0)
  {
    f->kfd = ret;
    return f;
  }
  else
  {
    file_decref(f);
    return ERR_PTR(ret);
  }
}

int fd_close(int fd)
{
  file_t* f = file_get(fd);
  if (!f)
    return -1;
  file_t* old = atomic_cas(&fds[fd], f, 0);
  file_decref(f);
  if (old != f)
    return -1;
  file_decref(f);
  return 0;
}

ssize_t file_read(file_t* f, void* buf, size_t size)
{
  populate_mapping(buf, size, PROT_WRITE);
  return frontend_syscall(SYS_read, f->kfd, va2pa(buf), size, 0, 0, 0, 0);
}

ssize_t file_pread(file_t* f, void* buf, size_t size, off_t offset)
{
  populate_mapping(buf, size, PROT_WRITE);
  return frontend_syscall(SYS_pread, f->kfd, va2pa(buf), size, offset, 0, 0, 0);
}

ssize_t file_write(file_t* f, const void* buf, size_t size)
{
  populate_mapping(buf, size, PROT_READ);
  return frontend_syscall(SYS_write, f->kfd, va2pa(buf), size, 0, 0, 0, 0);
}

ssize_t file_pwrite(file_t* f, const void* buf, size_t size, off_t offset)
{
  populate_mapping(buf, size, PROT_READ);
  return frontend_syscall(SYS_pwrite, f->kfd, va2pa(buf), size, offset, 0, 0, 0);
}

int file_stat(file_t* f, struct stat* s)
{
  struct frontend_stat buf;
  long ret = frontend_syscall(SYS_fstat, f->kfd, va2pa(&buf), 0, 0, 0, 0, 0);
  copy_stat(s, &buf);
  return ret;
}

int file_truncate(file_t* f, off_t len)
{
  return frontend_syscall(SYS_ftruncate, f->kfd, len, 0, 0, 0, 0, 0);
}

ssize_t file_lseek(file_t* f, size_t ptr, int dir)
{
  return frontend_syscall(SYS_lseek, f->kfd, ptr, dir, 0, 0, 0, 0);
}
