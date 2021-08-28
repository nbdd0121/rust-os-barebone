use core::cmp;
use core::fmt::{self, Write};
use spin::{Lazy, Mutex};

pub struct Console<'a> {
    video_mem: &'a mut [u16; 80 * 25],
    ptr: usize,
}

impl Write for Console<'_> {
    fn write_char(&mut self, c: char) -> fmt::Result {
        match c {
            '\x08' => {
                self.ptr -= cmp::min(1, self.ptr % 80);
            }
            '\t' => {
                self.ptr += 8 - self.ptr % 8;
            }
            '\n' => {
                self.ptr += 80 - self.ptr % 80;
            }
            '\x0C' => {
                self.video_mem.fill(0);
                self.ptr = 0;
            }
            '\r' => {
                self.ptr -= self.ptr % 80;
            }
            _ if c.is_ascii() && !c.is_ascii_control() => {
                self.video_mem[self.ptr] = c as u8 as u16 | 0x0700;
                self.ptr += 1;
            }
            _ => (),
        }
        if self.ptr > self.video_mem.len() {
            self.ptr -= self.video_mem.len();
        }
        Ok(())
    }

    fn write_str(&mut self, s: &str) -> fmt::Result {
        for c in s.chars() {
            self.write_char(c)?;
        }
        Ok(())
    }
}

pub static CONSOLE: Lazy<Mutex<Console<'_>>> = Lazy::new(|| {
    Mutex::new(Console {
        video_mem: unsafe { &mut *(0xB8000 as *mut _) },
        ptr: 0,
    })
});

pub fn console_write(args: core::fmt::Arguments<'_>) {
    CONSOLE.lock().write_fmt(args).unwrap();
}

macro_rules! format_args_nl {
    ($fmt:expr) => (format_args!(concat!($fmt, "\n")));
    ($fmt:expr, $($args:tt)* ) => (format_args!(concat!($fmt, "\n"), $($args)*));
}

macro_rules! println {
    ($($args:tt)*) => ({
        crate::print::console_write(format_args_nl!($($args)*))
    })
}

macro_rules! print {
    ($($args:tt)*) => ({
        crate::print::console_write(format_args!($($args)*))
    })
}
