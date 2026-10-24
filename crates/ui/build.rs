fn main() {
    // Pin the widget style so the app looks the same on every desktop OS.
    let config = slint_build::CompilerConfiguration::new().with_style("fluent".into());
    if let Err(e) = slint_build::compile_with_config("ui/app-window.slint", config) {
        panic!("failed to compile Slint UI: {e}");
    }
}
