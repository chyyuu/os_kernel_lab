# 制作在真机上u盘启动的ucore lab

## 编译 ucore lab for 真机上u盘启动
请参考
https://github.com/chyyuu/ucore_lab/blob/lab1_X/labcodes_answer/lab1_result/readme.md#for-kernel-with-grub-loading-in-real-x86-machine
编译出 ucore lab1 kernel: grub_kernel

## 格式化u盘
插入u盘，执行如下命令
```
df
```
可以看到
```
文件系统          1K-块     已用     可用 已用% 挂载点
/dev/sda5      58492984 49662756  8830228   85% /
...
/dev/sdb1      31473632     7648 31465984    1% /media/chyyuu/MULTIBOOT
```
其中最后一个`/dev/sdb1`就是u盘的标记。
接下来启动一个shell，并执行如下命令操作 

```
sudo su                  #切换到root管理员身份
fdisk -l                 #查询现挂载有的存储设备，记住你的u盘标记,，比如 /dev/sdb1
fdisk /dev/sdb1          #注意：把sdb1换成你机器上看到的u盘标记，接下来在fdisk界面操作
命令(输入 m 获取帮助)：d     #删除现存分区，如果有多个分区，则都删除掉
命令(输入 m 获取帮助)：n     #创建一个新分区，下面的操作都是用于创建新分区
  Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)

   输入 p                 #创建主分区
 分区号 (1-4, default 1): 
   输入 1                 #创建第一个分区 
 First sector (2048-62978047, default 2048):
   输入 [回车]             #缺省使用默认值第一个柱面
 Last sector, +sectors or +size{K,M,G,T,P} (2048-62978047, default 62978047): 
   再次输入[回车]           #缺省使用默认值作为最后一个柱面
   
命令(输入 m 获取帮助)：a     #活动分区）
命令(输入 m 获取帮助)：w     #将修改写入u盘并退出fdisk

#接下来又回到了shell
umount /dev/sdb1         #卸载已经挂载的分区
mkfs.vfat -F 32 -n MULTIBOOT /dev/sdb1     #将分区格式化为fat32
```

## 在u盘上安装grub2
继续执行如下命令操作 
```
mkdir /media/MULTIBOOT/              #创建目录用于挂载和拷贝文件
mount /dev/sdb1 /media/MULTIBOOT/    #挂载u盘
grub-install --force --no-floppy --root-directory=/media/MULTIBOOT/ /dev/sdb1    #安装grub2
```
此时，在u盘根目录下将出现`/boot/grub/`目录。现在还需在u盘`/boot/grub/`目录下创建一个启动菜单文件`grub.cfg`。
其内容如下：
```
menuentry 'ucore-lab1' {
	knetbsd /boot/grub_kernel
}
```
创建完`grub.cfg`文件后，再把编译生成的`grub_kernel`拷贝到`/media/MULTIBOOT/boot`目录下。
```
cp /YOU_DIR/ucore_lab/labcodes_answer/lab1_result/bin/grub_kernel /media/MULTIBOOT/boot
```
这时，准备工作完成了。

## 启动u盘运行ucore lab
重启机器，选择u盘启动（可能需要修改BIOS的启动选项），可以看到grub的选项菜单，点选`ucore_lab1`
就可以看到ucore lab1在真机上运行了。

