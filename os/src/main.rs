#![no_std]
#![no_main]
#![feature(llvm_asm)]
#![feature(global_asm)]
#![feature(panic_info_message)]
#![feature(alloc_error_handler)]

#![feature(allocator_api,
        alloc_prelude,
        const_raw_ptr_to_usize_cast)]

// #[macro_use]
extern crate alloc;

use alloc::prelude::v1::*;

global_asm!(include_str!("entry.asm"));

use core::panic::PanicInfo;
use core::fmt::{self, Write};

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    if let Some(location) = info.location() {
        println!("Panicked at {}:{} {}", location.file(), location.line(), info.message().unwrap());
    } else {
        println!("Panicked: {}", info.message().unwrap());
    }
    shutdown()
}

const SBI_CONSOLE_PUTCHAR: usize = 1;
const SBI_SHUTDOWN: usize = 8;

pub fn console_putchar(c: usize) {
    sbicall(SBI_CONSOLE_PUTCHAR, [c, 0, 0]);
}

pub fn shutdown() -> ! {
    sbicall(SBI_SHUTDOWN, [0, 0, 0]);
    panic!("It should shutdown!");
}

fn sbicall(id: usize, args: [usize; 3]) -> isize {
    let mut ret: isize;
    unsafe {
        llvm_asm!("ecall"
            : "={x10}" (ret)
            : "{x10}" (args[0]), "{x11}" (args[1]), "{x12}" (args[2]), "{x17}" (id)
            : "memory"
            : "volatile"
        );
    }
    ret
}


struct Stdout;

impl Write for Stdout {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for c in s.chars() {
            console_putchar(c as usize);
        }
        Ok(())
    }
}

pub fn print(args: fmt::Arguments) {
    Stdout.write_fmt(args).unwrap();
}

#[macro_export]
macro_rules! print {
    ($fmt: literal $(, $($arg: tt)+)?) => {
        print(format_args!($fmt $(, $($arg)+)?));
    }
}

#[macro_export]
macro_rules! println {
    ($fmt: literal $(, $($arg: tt)+)?) => {
        print(format_args!(concat!($fmt, "\n") $(, $($arg)+)?));
    }
}

//----------------- page-graind allocator -------------------
use core::{mem::size_of, ptr::null_mut};

static mut HEAP_START: usize = 0;
static mut HEAP_SIZE: usize =  0;

// We will use ALLOC_START to mark the start of the actual
// memory we can dish out.
static mut ALLOC_START: usize = 0;
const PAGE_ORDER: usize = 12;
pub const PAGE_SIZE: usize = 1 << 12;

/// Align (set to a multiple of some power of two)
/// This takes an order which is the exponent to 2^order
/// Therefore, all alignments must be made as a power of two.
/// This function always rounds up.
pub const fn align_val(val: usize, order: usize) -> usize {
    let o = (1usize << order) - 1;
    (val + o) & !o
}

#[repr(u8)]
pub enum PageBits {
    Empty = 0,
    Taken = 1 << 0,
    Last = 1 << 1,
}

impl PageBits {
    // We convert PageBits to a u8 a lot, so this is
    // for convenience.
    pub fn val(self) -> u8 {
        self as u8
    }
}

// Each page is described by the Page structure. Linux does this
// as well, where each 4096-byte chunk of memory has a structure
// associated with it. However, there structure is much larger.
pub struct Page {
    flags: u8,
}

impl Page {
    // If this page has been marked as the final allocation,
    // this function returns true. Otherwise, it returns false.
    pub fn is_last(&self) -> bool {
        if self.flags & PageBits::Last.val() != 0 {
            true
        }
        else {
            false
        }
    }

    // If the page is marked as being taken (allocated), then
    // this function returns true. Otherwise, it returns false.
    pub fn is_taken(&self) -> bool {
        if self.flags & PageBits::Taken.val() != 0 {
            true
        }
        else {
            false
        }
    }

    // This is the opposite of is_taken().
    pub fn is_free(&self) -> bool {
        !self.is_taken()
    }

    // Clear the Page structure and all associated allocations.
    pub fn clear(&mut self) {
        self.flags = PageBits::Empty.val();
    }

    // Set a certain flag. We ran into trouble here since PageBits
    // is an enumeration and we haven't implemented the BitOr Trait
    // on it.
    pub fn set_flag(&mut self, flag: PageBits) {
        self.flags |= flag.val();
    }

    pub fn clear_flag(&mut self, flag: PageBits) {
        self.flags &= !(flag.val());
    }
}

/// Initialize the allocation system. There are several ways that we can
/// implement the page allocator:
/// 1. Free list (singly linked list where it starts at the first free
/// allocation) 2. Bookkeeping list (structure contains a taken and length)
/// 3. Allocate one Page structure per 4096 bytes (this is what I chose)
/// 4. Others
pub fn page_init() {
    unsafe {
        let num_pages = HEAP_SIZE / PAGE_SIZE;
        let ptr = HEAP_START as *mut Page;
        // Clear all pages to make sure that they aren't accidentally
        // taken
        for i in 0..num_pages {
            (*ptr.add(i)).clear();
        }
        // Determine where the actual useful memory starts. This will be
        // after all Page structures. We also must align the ALLOC_START
        // to a page-boundary (PAGE_SIZE = 4096). ALLOC_START =
        // (HEAP_START + num_pages * size_of::<Page>() + PAGE_SIZE - 1)
        // & !(PAGE_SIZE - 1);
        ALLOC_START = align_val(
            HEAP_START
                + num_pages * size_of::<Page,>(),
            PAGE_ORDER,
        );
    }
}

/// Allocate a page or multiple pages
/// pages: the number of PAGE_SIZE pages to allocate
pub fn alloc(pages: usize) -> *mut u8 {
    // We have to find a contiguous allocation of pages
    assert!(pages > 0);
    unsafe {
        // We create a Page structure for each page on the heap. We
        // actually might have more since HEAP_SIZE moves and so does
        // the size of our structure, but we'll only waste a few bytes.
        let num_pages = HEAP_SIZE / PAGE_SIZE;
        let ptr = HEAP_START as *mut Page;
        for i in 0..num_pages - pages {
            let mut found = false;
            // Check to see if this Page is free. If so, we have our
            // first candidate memory address.
            if (*ptr.add(i)).is_free() {
                // It was FREE! Yay!
                found = true;
                for j in i..i + pages {
                    // Now check to see if we have a
                    // contiguous allocation for all of the
                    // request pages. If not, we should
                    // check somewhere else.
                    if (*ptr.add(j)).is_taken() {
                        found = false;
                        break;
                    }
                }
            }
            // We've checked to see if there are enough contiguous
            // pages to form what we need. If we couldn't, found
            // will be false, otherwise it will be true, which means
            // we've found valid memory we can allocate.
            if found {
                for k in i..i + pages - 1 {
                    (*ptr.add(k)).set_flag(PageBits::Taken);
                }
                // The marker for the last page is
                // PageBits::Last This lets us know when we've
                // hit the end of this particular allocation.
                (*ptr.add(i+pages-1)).set_flag(PageBits::Taken);
                (*ptr.add(i+pages-1)).set_flag(PageBits::Last);
                // The Page structures themselves aren't the
                // useful memory. Instead, there is 1 Page
                // structure per 4096 bytes starting at
                // ALLOC_START.
                return (ALLOC_START + PAGE_SIZE * i)
                    as *mut u8;
            }
        }
    }

    // If we get here, that means that no contiguous allocation was
    // found.
    null_mut()
}

/// Allocate and zero a page or multiple pages
/// pages: the number of pages to allocate
/// Each page is PAGE_SIZE which is calculated as 1 << PAGE_ORDER
/// On RISC-V, this typically will be 4,096 bytes.
pub fn zalloc(pages: usize) -> *mut u8 {
    // Allocate and zero a page.
    // First, let's get the allocation
    let ret = alloc(pages);
    if !ret.is_null() {
        let size = (PAGE_SIZE * pages) / 8;
        let big_ptr = ret as *mut u64;
        for i in 0..size {
            // We use big_ptr so that we can force an
            // sd (store doubleword) instruction rather than
            // the sb. This means 8x fewer stores than before.
            // Typically we have to be concerned about remaining
            // bytes, but fortunately 4096 % 8 = 0, so we
            // won't have any remaining bytes.
            unsafe {
                (*big_ptr.add(i)) = 0;
            }
        }
    }
    ret
}

