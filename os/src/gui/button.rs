use alloc::{sync::Arc, string::String};
use embedded_graphics::{prelude::{Size, Point, Primitive, RgbColor, Dimensions}, primitives::{Rectangle, PrimitiveStyle}, pixelcolor::Rgb888, Drawable, text::{Text, Alignment}, mono_font::{ascii::{FONT_6X10, FONT_10X20}, MonoTextStyle}};

use crate::{sync::UPIntrFreeCell, drivers::GPU_DEVICE};

use super::{Component, Graphics};

pub struct Button {
    inner: UPIntrFreeCell<ButtonInner>
}

pub struct ButtonInner {
    graphic: Graphics,
    text: String,
    parent: Option<Arc<dyn Component>>
}

impl Button {
    pub fn new(size: Size, point: Point, parent: Option<Arc<dyn Component>>,text:String) -> Self {
        let point = match &parent {
            Some(p) => {
                let (_, p) = p.bound();
                Point::new(p.x + point.x,p.y + point.y)
            },
            None => point,
        };
        Self {
            inner: unsafe {
                UPIntrFreeCell::new(
                    ButtonInner {
                        graphic: Graphics { size, point, drv:GPU_DEVICE.clone() },
                        text,
                        parent,
                    }
                )
            }
        }
    }
}

impl Component for Button {
    fn paint(&self) {
        let mut inner = self.inner.exclusive_access();
        let text = inner.text.clone();
        Text::with_alignment(
            text.as_str(),
            inner.graphic.bounding_box().center(), 
            MonoTextStyle::new(&FONT_10X20, Rgb888::BLACK), 
            Alignment::Center
        ).draw(&mut inner.graphic);
    }

    fn add(&self, comp: alloc::sync::Arc<dyn Component>) {
        unreachable!()
    }

    fn bound(&self) -> (embedded_graphics::prelude::Size, embedded_graphics::prelude::Point) {
        let inner = self.inner.exclusive_access();
        (inner.graphic.size, inner.graphic.point)
    }
}