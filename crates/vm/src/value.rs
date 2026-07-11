use std::fmt;
use crate::heap::Heap;

pub trait VmContext {
    fn get_heap_mut(&mut self) -> &mut Heap;
    fn execute_function(&mut self, func_idx: usize, args: Vec<Value>) -> Result<Value, String>;
}

pub type NativeFnVM = fn(&mut dyn VmContext, Vec<Value>) -> Result<Value, String>;

#[derive(Clone)]
pub struct FungsiBawaanVM {
    pub nama: String,
    pub func: NativeFnVM,
}

impl PartialEq for FungsiBawaanVM {
    fn eq(&self, other: &Self) -> bool {
        self.nama == other.nama
    }
}

impl fmt::Debug for FungsiBawaanVM {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "<fungsi bawaan {}>", self.nama)
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct FungsiVM {
    pub nama: String,
    pub parameter: Vec<String>,
    pub chunk: crate::compiler::Chunk,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum Value {
    Angka(f64),
    Boolean(bool),
    Kosong,
    String(usize),
    Array(usize),
    Kamus(usize),
    Fungsi(usize),
    FungsiBawaan(usize),
}

impl Value {
    pub fn to_string(&self, heap: &Heap) -> String {
        match self {
            Value::Angka(val) => val.to_string(),
            Value::String(idx) => heap.get_string(*idx).clone(),
            Value::Boolean(val) => (if *val { "benar" } else { "salah" }).to_string(),
            Value::Fungsi(idx) => format!("<fungsi {}>", heap.get_fungsi(*idx).nama),
            Value::FungsiBawaan(idx) => format!("<fungsi bawaan {}>", heap.get_fungsi_bawaan(*idx).nama),
            Value::Array(idx) => {
                let items: Vec<String> = heap.get_array(*idx).iter().map(|v| v.to_string(heap)).collect();
                format!("[{}]", items.join(", "))
            }
            Value::Kamus(idx) => {
                let items: Vec<String> = heap.get_kamus(*idx).iter().map(|(k, v)| format!("{}: {}", k, v.to_string(heap))).collect();
                format!("{{{}}}", items.join(", "))
            }
            Value::Kosong => "kosong".to_string(),
        }
    }
}
