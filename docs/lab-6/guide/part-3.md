## 解析 ELF 文件并创建线程

在之前实现内核线程时，我们只需要为线程指定一个起始位置就够了，因为所有的代码都在操作系统之中。但是现在，我们需要从 ELF 文件中加载用户程序的代码，并且映射到内存中。

当然，我们不需要自己实现 ELF 文件解析器，因为有 `xmas-elf` 这个 crate 替我们实现了 ELF 的解析。

### `xmas-elf` 解析器

tips：如果 IDE 无法对其中的类型进行推断，可以在 rustdoc 中找到该 crate 进行查阅。

#### 读取文件内容

`xmas-elf` 需要将 ELF 文件首先读取到内存中。在上一章文件系统的基础上，我们很容易为 `INode` 添加一个将整个文件作为 `[u8]` 读取出来的方法：

{% label %}os/src/fs/inode_ext.rs{% endlabel %}
```rust
fn readall(&self) -> Result<Vec<u8>> {
    // 从文件头读取长度
    let size = self.metadata()?.size;
    // 构建 Vec 并读取
    let mut buffer = Vec::with_capacity(size);
    unsafe { buffer.set_len(size) };
    self.read_at(0, buffer.as_mut_slice())?;
    Ok(buffer)
}
```

### 解析各个字段

对于 ELF 中的不同字段，其存放的地址通常是不连续的，同时其权限也会有所不同。我们利用 `xmas-elf` 库中的接口，便可以从读出的 ELF 文件中对应建立 `MemorySet`。

注意到，用户程序也会首先映射所有内核态的空间，否则将无法进行中断处理。

{% label %}os/src/memory/mapping/memory_set.rs{% endlabel %}
```rust
/// 通过 elf 文件创建内存映射（不包括栈）
pub fn from_elf(file: &ElfFile, is_user: bool) -> MemoryResult<MemorySet> {
    // 建立带有内核映射的 MemorySet
    let mut memory_set = MemorySet::new_kernel()?;

    // 遍历 elf 文件的所有部分
    for program_header in file.program_iter() {
        if program_header.get_type() != Ok(Type::Load) {
            continue;
        }
        // 从每个字段读取『起始地址』『大小』和『数据』
        let start = VirtualAddress(program_header.virtual_addr() as usize);
        let size = program_header.mem_size() as usize;
        let data: &[u8] =
            if let SegmentData::Undefined(data) = program_header.get_data(file).unwrap() {
                data
            } else {
                return Err("unsupported elf format");
            };

        // 将每一部分作为 Segment 进行映射
        let segment = Segment {
            map_type: MapType::Framed,
            range: Range::from(start..(start + size)),
            flags: Flags::user(is_user)
                | Flags::readable(program_header.flags().is_read())
                | Flags::writable(program_header.flags().is_write())
                | Flags::executable(program_header.flags().is_execute()),
        };

        // 建立映射并复制数据
        memory_set.add_segment(segment, Some(data))?;
    }

    Ok(memory_set)
}
```

### 加载数据到内存中

思考：我们在为用户程序建立映射时，虚拟地址是 ELF 文件中写明的，那物理地址是程序在磁盘中存储的地址吗？这样做有什么问题吗？

{% reveal %}
> 我们在模拟器上运行可能不觉得，但是如果直接映射磁盘空间，使用时会带来巨大的延迟，所以需要在程序准备运行时，将其磁盘中的数据复制到内存中。如果程序较大，操作系统可能只会复制少量数据，而更多的则在需要时再加载。当然，我们实现的简单操作系统就一次性全都加载到内存中了。
>
> 而且，就算是想要直接映射磁盘空间，也不一定可行。这是因为虚实地址转换时，页内偏移是不变的。这是就无法保证在 ELF 中指定的地址和其在磁盘中的地址满足这样的关系。
{% endreveal %}

我们将修改 `Mapping::map` 函数，为其增加一个参数表示用于初始化的数据。在实现时，有一些重要的细节需要考虑。

- 因为用户程序的内存分配是动态的，其分配到的物理页面不一定连续，所以必须单独考虑每一个页面
- 每一个字段的长度不一定是页大小的倍数，所以需要考虑不足一个页时的复制情况
- 程序有一个 bss 段，它在 ELF 中不保存数据，而其在加载到内存是需要零初始化
- 对于一个页面，有其**物理地址**、**虚拟地址**和**待加载数据的地址**。此时，是不是直接从**待加载数据的地址**拷贝到页面的**虚拟地址**，如同 `memcpy` 一样就可以呢？

{% reveal %}
> 在目前的框架中，只有当线程将要运行时，才会加载其页表。因此，除非我们额外的在每映射一个页面之后，就更新一次页表并且刷新 TLB，否则此时的**虚拟地址**是无法访问的。
>
> 但是，我们通过分配器得到了页面的**物理地址**，而这个物理地址实际上已经在内核的线性映射当中了。所以，这里实际上用的是**物理地址**来写入数据。
{% endreveal %}

具体的实现，可以查看 `os/src/memory/mapping/mapping.rs` 中的 `Mapping::map` 函数。

### 运行 Hello World？

现在，我们就可以在操作系统中运行磁盘镜像中的用户程序了，代码示例如下：

```rust
// 从文件系统中找到程序
let app = fs::ROOT_INODE.find("hello_world").unwrap();
// 读取数据
let data = app.readall().unwrap();
// 解析 ELF 文件
let elf = ElfFile::new(data.as_slice()).unwrap();
// 利用 ELF 文件创建线程，映射空间并加载数据
let process = Process::from_elf(&elf, true).unwrap();
// 再从 ELF 中读出程序入口地址
let thread = Thread::new(process, elf.header.pt2.entry_point() as usize, None).unwrap();
// 添加线程
PROCESSOR.get().add_thread(thread);
```

可惜的是，我们不能像内核线程一样在用户程序中直接使用 `print`。前者是基于 OpenSBI 的机器态调用，而为了让用户程序能够打印字符，我们还需要在操作系统中实现系统调用。
