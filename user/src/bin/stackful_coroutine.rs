// we porting below codes to Rcore Tutorial v3
// https://cfsamson.gitbook.io/green-threads-explained-in-200-lines-of-rust/
// https://github.com/cfsamson/example-greenthreads
#![no_std]
#![no_main]
#![feature(naked_functions)]
//#![feature(asm)]

extern crate alloc;
#[macro_use]
extern crate user_lib;

use core::arch::asm;

//#[macro_use]
use alloc::vec;
use alloc::vec::Vec;

use user_lib::exit;

// In our simple example we set most constraints here.
const DEFAULT_STACK_SIZE: usize = 4096; //128 got  SEGFAULT, 256(1024, 4096) got right results.
const MAX_TASKS: usize = 5;
static mut RUNTIME: usize = 0;

pub struct Runtime {
    tasks: Vec<Task>,
    current: usize,
}

#[derive(PartialEq, Eq, Debug)]
enum State {
    Available,
    Running,
    Ready,
}

struct Task {
    id: usize,
    stack: Vec<u8>,
    ctx: TaskContext,
    state: State,
}

#[derive(Debug, Default)]
#[repr(C)] // not strictly needed but Rust ABI is not guaranteed to be stable
pub struct TaskContext {
    // 15 u64
    x1: u64,  //ra: return addres
    x2: u64,  //sp
    x8: u64,  //s0,fp
    x9: u64,  //s1
    x18: u64, //x18-27: s2-11
    x19: u64,
    x20: u64,
    x21: u64,
    x22: u64,
    x23: u64,
    x24: u64,
    x25: u64,
    x26: u64,
    x27: u64,
    nx1: u64, //new return addres
}

impl Task {
    fn new(id: usize) -> Self {
        // We initialize each task here and allocate the stack. This is not neccesary,
        // we can allocate memory for it later, but it keeps complexity down and lets us focus on more interesting parts
        // to do it here. The important part is that once allocated it MUST NOT move in memory.
        Task {
            id:id,
            stack: vec![0_u8; DEFAULT_STACK_SIZE],
            ctx: TaskContext::default(),
            state: State::Available,
        }
    }
}

impl Runtime {
    pub fn new() -> Self {
        // This will be our base task, which will be initialized in the `running` state
        let base_task = Task {
            id: 0,
            stack: vec![0_u8; DEFAULT_STACK_SIZE],
            ctx: TaskContext::default(),
            state: State::Running,
        };

        // We initialize the rest of our tasks.
        let mut tasks = vec![base_task];
        let mut available_tasks: Vec<Task> = (1..MAX_TASKS).map(|i| Task::new(i)).collect();
        tasks.append(&mut available_tasks);

        Runtime { tasks, current: 0 }
    }

    /// This is cheating a bit, but we need a pointer to our Runtime stored so we can call yield on it even if
    /// we don't have a reference to it.
    pub fn init(&self) {
        unsafe {
            let r_ptr: *const Runtime = self;
            RUNTIME = r_ptr as usize;
        }
    }

    /// This is where we start running our runtime. If it is our base task, we call yield until
    /// it returns false (which means that there are no tasks scheduled) and we are done.
    pub fn run(&mut self) {
        while self.t_yield() {}
        println!("All tasks finished!");
    }

    /// This is our return function. The only place we use this is in our `guard` function.
    /// If the current task is not our base task we set its state to Available. It means
    /// we're finished with it. Then we yield which will schedule a new task to be run.
    fn t_return(&mut self) {
        if self.current != 0 {
            self.tasks[self.current].state = State::Available;
            self.t_yield();
        }
    }

