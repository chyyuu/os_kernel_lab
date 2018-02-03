#ifndef __KERN_DRIVER_IDE_H__
#define __KERN_DRIVER_IDE_H__

#include <defs.h>

#define MAX_IDE 4
#define MAX_NSECS 128
#define MAX_DISK_NSECS 0x10000000U
#define VALID_IDE(ideno) \
    (((ideno) >= 0) && ((ideno) < MAX_IDE) && (ide_devices[ideno].valid))

static struct ide_device {
    unsigned int valid;  // 0 or 1 (If Device Really Exists)
    unsigned int sets;   // Commend Sets Supported
    unsigned int size;   // Size in Sectors
    uintptr_t iobase;
    void *dev_data;
    char model[32];  // Model in String

    /* return 0 if succeed */
    int (*read_secs)(struct ide_device *dev, size_t secno, void *dst,
                     size_t nsecs);
    int (*write_secs)(struct ide_device *dev, size_t secno, const void *src,
                      size_t nsecs);
} ide_devices[MAX_IDE];

void ide_init(void);
bool ide_device_valid(unsigned short ideno);
size_t ide_device_size(unsigned short ideno);

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs);
int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs);

#endif /* !__KERN_DRIVER_IDE_H__ */
