use alloc::{
    collections::VecDeque,
    string::{String, ToString},
    sync::Arc,
};
use embedded_graphics::{
    mono_font::{ascii::FONT_10X20, MonoTextStyle},
    pixelcolor::Rgb888,
    prelude::{Dimensions, Point, Primitive, RgbColor, Size},
    primitives::{PrimitiveStyle, Rectangle},
    text::{Alignment, Text},
    Drawable,
};

use crate::{drivers::GPU_DEVICE, sync::UPIntrFreeCell};

use super::{button::Button, Component, Graphics, Panel};

pub struct Terminal {
    inner: UPIntrFreeCell<TerminalInner>,
}

pub struct TerminalInner {
    pub text: String,
    titel: Option<String>,
    graphic: Graphics,
    comps: VecDeque<Arc<dyn Component>>,
}

impl Terminal {
    pub fn new(
        size: Size,
        point: Point,
        parent: Option<Arc<dyn Component>>,
        titel: Option<String>,
        text: String,
    ) -> Self {
        Self {
            inner: unsafe {
                UPIntrFreeCell::new(TerminalInner {
                    text,
                    titel,
                    graphic: Graphics {
                        size,
                        point,
                        drv: GPU_DEVICE.clone(),
                    },
                    comps: VecDeque::new(),
                })
            },
        }
    }

    pub fn repaint(&self, text: String) {
        let mut inner = self.inner.exclusive_access();
        inner.text += text.as_str();
        Text::with_alignment(
            inner.text.clone().as_str(),
            Point::new(20, 50),
            MonoTextStyle::new(&FONT_10X20, Rgb888::BLACK),
            Alignment::Left,
        )
        .draw(&mut inner.graphic);
    }
}

impl Component for Terminal {
    fn paint(&self) {
        let mut inner = self.inner.exclusive_access();
        let len = inner.comps.len();
        drop(inner);
        for i in 0..len {
            let mut inner = self.inner.exclusive_access();
            let comp = Arc::downgrade(&inner.comps[i]);
            drop(inner);
            comp.upgrade().unwrap().paint();
        }
        let mut inner = self.inner.exclusive_access();
        let titel = inner.titel.get_or_insert("No Titel".to_string()).clone();
        let text = Text::new(
            titel.as_str(),
            Point::new(20, 20),
            MonoTextStyle::new(&FONT_10X20, Rgb888::BLACK),
        );
        text.draw(&mut inner.graphic);

        Text::with_alignment(
            inner.text.clone().as_str(),
            Point::new(20, 50),
            MonoTextStyle::new(&FONT_10X20, Rgb888::BLACK),
            Alignment::Left,
        )
        .draw(&mut inner.graphic);
    }

    fn add(&self, comp: Arc<dyn Component>) {
        let mut inner = self.inner.exclusive_access();
        inner.comps.push_back(comp);
    }

    fn bound(&self) -> (Size, Point) {
        let inner = self.inner.exclusive_access();
        (inner.graphic.size, inner.graphic.point)
    }
}
