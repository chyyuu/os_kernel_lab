use super::*;

pub fn mutex_create() -> isize {
    sys_mutex_create(false)
}
pub fn mutex_blocking_create() -> isize {
    sys_mutex_create(true)
}
pub fn mutex_lock(mutex_id: usize) {
    sys_mutex_lock(mutex_id);
}
pub fn mutex_unlock(mutex_id: usize) {
    sys_mutex_unlock(mutex_id);
}
pub fn semaphore_create(res_count: usize) -> isize {
    sys_semaphore_create(res_count)
}
pub fn semaphore_up(sem_id: usize) {
    sys_semaphore_up(sem_id);
}
pub fn semaphore_down(sem_id: usize) {
    sys_semaphore_down(sem_id);
}
pub fn condvar_create() -> isize {
    sys_condvar_create(0)
}
pub fn condvar_signal(condvar_id: usize) {
    sys_condvar_signal(condvar_id);
}
pub fn condvar_wait(condvar_id: usize, mutex_id: usize) {
    sys_condvar_wait(condvar_id, mutex_id);
}