/// Deallocate a page by its pointer
/// The way we've structured this, it will automatically coalesce
/// contiguous pages.
pub fn dealloc(ptr: *mut u8) {
    // Make sure we don't try to free a null pointer.
    assert!(!ptr.is_null());
    unsafe {
        let addr =
            HEAP_START + (ptr as usize - ALLOC_START) / PAGE_SIZE;
        // Make sure that the address makes sense. The address we
        // calculate here is the page structure, not the HEAP address!
        assert!(addr >= HEAP_START && addr < HEAP_START + HEAP_SIZE);
        let mut p = addr as *mut Page;
        // Keep clearing pages until we hit the last page.
        while (*p).is_taken() && !(*p).is_last() {
            (*p).clear();
            p = p.add(1);
        }
        // If the following assertion fails, it is most likely
        // caused by a double-free.
        assert!(
            (*p).is_last() == true,
            "Possible double-free detected! (Not taken found \
		         before last)"
        );
        // If we get here, we've taken care of all previous pages and
        // we are on the last page.
        (*p).clear();
    }
}

/// Print all page allocations
/// This is mainly used for debugging.
pub fn print_page_allocations() {
    unsafe {
        let num_pages = HEAP_SIZE / PAGE_SIZE;
        let mut beg = HEAP_START as *const Page;
        let end = beg.add(num_pages);
        let alloc_beg = ALLOC_START;
        let alloc_end = ALLOC_START + num_pages * PAGE_SIZE;
        println!(
            "PAGE ALLOCATION TABLE\nMETA: {:p} -> {:p}\nPHYS: \
		          0x{:x} -> 0x{:x}",
            beg, end, alloc_beg, alloc_end
        );
        println!("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        let mut num = 0;
        while beg < end {
            if (*beg).is_taken() {
                let start = beg as usize;
                let memaddr = ALLOC_START
                    + (start - HEAP_START)
                    * PAGE_SIZE;
                print!("0x{:x} => ", memaddr);
                loop {
                    num += 1;
                    if (*beg).is_last() {
                        let end = beg as usize;
                        let memaddr = ALLOC_START
                            + (end
                            - HEAP_START)
                            * PAGE_SIZE
                            + PAGE_SIZE - 1;
                        print!(
                            "0x{:x}: {:>3} page(s)",
                            memaddr,
                            (end - start + 1)
                        );
                        println!(".");
                        break;
                    }
                    beg = beg.add(1);
                }
            }
            beg = beg.add(1);
        }
        println!("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        println!(
            "Allocated: {:>5} pages ({:>9} bytes).",
            num,
            num * PAGE_SIZE
        );
        println!(
            "Free     : {:>5} pages ({:>9} bytes).",
            num_pages - num,
            (num_pages - num) * PAGE_SIZE
        );
    }
}

fn test_page_allocation() {
    print_page_allocations();
    let t1 = alloc(10);
    print_page_allocations();
    let t2 = alloc(8);
    print_page_allocations();
    dealloc(t1);
    print_page_allocations();
    dealloc(t2);
    print_page_allocations();
}

//-----------------------------------------------------
//use crate::page::{align_val, zalloc, Table, PAGE_SIZE};
//use core::{mem::size_of, ptr::null_mut};

// A single entry. We're using an i64 so that
// this will sign-extend rather than zero-extend
// since RISC-V requires that the reserved sections
// take on the most significant bit.
pub struct Entry {
    pub entry: i64,
}

// Table represents a single table, which contains 512 (2^9), 64-bit entries.
pub struct Table {
    pub entries: [Entry; 512],
}

impl Table {
    pub fn len() -> usize {
        512
    }
}

#[repr(usize)]
enum AllocListFlags {
    Taken = 1 << 63,
}
impl AllocListFlags {
    pub fn val(self) -> usize {
        self as usize
    }
}

struct AllocList {
    pub flags_size: usize,
}
impl AllocList {
    pub fn is_taken(&self) -> bool {
        self.flags_size & AllocListFlags::Taken.val() != 0
    }

    pub fn is_free(&self) -> bool {
        !self.is_taken()
    }

    pub fn set_taken(&mut self) {
        self.flags_size |= AllocListFlags::Taken.val();
    }

    pub fn set_free(&mut self) {
        self.flags_size &= !AllocListFlags::Taken.val();
    }

    pub fn set_size(&mut self, sz: usize) {
        let k = self.is_taken();
        self.flags_size = sz & !AllocListFlags::Taken.val();
        if k {
            self.flags_size |= AllocListFlags::Taken.val();
        }
    }

    pub fn get_size(&self) -> usize {
        self.flags_size & !AllocListFlags::Taken.val()
    }
}

// This is the head of the allocation. We start here when
// we search for a free memory location.
static mut KMEM_HEAD: *mut AllocList = null_mut();
// In the future, we will have on-demand pages
// so, we need to keep track of our memory footprint to
// see if we actually need to allocate more.
static mut KMEM_ALLOC: usize = 0;
static mut KMEM_PAGE_TABLE: *mut Table = null_mut();


// These functions are safe helpers around an unsafe
// operation.
pub fn get_head() -> *mut u8 {
    unsafe { KMEM_HEAD as *mut u8 }
}

pub fn get_page_table() -> *mut Table {
    unsafe { KMEM_PAGE_TABLE as *mut Table }
}

pub fn get_num_allocations() -> usize {
    unsafe { KMEM_ALLOC }
}

/// Initialize kernel's memory
/// This is not to be used to allocate memory
/// for user processes. If that's the case, use
/// alloc/dealloc from the page crate.
pub fn kmem_init() {
    unsafe {
        // Allocate 64 kernel pages (64 * 4096 = 262 KiB)
        let k_alloc = zalloc(64);
        assert!(!k_alloc.is_null());
        KMEM_ALLOC = 64;
        KMEM_HEAD = k_alloc as *mut AllocList;
        (*KMEM_HEAD).set_free();
        (*KMEM_HEAD).set_size(KMEM_ALLOC * PAGE_SIZE);
        KMEM_PAGE_TABLE = zalloc(1) as *mut Table;
    }
}

/// Allocate sub-page level allocation based on bytes and zero the memory
pub fn kzmalloc(sz: usize) -> *mut u8 {
    let size = align_val(sz, 3);
    let ret = kmalloc(size);

    if !ret.is_null() {
        for i in 0..size {
            unsafe {
                (*ret.add(i)) = 0;
            }
        }
    }
    ret
}

/// Allocate sub-page level allocation based on bytes
pub fn kmalloc(sz: usize) -> *mut u8 {
    unsafe {
        let size = align_val(sz, 3) + size_of::<AllocList>();
        let mut head = KMEM_HEAD;
        // .add() uses pointer arithmetic, so we type-cast into a u8
        // so that we multiply by an absolute size (KMEM_ALLOC *
        // PAGE_SIZE).
        let tail = (KMEM_HEAD as *mut u8).add(KMEM_ALLOC * PAGE_SIZE)
            as *mut AllocList;

        while head < tail {
            if (*head).is_free() && size <= (*head).get_size() {
                let chunk_size = (*head).get_size();
                let rem = chunk_size - size;
                (*head).set_taken();
                if rem > size_of::<AllocList>() {
                    let next = (head as *mut u8).add(size)
                        as *mut AllocList;
                    // There is space remaining here.
                    (*next).set_free();
                    (*next).set_size(rem);
                    (*head).set_size(size);
                }
                else {
                    // If we get here, take the entire chunk
                    (*head).set_size(chunk_size);
                }
                return head.add(1) as *mut u8;
            }
            else {
                // If we get here, what we saw wasn't a free
                // chunk, move on to the next.
                head = (head as *mut u8).add((*head).get_size())
                    as *mut AllocList;
            }
        }
    }
    // If we get here, we didn't find any free chunks--i.e. there isn't
    // enough memory for this. TODO: Add on-demand page allocation.
    null_mut()
}

/// Free a sub-page level allocation
pub fn kfree(ptr: *mut u8) {
    unsafe {
        if !ptr.is_null() {
            let p = (ptr as *mut AllocList).offset(-1);
            if (*p).is_taken() {
                (*p).set_free();
            }
            // After we free, see if we can combine adjacent free
            // spots to see if we can reduce fragmentation.
            coalesce();
        }
    }
}

/// Merge smaller chunks into a bigger chunk
pub fn coalesce() {
    unsafe {
        let mut head = KMEM_HEAD;
        let tail = (KMEM_HEAD as *mut u8).add(KMEM_ALLOC * PAGE_SIZE)
            as *mut AllocList;

        while head < tail {
            let next = (head as *mut u8).add((*head).get_size())
                as *mut AllocList;
            if (*head).get_size() == 0 {
                // If this happens, then we have a bad heap
                // (double free or something). However, that
                // will cause an infinite loop since the next
                // pointer will never move beyond the current
                // location.
                break;
            }
            else if next >= tail {
                // We calculated the next by using the size
                // given as get_size(), however this could push
                // us past the tail. In that case, the size is
                // wrong, hence we break and stop doing what we
                // need to do.
                break;
            }
            else if (*head).is_free() && (*next).is_free() {
                // This means we have adjacent blocks needing to
                // be freed. So, we combine them into one
                // allocation.
                (*head).set_size(
                    (*head).get_size()
                        + (*next).get_size(),
                );
            }
            // If we get here, we might've moved. Recalculate new
            // head.
            head = (head as *mut u8).add((*head).get_size())
                as *mut AllocList;
        }
    }
}

/// For debugging purposes, print the kmem table
pub fn print_kmem_table() {
    unsafe {
        let mut head = KMEM_HEAD;
        let tail = (KMEM_HEAD as *mut u8).add(KMEM_ALLOC * PAGE_SIZE)
            as *mut AllocList;
        while head < tail {
            println!(
                "{:p}: Length = {:<10} Taken = {}",
                head,
                (*head).get_size(),
                (*head).is_taken()
            );
            head = (head as *mut u8).add((*head).get_size())
                as *mut AllocList;
        }
    }
}

// ///////////////////////////////////
// / GLOBAL ALLOCATOR
// ///////////////////////////////////

// The global allocator allows us to use the data structures
// in the core library, such as a linked list or B-tree.
// We want to use these sparingly since we have a coarse-grained
// allocator.
use core::alloc::{GlobalAlloc, Layout};


// The global allocator is a static constant to a global allocator
// structure. We don't need any members because we're using this
// structure just to implement alloc and dealloc.
struct OsGlobalAlloc;

unsafe impl GlobalAlloc for OsGlobalAlloc {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        // We align to the next page size so that when
        // we divide by PAGE_SIZE, we get exactly the number
        // of pages necessary.
        kzmalloc(layout.size())
    }

    unsafe fn dealloc(&self, ptr: *mut u8, _layout: Layout) {
        // We ignore layout since our allocator uses ptr_start -> last
        // to determine the span of an allocation.
        kfree(ptr);
    }
}

