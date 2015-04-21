# 介绍(2015)

uCore OS Labs是用于清华大学计算机系本科操作系统课程的教学试验内容。


# 实验总体流程
1. 在[学堂在线](https://www.xuetangx.com/courses/TsinghuaX/30240243X/2015_T1/about)查看OS相关原理和labX的视频；
2. 在[实验指导书 on gitbook](http://objectkuan.gitbooks.io/ucore-docs/)上阅读实验指导书，并参考其内容完成练习和实验报告；
3. 在实验环境中完成实验并提交实验到git server（清华学生需要在学校内部的git server上，其他同学可提交在其他git server上）；
4. 如实验中碰到问题，在[在线OS课程问题集](http://xuyongjiande.gitbooks.io/os-qa/)查找是否已经有解答；
5. 每天（一周七日）都有助教或老师在piazza在线答疑。如在[在线OS课程问题集](http://xuyongjiande.gitbooks.io/os-qa/)没找到解答，可到[piazza在线OS课程问答和交流区](https://piazza.com/tsinghua.edu.cn/spring2015/30240243x/home)提问。（QQ群 181873534主要用于本课程和OS相关事件发布，以及各种一般性交流）；
6. 可进一步在[学堂在线](https://www.xuetangx.com/courses/TsinghuaX/30240243X/2015_T1/about)或[在线的操作系统课程练习题](https://www.gitbook.io/book/xuyongjiande/os_exercises)完成实验相关的练习题；

## 四种学习目标和对应手段
1. 掌握OS基本概念：看在线课程，能理解OS原理与概念；看在线实验指导书并分析源码，能理解labcodes_answer的labs运行结果
2. 掌握OS设计实现：在1的基础上，能够通过编程完成labcodes的8个lab实验中的基本练习和实验报告
3. 掌握OS核心功能：在2的基础上，能够通过编程完成labcodes的8个lab实验中的challenge练习
4. 掌握OS科学研究：在3的基础上，能够通过阅读论文、设计、编程、实验评价等过程来完成课程设计（大实验）

【**注意**】
  - **筑基内功**--请提前学习计算机原理、C语言、数据结构课程
  - **工欲善其事，必先利其器**--请掌握七种武器  [实验常用工具列表](https://github.com/objectkuan/ucore_docs/blob/master/lab0/lab0_ref_ucore-tools.md)
  - **学至于行之而止矣**--请在实验中体会操作系统的精髓
  - **打通任督二脉**--lab1和lab2与x86硬件相关性较大，比较困难，有些同学由于畏难而止步与此，很可惜！仅仅熟读内功心法是不够的，通过实践lab1和lab2后，对计算机原理中的中断、段页表机制、特权级等的理解会更深入和贴近实际，这等同于打通了任督二脉，后面的实验将一片坦途。
  
 
# 实验内容
## 实验指导书
 - [实验指导书 on gitbook](http://objectkuan.gitbooks.io/ucore-docs/) 
 - [实验常用工具列表](https://github.com/objectkuan/ucore_docs/blob/master/lab0/lab0_ref_ucore-tools.md)

> 【提醒】对于实验中的开发: `git`, `gcc`,`gdb`,`qemu`,`make`,`diff & patch`, `bash shell`这些重要工具的基本用法是需要提前掌握的.

> [实验指导书 on gitbook](http://objectkuan.gitbooks.io/ucore-docs/)中会存在一些bug，欢迎在在[piazza在线OS课程问答和交流区](https://piazza.com/tsinghua.edu.cn/spring2015/30240243x/home)提出，会有奖分！

## 实验题目

1. lab0 ：熟悉实验环境
1. lab1 ：启动操作系统
1. lab2 ：物理内存管理
1. lab3 ：虚拟内存管理
1. lab4 ：内核线程
1. lab5 ：用户进程
1. lab6 ：处理器调度
1. lab7 ：同步互斥
1. lab8 ：文件系统


## 实验环境
ucore OS实验主要在Linux环境下开发，有如下五种方法。

### 一、[在线实验--基于"实验楼"在线平台](http://www.shiyanlou.com/courses/221)
特点：不用在本机配置环境或安装虚拟机，你需要的是可以可以上网的网络浏览器，实验都可在网上完成！感谢[实验楼](http://www.shiyanlou.com/)提供的支持！

### 二、Windows下基于MingW进行实验
特点：可在Windows环境下完成实验。不用安装Linux，只需在Windows上安装相关软件即可。

- [windows下的ucore实验环境安装包](http://pan.baidu.com/s/1qWPtHxy)：下载安装即可。感谢杨海宇同学提供！
- [windows下手动配置ucore实验环境说明文档](http://pan.baidu.com/s/1i3JxZZR)：看你的安装能力。感谢“下来障”同学提供！

[NOTICE] 没有足够的技术支持，希望有感兴趣的生成一个安装软件包和中文使用说明，方便大家使用！

### 三、Windows下基于VirtualBox or VMWare进行实验
特点：可在Windows环境下完成实验。不用安装Linux，安装VirtualBox等虚拟机软件即可，可以用已经配好环的虚拟硬盘。安装简单，但性能受一定影响。

#### 1. 安装VirtualBox or VMWare软件

VirtualBox虚拟机软件

  https://www.virtualbox.org/

[NOTICE] 也可以安装vmware虚拟机软件

#### 2.使用已经预先安装好相关实验环境所需软件的虚拟硬盘

并下载已经安装好ubuntu 14.04  x86-64的虚拟硬盘文件压缩包。
[VirtualBox的虚拟硬盘文件压缩包2015版](http://pan.baidu.com/s/11zjRK)

--------------

压缩包可以用[haozip for windows软件](http://www.haozip.com)解压。解压压缩包后，可得到如下内容（大约6GB多）。 
```
mooc-os-2015-2.vdi
```

如果此时你已经安装好了VirtualBox, 就可以在VirtualBox模拟的x86-64计算机中新建一个虚拟机(配置为ubuntu linux x86 64bit），并指定此虚拟机的虚拟硬盘为你刚才解压的vdi文件。创建完虚拟机后，就可以运行此虚拟幻镜，并可以开始学习
ucore OS实验了。
```
用户名是 moocos
口令是 <空格键>
```

> [NOTICE]  如果正确安装了virtualbox并配置好虚拟机，但无法运行虚拟机或无法加入虚拟硬盘， 可以尝试删除virtualbox的一些配置目录，比如：
```
C:\Users\VirtualBox VMs\
```

建议a: 设置虚拟硬盘的大小为8GB以上，虚拟内存在1B以上。
建议b: 如果你的机器安装的是32位的windows，则下载32位的ubuntu 14.04 32bit img镜像。


### 四、在MAC OS下进行实验

感谢 altkatz！

Using gcc49

#### 1.install [homebrew](http://brew.sh/)

#### 2.install binutils, gcc, gdb targeting i386-elf

* `brew tap altkatz/homebrew-gcc_cross_compilers` 
* `brew install i386-elf-gcc` # may take an hour
* `brew install i386-elf-gdb` 

#### 3. install qemu-system-i386

* `brew install qemu`

### 五、手动在物理PC中安装环境


-------------------------------------
特点：性能最好，但安装有一定难度，需要对Linux比较熟悉

（这里假定安装的要是ubuntu14.04 x86-64的系统）

1) 在物理PC上安装ubuntu 

下载ubuntu 14.04 64bit img镜像，需要把镜像刻录到可启动的光盘或闪盘中,把光盘或闪盘放入物理PC，并在物理PC上重启安装。

2) 在ubuntu系统中安装实验环境相关软件
在shell（比如gnome-terminal）下可执行如下命令来安装相关软件 (“$”是shell的提示符，不用输入)
```
  $ sudo apt-get update
  $ sudo apt-get upgrade
  $ sudo apt-get install build-essential git qemu-system-x86 vim-gnome gdb cgdb eclipse-cdt make diffutils exuberant-ctags tmux openssh-server cscope meld qgit gitg gcc-multilib gcc-multilib g++-multilib
```
[NOTICE] 最小需要的安装包： build-essential git qemu-system-x86 gdb make diffutils gcc-multilib

[NOTICE] 如要源码编译qemu,需要执行  `apt-get install zlib1g-dev libsdl1.2-dev libesd0-dev automake`

## 实验中的练习步骤
以VirtualBox为例，进入VirtualBox中运行的ubuntu，点击左侧的gnome-terminal软件图标，可启动gnome-terminal
软件。在此软件中，执行如下命令：

1) 目前环境中已经有ucore lab源码，可进一步取得最新ucore lab源码
```
  $cd  moocos/ucore_lab  #到ucore lab所在目录
  $git pull   #取得最新的ucore lab源代码
  $cd
```

2) 学习源码
```
  $cd labX  #X为 1--8
```

3) 阅读，修改源码，可以用eclipse-cdt, understand, gedit或vim软件
```
  $eclipse
OR
  $understand
```

4) 修改完毕后，编译实验代码
```
  $make
``` 

5) 如果编译无误，则可以运行测试一下
```
  $make qemu
```

6) 如果需要调试，
  
  a. 可基于cgdb的字符方式(以lab1_ans为例)
```
  $cd labcodes_answer/lab1_ans
  $make debug
```
可以看到弹出两个窗口，一个是qemu,一个是cgdb
可以看到在bootloader的bootmain函数处停了下来。
然后我们就可以进一步在cgdb中用gdb的命令进行调试了
```
 (gdb)file bin/kernel   #加载ucore kernel的符号信息
 (gdb)break kern_init   #在函数kern_init处（即 0x100000地址处）设置断点
 (gdb)continue          #继续执行
```
这时就可以看到在kern_init处停了下来，可进一步调试。

  b. 基于eclipse-CDT的debug view进行调试，如果安装了zylin debug插件，则完成初步配置后，
     也可很方便地进行调试。

7) 可以运行如下命令，看看自己的得分
```
  $make grade
```

## 在线交流
- [piazza，OS课程技术交流的主要在线QA平台](https://piazza.com/tsinghua.edu.cn/spring2015/30240243x/home)
- QQ群 181873534  主要用于事件通知，聊天等

## 开发维护人员 
- [陈渝](http://soft.cs.tsinghua.edu.cn/~chen)  yuchen AT tsinghua.edu.cn
- 茅俊杰 eternal.n08 AT gmail.com

## 课程汇总信息
 - [课程汇总](https://github.com/chyyuu/mooc_os)

## UCORERS (代码贡献者)

茅俊杰、陈宇恒、刘聪、杨扬、渠准、任胜伟、朱文雷、
曹正、沈彤、陈旭、蓝昶、方宇剑、韩文涛、张凯成、
S郭晓林、薛天凡、胡刚、刘超、粟裕、袁昕颢...
欢迎加入我们的OS兴趣小组，共同进步！

## 版权信息

ucore OS起源于MIT CSAIL PDOS课题组开发的xv6&jos、哈佛大学开发的
OS161教学操作系统、以及Linux-2.4内核。

ucore OS中包含的xv6&jos代码版权属于Frans Kaashoek, Robert Morris,
and Russ Cox，使用MIT License。ucore OS中包含的OS/161代码版权属于
David A. Holland。包含的ostep练习的版权属于Remzi H. Arpaci-Dusseau and Andrea C. Arpaci-Dusseau。其他内部开发的ucore OS和相关练习的代码版权属于
陈渝、王乃铮、向勇，并采用GPL License. ucore OS相关的文档版权属于
陈渝、向勇，并采用 
Creative Commons Attribution/Share-Alike (CC-BY-SA) License. 
