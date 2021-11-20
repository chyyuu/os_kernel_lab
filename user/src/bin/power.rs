#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

// 正确输出：
// 3^10000=5079(MOD 10007)
// 3^20000=8202(MOD 10007)
// 3^30000=8824(MOD 10007)
// 3^40000=5750(MOD 10007)
// 3^50000=3824(MOD 10007)
// 3^60000=8516(MOD 10007)
// 3^70000=2510(MOD 10007)
// 3^80000=9379(MOD 10007)
// 3^90000=2621(MOD 10007)
// 3^100000=2749(MOD 10007)
// Test power OK!

const SIZE: usize = 10;
const P: u32 = 3;
const STEP: usize = 100000;
const MOD: u32 = 10007;

#[no_mangle]
fn main() -> i32 {
    let mut pow = [0u32; SIZE];
    let mut index: usize = 0;
    pow[index] = 1;
    for i in 1..=STEP {
        let last = pow[index];
        index = (index + 1) % SIZE;
        pow[index] = last * P % MOD;
        if i % 10000 == 0 {
            println!("{}^{}={}(MOD {})", P, i, pow[index], MOD);
        }
    }
    println!("Test power OK!");
    0
}
