use core::slice;

use super::bus::virtio::virtio_probe;
use crate::memory::VirtualAddress;
use device_tree::{DeviceTree, Node};

const DEVICE_TREE_MAGIC: u32 = 0xd00dfeed;

fn walk(node: &Node) {
    if let Ok(compatible) = node.prop_str("compatible") {
        if compatible == "virtio,mmio" {
            virtio_probe(node);
        }
    }
    for child in node.children.iter() {
        walk(child);
    }
}

struct DtbHeader {
    magic: u32,
    size: u32,
}

pub fn init(dtb_vaddr: VirtualAddress) {
    let header = unsafe { &*(dtb_vaddr.0 as *const DtbHeader) };
    // from_be 是大小端序的转换（from big endian）
    let magic = u32::from_be(header.magic);
    if magic == DEVICE_TREE_MAGIC {
        let size = u32::from_be(header.size);
        let data = unsafe { slice::from_raw_parts(dtb_vaddr.0 as *const u8, size as usize) };
        if let Ok(dt) = DeviceTree::load(data) {
            walk(&dt.root);
        }
    }
}
