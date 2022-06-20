use crate::sync::UPIntrFreeCell;
use alloc::{sync::Arc, vec::Vec};
use core::any::Any;
use embedded_graphics::pixelcolor::Rgb888;
use tinybmp::Bmp;
use virtio_drivers::{VirtIOGpu, VirtIOHeader};
const VIRTIO7: usize = 0x10007000;
pub trait GPUDevice: Send + Sync + Any {
    fn update_cursor(&self);
    fn getfreambuffer(&self) -> &mut [u8];
    fn flush(&self);
}

lazy_static::lazy_static!(
    pub static ref GPU_DEVICE: Arc<dyn GPUDevice> = Arc::new(VirtIOGPU::new());
);

pub struct VirtIOGPU {
    gpu: UPIntrFreeCell<VirtIOGpu<'static>>,
    fb: &'static [u8],
}
static BMP_DATA: &[u8] = include_bytes!("../../assert/mouse.bmp");
impl VirtIOGPU {
    pub fn new() -> Self {
        unsafe {
            let mut virtio = VirtIOGpu::new(&mut *(VIRTIO7 as *mut VirtIOHeader)).unwrap();

            let fbuffer = virtio.setup_framebuffer().unwrap();
            let len = fbuffer.len();
            let ptr = fbuffer.as_mut_ptr();
            let fb = core::slice::from_raw_parts_mut(ptr, len);

            let bmp = Bmp::<Rgb888>::from_slice(BMP_DATA).unwrap();
            let raw = bmp.as_raw();
            let mut b = Vec::new();
            for i in raw.image_data().chunks(3) {
                let mut v = i.to_vec();
                b.append(&mut v);
                if i == [255, 255, 255] {
                    b.push(0x0)
                } else {
                    b.push(0xff)
                }
            }
            virtio.setup_cursor(b.as_slice(), 50, 50, 50, 50).unwrap();

            Self {
                gpu: UPIntrFreeCell::new(virtio),
                fb,
            }
        }
    }
}

impl GPUDevice for VirtIOGPU {
    fn flush(&self) {
        self.gpu.exclusive_access().flush().unwrap();
    }
    fn getfreambuffer(&self) -> &mut [u8] {
        unsafe {
            let ptr = self.fb.as_ptr() as *const _ as *mut u8;
            core::slice::from_raw_parts_mut(ptr, self.fb.len())
        }
    }
    fn update_cursor(&self) {}
}