#[global_allocator]
/// Technically, we don't need the {} at the end, but it
/// reveals that we're creating a new structure and not just
/// copying a value.
static GA: OsGlobalAlloc = OsGlobalAlloc {};

#[alloc_error_handler]
/// If for some reason alloc() in the global allocator gets null_mut(),
/// then we come here. This is a divergent function, so we call panic to
/// let the tester know what's going on.
pub fn alloc_error(l: Layout) -> ! {
    panic!(
        "Allocator failed to allocate {} bytes with {}-byte alignment.",
        l.size(),
        l.align()
    );
}

pub fn test_alloc() {
    let mut a=Vec::<u8>::new();
    a.push(3);
    assert_eq!(a[0],3);
}
//-----------------------virtio block device --------------------------------
#[repr(C)]
pub struct Geometry {
    cylinders: u16,
    heads:     u8,
    sectors:   u8,
}

#[repr(C)]
pub struct Topology {
    physical_block_exp: u8,
    alignment_offset:   u8,
    min_io_size:        u16,
    opt_io_size:        u32,
}

// There is a configuration space for VirtIO that begins
// at offset 0x100 and continues to the size of the configuration.
// The structure below represents the configuration for a
// block device. Really, all that this OS cares about is the
// capacity.
#[repr(C)]
pub struct Config {
    capacity:                 u64,
    size_max:                 u32,
    seg_max:                  u32,
    geometry:                 Geometry,
    blk_size:                 u32,
    topology:                 Topology,
    writeback:                u8,
    unused0:                  [u8; 3],
    max_discard_sector:       u32,
    max_discard_seg:          u32,
    discard_sector_alignment: u32,
    max_write_zeroes_sectors: u32,
    max_write_zeroes_seg:     u32,
    write_zeroes_may_unmap:   u8,
    unused1:                  [u8; 3],
}

// The header/data/status is a block request
// packet. We send the header to tell the direction
// (blktype: IN/OUT) and then the starting sector
// we want to read. Then, we put the data buffer
// as the Data structure and finally an 8-bit
// status. The device will write one of three values
// in here: 0 = success, 1 = io error, 2 = unsupported
// operation.
#[repr(C)]
pub struct Header {
    blktype:  u32,
    reserved: u32,
    sector:   u64,
}

#[repr(C)]
pub struct Data {
    data: *mut u8,
}

#[repr(C)]
pub struct Status {
    status: u8,
}

#[repr(C)]
pub struct Request {
    header: Header,
    data:   Data,
    status: Status,
    head:   u16,
}

// Internal block device structure
// We keep our own used_idx and idx for
// descriptors. There is a shared index, but that
// tells us or the device if we've kept up with where
// we are for the available (us) or used (device) ring.
pub struct BlockDevice {
    queue:        *mut Queue,
    dev:          *mut u32,
    idx:          u16,
    ack_used_idx: u16,
    read_only:    bool,
}

// Type values
pub const VIRTIO_BLK_T_IN: u32 = 0;
pub const VIRTIO_BLK_T_OUT: u32 = 1;
pub const VIRTIO_BLK_T_FLUSH: u32 = 4;
pub const VIRTIO_BLK_T_DISCARD: u32 = 11;
pub const VIRTIO_BLK_T_WRITE_ZEROES: u32 = 13;

// Status values
pub const VIRTIO_BLK_S_OK: u8 = 0;
pub const VIRTIO_BLK_S_IOERR: u8 = 1;
pub const VIRTIO_BLK_S_UNSUPP: u8 = 2;

// Feature bits
pub const VIRTIO_BLK_F_SIZE_MAX: u32 = 1;
pub const VIRTIO_BLK_F_SEG_MAX: u32 = 2;
pub const VIRTIO_BLK_F_GEOMETRY: u32 = 4;
pub const VIRTIO_BLK_F_RO: u32 = 5;
pub const VIRTIO_BLK_F_BLK_SIZE: u32 = 6;
pub const VIRTIO_BLK_F_FLUSH: u32 = 9;
pub const VIRTIO_BLK_F_TOPOLOGY: u32 = 10;
pub const VIRTIO_BLK_F_CONFIG_WCE: u32 = 11;
pub const VIRTIO_BLK_F_DISCARD: u32 = 13;
pub const VIRTIO_BLK_F_WRITE_ZEROES: u32 = 14;

// Much like with processes, Rust requires some initialization
// when we declare a static. In this case, we use the Option
// value type to signal that the variable exists, but not the
// queue itself. We will replace this with an actual queue when
// we initialize the block system.
static mut BLOCK_DEVICES: [Option<BlockDevice>; 8] = [None, None, None, None, None, None, None, None];

pub fn setup_block_device(ptr: *mut u32) -> bool {
    unsafe {
        // We can get the index of the device based on its address.
        // 0x1000_1000 is index 0
        // 0x1000_2000 is index 1
        // ...
        // 0x1000_8000 is index 7
        // To get the number that changes over, we shift right 12 places (3 hex digits)
        let idx = (ptr as usize - MMIO_VIRTIO_START) >> 12;
        // [Driver] Device Initialization
        // 1. Reset the device (write 0 into status)
        ptr.add(MmioOffsets::Status.scale32()).write_volatile(0);
        let mut status_bits = StatusField::Acknowledge.val32();
        // 2. Set ACKNOWLEDGE status bit
        ptr.add(MmioOffsets::Status.scale32()).write_volatile(status_bits);
        // 3. Set the DRIVER status bit
        status_bits |= StatusField::DriverOk.val32();
        ptr.add(MmioOffsets::Status.scale32()).write_volatile(status_bits);
        // 4. Read device feature bits, write subset of feature
        // bits understood by OS and driver    to the device.
        let host_features = ptr.add(MmioOffsets::HostFeatures.scale32()).read_volatile();
        let guest_features = host_features & !(1 << VIRTIO_BLK_F_RO);
        let ro = host_features & (1 << VIRTIO_BLK_F_RO) != 0;
        ptr.add(MmioOffsets::GuestFeatures.scale32()).write_volatile(guest_features);
        // 5. Set the FEATURES_OK status bit
        status_bits |= StatusField::FeaturesOk.val32();
        ptr.add(MmioOffsets::Status.scale32()).write_volatile(status_bits);
        // 6. Re-read status to ensure FEATURES_OK is still set.
        // Otherwise, it doesn't support our features.
        let status_ok = ptr.add(MmioOffsets::Status.scale32()).read_volatile();
        // If the status field no longer has features_ok set,
        // that means that the device couldn't accept
        // the features that we request. Therefore, this is
        // considered a "failed" state.
        if false == StatusField::features_ok(status_ok) {
            print!("features fail...");
            ptr.add(MmioOffsets::Status.scale32()).write_volatile(StatusField::Failed.val32());
            return false;
        }
        // 7. Perform device-specific setup.
        // Set the queue num. We have to make sure that the
        // queue size is valid because the device can only take
        // a certain size.
        let qnmax = ptr.add(MmioOffsets::QueueNumMax.scale32()).read_volatile();
        ptr.add(MmioOffsets::QueueNum.scale32()).write_volatile(VIRTIO_RING_SIZE as u32);
        if VIRTIO_RING_SIZE as u32 > qnmax {
            print!("queue size fail...");
            return false;
        }
        // First, if the block device array is empty, create it!
        // We add 4095 to round this up and then do an integer
        // divide to truncate the decimal. We don't add 4096,
        // because if it is exactly 4096 bytes, we would get two
        // pages, not one.
        let num_pages = (size_of::<Queue>() + PAGE_SIZE - 1) / PAGE_SIZE;
        // println!("np = {}", num_pages);
        // We allocate a page for each device. This will the the
        // descriptor where we can communicate with the block
        // device. We will still use an MMIO register (in
        // particular, QueueNotify) to actually tell the device
        // we put something in memory. We also have to be
        // careful with memory ordering. We don't want to
        // issue a notify before all memory writes have
        // finished. We will look at that later, but we need
        // what is called a memory "fence" or barrier.
        ptr.add(MmioOffsets::QueueSel.scale32()).write_volatile(0);
        // Alignment is very important here. This is the memory address
        // alignment between the available and used rings. If this is wrong,
        // then we and the device will refer to different memory addresses
        // and hence get the wrong data in the used ring.
        // ptr.add(MmioOffsets::QueueAlign.scale32()).write_volatile(2);
        let queue_ptr = zalloc(num_pages) as *mut Queue;
        let queue_pfn = queue_ptr as u32;
        ptr.add(MmioOffsets::GuestPageSize.scale32()).write_volatile(PAGE_SIZE as u32);
        // QueuePFN is a physical page number, however it
        // appears for QEMU we have to write the entire memory
        // address. This is a physical memory address where we
        // (the OS) and the block device have in common for
        // making and receiving requests.
        ptr.add(MmioOffsets::QueuePfn.scale32()).write_volatile(queue_pfn / PAGE_SIZE as u32);
        // We need to store all of this data as a "BlockDevice"
        // structure We will be referring to this structure when
        // making block requests AND when handling responses.
        let bd = BlockDevice { queue:        queue_ptr,
            dev:          ptr,
            idx:          0,
            ack_used_idx: 0,
            read_only:    ro, };
        BLOCK_DEVICES[idx] = Some(bd);

        // 8. Set the DRIVER_OK status bit. Device is now "live"
        status_bits |= StatusField::DriverOk.val32();
        ptr.add(MmioOffsets::Status.scale32()).write_volatile(status_bits);

        true
    }
}

