use alloc::{collections::VecDeque, rc::Weak, sync::Arc};
use embedded_graphics::{
    pixelcolor::Rgb888,
    prelude::{Point, Primitive, RgbColor, Size},
    primitives::{PrimitiveStyle, Rectangle},
    Drawable,
};

use crate::{drivers::GPU_DEVICE, sync::UPIntrFreeCell};

use super::{Component, Graphics};

pub struct Panel {
    inner: UPIntrFreeCell<PanelInner>,
}
struct PanelInner {
    graphic: Graphics,
    comps: VecDeque<Arc<dyn Component>>,
}

impl Panel {
    pub fn new(size: Size, point: Point) -> Self {
        Self {
            inner: unsafe {
                UPIntrFreeCell::new(PanelInner {
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
}

impl Component for Panel {
    fn paint(&self) {
        let mut inner = self.inner.exclusive_access();

        Rectangle::new(Point::new(0, 0), inner.graphic.size)
            .into_styled(PrimitiveStyle::with_fill(Rgb888::WHITE))
            .draw(&mut inner.graphic)
            .unwrap();

        let len = inner.comps.len();
        drop(inner);
        for i in 0..len {
            let mut inner = self.inner.exclusive_access();
            let comp = Arc::downgrade(&inner.comps[i]);
            drop(inner);
            comp.upgrade().unwrap().paint();
        }
    }

    fn add(&self, comp: alloc::sync::Arc<dyn Component>) {
        let mut inner = self.inner.exclusive_access();
        inner.comps.push_back(comp);
    }

    fn bound(&self) -> (Size, Point) {
        let inner = self.inner.exclusive_access();
        (inner.graphic.size, inner.graphic.point)
    }
}
