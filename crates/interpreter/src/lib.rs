pub mod objek;
pub mod lingkungan;

use std::rc::Rc;
use std::cell::RefCell;

use ast::{Expression, InfixOperator, PrefixOperator, Program, Statement};
use errors::IplError;
use lingkungan::Lingkungan;
use objek::Objek;

pub struct Interpreter {
    pub lingkungan: Rc<RefCell<Lingkungan>>,
}

impl Interpreter {
    pub fn baru() -> Self {
        let env = Lingkungan::baru();
        Self {
            lingkungan: env,
        }
    }

    pub fn eval_program(&mut self, program: Program) -> Result<Objek, IplError> {
        let mut hasil = Objek::Kosong;

        for statement in program.statements {
            hasil = self.eval_statement(statement)?;

            if let Objek::Kembalikan(nilai) = hasil {
                return Ok(*nilai);
            }
        }

        Ok(hasil)
    }

    fn eval_statement(&mut self, statement: Statement) -> Result<Objek, IplError> {
        match statement {
            Statement::Expression(expr) => self.eval_expression(expr),
            Statement::Tampilkan { nilai, .. } => {
                for n in nilai {
                    let hasil_eval = self.eval_expression(n)?;
                    print!("{} ", hasil_eval);
                }
                println!();
                Ok(Objek::Kosong)
            }
            Statement::DeklarasiVariabel { nama, nilai, .. } => {
                let obj = self.eval_expression(nilai)?;
                self.lingkungan.borrow_mut().set(nama, obj);
                Ok(Objek::Kosong)
            }
            Statement::Assignment { nama, nilai, lokasi } => {
                if self.lingkungan.borrow().get(&nama).is_none() {
                    return Err(IplError::VariabelTidakDitemukan {
                        nama,
                        lokasi,
                        saran: Some("Pastikan menggunakan kata kunci 'buat' saat pertama kali mendeklarasikan variabel.".to_string()),
                    });
                }
                let obj = self.eval_expression(nilai)?;
                self.lingkungan.borrow_mut().set(nama, obj);
                Ok(Objek::Kosong)
            }
            Statement::Kembalikan { nilai, .. } => {
                if let Some(expr) = nilai {
                    let obj = self.eval_expression(expr)?;
                    Ok(Objek::Kembalikan(Box::new(obj)))
                } else {
                    Ok(Objek::Kembalikan(Box::new(Objek::Kosong)))
                }
            }
            Statement::Jika { kondisi, konsekuensi, alternatif, .. } => {
                let kondisi_eval = self.eval_expression(kondisi)?;
                
                if is_truthy(&kondisi_eval) {
                    self.eval_block(konsekuensi)
                } else if let Some(alt) = alternatif {
                    self.eval_block(alt)
                } else {
                    Ok(Objek::Kosong)
                }
            }
            Statement::Selama { kondisi, body, .. } => {
                let mut hasil = Objek::Kosong;
                loop {
                    let kondisi_eval = self.eval_expression(kondisi.clone())?;
                    if !is_truthy(&kondisi_eval) {
                        break;
                    }
                    hasil = self.eval_block(body.clone())?;
                    
                    if let Objek::Kembalikan(_) = hasil {
                        return Ok(hasil);
                    }
                }
                Ok(hasil)
            }
            Statement::DeklarasiFungsi { nama, parameter, body, .. } => {
                let fungsi = Objek::Fungsi {
                    parameter,
                    body,
                    env: Rc::clone(&self.lingkungan),
                };
                self.lingkungan.borrow_mut().set(nama, fungsi);
                Ok(Objek::Kosong)
            }
        }
    }

    fn eval_block(&mut self, statements: Vec<Statement>) -> Result<Objek, IplError> {
        let mut hasil = Objek::Kosong;

        for statement in statements {
            hasil = self.eval_statement(statement)?;

            if let Objek::Kembalikan(_) = hasil {
                return Ok(hasil);
            }
        }

        Ok(hasil)
    }

