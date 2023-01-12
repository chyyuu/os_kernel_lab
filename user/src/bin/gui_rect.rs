#![no_std]
#![no_main]

extern crate user_lib;
extern crate alloc;

use user_lib::{VIRTGPU_XRES, VIRTGPU_YRES, Display};

use embedded_graphics::pixelcolor::Rgb888;
use embedded_graphics::prelude::{DrawTarget, Drawable, Point, RgbColor, Size};
use embedded_graphics::primitives::{Primitive, PrimitiveStyle, Rectangle};

const INIT_X: i32 = 640;
const INIT_Y: i32 = 400;
const RECT_SIZE: u32 = 40;

pub struct DrawingBoard {
    disp: Display,
    latest_pos: Point,
}

impl DrawingBoard {
    pub fn new() -> Self {
        Self {
            disp: Display::new(Size::new(VIRTGPU_XRES, VIRTGPU_YRES)),
            latest_pos: Point::new(INIT_X, INIT_Y),
        }
    }
    fn paint(&mut self) {
        Rectangle::with_center(self.latest_pos, Size::new(RECT_SIZE, RECT_SIZE))
            .into_styled(PrimitiveStyle::with_stroke(Rgb888::WHITE, 1))
            .draw(&mut self.disp)
            .ok();
    }
    fn unpaint(&mut self) {
        Rectangle::with_center(self.latest_pos, Size::new(RECT_SIZE, RECT_SIZE))
            .into_styled(PrimitiveStyle::with_stroke(Rgb888::BLACK, 1))
            .draw(&mut self.disp)
            .ok();
    }
    pub fn move_rect(&mut self, dx: i32, dy: i32) {
        self.unpaint();
        self.latest_pos.x += dx;
        self.latest_pos.y += dy;
        self.paint();
    }
}

#[no_mangle]
pub fn main() -> i32 {
    let mut board = DrawingBoard::new();
    let _ = board.disp.clear(Rgb888::BLACK).unwrap();
    for i in 0..20 {
        board.latest_pos.x += i;
        board.latest_pos.y += i;
        board.paint();
    }
    0
}