pub fn fill_next_descriptor(bd: &mut BlockDevice, desc: Descriptor) -> u16 {
    unsafe {
        // The ring structure increments here first. This allows us to skip
        // index 0, which then in the used ring will show that .id > 0. This
        // is one way to error check. We will eventually get back to 0 as
        // this index is cyclical. However, it shows if the first read/write
        // actually works.
        bd.idx = (bd.idx + 1) % VIRTIO_RING_SIZE as u16;
        (*bd.queue).desc[bd.idx as usize] = desc;
        if (*bd.queue).desc[bd.idx as usize].flags & VIRTIO_DESC_F_NEXT != 0 {
            // If the next flag is set, we need another descriptor.
            (*bd.queue).desc[bd.idx as usize].next = (bd.idx + 1) % VIRTIO_RING_SIZE as u16;
        }
        bd.idx
    }
}
/// This is now a common block operation for both reads and writes. Therefore,
/// when one thing needs to change, we can change it for both reads and writes.
/// There is a lot of error checking that I haven't done. The block device reads
/// sectors at a time, which are 512 bytes. Therefore, our buffer must be capable
/// of storing multiples of 512 bytes depending on the size. The size is also
/// a multiple of 512, but we don't really check that.
/// We DO however, check that we aren't writing to an R/O device. This would
/// cause a I/O error if we tried to write to a R/O device.
pub fn block_op(dev: usize, buffer: *mut u8, size: u32, offset: u64, write: bool) {
    unsafe {
        if let Some(bdev) = BLOCK_DEVICES[dev - 1].as_mut() {
            // Check to see if we are trying to write to a read only device.
            if true == bdev.read_only && true == write {
                println!("Trying to write to read/only!");
                return;
            }
            let sector = offset / 512;
            // TODO: Before we get here, we are NOT allowed to schedule a read or
            // write OUTSIDE of the disk's size. So, we can read capacity from
            // the configuration space to ensure we stay within bounds.
            let blk_request_size = size_of::<Request>();
            let blk_request = kmalloc(blk_request_size) as *mut Request;
            let desc = Descriptor { addr:  &(*blk_request).header as *const Header as u64,
                len:   size_of::<Header>() as u32,
                flags: VIRTIO_DESC_F_NEXT,
                next:  0, };
            let head_idx = fill_next_descriptor(bdev, desc);
            (*blk_request).header.sector = sector;
            // A write is an "out" direction, whereas a read is an "in" direction.
            (*blk_request).header.blktype = if true == write {
                VIRTIO_BLK_T_OUT
            }
            else {
                VIRTIO_BLK_T_IN
            };
            // We put 111 in the status. Whenever the device finishes, it will write into
            // status. If we read status and it is 111, we know that it wasn't written to by
            // the device.
            (*blk_request).data.data = buffer;
            (*blk_request).header.reserved = 0;
            (*blk_request).status.status = 111;
            let desc = Descriptor { addr:  buffer as u64,
                len:   size,
                flags: VIRTIO_DESC_F_NEXT
                    | if false == write {
                    VIRTIO_DESC_F_WRITE
                }
                else {
                    0
                },
                next:  0, };
            let _data_idx = fill_next_descriptor(bdev, desc);
            let desc = Descriptor { addr:  &(*blk_request).status as *const Status as u64,
                len:   size_of::<Status>() as u32,
                flags: VIRTIO_DESC_F_WRITE,
                next:  0, };
            let _status_idx = fill_next_descriptor(bdev, desc);
            (*bdev.queue).avail.ring[(*bdev.queue).avail.idx as usize] = head_idx;
            (*bdev.queue).avail.idx = ((*bdev.queue).avail.idx + 1) % VIRTIO_RING_SIZE as u16;
            // The only queue a block device has is 0, which is the request
            // queue.
            bdev.dev.add(MmioOffsets::QueueNotify.scale32()).write_volatile(0);
        }
    }
}

pub fn blk_read(dev: usize, buffer: *mut u8, size: u32, offset: u64) {
    block_op(dev, buffer, size, offset, false);
}

pub fn blk_write(dev: usize, buffer: *mut u8, size: u32, offset: u64) {
    block_op(dev, buffer, size, offset, true);
}

/// Here we handle block specific interrupts. Here, we need to check
/// the used ring and wind it up until we've handled everything.
/// This is how the device tells us that it's finished a request.
pub fn pending(bd: &mut BlockDevice) {
    // Here we need to check the used ring and then free the resources
    // given by the descriptor id.
    unsafe {
        let ref queue = *bd.queue;
        while bd.ack_used_idx != queue.used.idx {
            let ref elem = queue.used.ring[bd.ack_used_idx as usize];
            bd.ack_used_idx = (bd.ack_used_idx + 1) % VIRTIO_RING_SIZE as u16;
            let rq = queue.desc[elem.id as usize].addr as *const Request;
            kfree(rq as *mut u8);
            // TODO: Awaken the process that will need this I/O. This is
            // the purpose of the waiting state.
        }
    }
}

/// The trap code will route PLIC interrupts 1..=8 for virtio devices. When
/// virtio determines that this is a block device, it sends it here.
pub fn blk_handle_interrupt(idx: usize) {
    unsafe {
        if let Some(bdev) = BLOCK_DEVICES[idx].as_mut() {
            pending(bdev);
        }
        else {
            println!("Invalid block device for interrupt {}", idx + 1);
        }
    }
}

//-----------------------virtio devices ------------------------------------

// Flags
// Descriptor flags have VIRTIO_DESC_F as a prefix
// Available flags have VIRTIO_AVAIL_F

pub const VIRTIO_DESC_F_NEXT: u16 = 1;
pub const VIRTIO_DESC_F_WRITE: u16 = 2;
pub const VIRTIO_DESC_F_INDIRECT: u16 = 4;

pub const VIRTIO_AVAIL_F_NO_INTERRUPT: u16 = 1;

pub const VIRTIO_USED_F_NO_NOTIFY: u16 = 1;

// According to the documentation, this must be a power
// of 2 for the new style. So, I'm changing this to use
// 1 << instead because that will enforce this standard.
pub const VIRTIO_RING_SIZE: usize = 1 << 7;

// VirtIO structures

// The descriptor holds the data that we need to send to
// the device. The address is a physical address and NOT
// a virtual address. The len is in bytes and the flags are
// specified above. Any descriptor can be chained, hence the
// next field, but only if the F_NEXT flag is specified.
#[repr(C)]
pub struct Descriptor {
    pub addr:  u64,
    pub len:   u32,
    pub flags: u16,
    pub next:  u16,
}