    /// This is the heart of our runtime. Here we go through all tasks and see if anyone is in the `Ready` state.
    /// If no task is `Ready` we're all done. This is an extremely simple scheduler using only a round-robin algorithm.
    ///
    /// If we find a task that's ready to be run we change the state of the current task from `Running` to `Ready`.
    /// Then we call switch which will save the current context (the old context) and load the new context
    /// into the CPU which then resumes based on the context it was just passed.
    ///
    /// NOITCE: if we comment below `#[inline(never)]`, we can not get the corrent running result
    #[inline(never)]
    fn t_yield(&mut self) -> bool {
        let mut pos = self.current;
        while self.tasks[pos].state != State::Ready {
            pos += 1;
            if pos == self.tasks.len() {
                pos = 0;
            }
            if pos == self.current {
                return false;
            }
        }

        if self.tasks[self.current].state != State::Available {
            self.tasks[self.current].state = State::Ready;
        }

        self.tasks[pos].state = State::Running;
        let old_pos = self.current;
        self.current = pos;

        unsafe {
            switch(&mut self.tasks[old_pos].ctx, &self.tasks[pos].ctx);
        }

        // NOTE: this might look strange and it is. Normally we would just mark this as `unreachable!()` but our compiler
        // is too smart for it's own good so it optimized our code away on release builds. Curiously this happens on windows
        // and not on linux. This is a common problem in tests so Rust has a `black_box` function in the `test` crate that
        // will "pretend" to use a value we give it to prevent the compiler from eliminating code. I'll just do this instead,
        // this code will never be run anyways and if it did it would always be `true`.
        self.tasks.len() > 0
    }

    /// While `yield` is the logically interesting function I think this the technically most interesting.
    ///
    /// When we spawn a new task we first check if there are any available tasks (tasks in `Parked` state).
    /// If we run out of tasks we panic in this scenario but there are several (better) ways to handle that.
    /// We keep things simple for now.
    ///
    /// When we find an available task we get the stack length and a pointer to our u8 bytearray.
    ///
    /// The next part we have to use some unsafe functions. First we write an address to our `guard` function
    /// that will be called if the function we provide returns. Then we set the address to the function we
    /// pass inn.
    ///
    /// Third, we set the value of `sp` which is the stack pointer to the address of our provided function so we start
    /// executing that first when we are scheuled to run.
    ///
    /// Lastly we set the state as `Ready` which means we have work to do and is ready to do it.
    pub fn spawn(&mut self, f: fn()) {
        let available = self
            .tasks
            .iter_mut()
            .find(|t| t.state == State::Available)
            .expect("no available task.");

        println!("RUNTIME: spawning task {}", available.id);
        let size = available.stack.len();
        unsafe {
            let s_ptr = available.stack.as_mut_ptr().offset(size as isize);

            // make sure our stack itself is 8 byte aligned - it will always
            // offset to a lower memory address. Since we know we're at the "high"
            // memory address of our allocated space, we know that offsetting to
            // a lower one will be a valid address (given that we actually allocated)
            // enough space to actually get an aligned pointer in the first place).
            let s_ptr = (s_ptr as usize & !7) as *mut u8;

            available.ctx.x1 = guard as u64; //ctx.x1  is old return address
            available.ctx.nx1 = f as u64; //ctx.nx2 is new return address
            available.ctx.x2 = s_ptr.offset(-32) as u64; //cxt.x2 is sp
        }
        available.state = State::Ready;
    }
}

/// This is our guard function that we place on top of the stack. All this function does is set the
/// state of our current task and then `yield` which will then schedule a new task to be run.
fn guard() {
    unsafe {
        let rt_ptr = RUNTIME as *mut Runtime;
        (*rt_ptr).t_return();
    };
}

/// We know that Runtime is alive the length of the program and that we only access from one core
/// (so no datarace). We yield execution of the current task  by dereferencing a pointer to our
/// Runtime and then calling `t_yield`
pub fn yield_task() {
    unsafe {
        let rt_ptr = RUNTIME as *mut Runtime;
        (*rt_ptr).t_yield();
    };
}

