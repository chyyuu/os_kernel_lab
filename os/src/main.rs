#![no_std]
#![no_main]
#![feature(llvm_asm)]
#![feature(global_asm)]
#![feature(panic_info_message)]

//=====================SHARE PARTS============================
const STDOUT: usize = 1;
const SYSCALL_WRITE: usize = 64;
const SYSCALL_EXIT: usize = 93;

//======================= SUPERVISOR MODE =========================
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
pub fn page_allocator_init() {
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

//-------------Paging&MMU-----------------------

// Represent (repr) our entry bits as
// unsigned 64-bit integers.
#[repr(i64)]
#[derive(Copy, Clone)]
pub enum EntryBits {
    None = 0,
    Valid = 1 << 0,
    Read = 1 << 1,
    Write = 1 << 2,
    Execute = 1 << 3,
    User = 1 << 4,
    Global = 1 << 5,
    Access = 1 << 6,
    Dirty = 1 << 7,

    // Convenience combinations
    ReadWrite = 1 << 1 | 1 << 2,
    ReadExecute = 1 << 1 | 1 << 3,
    ReadWriteExecute = 1 << 1 | 1 << 2 | 1 << 3,

    // User Convenience Combinations
    UserReadWrite = 1 << 1 | 1 << 2 | 1 << 4,
    UserReadExecute = 1 << 1 | 1 << 3 | 1 << 4,
    UserReadWriteExecute = 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4,
}

// Helper functions to convert the enumeration
// into an i64, which is what our page table
// entries will be.
impl EntryBits {
    pub fn val(self) -> i64 {
        self as i64
    }
}

// A single entry. We're using an i64 so that
// this will sign-extend rather than zero-extend
// since RISC-V requires that the reserved sections
// take on the most significant bit.
pub struct Entry {
    pub entry: i64,
}

// The Entry structure describes one of the 512 entries per table, which is
// described in the RISC-V privileged spec Figure 4.18.
impl Entry {
    pub fn is_valid(&self) -> bool {
        self.get_entry() & EntryBits::Valid.val() != 0
    }

    // The first bit (bit index #0) is the V bit for
    // valid.
    pub fn is_invalid(&self) -> bool {
        !self.is_valid()
    }

    // A leaf has one or more RWX bits set
    pub fn is_leaf(&self) -> bool {
        self.get_entry() & 0xe != 0
    }

    pub fn is_branch(&self) -> bool {
        !self.is_leaf()
    }

    pub fn set_entry(&mut self, entry: i64) {
        self.entry = entry;
    }

    pub fn get_entry(&self) -> i64 {
        self.entry
    }
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

/// Map a virtual address to a physical address using 4096-byte page
/// size.
/// root: a mutable reference to the root Table
/// vaddr: The virtual address to map
/// paddr: The physical address to map
/// bits: An OR'd bitset containing the bits the leaf should have.
///       The bits should contain only the following:
///          Read, Write, Execute, User, and/or Global
///       The bits MUST include one or more of the following:
///          Read, Write, Execute
///       The valid bit automatically gets added.
pub fn map(root: &mut Table, vaddr: usize, paddr: usize, bits: i64, level: usize) {
    // Make sure that Read, Write, or Execute have been provided
    // otherwise, we'll leak memory and always create a page fault.
    assert!(bits & 0xe != 0);
    // Extract out each VPN from the virtual address
    // On the virtual address, each VPN is exactly 9 bits,
    // which is why we use the mask 0x1ff = 0b1_1111_1111 (9 bits)
    let vpn = [
        // VPN[0] = vaddr[20:12]
        (vaddr >> 12) & 0x1ff,
        // VPN[1] = vaddr[29:21]
        (vaddr >> 21) & 0x1ff,
        // VPN[2] = vaddr[38:30]
        (vaddr >> 30) & 0x1ff,
    ];

    // Just like the virtual address, extract the physical address
    // numbers (PPN). However, PPN[2] is different in that it stores
    // 26 bits instead of 9. Therefore, we use,
    // 0x3ff_ffff = 0b11_1111_1111_1111_1111_1111_1111 (26 bits).
    let ppn = [
        // PPN[0] = paddr[20:12]
        (paddr >> 12) & 0x1ff,
        // PPN[1] = paddr[29:21]
        (paddr >> 21) & 0x1ff,
        // PPN[2] = paddr[55:30]
        (paddr >> 30) & 0x3ff_ffff,
    ];
    // We will use this as a floating reference so that we can set
    // individual entries as we walk the table.
    let mut v = &mut root.entries[vpn[2]];
    // Now, we're going to traverse the page table and set the bits
    // properly. We expect the root to be valid, however we're required to
    // create anything beyond the root.
    // In Rust, we create a range iterator using the .. operator.
    // The .rev() will reverse the iteration since we need to start with
    // VPN[2] The .. operator is inclusive on start but exclusive on end.
    // So, (0..2) will iterate 0 and 1.
    for i in (level..2).rev() {
        if !v.is_valid() {
            // Allocate a page
            let page = zalloc(1);
            // The page is already aligned by 4,096, so store it
            // directly The page is stored in the entry shifted
            // right by 2 places.
            v.set_entry(
                (page as i64 >> 2)
                    | EntryBits::Valid.val(),
            );
        }
        let entry = ((v.get_entry() & !0x3ff) << 2) as *mut Entry;
        v = unsafe { entry.add(vpn[i]).as_mut().unwrap() };
    }
    // When we get here, we should be at VPN[0] and v should be pointing to
    // our entry.
    // The entry structure is Figure 4.18 in the RISC-V Privileged
    // Specification
    let entry = (ppn[2] << 28) as i64 |   // PPN[2] = [53:28]
        (ppn[1] << 19) as i64 |   // PPN[1] = [27:19]
        (ppn[0] << 10) as i64 |   // PPN[0] = [18:10]
        bits |                    // Specified bits, such as User, Read, Write, etc
        EntryBits::Valid.val();   // Valid bit
    // Set the entry. V should be set to the correct pointer by the loop
    // above.
    v.set_entry(entry);
}

/// Unmaps and frees all memory associated with a table.
/// root: The root table to start freeing.
/// NOTE: This does NOT free root directly. This must be
/// freed manually.
/// The reason we don't free the root is because it is
/// usually embedded into the Process structure.
pub fn unmap(root: &mut Table) {
    // Start with level 2
    for lv2 in 0..Table::len() {
        let ref entry_lv2 = root.entries[lv2];
        if entry_lv2.is_valid() && entry_lv2.is_branch() {
            // This is a valid entry, so drill down and free.
            let memaddr_lv1 = (entry_lv2.get_entry() & !0x3ff) << 2;
            let table_lv1 = unsafe {
                // Make table_lv1 a mutable reference instead of a pointer.
                (memaddr_lv1 as *mut Table).as_mut().unwrap()
            };
            for lv1 in 0..Table::len() {
                let ref entry_lv1 = table_lv1.entries[lv1];
                if entry_lv1.is_valid() && entry_lv1.is_branch()
                {
                    let memaddr_lv0 = (entry_lv1.get_entry()
                        & !0x3ff) << 2;
                    // The next level is level 0, which
                    // cannot have branches, therefore,
                    // we free here.
                    dealloc(memaddr_lv0 as *mut u8);
                }
            }
            dealloc(memaddr_lv1 as *mut u8);
        }
    }
}

/// Walk the page table to convert a virtual address to a
/// physical address.
/// If a page fault would occur, this returns None
/// Otherwise, it returns Some with the physical address.
pub fn virt_to_phys(root: &Table, vaddr: usize) -> Option<usize> {
    // Walk the page table pointed to by root
    let vpn = [
        // VPN[0] = vaddr[20:12]
        (vaddr >> 12) & 0x1ff,
        // VPN[1] = vaddr[29:21]
        (vaddr >> 21) & 0x1ff,
        // VPN[2] = vaddr[38:30]
        (vaddr >> 30) & 0x1ff,
    ];

    let mut v = &root.entries[vpn[2]];
    for i in (0..=2).rev() {
        if v.is_invalid() {
            // This is an invalid entry, page fault.
            break;
        }
        else if v.is_leaf() {
            // According to RISC-V, a leaf can be at any level.

            // The offset mask masks off the PPN. Each PPN is 9
            // bits and they start at bit #12. So, our formula
            // 12 + i * 9
            let off_mask = (1 << (12 + i * 9)) - 1;
            let vaddr_pgoff = vaddr & off_mask;
            let addr = ((v.get_entry() << 2) as usize) & !off_mask;
            return Some(addr | vaddr_pgoff);
        }
        // Set v to the next entry which is pointed to by this
        // entry. However, the address was shifted right by 2 places
        // when stored in the page table entry, so we shift it left
        // to get it back into place.
        let entry = ((v.get_entry() & !0x3ff) << 2) as *const Entry;
        // We do i - 1 here, however we should get None or Some() above
        // before we do 0 - 1 = -1.
        v = unsafe { entry.add(vpn[i - 1]).as_ref().unwrap() };
    }

    // If we get here, we've exhausted all valid tables and haven't
    // found a leaf.
    None
}

/// Identity map range
/// Takes a contiguous allocation of memory and maps it using PAGE_SIZE
/// This assumes that start <= end
pub fn id_map_range(root: &mut Table,
                    start: usize,
                    end: usize,
                    bits: i64)
{
    let mut memaddr = start & !(PAGE_SIZE - 1);
    let num_kb_pages = (align_val(end, 12)
        - memaddr)
        / PAGE_SIZE;

    // I named this num_kb_pages for future expansion when
    // I decide to allow for GiB (2^30) and 2MiB (2^21) page
    // sizes. However, the overlapping memory regions are causing
    // nightmares.
    for _ in 0..num_kb_pages {
        map(root, memaddr, memaddr, bits, 0);
        memaddr += 1 << 12;
    }
}

pub fn paging_init() {
    //----------paging ---------------
    let root_ptr = alloc(1) as *mut Table ;
    let mut root = unsafe { root_ptr.as_mut().unwrap() };

    id_map_range(
        &mut root,
        0x80000000,
        0x80600000,
        EntryBits::ReadWriteExecute.val(),
    );

    use riscv::register::satp;
    // satp= table / 4096  |  Sv39 mode
    let satp = root_ptr as *const Table  as usize >>12 |(8 << 60);
    unsafe {
        satp::write(satp);
        llvm_asm!("sfence.vma" :::: "volatile");
    }
}
//----------------trap handling------------------------
use riscv::register::{
    mtvec::TrapMode,
    scause::{self, Exception, Trap},
    sstatus::{self, Sstatus, SPP},
    stval, stvec,sepc,
};

// TrapContext needs 34*8 bytes
#[repr(C)]
pub struct TrapContext {
    pub x: [usize; 32],
    pub sstatus: Sstatus,
    pub sepc: usize,
}

impl TrapContext {
    pub fn set_sp(&mut self, sp: usize) {
        self.x[2] = sp;  //x2 reg is sp reg
    }
    pub fn app_init_context(entry: usize, sp: usize) -> Self {
        let mut sstatus = sstatus::read();
        sstatus.set_spp(SPP::User);
        let mut cx = Self {
            x: [0; 32],
            sstatus,
            sepc: entry,
        };
        cx.set_sp(sp);
        cx
    }
}

// __alltraps & __restore functions
global_asm!(include_str!("trap.S"));

pub fn trap_init() {
    extern "C" {
        fn __alltraps(); //in trap.S
    }
    unsafe {
        stvec::write(__alltraps as usize, TrapMode::Direct);
    }
}


#[no_mangle]
pub fn trap_handler(cx: &mut TrapContext) -> &mut TrapContext {
    let scause = scause::read();
    let stval = stval::read();
    let sepc = sepc::read();

    match scause.cause() {
        Trap::Exception(Exception::Breakpoint) => {
            println!("[kernel] trap_handler {:?}, stval = {:#x}, sepc = {:#x}",
            scause.cause(),stval, sepc);
            cx.sepc += 2; //compact instr, so pc+=2
        }
        _ => {
            panic!(
                "Unsupported trap {:?}, stval = {:#x}, sepc = {:#x}",
                scause.cause(),
                stval, sepc
            );
        }
    }
    cx
}

//---------------- do syscall -------------------------
const FD_STDOUT: usize = 1;

pub fn do_write(fd: usize, buf: *const u8, len: usize) -> isize {
    match fd {
        FD_STDOUT => {
            let slice = unsafe { core::slice::from_raw_parts(buf, len) };
            let str = core::str::from_utf8(slice).unwrap();
            print!("{}", str);
            len as isize
        }
        _ => {
            panic!("Unsupported fd in sys_write!");
        }
    }
}

pub fn do_exit(exit_code: i32) -> ! {
    println!("[kernel] Application exited with code {}", exit_code);
    panic!("System down");
}

pub fn do_syscall(syscall_id: usize, args: [usize; 3]) -> isize {
    match syscall_id {
        SYSCALL_WRITE => do_write(args[0], args[1] as *const u8, args[2]),
        SYSCALL_EXIT => do_exit(args[0] as i32),
        _ => panic!("Unsupported syscall_id: {}", syscall_id),
    }
}

//================  run userapp ===================================
const USER_STACK_SIZE: usize = 4096 * 2;
const KERNEL_STACK_SIZE: usize = 4096 * 2;

#[repr(align(4096))]
struct KernelStack {
    data: [u8; KERNEL_STACK_SIZE],
}

#[repr(align(4096))]
struct UserStack {
    data: [u8; USER_STACK_SIZE],
}

static KERNEL_STACK: KernelStack = KernelStack {
    data: [0; KERNEL_STACK_SIZE],
};
static USER_STACK: UserStack = UserStack {
    data: [0; USER_STACK_SIZE],
};

impl KernelStack {
    fn get_sp(&self) -> usize {
        self.data.as_ptr() as usize + KERNEL_STACK_SIZE
    }
    pub fn push_context(&self, cx: TrapContext) -> &'static mut TrapContext {
        let cx_ptr = (self.get_sp() - core::mem::size_of::<TrapContext>()) as *mut TrapContext;
        unsafe {
            *cx_ptr = cx;
        }
        unsafe { cx_ptr.as_mut().unwrap() }
    }
}

impl UserStack {
    fn get_sp(&self) -> usize {
        self.data.as_ptr() as usize + USER_STACK_SIZE
    }
}

pub fn run_usrapp() -> ! {
    extern "C" {
        fn __restore(cx_addr: usize); //in trap.S
    }
    unsafe {
        __restore(KERNEL_STACK.push_context(TrapContext::app_init_context(
            usr_app_main as usize,
            USER_STACK.get_sp(),
        )) as *const _ as usize);
    }
    panic!("Unreachable in batch::run_current_app!");
}
//-------------------------------------------------------

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
    println!("syscall-fn {:#x}", syscall as usize);
    println!("sys_exit-fn {:#x}", sys_exit as usize);
    //----page-grained allocation-------------------
    unsafe {
        HEAP_START=ekernel as usize +4096;
        HEAP_SIZE = user_begin as usize - HEAP_START;
        println!("HEAP_START {:#x}, HEAP_SIZE {:#x}", HEAP_START, HEAP_SIZE);
    }
    page_allocator_init();
    test_page_allocation();

    paging_init();

    trap_init();
    //------------- test trap handler ----------------------
    unsafe {
        llvm_asm!("ebreak"
            : : : :
        );
    }
    //------------- test trap handler ----------------------
    
    //--------------- test paging code -------------------
    // let ptr = 0x80600000 as *const u8;
    // unsafe{ let c = *ptr; println!("{}",c); }
    //--------------- test paging code -------------------

    run_usrapp();

    panic!("\n[kernel] END: It should shutdown!");
}