    fn eval_expression(&mut self, expr: Expression) -> Result<Objek, IplError> {
        match expr {
            Expression::Angka(val, _) => Ok(Objek::Angka(val)),
            Expression::String(val, _) => Ok(Objek::String(val)),
            Expression::Boolean(val, _) => Ok(Objek::Boolean(val)),
            Expression::Kosong(_) => Ok(Objek::Kosong),
            Expression::Identifier(nama, lokasi) => {
                match self.lingkungan.borrow().get(&nama) {
                    Some(val) => Ok(val),
                    None => Err(IplError::VariabelTidakDitemukan {
                        nama,
                        lokasi,
                        saran: None,
                    }),
                }
            }
            Expression::Prefix { operator, kanan, lokasi } => {
                let kanan_obj = self.eval_expression(*kanan)?;
                self.eval_prefix_expression(operator, kanan_obj, lokasi)
            }
            Expression::Infix { kiri, operator, kanan, lokasi } => {
                let kiri_obj = self.eval_expression(*kiri)?;
                let kanan_obj = self.eval_expression(*kanan)?;
                self.eval_infix_expression(operator, kiri_obj, kanan_obj, lokasi)
            }
            Expression::Call { fungsi, argumen, lokasi } => {
                let fungsi_obj = self.eval_expression(*fungsi)?;
                
                let mut arg_eval = Vec::new();
                for arg in argumen {
                    arg_eval.push(self.eval_expression(arg)?);
                }

                match fungsi_obj {
                    Objek::FungsiBawaan(func) => {
                        Ok(func(arg_eval))
                    }
                    Objek::Fungsi { parameter, body, env } => {
                        if arg_eval.len() != parameter.len() {
                            return Err(IplError::Sintaks {
                                pesan: format!("Fungsi mengharapkan {} argumen, tapi diberikan {}", parameter.len(), arg_eval.len()),
                                lokasi,
                                saran: None,
                            });
                        }

                        let func_env = Lingkungan::baru_nested(env);
                        for (i, param_nama) in parameter.iter().enumerate() {
                            func_env.borrow_mut().set(param_nama.clone(), arg_eval[i].clone());
                        }

                        let env_sebelumnya = Rc::clone(&self.lingkungan);
                        self.lingkungan = func_env;

                        let hasil = self.eval_block(body);

                        self.lingkungan = env_sebelumnya;

                        match hasil? {
                            Objek::Kembalikan(val) => Ok(*val),
                            _ => Ok(Objek::Kosong),
                        }
                    }
                    _ => {
                        Err(IplError::Sintaks {
                            pesan: "Tidak dapat memanggil (call) selain dari fungsi.".to_string(),
                            lokasi,
                            saran: None,
                        })
                    }
                }
            }
        }
    }

    fn eval_prefix_expression(&self, operator: PrefixOperator, kanan: Objek, lokasi: errors::Lokasi) -> Result<Objek, IplError> {
        match operator {
            PrefixOperator::Bukan => {
                Ok(Objek::Boolean(!is_truthy(&kanan)))
            }
            PrefixOperator::Minus => {
                match kanan {
                    Objek::Angka(val) => Ok(Objek::Angka(-val)),
                    _ => Err(IplError::TipeData {
                        pesan: "Operator '-' hanya bisa digunakan untuk Angka.".to_string(),
                        lokasi,
                        saran: None,
                    })
                }
            }
        }
    }

