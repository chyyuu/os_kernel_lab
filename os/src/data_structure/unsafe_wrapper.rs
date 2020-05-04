//! 允许像 C 指针一样随意使用的 [`UnsafeWrapper`]

use alloc::boxed::Box;
use core::cell::UnsafeCell;

/// 允许从 &self 获取 &mut 内部变量
pub struct UnsafeWrapper<T> {
    object: UnsafeCell<T>,
}

impl<T> UnsafeWrapper<T> {
    pub fn new(object: T) -> Self {
        Self {
            object: UnsafeCell::new(object),
        }
    }

    pub fn get(&self) -> &mut T {
        unsafe { &mut *self.object.get() }
    }
}

impl<T: Default> Default for UnsafeWrapper<T> {
    fn default() -> Self {
        Self {
            object: UnsafeCell::new(T::default()),
        }
    }
}

unsafe impl<T> Sync for UnsafeWrapper<T> {}

pub trait StaticUnsafeInit {
    fn static_unsafe_init() -> Self;
}

pub struct StaticUnsafeWrapper<T> {
    pointer: UnsafeCell<*const UnsafeCell<T>>,
    _phantom: core::marker::PhantomData<T>,
}

impl<T> StaticUnsafeWrapper<T> {
    pub const fn new() -> Self {
        Self {
            pointer: UnsafeCell::new(0 as *const _),
            _phantom: core::marker::PhantomData,
        }
    }
}

impl<T: Default> StaticUnsafeWrapper<T> {
    pub fn get(&self) -> &mut T {
        unsafe {
            if *self.pointer.get() as usize == 0 {
                let boxed = Box::new(UnsafeCell::new(T::default()));
                *self.pointer.get() = Box::into_raw(boxed);
            }
            &mut *(**self.pointer.get()).get()
        }
    }
}

impl<T: Default> core::ops::Deref for StaticUnsafeWrapper<T> {
    type Target = T;
    fn deref(&self) -> &Self::Target {
        self.get()
    }
}

unsafe impl<T> Sync for StaticUnsafeWrapper<T> {}
