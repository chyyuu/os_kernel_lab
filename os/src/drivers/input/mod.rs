use crate::drivers::bus::virtio::VirtioHal;
use crate::sync::{Condvar, UPIntrFreeCell};
use crate::task::schedule;
use alloc::collections::VecDeque;
use alloc::sync::Arc;
use core::any::Any;
use virtio_drivers::{VirtIOHeader, VirtIOInput};

const VIRTIO5: usize = 0x10005000;
const VIRTIO6: usize = 0x10006000;

struct VirtIOInputInner {
    virtio_input: VirtIOInput<'static, VirtioHal>,
    events: VecDeque<u64>,
}

struct VirtIOInputWrapper {
    inner: UPIntrFreeCell<VirtIOInputInner>,
    //condvars: BTreeMap<u16, Condvar>,
    //condvar: Arc::<Condvar> ,
    condvar:Condvar,
}

pub trait InputDevice: Send + Sync + Any {
    fn read_event(&self) -> u64;
    fn handle_irq(&self);
    // fn events(&self) -> &VecDeque<u64>;
    fn is_empty(&self) -> bool;
}

lazy_static::lazy_static!(
    pub static ref KEYBOARD_DEVICE: Arc<dyn InputDevice> = Arc::new(VirtIOInputWrapper::new(VIRTIO5));
    pub static ref MOUSE_DEVICE: Arc<dyn InputDevice> = Arc::new(VirtIOInputWrapper::new(VIRTIO6));
    // pub static ref INPUT_CONDVAR: Arc::<Condvar> = Arc::new(Condvar::new());
);

// from virtio-drivers/src/input.rs
//const QUEUE_SIZE: u16 = 32;
// pub fn read_input_event() -> u64 {
//     loop {
        
//         //let mut inner = self.inner.exclusive_access();
//         let kb=KEYBOARD_DEVICE.clone();
//         let evs = kb.events();
//         if let Some(event) = evs.pop_front() {
//             return event;
//         } else {
//             let task_cx_ptr = INPUT_CONDVAR.clone().wait_no_sched();
//             drop(inner);
//             schedule(task_cx_ptr);
//         }
//     }
// }
impl VirtIOInputWrapper {
    pub fn new(addr: usize) -> Self {
        let inner = VirtIOInputInner {
            virtio_input: unsafe {
                VirtIOInput::<VirtioHal>::new(&mut *(addr as *mut VirtIOHeader)).unwrap()
            },
            events: VecDeque::new(),
        };

        // let mut condvars = BTreeMap::new();
        // let channels = QUEUE_SIZE;
        // for i in 0..channels {
        //     let condvar = Condvar::new();
        //     condvars.insert(i, condvar);
        // }

        Self {
            inner: unsafe { UPIntrFreeCell::new(inner) },
            //condvar: INPUT_CONDVAR.clone(),
            condvar: Condvar::new(),
        }
    }
}

impl InputDevice for VirtIOInputWrapper {
    fn is_empty(&self) -> bool {
        self.inner.exclusive_access().events.is_empty()
    }

    fn read_event(&self) -> u64 {
        loop {
            let mut inner = self.inner.exclusive_access();
            if let Some(event) = inner.events.pop_front() {
                return event;
            } else {
                let task_cx_ptr = self.condvar.wait_no_sched();
                drop(inner);
                schedule(task_cx_ptr);
            }
        }
    }

    // fn events(&self) -> &VecDeque<u64> {
    //     &self.inner.exclusive_access().events
    // }

    fn handle_irq(&self) {
        let mut count = 0;
        let mut result = 0;
        let mut key = 0;
        self.inner.exclusive_session(|inner| {
            inner.virtio_input.ack_interrupt();
            while let Some((token, event)) = inner.virtio_input.pop_pending_event() {
                count += 1;
                key = token;
                result = (event.event_type as u64) << 48
                    | (event.code as u64) << 32
                    | (event.value) as u64;
                inner.events.push_back(result);
                // for test
                //println!("[KERN] inputdev_handle_irq: event: {:x}", result);
            }
        });
        if count > 0 {
            //self.condvars.get(&key).unwrap().signal();
            self.condvar.signal();
        };
    }
}
