pub fn run_code(code: String) -> String {
    match runtime::execute_string(&code) {
        Ok(output) => output,
        Err(e) => format!("Error: {}", e),
    }
}

pub fn check_syntax(code: String) -> Vec<String> {
    // Basic syntax checking (mocked for now)
    // Could hook into runtime::execute_string dry run
    vec![]
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}
