#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::{framebuffer, framebuffer_flush};

pub const VIRTGPU_XRES: usize = 1280;
pub const VIRTGPU_YRES: usize = 800;

#[no_mangle]
pub fn main() -> i32 {
    let fb_ptr =framebuffer() as *mut u8;
    println!("Hello world from user mode program! 0x{:X} , len {}", fb_ptr as usize, VIRTGPU_XRES*VIRTGPU_YRES*4);
    let fb= unsafe {core::slice::from_raw_parts_mut(fb_ptr as *mut u8, VIRTGPU_XRES*VIRTGPU_YRES*4 as usize)};
    for y in 0..800 {
        for x in 0..1280 {
            let idx = (y * 1280 + x) * 4;
            fb[idx] = x as u8;
            fb[idx + 1] = y as u8;
            fb[idx + 2] = (x + y) as u8;
        }
    }
    framebuffer_flush();
    0
}
