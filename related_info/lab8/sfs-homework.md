# 基于简单文件系统（Simple File System）模拟环境，理解文件系统的基本实现

## 面向文件系统的用户操作
- mkdir() - 创建一个新目录
- creat() - 创建一个空文件
- open(), write(), close() - 对文件写一个数据buffer,注意常规文件的最大size是一个data block，所以第二次写（写文件的语义是在上次写的位置后再写一个data block）会报错（文件大小满了）。或者如果data block也满了，也会报错。
- link()   - 对文件创建一个硬链接（hard link）
- unlink() - 对文件取消一个硬链接 (如果文件的链接数为0，则删除文件


## disk filesystem的内部组织和关键数据结构

### disk filesystem的内部组织
- superblock   : 可用inode数量，可用data block数量
- inode bitmap ： inode的分配图（基于bitmap）
- inodes       ： inode的存储区域
- data bitmap  ： data block的分配图（基于bitmap）
- data         ： data block的存储区域

> bitmap: 0表示inode/data block是free， 1表示inode/data block是allocated

### 关键数据结构 

#### inode数据结构
 - inode : 包含3个fields, 用python list 表示
   - file type: f -> 常规文件：regular file, d -> 目录文件：directory
   - data block addr of file content: -1 -> file is empty 
   - reference count: file/directory的引用计数
  
> 比如 刚创建的一个空文件inode： `[f a:-1 r:1]`， 一个有1个硬链接的文件inode `[f a:10 r:2]`


#### 数据块内容结构
 - 一般文件的内容的表示：只是包含单个字符的list，即占一个data block，比如`['a']`, `['b']` .....
 - 目录内容的表示： 多个两元组`（name, inode_number）`形成的list，比如， 根目录 `[(.,0) (..,0)]`， 或者包含了一个`'f'`文件的根目录[(.,0) (..,0) (f,1)] 。 

> 注意：一个目录的目录项的个数是有限的。 `block.maxUsed = 32`

> 注意：data block的个数是有限的,为 fs.numData

> 注意：inode的个数是有限的,为 fs.numInodes
 
 
### 完整文件系统的例子 
```
fs.ibitmap: inode bitmap 11110000
fs.inodes:       [d a:0 r:5] [f a:1 r:1] [f a:-1 r:1] [d a:2 r:2] [] ...
fs.dbitmap: data bitmap  11100000
fs.data:         [(.,0) (..,0) (y,1) (z,2) (x,3)] [u] [(.,3) (..,0)] [] ...
```

> 此文件系统已使用8个inode空间, 8个data blocks. 其中，根目录包含5个目录项，`”.“，”..“，”y“，”z“，”x“`, ”y“是常规文件,并有文件内容，包含一个data block，文件内容为”u“。”z“是一个空的常规文件。”x“是一个目录文件，是空目录。

### 辅助数据结构 
也可理解为内存中的文件系统相关数据结构

- fs.files :当前文件系统中的常规文件list
- fs.dirs : 当前文件系统中的目录文件list
- fs.nameToInum ： 文件名:inode_num的对应关系

## 文件系统执行流程

### 文件系统初始化

第一步：格式化sfs文件系统
```
        self.numInodes = numInodes
        self.numData   = numData
        
        self.ibitmap = bitmap(self.numInodes)
        self.inodes  = []
        for i in range(self.numInodes):
            self.inodes.append(inode())

        self.dbitmap = bitmap(self.numData)
        self.data    = []
        for i in range(self.numData):
            self.data.append(block('free'))
```            

第二步：创建sfs文件系统的根目录

```
        self.ibitmap.markAllocated(self.ROOT)
        self.inodes[self.ROOT].setAll('d', 0, 2)
        self.dbitmap.markAllocated(self.ROOT)
        self.data[0].setType('d')
        self.data[0].addDirEntry('.',  self.ROOT)
        self.data[0].addDirEntry('..', self.ROOT)
```

第三步：在内存中保存相关数据
```
        self.files      = []
        self.dirs       = ['/']
        self.nameToInum = {'/':self.ROOT}         
```


第四步：随机生成文件相关的操作，改变sfs文件系统的内容        
 - doAppend: 
   - `fd=open(filename, O_WRONLY|O_APPEND); write(fd, buf, BLOCKSIZE); close(fd);`
 - doDelete:
   - `unlink()filename)`
 - doLink
   - `link()targetfile, sourcefile)`
 - doCreate
   - `create(filename)`  OR  `mkdir(dirname)`
   

## 问题1： 
根据[sfs文件系统的状态变化信息](./sfs_states.txt)，给出具体的文件相关操作内容.

## 问题2：
在[sfs-homework.py 参考代码的基础上](https://github.com/chyyuu/ucore_lab/blob/master/related_info/lab8/sfs-homework.py)，实现 `writeFile, createFile, createLink, deleteFile`，使得你的实现能够达到与问题1的正确结果一致

## 问题3：
实现`soft link`机制，并设计测试用例说明你实现的正确性。   
