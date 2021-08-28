fn main() {
    println!("cargo:rerun-if-changed=linker.ld");
    println!("cargo:rerun-if-changed=src/boot.s");
    cc::Build::new().file("src/boot.s").compile("foo");
}
