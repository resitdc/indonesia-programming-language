pub mod core;
pub mod matematika;
pub mod string;
pub mod list;
pub mod file;
pub mod waktu;
pub mod json;
pub mod http;

use std::rc::Rc;
use std::cell::RefCell;
use crate::lingkungan::Lingkungan;

pub fn register_all(env: &Rc<RefCell<Lingkungan>>) {
    core::register(env);
    matematika::register(env);
    string::register(env);
    list::register(env);
    file::register(env);
    waktu::register(env);
    json::register(env);
    http::register(env);
}
