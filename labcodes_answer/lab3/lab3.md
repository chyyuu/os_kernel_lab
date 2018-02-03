# 实验三：虚拟内存管理

## 练习一

### 实现方法

* 通过`get_pte`函数得到逻辑地址对应的页表项
* 若页表项为0，则分配一个实际物理页并建立映射关系

### 页表项和页目录项对页替换算法的用处

* 页表项中的Present Bit可用于指示该页是否在物理内存中，是实现缺页中断的基础
* R/W和U/S Bit可以指示该页的访问权限，让页替换算法可以区分不能调出的内核代码和可以调出的应用程序代码、数据页
* A和D bit指示该页是否被访问过以及是否被写过，可以帮助实现extended clock页替换算法等更复杂有效的页替换算法
* 9-11个bit可供系统利用来记录额外信息

### 缺页服务例程出现页访问异常

CPU会引发一个page fault中断，把引起页异常的线性地址保存在CR2中，进而形成嵌套中断

## 练习二

### _fifo_map_swappable

* 将新来的页插入到表头之前

### _fifo_swap_out_victim

* 获得表中第一个页即最早访问的页
* 从链表中删除该页
* 返回该Page的地址(通过修改*ptr_page实现)

### 实现extended clock页替换算法

swap_manager框架足以支持在ucore中实现此算法，在swap_out_victim函数可通过以下代码访问Accessed Bit和Dirty Bit

```
_clock_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick) {
......
    *ptr_page = le2page(le, pra_page_link);
    pte_t* ptep = get_pte(mm->pgdir, ptr_page->pra_vaddr, 0);
    bool accessed = *pte & PTE_A;
    bool dirty = *pte & PTE_D;
......
}
```

* 需要被换出页的特征为`accessed == 0 && dirty == 0`
* 判断方法见上面代码
* 可以利用始终中断定时进行换页操作

## 总结

### 实现与参考答案的区别

实现逻辑基本一致

### 知识点

* 页替换算法：用将内存页内容临时保存到swap的方式，扩大可用的内存而不显著影响性能