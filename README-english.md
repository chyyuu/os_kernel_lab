INTRODUCTION(2015)
============
ucore labs was used as OS Experiments in OS Course Of Dept. of Computer Science & Technology, Tsinghua University.

ucore is a teaching OS which is derived from xv6&jos in MIT, OS161 in Harvard and Linux.
ucore was developed and used in Department of Computer Science & Technology, Institute for Interdisciplinary Information Sciences, Tsinghua University.
The codes in the files that constitute xv6&jos are Copyright (2006-Current) Frans Kaashoek, Robert Morris, and Russ Cox and uses MIT License.
The codes in the files that constitute OS/161 are written by David A. Holland.
The codes in the files that constitute ucore are Copyright (2010-Current) Yu Chen, Naizheng Wang, Yong Xiang and uses GPL License.
The documents in the files that constitute ucore are Copyright (2010-Current) Yu Chen, Yong Xiang and uses Creative Commons Attribution/Share-Alike (CC-BY-SA) License. 

PEOPLES 
========

OS course for Dept. CS. in Tsinghua Univ., and MOOC OS course
-----------------------------------
Lectures: Chen, Yu   http://soft.cs.tsinghua.edu.cn/~chen
TA: Qi, Xiao  qixiao0113@gmail.com
TA: Mao, Junjie eternal.n08@gmail.com

CONTENTS
========

os course info
----------------
* [newest os course summary materials](https://github.com/chyyuu/mooc_os)
* [newest chinese README for ucore_lab](https://github.com/chyyuu/ucore_lab/)

labs info
----------------
lab0: preparing
lab1: boot/protect mode/stack/interrupt
lab2: physical memory management
lab3: virtual memory management
lab4: kernel thread management
lab5: user process management
lab6: scheduling
lab7: mutex/sync
lab8: filesystem

WORK IN MS WINDOWS
==================
Working in Linux is encouraged. But If you like to work in MS Windows, we provide virtual machine environment (Runnint Ubuntu in VirtualBox) in
Windows to help you to finish the labs. If you don't want to install ubuntu and other softs to finish these labs in Windows, you can use 
VirtualBox soft (https://www.virtualbox.org/) and a virtual disk image with all these softs. Below example is shown how to setup lab environment in Windows.
You can download this virtual disk image -- oslabs_for_student_2012.zip (576.2MB,) from  http://pan.baidu.com/share/link?shareid=69868&uk=2585194235, which
is an VirtualBox disk image (contains ubuntu 12.04 and needed softs, and is zipped with zip and xz format), and can be unzipped 
by haozip software (http://www.haozip.com). 
After unzip oslabs_for_student_XXX.zip, you will get 
---
C:\vms\ubuntu-14.04.vbox.xz
C:\vms\ubuntu-14.04.vmdk.vmdk.xz
C:\vms\ubuntu-14.04.vmdk-flat.vmdk.xz
---
then you will continue unzip all these files, and get
---
C:\vms\ubuntu-14.04.vbox
C:\vms\ubuntu-14.04.vmdk.vmdk
C:\vms\ubuntu-14.04.vmdk-flat.vmdk
---
If you installed VirtualBox soft, then the last step is: double clik file "ubuntu-12.04.vbox" and run ubuntu 12.04 in VirtualBox.
In ubuntu 12.04 login Interface:
username: chy
password: <SPACE KEY>

After you login, you will see the directory ucore_lab in HOME directory.

TESTED ENVIRONMENT
==================
UBUNTU 14.04: GCC-4.8.2 CLANG-3.5
FEDORA 20: GCC-4.8.2

EXERCISE STEPS
==============
0 Get the newest os lab src codes/docs.(Insure you can connect to github in ubuntu running on VrtualBox)
0.1 If you try to get all codes
  $rm -rf ucore_lab
  $git clone git://github.com/chyyuu/ucore_lab.git
  $cd ucore_lab
0.2 If you gloned ucore_lab and only try to get the updated codes
  $cd ucore_lab
  $git pull
1 $cd labX  
2 read codes (specially the modified or added files)
3 add your code
4 compile your code
  $make
5 check your code
  $make qemu
OR
  $make grade

6 debug your code
  $make debug

7 handin your code
  $make handin

OPTION
==============
Now, ucore suuport LLVM/Clang-3.5 + 
in step4:
  $ USELLVM=1 make
then you will use clang to compile ucore

GRADE/RANK
==========
Superman: Finish all OS labs in one month by yourself
Master: Finish all OS labs in two month by yourself
Veteran: Finish all OS labs in three month by yourself
Apprentice: Finish all OS labs in one semester with other guy's help
 
RESOURCE REPOSITORY
===================
Basic OS labs (for students who learn OS course)
The newest lab codes and docs is in https://github.com/chyyuu/ucore_lab

Advanced OS labs (for OS geeks or hackers or guys with Superman/Master Rank)
The newest lab codes and docs is in https://github.com/chyyuu/ucore_plus

LEARNING DISSCUSS GROUPS
========================

os learning group based on QQ 
-------------------------------
QQ id: 181873534

general discuss
--------------------------------
If you have any questions about ucore basic os labs, 
you can subscribe to the Google Groups "os-course" group (http://groups.google.com/group/oscourse?hl=en.)
To post to this group, send email to oscourse@googlegroups.com.
To unsubscribe from this group, send email to oscourse+unsubscribe@googlegroups.com.
For more options, visit this group at http://groups.google.com/group/oscourse?hl=en.

DEVELOPMENT DISCUSS GROUPS
==========================
If you have any questions about ucore advanced os labs, 
If you want to be a developer of ucore or pay attention to the development of ucore, 
you can subscribe to the Google Groups "ucore_dev" group (http://groups.google.com/group/ucore_dev?hl=en.)
To post to this group, send email to ucore_dev@googlegroups.com.
To unsubscribe from this group, send email to ucore_dev+unsubscribe@googlegroups.com.
For more options, visit this group at http://groups.google.com/group/ucore_dev?hl=en.

UCORERS (Contributors)
======================
Junjie Mao, Yuheng Chen, Cong Liu, Yang Yang, Zhun Qu, Shengwei Ren, Wenlei Zhu, Cao Zhang, Tong Sen, Xu Chen, 
Cang Nan, Yujian Fang, Wentao Han, Kaichen Zhang, Xiaolin Guo, Tianfan Xue, Gang Hu, Cao Liu, Yu Su,Xinhao Yuan, ...
