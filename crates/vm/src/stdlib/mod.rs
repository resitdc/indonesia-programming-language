pub mod core;
pub mod waktu;
pub mod matematika;
pub mod list;
pub mod json;
pub mod http;
pub mod env;
pub mod file;
pub mod web;
pub mod cookie;
pub mod session;
pub mod tugas;
pub mod string;
pub mod db;
pub mod kripto;
pub mod log;

use crate::machine::VM;

pub fn register_all(vm: &mut VM) {
    core::register(vm);
    waktu::register(vm);
    matematika::register(vm);
    list::register(vm);
    json::register(vm);
    http::register(vm);
    env::register(vm);
    file::register(vm);
    web::register(vm);
    cookie::register(vm);
    session::register(vm);
    tugas::register(vm);
    string::register(vm);
    db::register(vm);
    kripto::register(vm);
    log::register(vm);
}
