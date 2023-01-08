#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;
use oorandom;

#[no_mangle]
pub fn main() -> i32 {
    println!("random num  program!");
    let seed = 4;
    let mut rng = oorandom::Rand32::new(seed);
    println!("OORandom: Random number 32bit: {}", rng.rand_i32());
    println!("OORandom: Random number range: {}", rng.rand_range(1..100));
    0
}