//! RPL Studio Core — Native FFI bridge to RPL Rust backend.
//!
//! This crate is compiled as a C-compatible dynamic/static library.
//! All logic delegates to the RPL `runtime` crate.

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

mod api;
mod frb_generated;

/// Return RPL version string.
/// Caller must free the returned string with `rpl_free_string`.
#[unsafe(no_mangle)]
pub extern "C" fn rpl_version() -> *mut c_char {
    let version = runtime::version();
    let c_string = CString::new(version).unwrap_or_default();
    c_string.into_raw()
}

/// Free a string previously returned by an RPL FFI function.
#[unsafe(no_mangle)]
pub extern "C" fn rpl_free_string(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        let _ = CString::from_raw(ptr);
    }
}

/// Execute RPL code and return the output as a string.
/// Returns a JSON string: `{"ok": output}` or `{"error": message}`.
/// Caller must free the returned string with `rpl_free_string`.
#[unsafe(no_mangle)]
pub extern "C" fn rpl_execute(code: *const c_char) -> *mut c_char {
    let code_str = if code.is_null() {
        String::new()
    } else {
        unsafe { CStr::from_ptr(code) }.to_string_lossy().into_owned()
    };

    let result = match runtime::execute_string(&code_str) {
        Ok(output) => format!(r#"{{"ok":"{}"}}"#, output.escape_default()),
        Err(e) => format!(r#"{{"error":"{}"}}"#, e.to_string().escape_default()),
    };

    let c_result = CString::new(result).unwrap_or_default();
    c_result.into_raw()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn test_version_not_null() {
        let version = rpl_version();
        assert!(!version.is_null());
        rpl_free_string(version);
    }

    #[test]
    fn test_execute_hello() {
        let input = CString::new("buat x = 10\ntampilkan \"Halo \" + string.dari(x)").unwrap();
        let result = rpl_execute(input.as_ptr());
        assert!(!result.is_null());

        let output = unsafe { CStr::from_ptr(result) }.to_string_lossy().into_owned();
        assert!(output.contains("ok") || output.contains("error"));

        rpl_free_string(result);
    }
}