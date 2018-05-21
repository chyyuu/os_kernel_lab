#include <ulib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stat.h>
#include <file.h>
#include <dir.h>
#include <unistd.h>

#define printf(...)                 fprintf(1, __VA_ARGS__)

static int safe_open(const char *path, int open_flags)
{
	int fd = open(path, open_flags);
	printf("fd is %d\n",fd);
	assert(fd >= 0);
	return fd;
}

static struct stat *safe_fstat(int fd)
{
	static struct stat __stat, *stat = &__stat;
	int ret = fstat(fd, stat);
	assert(ret == 0);
	return stat;
}


static void safe_read(int fd, void *data, size_t len)
{
	int ret = read(fd, data, len);
	assert(ret == len);
}


int main(void)
{
	int fd1 = safe_open("sfs_filetest1", O_RDONLY);
	struct stat *stat = safe_fstat(fd1);
	assert(stat->st_size >= 0 && stat->st_blocks >= 0);
	printf("sfs_filetest1 pass.\n");
	return 0;
}
