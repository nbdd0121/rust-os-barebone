#![no_std]
#![no_main]
#![feature(asm)]

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo<'_>) -> ! {
    abort();
}

#[no_mangle]
extern "C" fn abort() -> ! {
    unsafe { asm!("cli\nhlt", options(noreturn)) };
}

#[no_mangle]
extern "C" fn _start() -> ! {
    todo!();
}
