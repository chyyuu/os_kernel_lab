/// Wrap a static data structure inside it so that we are 
/// able to access it without any `unsafe`.
///
/// We should only use it in uniprocessor.
///
/// In order to get mutable reference of inner data, call 
/// `upsafe_access`. 
pub struct UPSafeCell<T> {
    /// inner data
    data: T,
}

unsafe impl<T> Sync for UPSafeCell<T> {}

impl<T> UPSafeCell<T> {
    /// User is responsible to guarantee that inner struct is only used in
    /// uniprocessor.
    pub unsafe fn new(value: T) -> Self {
        Self { data: value, }
    }
    /// Mention that user should hold exactly one &mut T at a time. 
    pub fn upsafe_access(&self) -> &mut T {
        unsafe {
            &mut *(&self.data as *const _ as usize as *mut T)
        }
    }
}