#[repr(C)]
pub struct Available {
    pub flags: u16,
    pub idx:   u16,
    pub ring:  [u16; VIRTIO_RING_SIZE],
    pub event: u16,
}

#[repr(C)]
pub struct UsedElem {
    pub id:  u32,
    pub len: u32,
}

#[repr(C)]
pub struct Used {
    pub flags: u16,
    pub idx:   u16,
    pub ring:  [UsedElem; VIRTIO_RING_SIZE],
    pub event: u16,
}

#[repr(C)]
pub struct Queue {
    pub desc:  [Descriptor; VIRTIO_RING_SIZE],
    pub avail: Available,
    // Calculating padding, we need the used ring to start on a page boundary. We take the page size, subtract the
    // amount the descriptor ring takes then subtract the available structure and ring.
    pub padding0: [u8; PAGE_SIZE - size_of::<Descriptor>() * VIRTIO_RING_SIZE - size_of::<Available>()],
    pub used:     Used,
}

// The MMIO transport is "legacy" in QEMU, so these registers represent
// the legacy interface.
#[repr(usize)]
pub enum MmioOffsets {
    MagicValue = 0x000,
    Version = 0x004,
    DeviceId = 0x008,
    VendorId = 0x00c,
    HostFeatures = 0x010,
    HostFeaturesSel = 0x014,
    GuestFeatures = 0x020,
    GuestFeaturesSel = 0x024,
    GuestPageSize = 0x028,
    QueueSel = 0x030,
    QueueNumMax = 0x034,
    QueueNum = 0x038,
    QueueAlign = 0x03c,
    QueuePfn = 0x040,
    QueueNotify = 0x050,
    InterruptStatus = 0x060,
    InterruptAck = 0x064,
    Status = 0x070,
    Config = 0x100,
}

#[repr(usize)]
pub enum DeviceTypes {
    None = 0,
    Network = 1,
    Block = 2,
    Console = 3,
    Entropy = 4,
    Gpu = 16,
    Input = 18,
    Memory = 24,
}

// Enumerations in Rust aren't easy to convert back
// and forth. Furthermore, we're going to use a u32
// pointer, so we need to "undo" the scaling that
// Rust will do with the .add() function.
impl MmioOffsets {
    pub fn val(self) -> usize {
        self as usize
    }

    pub fn scaled(self, scale: usize) -> usize {
        self.val() / scale
    }

    pub fn scale32(self) -> usize {
        self.scaled(4)
    }
}

pub enum StatusField {
    Acknowledge = 1,
    Driver = 2,
    Failed = 128,
    FeaturesOk = 8,
    DriverOk = 4,
    DeviceNeedsReset = 64,
}

// The status field will be compared to the status register. So,
// I've made some helper functions to checking that register easier.
impl StatusField {
    pub fn val(self) -> usize {
        self as usize
    }

    pub fn val32(self) -> u32 {
        self as u32
    }

    pub fn test(sf: u32, bit: StatusField) -> bool {
        sf & bit.val32() != 0
    }

    pub fn is_failed(sf: u32) -> bool {
        StatusField::test(sf, StatusField::Failed)
    }

    pub fn needs_reset(sf: u32) -> bool {
        StatusField::test(sf, StatusField::DeviceNeedsReset)
    }

    pub fn driver_ok(sf: u32) -> bool {
        StatusField::test(sf, StatusField::DriverOk)
    }

    pub fn features_ok(sf: u32) -> bool {
        StatusField::test(sf, StatusField::FeaturesOk)
    }
}

// We probably shouldn't put these here, but it'll help
// with probing the bus, etc. These are architecture specific
// which is why I say that.
pub const MMIO_VIRTIO_START: usize = 0x1000_1000;
pub const MMIO_VIRTIO_END: usize = 0x1000_8000;
pub const MMIO_VIRTIO_STRIDE: usize = 0x1000;
pub const MMIO_VIRTIO_MAGIC: u32 = 0x74_72_69_76;

// The VirtioDevice is essentially a structure we can put into an array
// to determine what virtio devices are attached to the system. Right now,
// we're using the 1..=8  linearity of the VirtIO devices on QEMU to help
// with reducing the data structure itself. Otherwise, we might be forced
// to use an MMIO pointer.
pub struct VirtioDevice {
    pub devtype: DeviceTypes,
}

impl VirtioDevice {
    pub const fn new() -> Self {
        VirtioDevice { devtype: DeviceTypes::None, }
    }

    pub const fn new_with(devtype: DeviceTypes) -> Self {
        VirtioDevice { devtype }
    }
}

static mut VIRTIO_DEVICES: [Option<VirtioDevice>; 8] = [None, None, None, None, None, None, None, None];

/// Probe the VirtIO bus for devices that might be
/// out there.
pub fn virtio_probe() {
    // Rust's for loop uses an Iterator object, which now has a step_by
    // modifier to change how much it steps. Also recall that ..= means up
    // to AND including MMIO_VIRTIO_END.
    for addr in (MMIO_VIRTIO_START..=MMIO_VIRTIO_END).step_by(MMIO_VIRTIO_STRIDE) {
        print!("Virtio probing 0x{:08x}...", addr);
        let magicvalue;
        let deviceid;
        let ptr = addr as *mut u32;
        unsafe {
            magicvalue = ptr.read_volatile();
            deviceid = ptr.add(2).read_volatile();
        }
        // 0x74_72_69_76 is "virt" in little endian, so in reality
        // it is triv. All VirtIO devices have this attached to the
        // MagicValue register (offset 0x000)
        if MMIO_VIRTIO_MAGIC != magicvalue {
            println!("not virtio.");
        }
        // If we are a virtio device, we now need to see if anything
        // is actually attached to it. The DeviceID register will
        // contain what type of device this is. If this value is 0,
        // then it is not connected.
        else if 0 == deviceid {
            println!("not connected.");
        }
        // If we get here, we have a connected virtio device. Now we have
        // to figure out what kind it is so we can do device-specific setup.
        else {
            match deviceid {
                // DeviceID 1 is a network device
                1 => {
                    print!("network device...");
                    if false == setup_network_device(ptr) {
                        println!("setup failed.");
                    }
                    else {
                        println!("setup succeeded!");
                    }
                },
                // DeviceID 2 is a block device
                2 => {
                    print!("block device...");
                    if false == setup_block_device(ptr) {
                        println!("setup failed.");
                    }
                    else {
                        let idx = (addr - MMIO_VIRTIO_START) >> 12;
                        unsafe {
                            VIRTIO_DEVICES[idx] =
                                Some(VirtioDevice::new_with(DeviceTypes::Block));
                        }
                        println!("setup succeeded!");
                    }
                },
                // DeviceID 4 is a random number generator device
                4 => {
                    print!("entropy device...");
                    if false == setup_entropy_device(ptr) {
                        println!("setup failed.");
                    }
                    else {
                        println!("setup succeeded!");
                    }
                },
                // DeviceID 16 is a GPU device
                16 => {
                    print!("GPU device...");
                    if false == setup_gpu_device(ptr) {
                        println!("setup failed.");
                    }
                    else {
                        println!("setup succeeded!");
                    }
                },
                // DeviceID 18 is an input device
                18 => {
                    print!("input device...");
                    if false == setup_input_device(ptr) {
                        println!("setup failed.");
                    }
                    else {
                        println!("setup succeeded!");
                    }
                },
                _ => println!("unknown device type."),
            }
        }
    }
}

pub fn setup_entropy_device(_ptr: *mut u32) -> bool {
    false
}

pub fn setup_network_device(_ptr: *mut u32) -> bool {
    false
}

pub fn setup_gpu_device(_ptr: *mut u32) -> bool {
    false
}

pub fn setup_input_device(_ptr: *mut u32) -> bool {
    false
}

// The External pin (PLIC) trap will lead us here if it is
// determined that interrupts 1..=8 are what caused the interrupt.
// In here, we try to figure out where to direct the interrupt
// and then handle it.
pub fn handle_interrupt(interrupt: u32) {
    let idx = interrupt as usize - 1;
    unsafe {
        if let Some(vd) = &VIRTIO_DEVICES[idx] {
            match vd.devtype {
                DeviceTypes::Block => {
                    blk_handle_interrupt(idx);
                },
                _ => {
                    println!("Invalid device generated interrupt!");
                },
            }
        }
        else {
            println!("Spurious interrupt {}", interrupt);
        }
    }
}

