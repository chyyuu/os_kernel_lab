use crate::memory::paging::PageEntry;

#[derive(Clone,Debug)]
pub struct MemoryAttr {
    user : bool,
    readonly : bool,
    execute : bool,
}

impl MemoryAttr {
    pub fn new() -> Self{
        MemoryAttr {
            user : false,
            readonly : false,
            execute : false,
        }
    }


    pub fn set_user(mut self) -> Self {
        self.user = true;
        self
    }
    pub fn set_readonly(mut self) -> Self {
        self.readonly = true;
        self
    }
    pub fn set_execute(mut self) -> Self {
        self.execute = true;
        self
    }


    pub fn apply(&self, entry : &mut PageEntry) {
        entry.set_present(true);
        entry.set_user(self.user);
        entry.set_writable(!self.readonly);
        entry.set_execute(self.execute);
    }
}
