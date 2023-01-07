use alloc::sync::Arc;
use embedded_graphics::{
    draw_target::DrawTarget,
    pixelcolor::Rgb888,
    prelude::{OriginDimensions, Point, RgbColor, Size},
};

use crate::board::VIRTGPU_XRES;
use crate::drivers::{GpuDevice, GPU_DEVICE};

#[derive(Clone)]
pub struct Graphics {
    pub size: Size,
    pub point: Point,
    pub drv: Arc<dyn GpuDevice>,
}

impl Graphics {
    pub fn new(size: Size, point: Point) -> Self {
        Self {
            size,
            point,
            drv: GPU_DEVICE.clone(),
        }
    }
    pub fn reset(&self) {
        let fb = self.drv.get_framebuffer();
        fb.fill(0u8);
    }

    pub fn get_framebuffer(&self)-> &mut [u8] {
        self.drv.get_framebuffer()
    }
}

impl OriginDimensions for Graphics {
    fn size(&self) -> Size {
        self.size
    }
}

impl DrawTarget for Graphics {
    type Color = Rgb888;

    type Error = core::convert::Infallible;

    fn draw_iter<I>(&mut self, pixels: I) -> Result<(), Self::Error>
    where
        I: IntoIterator<Item = embedded_graphics::Pixel<Self::Color>>,
    {
        let fb = self.drv.get_framebuffer();

        pixels.into_iter().for_each(|px| {
            let idx = ((self.point.y + px.0.y) * VIRTGPU_XRES as i32 + self.point.x + px.0.x)
                as usize
                * 4;
            if idx + 2 >= fb.len() {
                return;
            }
            fb[idx] = px.1.b();
            fb[idx + 1] = px.1.g();
            fb[idx + 2] = px.1.r();
        });
        self.drv.flush();
        Ok(())
    }
}
