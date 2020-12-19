use super::{
    BlockDevice,
    BLOCK_SZ,
    BlockCache,
    get_block_cache,
};
use alloc::sync::Arc;
use core::marker::PhantomData;

pub struct Dirty<T> {
    block_cache: Arc<BlockCache>,
    offset: usize,
    phantom: PhantomData<T>,
}

impl<T> Dirty<T> where T: Sized {
    pub fn new(block_id: usize, offset: usize, block_device: Arc<dyn BlockDevice>) -> Self {
        Self {
            block_cache: get_block_cache(block_id, block_device.clone()),
            offset,
            phantom: PhantomData,
        }
    }
    pub fn get_mut(&mut self) -> &mut T {
        let type_size = core::mem::size_of::<T>();
        // assert that the struct is inside a block
        assert!(self.offset + type_size <= BLOCK_SZ);
        let start_addr = self.block_cache.start_addr(self.offset);
        unsafe { &mut *(start_addr as *mut T) }
    }
    pub fn get_ref(&self) -> &T {
        let type_size = core::mem::size_of::<T>();
        // assert that the struct is inside a block
        assert!(self.offset + type_size <= BLOCK_SZ);
        let start_addr = self.block_cache.start_addr(self.offset);
        unsafe { &*(start_addr as *const T) }
    }
    pub fn read<V>(&self, f: impl FnOnce(&T) -> V) -> V {
        f(self.get_ref())
    }
    pub fn modify(&mut self, f: impl FnOnce(&mut T)) {
        f(self.get_mut());
    }
}
