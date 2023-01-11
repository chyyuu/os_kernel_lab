#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;
extern crate alloc;

use user_lib::console::getchar;
use user_lib::{Display, key_pressed, sleep, VIRTGPU_XRES, VIRTGPU_YRES};

use embedded_graphics::pixelcolor::*;
use embedded_graphics::prelude::{Drawable, Point, RgbColor, Size};
use embedded_graphics::primitives::Primitive;
use embedded_graphics::primitives::{PrimitiveStyle, Rectangle};
use embedded_graphics::Pixel;
use embedded_graphics::{draw_target::DrawTarget, prelude::OriginDimensions};
use oorandom; //random generator

struct Snake<T: PixelColor, const MAX_SIZE: usize> {
    parts: [Pixel<T>; MAX_SIZE],
    len: usize,
    direction: Direction,
    size_x: u32,
    size_y: u32,
}

struct SnakeIntoIterator<'a, T: PixelColor, const MAX_SIZE: usize> {
    snake: &'a Snake<T, MAX_SIZE>,
    index: usize,
}

impl<'a, T: PixelColor, const MAX_SIZE: usize> IntoIterator for &'a Snake<T, MAX_SIZE> {
    type Item = Pixel<T>;
    type IntoIter = SnakeIntoIterator<'a, T, MAX_SIZE>;

    fn into_iter(self) -> Self::IntoIter {
        SnakeIntoIterator {
            snake: self,
            index: 0,
        }
    }
}

impl<'a, T: PixelColor, const MAX_SIZE: usize> Iterator for SnakeIntoIterator<'a, T, MAX_SIZE> {
    type Item = Pixel<T>;

    fn next(&mut self) -> Option<Self::Item> {
        let cur = self.snake.parts[self.index];
        if self.index < self.snake.len {
            self.index += 1;
            return Some(cur);
        }
        None
    }
}

impl<T: PixelColor, const MAX_SIZE: usize> Snake<T, MAX_SIZE> {
    fn new(color: T, size_x: u32, size_y: u32) -> Snake<T, MAX_SIZE> {
        Snake {
            parts: [Pixel::<T>(Point { x: 0, y: 0 }, color); MAX_SIZE],
            len: 1,
            direction: Direction::None,
            size_x,
            size_y,
        }
    }
    fn set_direction(&mut self, direction: Direction) {
        self.direction = direction;
    }
    fn contains(&self, this: Point) -> bool {
        for part in self.into_iter() {
            if part.0 == this {
                return true;
            };
        }
        false
    }
    fn grow(&mut self) {
        if self.len < MAX_SIZE - 1 {
            self.len += 1;
        }
    }
    fn make_step(&mut self) {
        let mut i = self.len;
        while i > 0 {
            self.parts[i] = self.parts[i - 1];
            i -= 1;
        }
        match self.direction {
            Direction::Left => {
                if self.parts[0].0.x == 0 {
                    self.parts[0].0.x = (self.size_x - 1) as i32;
                } else {
                    self.parts[0].0.x -= 1;
                }
            }
            Direction::Right => {
                if self.parts[0].0.x == (self.size_x - 1) as i32 {
                    self.parts[0].0.x = 0;
                } else {
                    self.parts[0].0.x += 1;
                }
            }
            Direction::Up => {
                if self.parts[0].0.y == 0 {
                    self.parts[0].0.y = (self.size_y - 1) as i32;
                } else {
                    self.parts[0].0.y -= 1;
                }
            }
            Direction::Down => {
                if self.parts[0].0.y == (self.size_y - 1) as i32 {
                    self.parts[0].0.y = 0;
                } else {
                    self.parts[0].0.y += 1;
                }
            }
            Direction::None => {}
        }
    }
}

struct Food<T: PixelColor> {
    size_x: u32,
    size_y: u32,
    place: Pixel<T>,
    rng: oorandom::Rand32,
}

impl<T: PixelColor> Food<T> {
    pub fn new(color: T, size_x: u32, size_y: u32) -> Self {
        let seed = 4;
        let rng = oorandom::Rand32::new(seed);
        Food {
            size_x,
            size_y,
            place: Pixel(Point { x: 0, y: 0 }, color),
            rng,
        }
    }
    fn replace<'a, const MAX_SIZE: usize>(&mut self, iter_source: &Snake<T, MAX_SIZE>) {
        let mut p: Point;
        'outer: loop {
            let random_number = self.rng.rand_u32();
            let blocked_positions = iter_source.into_iter();
            p = Point {
                x: ((random_number >> 24) as u16 % self.size_x as u16).into(),
                y: ((random_number >> 16) as u16 % self.size_y as u16).into(),
            };
            for blocked_position in blocked_positions {
                if p == blocked_position.0 {
                    continue 'outer;
                }
            }
            break;
        }
        self.place = Pixel::<T> {
            0: p,
            1: self.place.1,
        }
    }
    fn get_pixel(&self) -> Pixel<T> {
        self.place
    }
}

#[derive(PartialEq, Debug, Clone, Copy)]
pub enum Direction {
    Left,
    Right,
    Up,
    Down,
    None,
}

pub struct SnakeGame<const MAX_SNAKE_SIZE: usize, T: PixelColor> {
    snake: Snake<T, MAX_SNAKE_SIZE>,
    food: Food<T>,
    food_age: u32,
    food_lifetime: u32,
    size_x: u32,
    size_y: u32,
    scale_x: u32,
    scale_y: u32,
}