//======================= USR MODE APP =========================
//========= usr mode syscall ==============
#[no_mangle]
#[link_section=".usrapp.entry"]
fn syscall(id: usize, args: [usize; 3]) -> isize {
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

#[no_mangle]
#[link_section=".usrapp.entry"]
pub fn sys_exit(xstate: i32) -> isize {
    syscall(SYSCALL_EXIT, [xstate as usize, 0, 0])
}

#[no_mangle]
#[link_section=".usrapp.entry"]
pub fn sys_write(fd: usize, buffer: &[u8]) -> isize {
    syscall(SYSCALL_WRITE, [fd, buffer.as_ptr() as usize, buffer.len()])
}

//=============== usr mode console ==================
struct Ustdout;


impl Write for Ustdout {
#[no_mangle]
#[link_section=".usrapp.entry"]
    fn write_str(&mut self, s: &str) -> fmt::Result {
        sys_write(STDOUT, s.as_bytes());
        Ok(())
    }
}

#[no_mangle]
#[link_section=".usrapp.entry"]
pub fn uconsole_print(args: fmt::Arguments) {
    Ustdout.write_fmt(args).unwrap();
}

#[macro_export]
macro_rules! uprint {
    ($fmt: literal $(, $($arg: tt)+)?) => {
        uconsole_print(format_args!($fmt $(, $($arg)+)?));
    }
}

#[macro_export]
macro_rules! uprintln {
    ($fmt: literal $(, $($arg: tt)+)?) => {
        uconsole_print(format_args!(concat!($fmt, "\n") $(, $($arg)+)?));
    }
}

//================ userapp main =============================
#[no_mangle]
#[link_section = ".usrapp.entry"]
extern "C" fn usr_app_main() {
    uprintln!("Usrapp: Hello, world!");
    sys_exit(9);
}

