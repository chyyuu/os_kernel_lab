INTRODUCTION
============
ucore os labs was used as OS Experiments in OS Course Of Dept. of Computer Science & Technology, Tsinghua University.

NEWS
====
- 2019.01.19: [rcore os labs(pre-alpha version)](https://github.com/oscourse-tsinghua/rcore_plus/tree/lab8-rv32) on RISC-V(32bit) were released. Thanks Runji Wang, Wei Zhang, Zhenyang Dai, Jiajie Chen, Yuekai Jia, Cheng Lu...'s great work!
- 2019.01.19: [rcore os labs(pre-pre-alpha version)](https://github.com/oscourse-tsinghua/rcore_plus/tree/lab8-aarch64) on Raspberry Pi(AARCH 64bit) were released. Thanks Yuekai Jia, Runji Wang, Jiajie Chen...'s great work!
- 2018.04.03：ucore os labs were ported on RISC-V(64bit) CPU（privileged arch spec 1.10). You can access [repo's riscv64-priv-1.10 branch](https://github.com/chyyuu/ucore_os_lab/tree/riscv64-priv-1.10). Thanks Zhengxing Shi's great work!
- 2018.03.18: Weixiao Huang provided https://github.com/weixiao-huang/silver-spoon to support os labs in docker environment on windows/macos/linux. [details](https://github.com/weixiao-huang/silver-spoon/tree/master/docs)
- 2018.02.03：ucore os labs were ported on RISC-V(32bit) CPU（privileged arch spec 1.10). You can access [repo's riscv32-priv-1.10 branch](https://github.com/chyyuu/ucore_os_lab/tree/riscv32-priv-1.10). Thanks  Wei Zhang's great work!

MAINTAINERS
===========

OS course for Dept. CS. in Tsinghua Univ., and MOOC OS course
-----------------------------------
- Chen, Yu: yuchen@tsinghua.edu.cn http://soft.cs.tsinghua.edu.cn/~chen
- Xiang, Yong: xyong@tsinghua.edu.cn
- Mao, Junjie: eternal.n08@gmail.com
- Zhang, Wei: zhangwei15@mails.tsinghua.edu.cn
- Wang, Runji: wangrunji0408@163.com 
- Jia, Yuekai: jiayk15@mails.tsinghua.edu.cn

CONTENTS
========

labs info
----------------
```
lab0: preparing
lab1: boot/protect mode/stack/interrupt
lab2: physical memory management
lab3: virtual memory management
lab4: kernel thread management
lab5: user process management
lab6: scheduling
lab7: mutex/sync
lab8: filesystem
```

TESTED ENVIRONMENT
==================
```
UBUNTU 16.04 x86-64: GCC-7.3 
UBUNTU 14.04+: GCC-4.8.2+ CLANG-3.5+
FEDORA 20+: GCC-4.8.2+
```

EXERCISE STEPS
==============
```
0 Get the newest os lab src code/docs.(Insure you can connect to github in ubuntu running on VrtualBox)
0.1 If you try to get all code
  $rm -rf ucore_lab
  $git clone git://github.com/chyyuu/ucore_os_lab.git
  $cd ucore_lab
0.2 If you cloned ucore_lab and only try to get the updated code
  $cd ucore_os_lab
  $git pull
1 $cd labX  
2 read code (specially the modified or added files)
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
```

OPTION
==============
Now, ucore suuport LLVM/Clang-3.5 + 
in step4:
  $ USELLVM=1 make
then you will use clang to compile ucore

GRADE/RANK
==========
```
Superman: Finish all OS labs in one month by yourself
Master: Finish all OS labs in two month by yourself
Veteran: Finish all OS labs in three month by yourself
Apprentice: Finish all OS labs in one semester with other guy's help
```

RESOURCE REPOSITORY
===================
```
Basic OS labs (for students who learn OS course)
The newest lab codes and docs is in https://github.com/chyyuu/ucore_os_lab

Advanced OS labs (for OS geeks or hackers or guys with Superman/Master Rank)
The newest lab codes and docs is in https://github.com/chyyuu/ucore_plus
```


UCORERS (Contributors)
======================

Junjie Mao, Yuheng Chen, Cong Liu, Yang Yang, Zhun Qu, Shengwei Ren, Wenlei Zhu, Cao Zhang, Tong Sen, Xu Chen, 
Cang Nan, Yujian Fang, Wentao Han, Kaichen Zhang, Xiaolin Guo, Tianfan Xue, Gang Hu, Cao Liu, Yu Su,Xinhao Yuan, Wei Zhang, Kaixiang Lei...

Join us, OS research group in Tsinghua Univ.
============================================
If you are interested in OS Research/Development, we welcome you to joining our OS research group:
- OS performance improvement for multicore architecture
- fuzzing/symbolic execution technologies on OS for finding kernel bugs
- improving performance and reliability on OS subsystem, such as device driver
- design OS specification and build correct OS
- OS & CPU(such as RISC-V）codesign
- other topics about OS

Just like [other great OS researchs ](https://github.com/chyyuu/aos_course/blob/master/readinglist.md)

Send me email!

OTHER INFO
==========
ucore is a teaching OS which is derived from xv6&jos in MIT, OS161 in Harvard and Linux.

ucore was developed and used in Department of Computer Science & Technology, Institute for Interdisciplinary Information Sciences, Tsinghua University.

The codes in the files that constitute xv6&jos are Copyright (2006-Current) Frans Kaashoek, Robert Morris, and Russ Cox and uses MIT License.

The codes in the files that constitute OS/161 are written by David A. Holland.

The codes in the files that constitute ucore are Copyright (2010-Current) Yu Chen, Naizheng Wang, Yong Xiang and uses GPL License.

The documents in the files that constitute ucore are Copyright (2010-Current) Yu Chen, Yong Xiang and uses Creative Commons Attribution/Share-Alike (CC-BY-SA) License. 

