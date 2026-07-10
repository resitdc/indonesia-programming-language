use std::fmt;
use std::rc::Rc;
use std::cell::RefCell;
use std::collections::HashMap;
use ast::Statement;
use crate::lingkungan::Lingkungan;

#[derive(Clone)]
pub enum Objek {
    Angka(f64),
    String(String),
    Boolean(bool),
    Kosong,
    Kembalikan(Box<Objek>),
    Fungsi {
        parameter: Vec<String>,
        body: Vec<Statement>,
        env: Rc<RefCell<Lingkungan>>,
    },
    FungsiBawaan(fn(Vec<Objek>) -> Objek),
    Modul(Rc<RefCell<Lingkungan>>),
    Array(Vec<Objek>),
    Kamus(HashMap<String, Objek>),
}

impl PartialEq for Objek {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (Objek::Angka(a), Objek::Angka(b)) => a == b,
            (Objek::String(a), Objek::String(b)) => a == b,
            (Objek::Boolean(a), Objek::Boolean(b)) => a == b,
            (Objek::Kosong, Objek::Kosong) => true,
            (Objek::Kembalikan(a), Objek::Kembalikan(b)) => a == b,
            (Objek::Array(a), Objek::Array(b)) => a == b,
            (Objek::Kamus(a), Objek::Kamus(b)) => a == b,
            _ => false,
        }
    }
}

impl fmt::Debug for Objek {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self)
    }
}

impl fmt::Display for Objek {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Objek::Angka(val) => write!(f, "{}", val),
            Objek::String(val) => write!(f, "{}", val),
            Objek::Boolean(val) => write!(f, "{}", if *val { "benar" } else { "salah" }),
            Objek::Kosong => write!(f, "kosong"),
            Objek::Kembalikan(val) => write!(f, "{}", val),
            Objek::Fungsi { .. } => write!(f, "[Fungsi kustom]"),
            Objek::FungsiBawaan(_) => write!(f, "[Fungsi bawaan]"),
            Objek::Modul(_) => write!(f, "[Modul]"),
            Objek::Array(elemen) => {
                let items: Vec<String> = elemen.iter().map(|e| format!("{}", e)).collect();
                write!(f, "[{}]", items.join(", "))
            }
            Objek::Kamus(pasangan) => {
                let mut items: Vec<String> = pasangan.iter().map(|(k, v)| format!("{}: {}", k, v)).collect();
                items.sort(); // Sort to ensure consistent output format
                write!(f, "{{{}}}", items.join(", "))
            }
        }
    }
}
