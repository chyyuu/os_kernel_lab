use crate::{
    gui::{Button, Component},
    sync::UPIntrFreeCell,
    syscall::PAD,
};
use alloc::{string::ToString, sync::Arc};
use core::any::Any;
use embedded_graphics::{
    prelude::{Point, Size},
    text::Text,
};
use k210_hal::cache::Uncache;
use virtio_drivers::{VirtIOHeader, VirtIOInput};
use virtio_input_decoder::{Decoder, Key, KeyType};

use super::GPU_DEVICE;

const VIRTIO5: usize = 0x10005000;
const VIRTIO6: usize = 0x10006000;

struct VirtIOINPUT(UPIntrFreeCell<VirtIOInput<'static>>);

pub trait INPUTDevice: Send + Sync + Any {
    fn handle_irq(&self);
}

lazy_static::lazy_static!(
    pub static ref KEYBOARD_DEVICE: Arc<dyn INPUTDevice> = Arc::new(VirtIOINPUT::new(VIRTIO5));
    pub static ref MOUSE_DEVICE: Arc<dyn INPUTDevice> = Arc::new(VirtIOINPUT::new(VIRTIO6));
);

impl VirtIOINPUT {
    pub fn new(addr: usize) -> Self {
        Self(unsafe {
            UPIntrFreeCell::new(VirtIOInput::new(&mut *(addr as *mut VirtIOHeader)).unwrap())
        })
    }
}

impl INPUTDevice for VirtIOINPUT {
    fn handle_irq(&self) {
        let mut input = self.0.exclusive_access();
        input.ack_interrupt();
        let event = input.pop_pending_event().unwrap();
        let dtype = match Decoder::decode(
            event.event_type as usize,
            event.code as usize,
            event.value as usize,
        ) {
            Ok(dtype) => dtype,
            Err(_) => return,
        };
        match dtype {
            virtio_input_decoder::DecodeType::Key(key, r#type) => {
                println!("{:?} {:?}", key, r#type);
                if r#type == KeyType::Press {
                    let mut inner = PAD.exclusive_access();
                    let a = inner.as_ref().unwrap();
                    match key.to_char() {
                        Ok(mut k) => {
                            if k == '\r' {
                                a.repaint(k.to_string() + "\n")
                            } else {
                                a.repaint(k.to_string())
                            }
                        }
                        Err(_) => {}
                    }
                }
            }
            virtio_input_decoder::DecodeType::Mouse(mouse) => println!("{:?}", mouse),
        }
    }
}
