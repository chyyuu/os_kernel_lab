## 设备树

### 从哪里读取设备信息

既然我们要实现把数据放在某个存储设备上并让操作系统来读取，首先操作系统就要有一个读取全部已接入设备信息的能力，而设备信息放在哪里又是谁帮我们来做的呢？这个问题其实在[物理内存探测](../../lab-2/guide/part-2.md)中就提到过，在 RISC-V 中，这个一般是由 Bootloader，即 OpenSBI 完成的。它来完成对于包括物理内存在内的各外设的扫描，将扫描结果以**设备树二进制对象（DTB，Device Tree Blob）**的格式保存在物理内存中的某个地方。而这个放置的物理地址将放在 `a1` 寄存器中，而将会把 HART ID （HART，Hardware Thread，硬件线程，就是执行 CPU 核心的 ID）放在 `a0` 寄存器上。

在我们之前的函数中并没有使用过这两个参数，如果要使用，我们不需要修改任何入口汇编的代码，只需要给 `rust_main` 函数增加两个参数即可：

{% label %}os/src/main.rs{% endlabel %}
```rust
/// Rust 的入口函数
///
/// 在 `_start` 为我们进行了一系列准备之后，这是第一个被调用的 Rust 函数
#[no_mangle]
pub extern "C" fn rust_main(_hart_id: usize, dtb_pa: PhysicalAddress) -> ! {
    memory::init();
    interrupt::init();
    drivers::init(dtb_pa);
    ...
}
```

打印输出一下，`dtb_pa` 变量约在 0x82200000 附近，而内核结束的地址约为 0x80b17000，也就是在我们内核的后面放着，当我们内核代码超过 32MB 的时候就会出现问题，再更好的实现中，其实 OpenSBI 启动的应该是第二级小巧的 Bootloader，而我们现在全部内核内容都在内存中，我们暂时不理会这个问题。

### 设备树

上面提到 OpenSBI 会把设备信息以设备树的格式放在某个地址上，哪设备树格式究竟是怎样的呢？在各种操作系统中，我们打开设备管理器（Windows）和系统报告（macOS）等内置的系统软件就可以看到我们使用的电脑的设备树，一个典型的设备树如下图所示：

<div align=center> <img src="../pics/device-tree.png" style="zoom:40%;"/> </div>

每个设备在物理上连接到了父设备上最后再通过总线等连接起来构成一整个设备树，在每个节点上都描述了对应设备的信息，如支持的协议是什么类型等等。而操作系统就是通过这些节点上的信息来实现对设备的识别的。

> **[info] 设备节点属性**
>
> 具体而言，一个设备节点上会有几个标准属性，这里简要介绍我们需要用到的几个：
>
>   - compatible：该属性指的是该设备的编程模型，一般格式为 "manufacturer,model"，分别指一个出厂标签和具体模型。如 "virtio,mmio" 指的是这个设备通过 virtio 协议、MMIO（内存映射 I/O）方式来驱动
>   - model：指的是设备生产商给设备的型号
>   - reg：当一些很长的信息或者数据无法用其他标准属性来定义时，可以用 reg 段来自定义存储一些信息
>
> 设备树是一个比较复杂的标准，更多细节可以参考 [Device Tree Reference](https://elinux.org/Device_Tree_Reference)。

### 解析设备树

对于上面的属性，我们不需要自己来实现这件事情，可以直接调用 rCore 中 device_tree 库，然后遍历树上节点即可：

{% label %}os/src/drivers/device_tree.rs{% endlabel %}
```rust
/// 递归遍历设备树
fn walk(node: &Node) {
    // 检查设备的协议支持并初始化
    if let Ok(compatible) = node.prop_str("compatible") {
        if compatible == "virtio,mmio" {
            virtio_probe(node);
        }
    }
    // 遍历子树
    for child in node.children.iter() {
        walk(child);
    }
}

/// 整个设备树的 Headers（用于验证和读取）
struct DtbHeader {
    magic: u32,
    size: u32,
}

/// 遍历设备树并初始化设备
pub fn init(dtb_va: VirtualAddress) {
    let header = unsafe { &*(dtb_va.0 as *const DtbHeader) };
    // from_be 是大小端序的转换（from big endian）
    let magic = u32::from_be(header.magic);
    if magic == DEVICE_TREE_MAGIC {
        let size = u32::from_be(header.size);
        // 拷贝数据，加载并遍历
        let data = unsafe { slice::from_raw_parts(dtb_va.0 as *const u8, size as usize) };
        if let Ok(dt) = DeviceTree::load(data) {
            walk(&dt.root);
        }
    }
}
```

注意到，在开始的时候，有一步来验证 Magic Number，这一步也是一个标准，为了验证这段内存到底是不是设备树。在遍历过程中，一旦发现了一个支持 "virtio,mmio" 的设备（其实就是 QEMU 模拟的存储设备），就进入下一步的逻辑加载驱动。