    fn eval_infix_expression(&self, operator: InfixOperator, kiri: Objek, kanan: Objek, lokasi: errors::Lokasi) -> Result<Objek, IplError> {
        match (kiri, kanan) {
            (Objek::Angka(kiri_val), Objek::Angka(kanan_val)) => {
                self.eval_angka_infix(operator, kiri_val, kanan_val, lokasi)
            }
            (Objek::String(kiri_val), Objek::String(kanan_val)) => {
                self.eval_string_infix(operator, kiri_val, kanan_val, lokasi)
            }
            (Objek::String(kiri_val), Objek::Angka(kanan_val)) => {
                if operator == InfixOperator::Tambah {
                    Ok(Objek::String(format!("{}{}", kiri_val, kanan_val)))
                } else {
                    Err(IplError::TipeData {
                        pesan: format!("Operator tidak didukung untuk String dan Angka"),
                        lokasi,
                        saran: None,
                    })
                }
            }
            (Objek::Angka(kiri_val), Objek::String(kanan_val)) => {
                if operator == InfixOperator::Tambah {
                    Ok(Objek::String(format!("{}{}", kiri_val, kanan_val)))
                } else {
                    Err(IplError::TipeData {
                        pesan: format!("Operator tidak didukung untuk Angka dan String"),
                        lokasi,
                        saran: None,
                    })
                }
            }
            (kiri_obj, kanan_obj) => {
                match operator {
                    InfixOperator::SamaDengan => Ok(Objek::Boolean(kiri_obj == kanan_obj)),
                    InfixOperator::TidakSamaDengan => Ok(Objek::Boolean(kiri_obj != kanan_obj)),
                    InfixOperator::Dan => Ok(Objek::Boolean(is_truthy(&kiri_obj) && is_truthy(&kanan_obj))),
                    InfixOperator::Atau => Ok(Objek::Boolean(is_truthy(&kiri_obj) || is_truthy(&kanan_obj))),
                    _ => Err(IplError::TipeData {
                        pesan: format!("Operator tidak didukung untuk tipe data {} dan {}", kiri_obj, kanan_obj),
                        lokasi,
                        saran: None,
                    })
                }
            }
        }
    }

    fn eval_angka_infix(&self, operator: InfixOperator, kiri: f64, kanan: f64, _lokasi: errors::Lokasi) -> Result<Objek, IplError> {
        match operator {
            InfixOperator::Tambah => Ok(Objek::Angka(kiri + kanan)),
            InfixOperator::Kurang => Ok(Objek::Angka(kiri - kanan)),
            InfixOperator::Kali => Ok(Objek::Angka(kiri * kanan)),
            InfixOperator::Bagi => Ok(Objek::Angka(kiri / kanan)),
            InfixOperator::Mod => Ok(Objek::Angka(kiri % kanan)),
            InfixOperator::LebihDari => Ok(Objek::Boolean(kiri > kanan)),
            InfixOperator::KurangDari => Ok(Objek::Boolean(kiri < kanan)),
            InfixOperator::Minimal => Ok(Objek::Boolean(kiri >= kanan)),
            InfixOperator::Maksimal => Ok(Objek::Boolean(kiri <= kanan)),
            InfixOperator::SamaDengan => Ok(Objek::Boolean(kiri == kanan)),
            InfixOperator::TidakSamaDengan => Ok(Objek::Boolean(kiri != kanan)),
            _ => Ok(Objek::Kosong),
        }
    }

    fn eval_string_infix(&self, operator: InfixOperator, kiri: String, kanan: String, lokasi: errors::Lokasi) -> Result<Objek, IplError> {
        match operator {
            InfixOperator::Tambah => Ok(Objek::String(format!("{}{}", kiri, kanan))),
            InfixOperator::SamaDengan => Ok(Objek::Boolean(kiri == kanan)),
            InfixOperator::TidakSamaDengan => Ok(Objek::Boolean(kiri != kanan)),
            _ => Err(IplError::TipeData {
                pesan: "Operasi matematika tidak didukung pada String kecuali Penjumlahan (+).".to_string(),
                lokasi,
                saran: None,
            })
        }
    }
}

fn is_truthy(obj: &Objek) -> bool {
    match obj {
        Objek::Kosong => false,
        Objek::Boolean(val) => *val,
        Objek::Angka(val) => *val != 0.0,
        _ => true,
    }
}
