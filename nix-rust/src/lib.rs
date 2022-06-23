
#[cxx::bridge]
mod ffi {
    extern "Rust" {
        type MyThing;

        fn make_thing() -> Box<MyThing>;
        fn foo(self: &MyThing) -> i32;
        fn bar(self: &MyThing) -> &str;
    }
}


pub struct MyThing {
    myfoo: i32,
    bar: String
}

impl MyThing {
    pub fn foo(&self) -> i32 {
        self.myfoo
    }
    pub fn bar(&self) -> &str {
        &self.bar
    }
}

pub fn make_thing() -> Box<MyThing> {
    Box::new(MyThing {
        myfoo: 1,
        bar: String::from("Hello from Rust!"),
    })
}
