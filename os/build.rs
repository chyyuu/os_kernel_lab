use std::io::{Result, Write};
use std::fs::{File, read_dir};

fn main() {
    println!("cargo:rerun-if-changed=../user");
    insert_app_data().unwrap();
}

static TARGET_PATH: &'static str = "../user/target/riscv64gc-unknown-none-elf/release/";

fn insert_app_data() -> Result<()> {
    let mut f = File::create("src/link_app.S").unwrap();
    let apps: Vec<_> = read_dir("../user/src/bin")
        .unwrap()
        .into_iter()
        .map(|dir_entry| {
            let mut name_with_ext = dir_entry.unwrap().file_name().into_string().unwrap();
            name_with_ext.drain(name_with_ext.find('.').unwrap()..name_with_ext.len());
            name_with_ext
        })
        .collect();

    writeln!(f, r#"
    .align 4
    .section .data
    .global _num_app
_num_app:
    .quad {}
    "#, apps.len())?;

    for i in 0..apps.len() {
        writeln!(f, r#"
    .quad app_{}_start
        "#, i)?;
    }
    writeln!(f, r#"
    .quad app_{}_end
    "#, apps.len() - 1)?;

    for (idx, app_with_extension) in apps.iter().enumerate() {
        writeln!(f, r#"
    .section .data
    .global app_{0}_start
    .global app_{0}_end
app_{0}_start:
    .incbin "{2}{1}.bin"
app_{0}_end:
        "#, idx, app_with_extension, TARGET_PATH)?;
    }
    Ok(())
}