/// So here is our inline Assembly. As you remember from our first example this is just a bit more elaborate where we first
/// read out the values of all the registers we need and then sets all the register values to the register values we
/// saved when we suspended exceution on the "new" task.
///
/// This is essentially all we need to do to save and resume execution.
///
/// Some details about inline assembly.
///
/// The assembly commands in the string literal is called the assemblt template. It is preceeded by
/// zero or up to four segments indicated by ":":
///
/// - First ":" we have our output parameters, this parameters that this function will return.
/// - Second ":" we have the input parameters which is our contexts. We only read from the "new" context
/// but we modify the "old" context saving our registers there (see volatile option below)
/// - Third ":" This our clobber list, this is information to the compiler that these registers can't be used freely
/// - Fourth ":" This is options we can pass inn, Rust has 3: "alignstack", "volatile" and "intel"
///
/// For this to work on windows we need to use "alignstack" where the compiler adds the neccesary padding to
/// make sure our stack is aligned. Since we modify one of our inputs, our assembly has "side effects"
/// therefore we should use the `volatile` option. I **think** this is actually set for us by default
/// when there are no output parameters given (my own assumption after going through the source code)
/// for the `asm` macro, but we should make it explicit anyway.
///
/// One last important part (it will not work without this) is the #[naked] attribute. Basically this lets us have full
/// control over the stack layout since normal functions has a prologue-and epilogue added by the
/// compiler that will cause trouble for us. We avoid this by marking the funtion as "Naked".
/// For this to work on `release` builds we also need to use the `#[inline(never)] attribute or else
/// the compiler decides to inline this function (curiously this currently only happens on Windows).
/// If the function is inlined we get a curious runtime error where it fails when switching back
/// to as saved context and in general our assembly will not work as expected.
///
/// see: https://github.com/rust-lang/rfcs/blob/master/text/1201-naked-fns.md
/// see: https://doc.rust-lang.org/nightly/reference/inline-assembly.html
/// see: https://doc.rust-lang.org/nightly/rust-by-example/unsafe/asm.html
#[naked]
#[no_mangle]
unsafe extern "C" fn switch(old: *mut TaskContext, new: *const TaskContext) {
    // a0: _old, a1: _new
    asm!(
        "
        sd x1, 0x00(a0)
        sd x2, 0x08(a0)
        sd x8, 0x10(a0)
        sd x9, 0x18(a0)
        sd x18, 0x20(a0)
        sd x19, 0x28(a0)
        sd x20, 0x30(a0)
        sd x21, 0x38(a0)
        sd x22, 0x40(a0)
        sd x23, 0x48(a0)
        sd x24, 0x50(a0)
        sd x25, 0x58(a0)
        sd x26, 0x60(a0)
        sd x27, 0x68(a0)
        sd x1, 0x70(a0)

        ld x1, 0x00(a1)
        ld x2, 0x08(a1)
        ld x8, 0x10(a1)
        ld x9, 0x18(a1)
        ld x18, 0x20(a1)
        ld x19, 0x28(a1)
        ld x20, 0x30(a1)
        ld x21, 0x38(a1)
        ld x22, 0x40(a1)
        ld x23, 0x48(a1)
        ld x24, 0x50(a1)
        ld x25, 0x58(a1)
        ld x26, 0x60(a1)
        ld x27, 0x68(a1)
        ld t0, 0x70(a1)

        jr t0
    ",
        options(noreturn)
    );
}

#[no_mangle]
pub fn main() {
    println!("stackful_coroutine begin...");
    println!("TASK  0(Runtime) STARTING");
    let mut runtime = Runtime::new();
    runtime.init();
    runtime.spawn(|| {
        println!("TASK  1 STARTING");
        let id = 1;
        for i in 0..4 {
            println!("task: {} counter: {}", id, i);
            yield_task();
        }
        println!("TASK 1 FINISHED");
    });
    runtime.spawn(|| {
        println!("TASK 2 STARTING");
        let id = 2;
        for i in 0..8 {
            println!("task: {} counter: {}", id, i);
            yield_task();
        }
        println!("TASK 2 FINISHED");
    });
    runtime.spawn(|| {
        println!("TASK 3 STARTING");
        let id = 3;
        for i in 0..12 {
            println!("task: {} counter: {}", id, i);
            yield_task();
        }
        println!("TASK 3 FINISHED");
    });
    runtime.spawn(|| {
        println!("TASK 4 STARTING");
        let id = 4;
        for i in 0..16 {
            println!("task: {} counter: {}", id, i);
            yield_task();
        }
        println!("TASK 4 FINISHED");
    });
    runtime.run();
    println!("stackful_coroutine PASSED");
    exit(0);
}
