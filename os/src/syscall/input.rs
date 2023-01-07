//use crate::drivers::{KEYBOARD_DEVICE,MOUSE_DEVICE,INPUT_CONDVAR,read_input_event};
use crate::drivers::{KEYBOARD_DEVICE,MOUSE_DEVICE};

pub fn sys_event_get() ->isize {
    let kb = KEYBOARD_DEVICE.clone();
    let mouse = MOUSE_DEVICE.clone();
    //let input=INPUT_CONDVAR.clone();
    //read_input_event() as isize
    if !kb.is_empty(){
        kb.read_event() as isize
    }  else if !mouse.is_empty() {
        mouse.read_event() as isize
    } else {
        0
    }

}