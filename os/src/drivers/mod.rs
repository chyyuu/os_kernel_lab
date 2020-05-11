use crate::memory::{PhysicalAddress, VirtualAddress};

pub mod device_tree;
pub mod driver;
pub mod virtio;

pub fn init(dtb_paddr: usize) {
    let dtb_vaddr = VirtualAddress::from(PhysicalAddress(dtb_paddr));
    device_tree::init(dtb_vaddr);
    println!("mod driver initialized")
}
