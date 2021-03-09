# rcore tutorial v4
--------------------------------------------------------------
## mini hello app with mini runtime

## pre-requirement in ubuntu 20.04
- rustc nightly with riscv64gc-unknown-none-elf target support
- qemu-riscv64

```
$ cd os
# run app
$ make run
...
Hello, world!

# show app's assembly codes
$ find . -name "*.s"
./target/riscv64gc-unknown-none-elf/release/deps/user_lib-d829414de784f242.s
./target/riscv64gc-unknown-none-elf/release/deps/hello_world-53267b4e3ef76c18.s
```


