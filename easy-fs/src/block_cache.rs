use super::{
    BlockDevice,
    BLOCK_SZ,
};
use alloc::sync::{Arc, Weak};
use alloc::collections::BTreeMap;
use lazy_static::*;
use spin::Mutex;

pub struct BlockCache {
    cache: [u8; BLOCK_SZ],
    block_id: usize,
    block_device: Arc<dyn BlockDevice>,
}

impl BlockCache {
    pub fn new(block_id: usize, block_device: Arc<dyn BlockDevice>) -> Self {
        let mut cache = [0u8; BLOCK_SZ];
        block_device.read_block(block_id, &mut cache);
        Self {
            cache,
            block_id,
            block_device,
        }
    }
    pub fn start_addr(&self, offset: usize) -> usize {
        &self.cache[offset] as *const _ as usize
    }
}

impl Drop for BlockCache {
    fn drop(&mut self) {
        // write back
        self.block_device.write_block(self.block_id, &self.cache);
        // invalid in block cache manager
        BLOCK_CACHE_MANAGER.lock().invalid(self.block_id);
    }
}

pub struct BlockCacheManager {
    map: BTreeMap<usize, Weak<BlockCache>>,
}

lazy_static! {
    static ref BLOCK_CACHE_MANAGER: Mutex<BlockCacheManager> = Mutex::new(
        BlockCacheManager::new()
    );
}

impl BlockCacheManager {
    pub fn new() -> Self {
        Self { map: BTreeMap::new() }
    }
    pub fn get(
        &mut self,
        block_id: usize,
        block_device: Arc<dyn BlockDevice>
    ) -> Arc<BlockCache> {
        if let Some(block_cache) = self.map.get(&block_id) {
            // return cloned
            block_cache.upgrade().unwrap().clone()
        } else {
            // fetch from disk
            let block_cache = Arc::new(BlockCache::new(
                block_id,
                block_device.clone()
            ));
            self.map.insert(
                block_id,
                Arc::downgrade(&block_cache),
            );
            // return
            block_cache
        }
    }
    pub fn invalid(&mut self, block_id: usize) {
        assert!(self.map.remove(&block_id).is_some());
    }
}

pub fn get_block_cache(
    block_id: usize,
    block_device: Arc<dyn BlockDevice>
) -> Arc<BlockCache> {
    BLOCK_CACHE_MANAGER.lock().get(block_id, block_device)
}