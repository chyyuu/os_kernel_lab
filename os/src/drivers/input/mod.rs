use crate::drivers::bus::virtio::VirtioHal;
use crate::sync::UPIntrFreeCell;
use alloc::sync::Arc;
use core::any::Any;
use virtio_drivers::{VirtIOHeader, VirtIOInput};
use virtio_input_decoder::{Decoder, Key, KeyType};

const VIRTIO5: usize = 0x10005000;
const VIRTIO6: usize = 0x10006000;

struct VirtIOInputWrapper(UPIntrFreeCell<VirtIOInput<'static, VirtioHal>>);

pub trait InputDevice: Send + Sync + Any {
    fn handle_irq(&self);
}

lazy_static::lazy_static!(
    pub static ref KEYBOARD_DEVICE: Arc<dyn InputDevice> = Arc::new(VirtIOInputWrapper::new(VIRTIO5));
    pub static ref MOUSE_DEVICE: Arc<dyn InputDevice> = Arc::new(VirtIOInputWrapper::new(VIRTIO6));
);

impl VirtIOInputWrapper {
    pub fn new(addr: usize) -> Self {
        Self(unsafe {
            UPIntrFreeCell::new(
                VirtIOInput::<VirtioHal>::new(&mut *(addr as *mut VirtIOHeader)).unwrap(),
            )
        })
    }
}

impl InputDevice for VirtIOInputWrapper {
    fn handle_irq(&self) {
        let mut input = self.0.exclusive_access();
        input.ack_interrupt();
        while let Some(event) = input.pop_pending_event() {
            let dtype = match Decoder::decode(
                event.event_type as usize,
                event.code as usize,
                event.value as usize,
            ) {
                Ok(dtype) => dtype,
                Err(_) => break,
            };
            match dtype {
                virtio_input_decoder::DecodeType::Key(key, r#type) => {
                    if r#type == KeyType::Press {
                        match key {
                            _ => {}
                        }
                    }
                }
                _ => {}
            }
        }
    }
}