fn test_virtio_blk_device(){

    // This just tests the block device. We know that it connects backwards (8, 7, ..., 1).
    let buffer = kmalloc(1024);
    // Offset 1024 is the first block, which is the superblock. In the minix 3 file system, the first
    // block is the "boot block", which in our case will be 0.
    blk_read(8, buffer, 512, 1024);
    let mut i = 0;
    loop {
        if i > 100_000_000 {
            break;
        }
        i += 1;
    }
    println!("Test hdd.dsk ....");
    unsafe {
        print!("  ");
        for i in 0..16 {
            print!("{:02x} ", buffer.add(i).read());
        }
        println!(" ");
        print!("  ");
        for i in 0..16 {
            print!("{:02x} ", buffer.add(16+i).read());
        }
        println!(" ");
        print!("  ");
        for i in 0..16 {
            print!("{:02x} ", buffer.add(32+i).read());
        }
        println!(" ");
        print!("  ");
        for i in 0..16 {
            print!("{:02x} ", buffer.add(48+i).read());
        }
        println!(" ");
        buffer.add(0).write(0xaa);
        buffer.add(1).write(0xbb);
        buffer.add(2).write(0x7a);

    }
    //test for write.  But we will test fs, so comment below line
    //blk_write(8, buffer, 512, 0);
    // Free the testing buffer.
    kfree(buffer);
    println!("Test hdd.dsk  OK!");
}

//----------------------- Buffer ------------------------------------
use core::{ops::{Index, IndexMut}};
use alloc::{boxed::Box, collections::BTreeMap, string::String};
/// Copy one data from one memory location to another.
pub unsafe fn memcpy(dest: *mut u8, src: *const u8, bytes: usize) {
    let bytes_as_8 = bytes / 8;
    let dest_as_8 = dest as *mut u64;
    let src_as_8 = src as *const u64;

    for i in 0..bytes_as_8 {
        *(dest_as_8.add(i)) = *(src_as_8.add(i));
    }
    let bytes_completed = bytes_as_8 * 8;
    let bytes_remaining = bytes - bytes_completed;
    for i in bytes_completed..bytes_remaining {
        *(dest.add(i)) = *(src.add(i));
    }
}

// We need a Buffer that can automatically be created and destroyed
// in the lifetime of our read and write functions. In C, this would entail
// goto statements that "unravel" all of the allocations that we made. Take
// a look at the read() function to see why I thought this way would be better.
pub struct Buffer {
    buffer: *mut u8,
    len: usize
}

impl Buffer {
    pub fn new(sz: usize) -> Self {
        Self {
            buffer: kmalloc(sz),
            len: sz
        }
    }

    pub fn get_mut(&mut self) -> *mut u8 {
        self.buffer
    }

    pub fn get(&self) -> *const u8 {
        self.buffer
    }

    pub fn len(&self) -> usize {
        self.len
    }
}

impl Default for Buffer {
    fn default() -> Self {
        Self::new(1024)
    }
}

impl Index<usize> for Buffer {
    type Output = u8;
    fn index(&self, idx: usize) -> &Self::Output {
        unsafe {
            self.get().add(idx).as_ref().unwrap()
        }
    }
}

impl IndexMut<usize> for Buffer {
    fn index_mut(&mut self, idx: usize) -> &mut Self::Output {
        unsafe {
            self.get_mut().add(idx).as_mut().unwrap()
        }
    }

}

impl Clone for Buffer {
    fn clone(&self) -> Self {
        let mut new = Self {
            buffer: kmalloc(self.len()),
            len: self.len()
        };
        unsafe {
            memcpy(new.get_mut(), self.get(), self.len());
        }
        new
    }
}

// This is why we have the Buffer. Instead of having to unwind
// all other buffers, we drop here when the block buffer goes out of scope.
impl Drop for Buffer {
    fn drop(&mut self) {
        if !self.buffer.is_null() {
            kfree(self.buffer);
            self.buffer = null_mut();
        }
    }
}

//----------------------- minix fs -----------------------------------------

pub const MAGIC: u16 = 0x4d5a;
pub const BLOCK_SIZE: u32 = 1024;
pub const NUM_IPTRS: usize = BLOCK_SIZE as usize / 4;
pub const S_IFDIR: u16 = 0o040_000;
pub const S_IFREG: u16 = 0o100_000;
/// The superblock describes the file system on the disk. It gives
/// us all the information we need to read the file system and navigate
/// the file system, including where to find the inodes and zones (blocks).
#[repr(C)]
pub struct SuperBlock {
    pub ninodes:         u32,
    pub pad0:            u16,
    pub imap_blocks:     u16,
    pub zmap_blocks:     u16,
    pub first_data_zone: u16,
    pub log_zone_size:   u16,
    pub pad1:            u16,
    pub max_size:        u32,
    pub zones:           u32,
    pub magic:           u16,
    pub pad2:            u16,
    pub block_size:      u16,
    pub disk_version:    u8
}

/// An inode stores the "meta-data" to a file. The mode stores the permissions
/// AND type of file. This is how we differentiate a directory from a file. A file
/// size is in here too, which tells us how many blocks we need to read. Finally, the
/// zones array points to where we can find the blocks, which is where the data
/// is contained for the file.
#[repr(C)]
#[derive(Copy, Clone)]
pub struct Inode {
    pub mode:   u16,
    pub nlinks: u16,
    pub uid:    u16,
    pub gid:    u16,
    pub size:   u32,
    pub atime:  u32,
    pub mtime:  u32,
    pub ctime:  u32,
    pub zones:  [u32; 10]
}

/// Notice that an inode does not contain the name of a file. This is because
/// more than one file name may refer to the same inode. These are called "hard links"
/// Instead, a DirEntry essentially associates a file name with an inode as shown in
/// the structure below.
#[repr(C)]
pub struct DirEntry {
    pub inode: u32,
    pub name:  [u8; 60]
}

/// The MinixFileSystem implements the FileSystem trait for the VFS.
pub struct MinixFileSystem;
// The plan for this in the future is to have a single inode cache. What we
// will do is have a cache of Node structures which will combine the Inode
// with the block drive.
static mut MFS_INODE_CACHE: [Option<BTreeMap<String, Inode>>; 8] = [None, None, None, None, None, None, None, None];

impl MinixFileSystem {
    /// Inodes are the meta-data of a file, including the mode (permissions and type) and
    /// the file's size. They are stored above the data zones, but to figure out where we
    /// need to go to get the inode, we first need the superblock, which is where we can
    /// find all of the information about the filesystem itself.
    pub fn get_inode(bdev: usize, inode_num: u32) -> Option<Inode> {
        // When we read, everything needs to be a multiple of a sector (512 bytes)
        // So, we need to have memory available that's at least 512 bytes, even if
        // we only want 10 bytes or 32 bytes (size of an Inode).
        let mut buffer = Buffer::new(1024);

        // Here is a little memory trick. We have a reference and it will refer to the
        // top portion of our buffer. Since we won't be using the super block and inode
        // simultaneously, we can overlap the memory regions.

        // For Rust-ers, I'm showing two ways here. The first way is to get a reference
        // from a pointer. You will see the &* a lot in Rust for references. Rust
        // makes dereferencing a pointer cumbersome, which lends to not using them.
        let super_block = unsafe { &*(buffer.get_mut() as *mut SuperBlock) };
        // I opted for a pointer here instead of a reference because we will be offsetting the inode by a certain amount.
        let inode = buffer.get_mut() as *mut Inode;
        // Read from the block device. The size is 1 sector (512 bytes) and our offset is past
        // the boot block (first 1024 bytes). This is where the superblock sits.
        syc_read(bdev, buffer.get_mut(), 512, 1024);
        if super_block.magic == MAGIC {
            // If we get here, we successfully read what we think is the super block.
            // The math here is 2 - one for the boot block, one for the super block. Then we
            // have to skip the bitmaps blocks. We have a certain number of inode map blocks (imap)
            // and zone map blocks (zmap).
            // The inode comes to us as a NUMBER, not an index. So, we need to subtract 1.
            let inode_offset = (2 + super_block.imap_blocks + super_block.zmap_blocks) as usize * BLOCK_SIZE as usize
                + ((inode_num as usize - 1) / (BLOCK_SIZE as usize / size_of::<Inode>())) * BLOCK_SIZE as usize;

            // Now, we read the inode itself.
            // The block driver requires that our offset be a multiple of 512. We do that with the
            // inode_offset. However, we're going to be reading a group of inodes.
            syc_read(bdev, buffer.get_mut(), 1024, inode_offset as u32);

            // There are 1024 / size_of<Inode>() inodes in each read that we can do. However, we need to figure out which inode in that group we need to read. We just take the % of this to find out.
            let read_this_node = (inode_num as usize - 1) % (BLOCK_SIZE as usize / size_of::<Inode>());

            // We copy the inode over. This might not be the best thing since the Inode will
            // eventually have to change after writing.
            return unsafe { Some(*(inode.add(read_this_node))) };
        }
        // If we get here, some result wasn't OK. Either the super block
        // or the inode itself.
        println!("MAGIC {:#x} , the real magic {:#x} ",MAGIC, super_block.magic);
        None
    }
}

