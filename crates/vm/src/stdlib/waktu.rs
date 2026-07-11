use crate::machine::VM;
use crate::value::{Value, FungsiBawaanVM};
use std::collections::HashMap;
use crate::heap::{HeapData};
use std::time::{SystemTime, UNIX_EPOCH};
use chrono::Local;

pub fn register(vm: &mut VM) {
    let mut module_dict = HashMap::new();
    
    let sekarang_func = FungsiBawaanVM {
        nama: "sekarang".to_string(),
        func: |_heap, args| {
            if !args.is_empty() {
                return Err("Fungsi 'sekarang' tidak menerima argumen".to_string());
            }
            match SystemTime::now().duration_since(UNIX_EPOCH) {
                Ok(n) => Ok(Value::Angka(n.as_millis() as f64)),
                Err(_) => Err("Waktu sistem error".to_string()),
            }
        },
    };
    let sekarang_idx = vm.heap.alloc(HeapData::FungsiBawaan(sekarang_func));
    module_dict.insert("sekarang".to_string(), Value::FungsiBawaan(sekarang_idx));

    let string_func = FungsiBawaanVM {
        nama: "string".to_string(),
        func: |ctx, args| {
            if !args.is_empty() {
                return Err("Fungsi 'string' tidak menerima argumen".to_string());
            }
            let now = Local::now();
            let s = now.format("%Y-%m-%d %H:%M:%S").to_string();
            let new_idx = ctx.get_heap_mut().alloc(HeapData::String(s));
            Ok(Value::String(new_idx))
        },
    };
    let string_idx = vm.heap.alloc(HeapData::FungsiBawaan(string_func));
    module_dict.insert("string".to_string(), Value::FungsiBawaan(string_idx));

    let tunggu_func = FungsiBawaanVM {
        nama: "tunggu".to_string(),
        func: |_ctx, args| {
            if args.len() != 1 {
                return Err("Fungsi 'tunggu' membutuhkan 1 argumen (angka milidetik)".to_string());
            }
            if let Value::Angka(ms) = args[0] {
                std::thread::sleep(std::time::Duration::from_millis(ms as u64));
                Ok(Value::Kosong)
            } else {
                Err("Argumen fungsi 'tunggu' harus berupa angka".to_string())
            }
        },
    };
    let tunggu_idx = vm.heap.alloc(HeapData::FungsiBawaan(tunggu_func));
    module_dict.insert("tunggu".to_string(), Value::FungsiBawaan(tunggu_idx));

    let dict_idx = vm.heap.alloc(HeapData::Kamus(module_dict));
    vm.set_global("waktu".to_string(), Value::Kamus(dict_idx));
}
