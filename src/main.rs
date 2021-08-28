#![no_std]
#![no_main]
#![feature(asm)]

#[macro_use]
mod print;

use core::panic::PanicInfo;

#[panic_handler]
fn panic(info: &PanicInfo<'_>) -> ! {
    println!("{}", info);
    abort();
}

#[no_mangle]
extern "C" fn abort() -> ! {
    unsafe { asm!("cli\nhlt", options(noreturn)) };
}

#[no_mangle]
extern "C" fn _start() -> ! {
    print!("\x0C");
    println!("Hello world!");
    todo!();
}
