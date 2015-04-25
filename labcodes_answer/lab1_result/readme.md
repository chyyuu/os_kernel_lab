# for kernel with original bootloader and ucore kernel
```
make 
```
and
```
make qemu
```

# for kernel with grub loading in real x86 machine

compiling command:
```
$make mboot
```
> need `nasm`, try to use `sudo apt-get install nasm` to install this soft.

after this, will generate `bin/grub_kernel`

## a) run it in qemu

we could use 
```
qemu-system-i386 -kernel bin/grub_kernel
```
to load the lab1 ucore kernel

## b) run it in real x86 machine
```
sudo cp bin/grub_kernel /boot
```
and edit `/boot/grub/grub.cfg`, to add an item in grub.cfg.
For example:
```
menuentry 'ucore-lab1' {
        insmod part_msdos
        insmod jfs
        set root='hd0,msdos5'
        if [ x$feature_platform_search_hint = xy ]; then
          search --no-floppy --fs-uuid --set=root --hint-bios=hd0,msdos5 --hint-efi=hd0,msdos5 --hint-baremetal=ahci0,msdos5  3c5b2f97-967d-4949-96e5-aba6855d8634
        else
          search --no-floppy --fs-uuid --set=root 3c5b2f97-967d-4949-96e5-aba6855d8634
        fi
        knetbsd /boot/grub_kernel
}
```
Reboot the machine, choose ucore-lab1 in grub menu, then you will see ucore lab1 on screen of your machine.
