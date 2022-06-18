mod graphic;
mod image;
mod panel;
mod icon;
mod button;
mod terminal;
use alloc::sync::Arc;
use embedded_graphics::prelude::{Size, Point};
use core::any::Any;
pub use graphic::*;
pub use panel::*;
pub use image::*;
pub use icon::*;
pub use terminal::*;
pub use button::*;

pub trait Component: Send + Sync + Any {
    fn paint(&self);
    fn add(&self, comp: Arc<dyn Component>);
    fn bound(&self) -> (Size, Point);
}
