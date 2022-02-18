mod ns16550a;

pub use ns16550a::NS16550a;

use crate::board::CharDeviceImpl;
use alloc::sync::Arc;
use lazy_static::*;

pub trait CharDevice {
    fn read(&self) -> u8;
    fn write(&self, ch: u8);
    fn handle_irq(&self);
}

lazy_static! {
    pub static ref UART: Arc<CharDeviceImpl> = Arc::new(CharDeviceImpl::new());
}
