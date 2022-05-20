#![no_std]
#![no_main]

extern crate alloc;

#[macro_use]
extern crate user_lib;
use user_lib::console::getchar;

const LF: u8 = 0x0au8;
const CR: u8 = 0x0du8;

#[no_mangle]
pub fn main() -> i32 {
    println!("getchar starting....  Press 'ENTER' will quit.");

    loop {
        let c = getchar();

        println!("Got Char  {}", c);
        if c == LF || c == CR {
            println!("exit(0)");
            return 0;
        }
    }
}
