## 文件系统

之前我们在加载 QEMU 的时候引入了一个镜像文件，这个文件的打包是由 [rcore-fs-fuse 工具](https://github.com/rcore-os/rcore-fs/tree/master/rcore-fs-fuse) 来完成的，它会根据不同的格式把目录的文件封装成一个文件系统的镜像，然后我们把这个镜像像设备一样挂载在 QEMU 上就被抽象成了设备，接下来我们需要让操作系统理解设备里面文件系统。

### Simple File System

因为文件系统本身比较庞大，我们这里还是用了 rCore 中的文件系统模块 [rcore-fs](https://github.com/rcore-os/rcore-fs)，其中实现了很多格式的文件系统，我们这里选择最简单的 Simple File System（这也是为什么 QEMU 中的设备 id 为 `sfs`），关于文件系统的细节，这里将不展开描述，可以参考[前人的分析](../files/rcore-fs-analysis.pdf)。

不过，为了使用这个模块，一个自然的想法是存取根目录的 `INode`（一个 `INode` 是对一个文件的位置抽象，目录也是文件的一种），后面对于文件系统的操作都可以通过根目录来实现。

### 实现

这里我们用到了我们的老朋友 `lazy_static` 宏，将会在我们第一次使用 `ROOT_INODE` 时进行初始化，而初始化的方式是找到全部设备驱动中的第一个存储设备作为根目录。

{% label %}os/src/fs/mod.rs{% endlabel %}
```rust
lazy_static! {
    /// 根文件系统的根目录的 INode
    pub static ref ROOT_INODE: Arc<dyn INode> = {
        // 选择第一个块设备
        for driver in DRIVERS.read().iter() {
            if driver.device_type() == DeviceType::Block {
                let device = BlockDevice(driver.clone());
                // 动态分配一段内存空间作为设备 Cache
                let device_with_cache = Arc::new(BlockCache::new(device, BLOCK_CACHE_CAPACITY));
                return SimpleFileSystem::open(device_with_cache)
                    .expect("failed to open SFS")
                    .root_inode();
            }
        }
        panic!("failed to load fs")
    };
}
```

同时，还可以注意到我们也加入了一个 `BlockCache`，该模块也是 rcore-fs 提供的，提供了一个存储设备在内存 Cache 的抽象，通过调用 `BlockCache::new(device, BLOCK_CACHE_CAPACITY)` 就可以把 `device` 自动变为一个有 Cache 的设备。最后我们用 `SimpleFileSystem::open` 打开并返回根节点即可。

### 测试

终于到了激动人心的测试环节了！我们首先在触发一下 `ROOT_INODE` 的初始化，然后尝试输出一下根目录的内容：

{% label %}os/src/fs/mod.rs{% endlabel %}
```rust
/// 打印某个目录的全部文件
pub fn ls(path: &str) {
    let mut id = 0;
    let dir = ROOT_INODE.lookup(path).unwrap();
    print!("files in {}: \n  ", path);
    while let Ok(name) = dir.get_entry(id) {
        id += 1;
        print!("{} ", name);
    }
    print!("\n");
}

/// 触发 [`static@ROOT_INODE`] 的初始化并打印根目录内容
pub fn init() {
    ls("/");
    println!("mod fs initialized");
}
```

最后在主函数中测试初始化，然后测试在另一个内核线程中创建个文件夹，而之所以在另一个线程中做是为了验证我们之前写驱动涉及到的页表的那些操作：

{% label %}os/src/fs/mod.rs{% endlabel %}
```rust
/// Rust 的入口函数
///
/// 在 `_start` 为我们进行了一系列准备之后，这是第一个被调用的 Rust 函数
#[no_mangle]
pub extern "C" fn rust_main(_hart_id: usize, dtb_pa: PhysicalAddress) -> ! {
    memory::init();
    interrupt::init();
    drivers::init(dtb_pa);
    fs::init();

    let process = Process::new_kernel().unwrap();

    PROCESSOR
        .get()
        .add_thread(Thread::new(process.clone(), simple as usize, Some(&[0])).unwrap());

    // 把多余的 process 引用丢弃掉
    drop(process);

    PROCESSOR.get().run()
}

/// 测试任何内核线程都可以操作文件系统和驱动
fn simple(id: usize) {
    println!("hello from thread id {}", id);
    // 新建一个目录
    fs::ROOT_INODE
        .create("tmp", rcore_fs::vfs::FileType::Dir, 0o666)
        .expect("failed to mkdir /tmp");
    // 输出根文件目录内容
    fs::ls("/");

    loop {}
}
```

`make run` 一下，你会得到类似的输出：

{% label %}运行输出{% endlabel %}
```
mod memory initialized
mod interrupt initialized
mod driver initialized
files in /: 
  . .. temp rust 
mod fs initialized
hello from thread id 0
files in /: 
  . .. temp rust tmp 
100 tick
200 tick
...
```

成功了！我们可以看到系统正确的读出了文件，而且也正确地创建了文件，这为后面用户进程数据的放置提供了很好的保障。