impl<const MAX_SIZE: usize, T: PixelColor> SnakeGame<MAX_SIZE, T> {
    pub fn new(
        size_x: u32,
        size_y: u32,
        scale_x: u32,
        scale_y: u32,
        snake_color: T,
        food_color: T,
        food_lifetime: u32,
    ) -> Self {
        let snake = Snake::<T, MAX_SIZE>::new(snake_color, size_x / scale_x, size_y / scale_y);
        let mut food = Food::<T>::new(food_color, size_x / scale_x, size_y / scale_y);
        food.replace(&snake);
        SnakeGame {
            snake,
            food,
            food_age: 0,
            food_lifetime,
            size_x,
            size_y,
            scale_x,
            scale_y,
        }
    }
    pub fn set_direction(&mut self, direction: Direction) {
        self.snake.set_direction(direction);
    }
    pub fn draw<D>(&mut self, target: &mut D) -> ()
    where
        D: DrawTarget<Color = T>,
    {
        self.snake.make_step();
        let hit = self.snake.contains(self.food.get_pixel().0);
        if hit {
            self.snake.grow();
        }
        self.food_age += 1;
        if self.food_age >= self.food_lifetime || hit {
            self.food.replace(&self.snake);
            self.food_age = 0;
        }

        let mut scaled_display = ScaledDisplay::<D> {
            real_display: target,
            size_x: self.size_x / self.scale_x,
            size_y: self.size_y / self.scale_y,
            scale_x: self.scale_x,
            scale_y: self.scale_y,
        };

        for part in self.snake.into_iter() {
            _ = part.draw(&mut scaled_display);
        }
        _ = self.food.get_pixel().draw(&mut scaled_display);
    }
}

/// A dummy DrawTarget implementation that can magnify each pixel so the user code does not need to adapt for scaling things
struct ScaledDisplay<'a, T: DrawTarget> {
    real_display: &'a mut T,
    size_x: u32,
    size_y: u32,
    scale_x: u32,
    scale_y: u32,
}

impl<'a, T: DrawTarget> DrawTarget for ScaledDisplay<'a, T> {
    type Color = T::Color;
    type Error = T::Error;

    fn draw_iter<I>(&mut self, pixels: I) -> Result<(), Self::Error>
    where
        I: IntoIterator<Item = Pixel<Self::Color>>,
    {
        for pixel in pixels {
            let style = PrimitiveStyle::with_fill(pixel.1);
            Rectangle::new(
                Point::new(
                    pixel.0.x * self.scale_x as i32,
                    pixel.0.y * self.scale_y as i32,
                ),
                Size::new(self.scale_x as u32, self.scale_y as u32),
            )
            .into_styled(style)
            .draw(self.real_display)?;
        }
        Ok(())
    }
}

impl<'a, T: DrawTarget> OriginDimensions for ScaledDisplay<'a, T> {
    fn size(&self) -> Size {
        Size::new(self.size_x as u32, self.size_y as u32)
    }
}

#[cfg(test)]
mod tests {

    use crate::Snake;
    use embedded_graphics::pixelcolor::*;
    use embedded_graphics::prelude::*;

    #[test]
    fn snake_basic() {
        let mut snake = Snake::<Rgb888, 20>::new(Rgb888::RED, 8, 8);
        snake.set_direction(crate::Direction::Right);
        assert_eq!(
            Pixel::<Rgb888>(Point { x: 0, y: 0 }, Rgb888::RED),
            snake.into_iter().next().unwrap()
        );
        snake.make_step();
        assert_eq!(
            Pixel::<Rgb888>(Point { x: 1, y: 0 }, Rgb888::RED),
            snake.into_iter().nth(0).unwrap()
        );
        assert_eq!(
            Pixel::<Rgb888>(Point { x: 0, y: 0 }, Rgb888::RED),
            snake.into_iter().nth(1).unwrap()
        );
        snake.set_direction(crate::Direction::Down);
        snake.make_step();
        assert_eq!(
            Pixel::<Rgb888>(Point { x: 1, y: 1 }, Rgb888::RED),
            snake.into_iter().nth(0).unwrap()
        );
        assert_eq!(
            Pixel::<Rgb888>(Point { x: 1, y: 0 }, Rgb888::RED),
            snake.into_iter().nth(1).unwrap()
        );
        assert_eq!(
            Pixel::<Rgb888>(Point { x: 0, y: 0 }, Rgb888::RED),
            snake.into_iter().nth(2).unwrap()
        );
        assert_eq!(true, snake.contains(Point { x: 0, y: 0 }));
        assert_eq!(true, snake.contains(Point { x: 1, y: 0 }));
        assert_eq!(true, snake.contains(Point { x: 1, y: 1 }));
    }
}

const LF: u8 = 0x0au8;
const CR: u8 = 0x0du8;
#[no_mangle]
pub fn main() -> i32 {
    let mut disp = Display::new(Size::new(VIRTGPU_XRES, VIRTGPU_YRES));
    let mut game = SnakeGame::<20, Rgb888>::new(1280, 800, 20, 20, Rgb888::RED, Rgb888::YELLOW, 50);
    let _ = disp.clear(Rgb888::BLACK).unwrap();
    loop {
        if key_pressed() {
            let c = getchar();
            match c {
                LF => break,
                CR => break,
                b'w' => game.set_direction(Direction::Up),
                b's' => game.set_direction(Direction::Down),
                b'a' => game.set_direction(Direction::Left),
                b'd' => game.set_direction(Direction::Right),
                _ => (),
            }
        }
        let _ = disp.clear(Rgb888::BLACK).unwrap();
        game.draw(&mut disp);
        sleep(10);
    }
    0
}
