use super::BlockDevice;
use super::BLOCK_SZ;
use alloc::sync::Arc;
use core::marker::PhantomData;

pub struct Dirty<T> {
    block_id: usize,
    block_cache: [u8; BLOCK_SZ],
    offset: usize,
    dirty: bool,
    block_device: Arc<dyn BlockDevice>,
    phantom: PhantomData<T>,
}

impl<T> Dirty<T> where T: Sized {
    pub fn new(block_id: usize, offset: usize, block_device: Arc<dyn BlockDevice>) -> Self {
        Self {
            block_id,
            block_cache: {
                let mut cache = [0u8; BLOCK_SZ];
                block_device.read_block(block_id as usize, &mut cache);
                cache
            },
            offset,
            dirty: false,
            block_device,
            phantom: PhantomData,
        }
    }
    pub fn get_mut(&mut self) -> &mut T {
        self.dirty = true;
        let type_size = core::mem::size_of::<T>();
        // assert that the struct is inside a block
        assert!(self.offset + type_size <= BLOCK_SZ);
        let start_addr = &self.block_cache[self.offset] as *const _ as usize;
        unsafe { &mut *(start_addr as *mut T) }
    }
    pub fn get_ref(&self) -> &T {
        let type_size = core::mem::size_of::<T>();
        // assert that the struct is inside a block
        assert!(self.offset + type_size <= BLOCK_SZ);
        let start_addr = &self.block_cache[self.offset] as *const _ as usize;
        unsafe { &*(start_addr as *const T) }
    }
    pub fn read<V>(&self, f: impl FnOnce(&T) -> V) -> V {
        f(self.get_ref())
    }
    pub fn modify(&mut self, f: impl FnOnce(&mut T)) {
        f(self.get_mut());
    }
    pub fn write_back(&mut self) {
        if self.dirty {
            self.block_device
                .write_block(self.block_id as usize, &self.block_cache);
        }
    }
}

impl<T> Drop for Dirty<T> {
    fn drop(&mut self) {
        self.write_back();
    }
}