mod button;
mod graphic;
mod icon;
mod image;
mod panel;
mod terminal;
use alloc::sync::Arc;
pub use button::*;
use core::any::Any;
use embedded_graphics::prelude::{Point, Size};
pub use graphic::*;
pub use icon::*;
pub use image::*;
pub use panel::*;
pub use terminal::*;

pub trait Component: Send + Sync + Any {
    fn paint(&self);
    fn add(&self, comp: Arc<dyn Component>);
    fn bound(&self) -> (Size, Point);
}
