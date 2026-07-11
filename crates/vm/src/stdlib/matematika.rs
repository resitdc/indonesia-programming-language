use crate::machine::VM;
use crate::value::{Value, FungsiBawaanVM};
use std::collections::HashMap;
use crate::heap::{HeapData};
use rand::Rng;

pub fn register(vm: &mut VM) {
    let mut module_dict = HashMap::new();
    
    let acak_func = FungsiBawaanVM {
        nama: "acak".to_string(),
        func: |_heap, args| {
            if !args.is_empty() {
                return Err("Fungsi 'acak' tidak menerima argumen".to_string());
            }
            let mut rng = rand::thread_rng();
            Ok(Value::Angka(rng.r#gen::<f64>()))
        },
    };
    let acak_idx = vm.heap.alloc(HeapData::FungsiBawaan(acak_func));
    module_dict.insert("acak".to_string(), Value::FungsiBawaan(acak_idx));

    let bulat_func = FungsiBawaanVM {
        nama: "bulat".to_string(),
        func: |_heap, args| {
            if args.len() != 1 {
                return Err("Fungsi 'bulat' membutuhkan 1 argumen: angka".to_string());
            }
            if let Value::Angka(n) = args[0] {
                Ok(Value::Angka(n.round()))
            } else {
                Err("Argumen harus berupa angka".to_string())
            }
        },
    };
    let bulat_idx = vm.heap.alloc(HeapData::FungsiBawaan(bulat_func));
    module_dict.insert("bulat".to_string(), Value::FungsiBawaan(bulat_idx));

    let akar_func = FungsiBawaanVM {
        nama: "akar".to_string(),
        func: |_heap, args| {
            if args.len() != 1 {
                return Err("Fungsi 'akar' membutuhkan 1 argumen: angka".to_string());
            }
            if let Value::Angka(n) = args[0] {
                if n < 0.0 {
                    return Err("Tidak bisa menghitung akar dari bilangan negatif".to_string());
                }
                Ok(Value::Angka(n.sqrt()))
            } else {
                Err("Argumen harus berupa angka".to_string())
            }
        },
    };
    let akar_idx = vm.heap.alloc(HeapData::FungsiBawaan(akar_func));
    module_dict.insert("akar".to_string(), Value::FungsiBawaan(akar_idx));
    
    let dict_idx = vm.heap.alloc(HeapData::Kamus(module_dict));
    vm.set_global("matematika".to_string(), Value::Kamus(dict_idx));
}
