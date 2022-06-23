mod ns16550a;

#[cfg(feature = "board_qemu")]
use crate::board::CharDeviceImpl;
use alloc::sync::Arc;
use lazy_static::*;
pub use ns16550a::NS16550a;

pub trait CharDevice {
    fn read(&self) -> u8;
    fn write(&self, ch: u8);
    fn handle_irq(&self);
}
#[cfg(feature = "board_qemu")]
lazy_static! {
    pub static ref UART: Arc<CharDeviceImpl> = Arc::new(CharDeviceImpl::new());
}
