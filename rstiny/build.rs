// build.rs
fn main() {
    println!("cargo:rustc-link-arg=-T");
    println!("cargo:rustc-link-arg=rstiny/link.lds");
    println!("cargo:rustc-codegen-options=-C target-cpu=cortex-a76");
}
