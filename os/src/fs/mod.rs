mod pipe;
mod stdio;

use crate::mm::UserBuffer;
use core::any::Any;

pub trait File : Any + Send + Sync {
    fn read(&self, buf: UserBuffer) -> usize;
    fn write(&self, buf: UserBuffer) -> usize;
    fn as_any_ref(&self) -> &dyn Any;
}

impl dyn File {
    #[allow(unused)]
    pub fn downcast_ref<T: File>(&self) -> Option<&T> {
        self.as_any_ref().downcast_ref::<T>()
    }
}

pub use pipe::{Pipe, make_pipe};
pub use stdio::{Stdin, Stdout};