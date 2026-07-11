use crate::machine::VM;
use crate::value::{Value, FungsiBawaanVM};
use crate::heap::HeapData;

pub fn register(vm: &mut VM) {
    let angka_func = FungsiBawaanVM {
        nama: "angka".to_string(),
        func: |heap, args| {
            if args.len() != 1 {
                return Err("Fungsi 'angka' membutuhkan 1 argumen".to_string());
            }
            match &args[0] {
                Value::Angka(n) => Ok(Value::Angka(*n)),
                Value::String(idx) => {
                    let s = heap.get_string(*idx).clone();
                    if let Ok(n) = s.parse::<f64>() {
                        Ok(Value::Angka(n))
                    } else {
                        Err(format!("Tidak dapat mengubah '{}' menjadi angka", s))
                    }
                }
                _ => Err("Argumen tidak didukung".to_string()),
            }
        },
    };
    
    let angka_idx = vm.heap.alloc(HeapData::FungsiBawaan(angka_func));
    vm.set_global("angka".to_string(), Value::FungsiBawaan(angka_idx));

    let teks_func = FungsiBawaanVM {
        nama: "teks".to_string(),
        func: |heap, args| {
            if args.len() != 1 {
                return Err("Fungsi 'teks' membutuhkan 1 argumen".to_string());
            }
            let s = args[0].to_string(heap);
            let idx = heap.alloc(HeapData::String(s));
            Ok(Value::String(idx))
        },
    };
    
    let teks_idx = vm.heap.alloc(HeapData::FungsiBawaan(teks_func));
    vm.set_global("teks".to_string(), Value::FungsiBawaan(teks_idx));
}
