use crate::memory::{PhysicalAddress, VirtualAddress};

pub mod block;
pub mod bus;
pub mod device_tree;
pub mod driver;

pub fn init(dtb_paddr: PhysicalAddress) {
    let dtb_vaddr = VirtualAddress::from(dtb_paddr);
    device_tree::init(dtb_vaddr);
    println!("mod driver initialized")
}
