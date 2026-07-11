use crate::machine::VM;
use crate::value::{Value, FungsiBawaanVM};
use std::collections::HashMap;
use crate::heap::HeapData;
use std::env;

pub fn register(vm: &mut VM) {
    let mut module_dict = HashMap::new();
    
    let _ = dotenvy::dotenv();
    
    let get_func = FungsiBawaanVM {
        nama: "get".to_string(),
        func: |heap, args| {
            if args.is_empty() {
                return Err("Fungsi 'get' membutuhkan 1 argumen: kunci (key)".to_string());
            }
            if let Value::String(idx) = &args[0] {
                let key = heap.get_string(*idx).clone();
                match env::var(&key) {
                    Ok(val) => {
                        let new_idx = heap.alloc(HeapData::String(val));
                        Ok(Value::String(new_idx))
                    },
                    Err(_) => Ok(Value::Kosong),
                }
            } else {
                Err("Kunci (key) harus berupa teks".to_string())
            }
        },
    };
    let get_idx = vm.heap.alloc(HeapData::FungsiBawaan(get_func));
    module_dict.insert("get".to_string(), Value::FungsiBawaan(get_idx));

    let dict_idx = vm.heap.alloc(HeapData::Kamus(module_dict));
    vm.set_global("env".to_string(), Value::Kamus(dict_idx));
}
