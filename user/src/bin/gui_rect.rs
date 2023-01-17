#![no_std]
#![no_main]

extern crate alloc;
extern crate user_lib;

use user_lib::{Display, VIRTGPU_XRES, VIRTGPU_YRES};

use embedded_graphics::pixelcolor::Rgb888;
use embedded_graphics::prelude::{DrawTarget, Drawable, Point, RgbColor, Size};
use embedded_graphics::primitives::{Circle, Primitive, PrimitiveStyle, Rectangle,Triangle};

const INIT_X: i32 = 80;
const INIT_Y: i32 = 400;
const RECT_SIZE: u32 = 150;

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
            .into_styled(PrimitiveStyle::with_stroke(Rgb888::RED, 10))
            .draw(&mut self.disp)
            .ok();
        Circle::new(self.latest_pos + Point::new(-70, -300), 150)
            .into_styled(PrimitiveStyle::with_fill(Rgb888::BLUE))
            .draw(&mut self.disp)
            .ok();
        Triangle::new(self.latest_pos + Point::new(0, 150), self.latest_pos + Point::new(80, 200), self.latest_pos + Point::new(-120, 300))
            .into_styled(PrimitiveStyle::with_stroke(Rgb888::GREEN, 10))
            .draw(&mut self.disp)
            .ok();
    }
    fn unpaint(&mut self) {
        Rectangle::with_center(self.latest_pos, Size::new(RECT_SIZE, RECT_SIZE))
            .into_styled(PrimitiveStyle::with_stroke(Rgb888::BLACK, 10))
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
    for i in 0..5 {
        board.latest_pos.x += (RECT_SIZE as i32 + 20);
        //board.latest_pos.y += i;
        board.paint();
    }
    0
}
