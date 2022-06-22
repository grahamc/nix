use cxx::UniquePtr;

#[cxx::bridge]
mod ffi {
    extern "Rust" {
        fn make_buf() -> usize;
    }
}


pub fn make_buf() -> usize {
    1
}
