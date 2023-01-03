use super::Graphics;
use crate::sync::UPIntrFreeCell;
use embedded_graphics::pixelcolor::Rgb888;
use embedded_graphics::prelude::{Drawable, Point, RgbColor, Size};
use embedded_graphics::primitives::Primitive;
use embedded_graphics::primitives::{PrimitiveStyle, Rectangle};
use lazy_static::*;

const INIT_X: i32 = 640;
const INIT_Y: i32 = 400;
const RECT_SIZE: u32 = 40;

pub struct DrawingBoard {
    graphics: Graphics,
    latest_pos: Point,
}

impl DrawingBoard {
    pub fn new() -> Self {
        Self {
            graphics: Graphics::new(Size::new(1280, 800), Point::new(0, 0)),
            latest_pos: Point::new(INIT_X, INIT_Y),
        }
    }
    fn paint(&mut self) {
        Rectangle::with_center(self.latest_pos, Size::new(RECT_SIZE, RECT_SIZE))
            .into_styled(PrimitiveStyle::with_stroke(Rgb888::WHITE, 1))
            .draw(&mut self.graphics)
            .ok();
    }
    fn unpaint(&mut self) {
        Rectangle::with_center(self.latest_pos, Size::new(RECT_SIZE, RECT_SIZE))
            .into_styled(PrimitiveStyle::with_stroke(Rgb888::BLACK, 1))
            .draw(&mut self.graphics)
            .ok();
    }
    pub fn move_rect(&mut self, dx: i32, dy: i32) {
        self.unpaint();
        self.latest_pos.x += dx;
        self.latest_pos.y += dy;
        self.paint();
    }
    pub fn reset(&mut self) {
        self.latest_pos = Point::new(INIT_X, INIT_Y);
        self.graphics.reset();
    }
}

lazy_static! {
    pub static ref DRAWING_BOARD: UPIntrFreeCell<DrawingBoard> = unsafe { UPIntrFreeCell::new(DrawingBoard::new()) };
}

pub fn init_paint() {
    DRAWING_BOARD.exclusive_session(|ripple| {
        ripple.paint();
    });
}

pub fn move_rect(dx: i32, dy: i32) {
    DRAWING_BOARD.exclusive_session(|ripple| {
        ripple.move_rect(dx, dy);
    });
}

pub fn reset() {
    DRAWING_BOARD.exclusive_session(|ripple| {
        ripple.reset();
    });
}
