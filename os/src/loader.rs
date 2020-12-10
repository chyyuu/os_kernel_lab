use alloc::vec::Vec;

pub fn get_num_app() -> usize {
    extern "C" { fn _num_app(); }
    unsafe { (_num_app as usize as *const usize).read_volatile() }
}

pub fn get_app_data(app_id: usize) -> &'static [u8] {
    extern "C" { fn _num_app(); }
    let num_app_ptr = _num_app as usize as *const usize;
    let num_app = get_num_app();
    let app_start = unsafe {
        core::slice::from_raw_parts(num_app_ptr.add(1), num_app + 1)
    };
    assert!(app_id < num_app);
    unsafe {
        core::slice::from_raw_parts(
            app_start[app_id] as *const u8,
            app_start[app_id + 1] - app_start[app_id]
        )
    }
}

#[allow(unused)]
pub fn get_app_data_by_name(name: &str) -> Option<&'static [u8]> {
    let num_app = get_num_app();
    let app_names = app_names();
    (0..num_app)
        .find(|&i| app_names[i] == name)
        .map(|i| get_app_data(i))
}

#[allow(unused)]
fn app_names() -> Vec<&'static str> {
    let num_app = get_num_app();
    extern "C" { fn _app_names(); }
    let mut start = _app_names as usize as *const u8;
    let mut v = Vec::new();
    unsafe {
        for _ in 0..num_app {
            let mut end = start;
            while end.read_volatile() != '\n' as u8 {
                end = end.add(1);
            }
            let slice = core::slice::from_raw_parts(start, end as usize - start as usize);
            let str = core::str::from_utf8(slice).unwrap();
            v.push(str);
            // Mention that there is a extra char between names
            start = end.add(2);
        }
    }
    v
}

pub fn list_apps() {
    let apps = app_names();
    println!("/**** APPS ****");
    for app in apps {
        println!("{}", app);
    }
    println!("**************/")
}