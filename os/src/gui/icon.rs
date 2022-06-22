use alloc::{string::String, sync::Arc, vec::Vec};
use embedded_graphics::{
    image::Image,
    mono_font::{ascii::FONT_10X20, iso_8859_13::FONT_6X12, MonoTextStyle},
    pixelcolor::Rgb888,
    prelude::{Point, RgbColor, Size},
    text::Text,
    Drawable,
};
use tinybmp::Bmp;

use crate::{drivers::GPU_DEVICE, sync::UPIntrFreeCell};
use crate::board::{VIRTGPU_XRES, VIRTGPU_YRES};
use super::{Component, Graphics, ImageComp};

static FILEICON: &[u8] = include_bytes!("../assert/file.bmp");

pub struct IconController {
    inner: UPIntrFreeCell<IconControllerInner>,
}

pub struct IconControllerInner {
    files: Vec<String>,
    graphic: Graphics,
    parent: Option<Arc<dyn Component>>,
}

impl IconController {
    pub fn new(files: Vec<String>, parent: Option<Arc<dyn Component>>) -> Self {
        IconController {
            inner: unsafe {
                UPIntrFreeCell::new(IconControllerInner {
                    files,
                    graphic: Graphics {
                        size: Size::new(VIRTGPU_XRES, VIRTGPU_YRES),
                        point: Point::new(0, 0),
                        drv: GPU_DEVICE.clone(),
                    },
                    parent,
                })
            },
        }
    }
}

impl Component for IconController {
    fn paint(&self) {
        println!("demo");
        let mut inner = self.inner.exclusive_access();
        let mut x = 10;
        let mut y = 10;
        let v = inner.files.clone();
        for file in v {
            println!("file");
            let bmp = Bmp::<Rgb888>::from_slice(FILEICON).unwrap();
            Image::new(&bmp, Point::new(x, y)).draw(&mut inner.graphic);
            let text = Text::new(
                file.as_str(),
                Point::new(x + 20, y + 80),
                MonoTextStyle::new(&FONT_10X20, Rgb888::BLACK),
            );
            text.draw(&mut inner.graphic);
            if y >= 600 {
                x = x + 70;
                y = 10;
            } else {
                y = y + 90;
            }
        }
    }

    fn add(&self, comp: Arc<dyn Component>) {
        todo!()
    }

    fn bound(&self) -> (Size, Point) {
        todo!()
    }
}