impl MinixFileSystem {
    /// Init is where we would cache the superblock and inode to avoid having to read
    /// it over and over again, like we do for read right now.
    fn cache_at(btm: &mut BTreeMap<String, Inode>, cwd: &String, inode_num: u32, bdev: usize) {
        let ino = Self::get_inode(bdev, inode_num).unwrap();
        let mut buf = Buffer::new(((ino.size + BLOCK_SIZE - 1) & !BLOCK_SIZE) as usize);
        let dirents = buf.get() as *const DirEntry;
        let sz = Self::read(bdev, &ino, buf.get_mut(), BLOCK_SIZE, 0);
        let num_dirents = sz as usize / size_of::<DirEntry>();
        // We start at 2 because the first two entries are . and ..
        for i in 2..num_dirents {
            unsafe {
                let ref d = *dirents.add(i);
                let d_ino = Self::get_inode(bdev, d.inode).unwrap();
                let mut new_cwd = String::with_capacity(120);
                for i in cwd.bytes() {
                    new_cwd.push(i as char);
                }
                // Add a directory separator between this inode and the next.
                // If we're the root (inode 1), we don't want to double up the
                // frontslash, so only do it for non-roots.
                if inode_num != 1 {
                    new_cwd.push('/');
                }
                for i in 0..60 {
                    if d.name[i] == 0 {
                        break;
                    }
                    new_cwd.push(d.name[i] as char);
                }
                new_cwd.shrink_to_fit();
                if d_ino.mode & S_IFDIR != 0 {
                    // This is a directory, cache these. This is a recursive call,
                    // which I don't really like.
                    Self::cache_at(btm, &new_cwd, d.inode, bdev);
                }
                else {
                    btm.insert(new_cwd, d_ino);
                }
            }
        }
    }

    // Run this ONLY in a process!
    pub fn init(bdev: usize) {
        if unsafe { MFS_INODE_CACHE[bdev - 1].is_none() } {
            let mut btm = BTreeMap::new();
            let cwd = String::from("/");

            // Let's look at the root (inode #1)
            Self::cache_at(&mut btm, &cwd, 1, bdev);
            unsafe {
                MFS_INODE_CACHE[bdev - 1] = Some(btm);
            }
        }
        else {
            println!("KERNEL: Initialized an already initialized filesystem {}", bdev);
        }
    }

    /// The goal of open is to traverse the path given by path. If we cache the inodes
    /// in RAM, it might make this much quicker. For now, this doesn't do anything since
    /// we're just testing read based on if we know the Inode we're looking for.
    pub fn open(bdev: usize, path: &str) -> Result<Inode, FsError> {
        if let Some(cache) = unsafe { MFS_INODE_CACHE[bdev - 1].take() } {
            let ret;
            if let Some(inode) = cache.get(path) {
                ret = Ok(*inode);
            }
            else {
                ret = Err(FsError::FileNotFound);
            }
            unsafe {
                MFS_INODE_CACHE[bdev - 1].replace(cache);
            }
            ret
        }
        else {
            Err(FsError::FileNotFound)
        }
    }

