## 代码规范

### 代码风格
- 以 cargo 输出没有 Warning 为准
- 可以通过 `cargo fmt` 来自动规范代码

### 注释规范
- 用 `//!` 注释外层内容，例如在文件开始注释整个模块
- 用 `///` 为函数添加 doc 注释，其内部使用 markdown 语法
- 可以使用 markdown 格式的链接，链接内容使用 rust 可以直接链上，例如
  ```rust
  /// 样例注释
  /// [`link`]: crate::xxx::xxx
  fn some_func() {}
  ```

- 对于地址 literal，使用小写，使用 `_` 每隔四位进行标记，例如 `0x8000_0000` `0xffff_ffff_c000_0000`

### 参考
- https://doc.rust-lang.org/1.26.2/book/first-edition/comments.html
- https://doc.rust-lang.org/1.26.2/book/second-edition/ch14-02-publishing-to-crates-io.html