    pub fn read(bdev: usize, inode: &Inode, buffer: *mut u8, size: u32, offset: u32) -> u32 {
        // Our strategy here is to use blocks to see when we need to start reading
        // based on the offset. That's offset_block. Then, the actual byte within
        // that block that we need is offset_byte.
        let mut blocks_seen = 0u32;
        let offset_block = offset / BLOCK_SIZE;
        let mut offset_byte = offset % BLOCK_SIZE;
        // First, the _size parameter (now in bytes_left) is the size of the buffer, not
        // necessarily the size of the file. If our buffer is bigger than the file, we're OK.
        // If our buffer is smaller than the file, then we can only read up to the buffer size.
        let mut bytes_left = if size > inode.size {
            inode.size
        }
        else {
            size
        };
        let mut bytes_read = 0u32;
        // The block buffer automatically drops when we quit early due to an error or we've read enough. This will be the holding port when we go out and read a block. Recall that even if we want 10 bytes, we have to read the entire block (really only 512 bytes of the block) first. So, we use the block_buffer as the middle man, which is then copied into the buffer.
        let mut block_buffer = Buffer::new(BLOCK_SIZE as usize);
        // Triply indirect zones point to a block of pointers (BLOCK_SIZE / 4). Each one of those pointers points to another block of pointers (BLOCK_SIZE / 4). Each one of those pointers yet again points to another block of pointers (BLOCK_SIZE / 4). This is why we have indirect, iindirect (doubly), and iiindirect (triply).
        let mut indirect_buffer = Buffer::new(BLOCK_SIZE as usize);
        let mut iindirect_buffer = Buffer::new(BLOCK_SIZE as usize);
        let mut iiindirect_buffer = Buffer::new(BLOCK_SIZE as usize);
        // I put the pointers *const u32 here. That means we will allocate the indirect, doubly indirect, and triply indirect even for small files. I initially had these in their respective scopes, but that required us to recreate the indirect buffer for doubly indirect and both the indirect and doubly indirect buffers for the triply indirect. Not sure which is better, but I probably wasted brain cells on this.
        let izones = indirect_buffer.get() as *const u32;
        let iizones = iindirect_buffer.get() as *const u32;
        let iiizones = iiindirect_buffer.get() as *const u32;

        // ////////////////////////////////////////////
        // // DIRECT ZONES
        // ////////////////////////////////////////////
        // In Rust, our for loop automatically "declares" i from 0 to < 7. The syntax
        // 0..7 means 0 through to 7 but not including 7. If we want to include 7, we
        // would use the syntax 0..=7.
        for i in 0..7 {
            // There are 7 direct zones in the Minix 3 file system. So, we can just read them one by one. Any zone that has the value 0 is skipped and we check the next zones. This might happen as we start writing and truncating.
            if inode.zones[i] == 0 {
                continue;
            }
            // We really use this to keep track of when we need to actually start reading
            // But an if statement probably takes more time than just incrementing it.
            if offset_block <= blocks_seen {
                // If we get here, then our offset is within our window that we want to see.
                // We need to go to the direct pointer's index. That'll give us a block INDEX.
                // That makes it easy since all we have to do is multiply the block size
                // by whatever we get. If it's 0, we skip it and move on.
                let zone_offset = inode.zones[i] * BLOCK_SIZE;
                // We read the zone, which is where the data is located. The zone offset is simply the block
                // size times the zone number. This makes it really easy to read!
                syc_read(bdev, block_buffer.get_mut(), BLOCK_SIZE, zone_offset);

                // There's a little bit of math to see how much we need to read. We don't want to read
                // more than the buffer passed in can handle, and we don't want to read if we haven't
                // taken care of the offset. For example, an offset of 10000 with a size of 2 means we
                // can only read bytes 10,000 and 10,001.
                let read_this_many = if BLOCK_SIZE - offset_byte > bytes_left {
                    bytes_left
                }
                else {
                    BLOCK_SIZE - offset_byte
                };
                // Once again, here we actually copy the bytes into the final destination, the buffer. This memcpy
                // is written in cpu.rs.
                unsafe {
                    memcpy(buffer.add(bytes_read as usize), block_buffer.get().add(offset_byte as usize), read_this_many as usize);
                }
                // Regardless of whether we have an offset or not, we reset the offset byte back to 0. This
                // probably will get set to 0 many times, but who cares?
                offset_byte = 0;
                // Reset the statistics to see how many bytes we've read versus how many are left.
                bytes_read += read_this_many;
                bytes_left -= read_this_many;
                // If no more bytes are left, then we're done.
                if bytes_left == 0 {
                    return bytes_read;
                }
            }
            // The blocks_seen is for the offset. We need to skip a certain number of blocks FIRST before getting
            // to the offset. The reason we need to read the zones is because we need to skip zones of 0, and they
            // do not contribute as a "seen" block.
            blocks_seen += 1;
        }
        // ////////////////////////////////////////////
        // // SINGLY INDIRECT ZONES
        // ////////////////////////////////////////////
        // Each indirect zone is a list of pointers, each 4 bytes. These then
        // point to zones where the data can be found. Just like with the direct zones,
        // we need to make sure the zone isn't 0. A zone of 0 means skip it.
        if inode.zones[7] != 0 {
            syc_read(bdev, indirect_buffer.get_mut(), BLOCK_SIZE, BLOCK_SIZE * inode.zones[7]);
            let izones = indirect_buffer.get() as *const u32;
            for i in 0..NUM_IPTRS {
                // Where do I put unsafe? Dereferencing the pointers and memcpy are the unsafe functions.
                unsafe {
                    if izones.add(i).read() != 0 {
                        if offset_block <= blocks_seen {
                            syc_read(bdev, block_buffer.get_mut(), BLOCK_SIZE, BLOCK_SIZE * izones.add(i).read());
                            let read_this_many = if BLOCK_SIZE - offset_byte > bytes_left {
                                bytes_left
                            }
                            else {
                                BLOCK_SIZE - offset_byte
                            };
                            memcpy(buffer.add(bytes_read as usize), block_buffer.get().add(offset_byte as usize), read_this_many as usize);
                            bytes_read += read_this_many;
                            bytes_left -= read_this_many;
                            offset_byte = 0;
                            if bytes_left == 0 {
                                return bytes_read;
                            }
                        }
                        blocks_seen += 1;
                    }
                }
            }
        }
        // ////////////////////////////////////////////
        // // DOUBLY INDIRECT ZONES
        // ////////////////////////////////////////////
        if inode.zones[8] != 0 {
            syc_read(bdev, indirect_buffer.get_mut(), BLOCK_SIZE, BLOCK_SIZE * inode.zones[8]);
            unsafe {
                for i in 0..NUM_IPTRS {
                    if izones.add(i).read() != 0 {
                        syc_read(bdev, iindirect_buffer.get_mut(), BLOCK_SIZE, BLOCK_SIZE * izones.add(i).read());
                        for j in 0..NUM_IPTRS {
                            if iizones.add(j).read() != 0 {
                                // Notice that this inner code is the same for all end-zone pointers. I'm thinking about
                                // moving this out of here into a function of its own, but that might make it harder
                                // to follow.
                                if offset_block <= blocks_seen {
                                    syc_read(bdev, block_buffer.get_mut(), BLOCK_SIZE, BLOCK_SIZE * iizones.add(j).read());
                                    let read_this_many = if BLOCK_SIZE - offset_byte > bytes_left {
                                        bytes_left
                                    }
                                    else {
                                        BLOCK_SIZE - offset_byte
                                    };
                                    memcpy(
                                        buffer.add(bytes_read as usize),
                                        block_buffer.get().add(offset_byte as usize),
                                        read_this_many as usize
                                    );
                                    bytes_read += read_this_many;
                                    bytes_left -= read_this_many;
                                    offset_byte = 0;
                                    if bytes_left == 0 {
                                        return bytes_read;
                                    }
                                }
                                blocks_seen += 1;
                            }
                        }
                    }
                }
            }
        }
        // ////////////////////////////////////////////
        // // TRIPLY INDIRECT ZONES
        // ////////////////////////////////////////////
        if inode.zones[9] != 0 {
            syc_read(bdev, indirect_buffer.get_mut(), BLOCK_SIZE, BLOCK_SIZE * inode.zones[9]);
            unsafe {
                for i in 0..NUM_IPTRS {
                    if izones.add(i).read() != 0 {
                        syc_read(bdev, iindirect_buffer.get_mut(), BLOCK_SIZE, BLOCK_SIZE * izones.add(i).read());
                        for j in 0..NUM_IPTRS {
                            if iizones.add(j).read() != 0 {
                                syc_read(bdev, iiindirect_buffer.get_mut(), BLOCK_SIZE, BLOCK_SIZE * iizones.add(j).read());
                                for k in 0..NUM_IPTRS {
                                    if iiizones.add(k).read() != 0 {
                                        // Hey look! This again.
                                        if offset_block <= blocks_seen {
                                            syc_read(bdev, block_buffer.get_mut(), BLOCK_SIZE, BLOCK_SIZE * iiizones.add(k).read());
                                            let read_this_many = if BLOCK_SIZE - offset_byte > bytes_left {
                                                bytes_left
                                            }
                                            else {
                                                BLOCK_SIZE - offset_byte
                                            };
                                            memcpy(
                                                buffer.add(bytes_read as usize),
                                                block_buffer.get().add(offset_byte as usize),
                                                read_this_many as usize
                                            );
                                            bytes_read += read_this_many;
                                            bytes_left -= read_this_many;
                                            offset_byte = 0;
                                            if bytes_left == 0 {
                                                return bytes_read;
                                            }
                                        }
                                        blocks_seen += 1;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        // Anyone else love this stairstep style? I probably should put the pointers in a function by themselves,
        // but I think that'll make it more difficult to see what's actually happening.

        bytes_read
    }

    pub fn write(&mut self, _desc: &Inode, _buffer: *const u8, _offset: u32, _size: u32) -> u32 {
        0
    }

    pub fn stat(&self, inode: &Inode) -> Stat {
        Stat { mode: inode.mode,
            size: inode.size,
            uid:  inode.uid,
            gid:  inode.gid }
    }
}

/// This is a wrapper function around the syscall_block_read. This allows me to do
/// other things before I call the system call (or after). However, all the things I
/// wanted to do are no longer there, so this is a worthless function.
fn syc_read(bdev: usize, buffer: *mut u8, size: u32, offset: u32)  {
    blk_read(bdev, buffer, size, offset as u64);
}

// We have to start a process when reading from a file since the block
// device will block. We only want to block in a process context, not an
// interrupt context.
struct ProcArgs {
    pub pid:    u16,
    pub dev:    usize,
    pub buffer: *mut u8,
    pub size:   u32,
    pub offset: u32,
    pub node:   u32
}

// This is the actual code ran inside of the read process.
fn read_proc(args_addr: usize) {
    let args = unsafe { Box::from_raw(args_addr as *mut ProcArgs) };

    // Start the read! Since we're in a kernel process, we can block by putting this
    // process into a waiting state and wait until the block driver returns.
    let inode = MinixFileSystem::get_inode(args.dev, args.node);
    let bytes = MinixFileSystem::read(args.dev, &inode.unwrap(), args.buffer, args.size, args.offset);

    // Let's write the return result into regs[10], which is A0.
    // unsafe {
    //     let ptr = get_by_pid(args.pid);
    //     if !ptr.is_null() {
    //      //   (*(*ptr).get_frame_mut()).regs[Registers::A0 as usize] = bytes as usize;
    //     }
    // }
    // This is the process making the system call. The system itself spawns another process
    // which goes out to the block device. Since we're passed the read call, we need to awaken
    // the process and get it ready to go. The only thing this process needs to clean up is the
    // tfree(), but the user process doesn't care about that.
    //set_running(args.pid);
}

/// System calls will call process_read, which will spawn off a kernel process to read
/// the requested data.
pub fn process_read(pid: u16, dev: usize, node: u32, buffer: *mut u8, size: u32, offset: u32) {
    // println!("FS read {}, {}, 0x{:x}, {}, {}", pid, dev, buffer as usize, size, offset);
    let args = ProcArgs { pid,
        dev,
        buffer,
        size,
        offset,
        node };
    let boxed_args = Box::new(args);
    //set_waiting(pid);
    //let _ = add_kernel_process_args(read_proc, Box::into_raw(boxed_args) as usize);
}

/// Stats on a file. This generally mimics an inode
/// since that's the information we want anyway.
/// However, inodes are filesystem specific, and we
/// want a more generic stat.
pub struct Stat {
    pub mode: u16,
    pub size: u32,
    pub uid:  u16,
    pub gid:  u16
}

pub enum FsError {
    Success,
    FileNotFound,
    Permission,
    IsFile,
    IsDirectory
}

fn test_fs(){
    MinixFileSystem::init(8);
}
//-------------------------------minixfs end---------------------------------

fn clear_bss() {
    extern "C" {
        fn sbss();
        fn ebss();
    }
    (sbss as usize..ebss as usize).for_each(|a| {
        unsafe { (a as *mut u8).write_volatile(0) }
    });
}

#[no_mangle]
#[link_section=".text.entry"]
extern "C" fn rust_main() {
    extern "C" {
        fn stext();
        fn etext();
        fn srodata();
        fn erodata();
        fn sdata();
        fn edata();
        fn sbss();
        fn ebss();
        fn boot_stack();
        fn boot_stack_top();
        fn stack_begin();
        fn stack_end();
        fn ekernel();
        fn user_begin();
    }
    clear_bss();
    println!("Hello, world!");
    println!(".text [{:#x}, {:#x})", stext as usize, etext as usize);
    println!(".rodata [{:#x}, {:#x})", srodata as usize, erodata as usize);
    println!(".data [{:#x}, {:#x})", sdata as usize, edata as usize);
    println!(".bss [{:#x}, {:#x})", sbss as usize, ebss as usize);
    println!(
        "boot_stack [{:#x}, {:#x})",
        boot_stack as usize, boot_stack_top as usize
    );
    println!(".stack [{:#x}, {:#x})", stack_begin as usize, stack_end as usize);
    println!(".ekernel {:#x}", ekernel as usize);
    println!("user_begin {:#x}", user_begin as usize);
    //-----------------------
    unsafe {
        HEAP_START=ekernel as usize +4096;
        HEAP_SIZE = user_begin as usize - HEAP_START;
        println!("HEAP_START {:#x}, HEAP_SIZE {:#x}", HEAP_START, HEAP_SIZE);
    }
    page_init();
    test_page_allocation();
    kmem_init();
    test_alloc();
    // Set up virtio. This requires a working heap and page-grained allocator.
    virtio_probe();
    test_virtio_blk_device();
    test_fs();
    println!("[kernel] OK ALL! Shutdown!");
    shutdown();
    //panic!("NO! should not come here");
}
