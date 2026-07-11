use crate::opcodes::OpCode;
use crate::compiler::Chunk;
use std::collections::HashMap;
use crate::heap::{Heap, HeapData};
use crate::value::{FungsiVM, Value};
use errors::Lokasi;

#[derive(Clone)]
pub struct CallFrame {
    pub fungsi: usize, // index to Heap.fungsi
    pub ip: usize,
    pub stack_offset: usize,
}

impl CallFrame {
    pub fn read_byte(&mut self, heap: &Heap) -> u8 {
        let byte = heap.get_fungsi(self.fungsi).chunk.code[self.ip];
        self.ip += 1;
        byte
    }
    
    pub fn read_short(&mut self, heap: &Heap) -> u16 {
        let b1 = self.read_byte(heap) as u16;
        let b2 = self.read_byte(heap) as u16;
        (b1 << 8) | b2
    }

    fn read_constant(&mut self, heap: &Heap) -> Value {
        let index = self.read_short(heap);
        heap.get_fungsi(self.fungsi).chunk.constants[index as usize]
    }
}

pub struct VM {
    frames: Vec<CallFrame>,
    stack: Vec<Value>,
    globals: HashMap<String, Value>,
    pub heap: Heap,
    pub tasks: HashMap<usize, std::thread::JoinHandle<(Result<Value, String>, Heap)>>,
    pub next_task_id: usize,
}

impl Default for VM {
    fn default() -> Self {
        Self::new()
    }
}

impl VM {
    pub fn new() -> Self {
        Self {
            frames: Vec::with_capacity(64),
            stack: Vec::with_capacity(256),
            globals: HashMap::new(),
            heap: Heap::new(),
            tasks: HashMap::new(),
            next_task_id: 1,
        }
    }

    pub fn clone_vm(&self) -> VM {
        VM {
            frames: self.frames.clone(),
            stack: self.stack.clone(),
            globals: self.globals.clone(),
            heap: self.heap.clone(),
            tasks: HashMap::new(),
            next_task_id: 1,
        }
    }

    pub fn set_global(&mut self, name: String, value: Value) {
        self.globals.insert(name, value);
    }

    pub fn gc_collect(&mut self) {
        let mut roots = Vec::new();
        for val in &self.stack { roots.push(*val); }
        for val in self.globals.values() { roots.push(*val); }
        for frame in &self.frames { roots.push(Value::Fungsi(frame.fungsi)); }
        
        for val in roots {
            match val {
                Value::Array(i) | Value::Kamus(i) | Value::String(i) | Value::Fungsi(i) | Value::FungsiBawaan(i) => {
                    self.heap.mark(i);
                },
                _ => {}
            }
        }
        
        let before = self.heap.allocated_count;
        self.heap.sweep();
        let after = self.heap.allocated_count;
        
        if before > after {
            // println!("[GC] Dibersihkan: {} objek", before - after); // Disabled to keep output clean, but can be enabled for debugging
        }
    }



    fn current_lokasi(&self) -> Option<Lokasi> {
        if let Some(frame) = self.frames.last() {
            let ip = if frame.ip > 0 { frame.ip - 1 } else { 0 };
            if let crate::heap::HeapData::Fungsi(f) = &self.heap.objects[frame.fungsi].data {
                return f.chunk.locations.get(ip).copied();
            }
        }
        None
    }

    fn err(&self, msg: impl Into<String>) -> (String, Option<Lokasi>) {
        (msg.into(), self.current_lokasi())
    }

    pub fn execute(&mut self, chunk: Chunk) -> Result<(), (String, Option<Lokasi>)> {
        let main_fungsi = FungsiVM {
            nama: "main".to_string(),
            parameter: vec![],
            chunk,
        };
        let fungsi_idx = self.heap.alloc(HeapData::Fungsi(main_fungsi));

        self.frames.push(CallFrame {
            fungsi: fungsi_idx,
            ip: 0,
            stack_offset: 0,
        });

        self.run(0)
    }

    fn run(&mut self, initial_frames: usize) -> Result<(), (String, Option<Lokasi>)> {
        loop {
            // Trigger GC if we allocated a lot
            if self.heap.allocated_count > 1000 {
                self.gc_collect();
            }

            let instruction = {
                let frame = self.frames.last_mut().unwrap();
                frame.read_byte(&self.heap)
            };

            let opcode = OpCode::from_u8(instruction)
                .ok_or_else(|| self.err(format!("Unknown opcode {}", instruction)))?;

            match opcode {
                OpCode::Return => {
                    let result = self.stack.pop().unwrap_or(Value::Kosong);
                    
                    let frame = self.frames.pop().unwrap();
                    
                    self.stack.truncate(frame.stack_offset);
                    self.stack.push(result);

                    if self.frames.len() == initial_frames {
                        return Ok(());
                    }
                }
                OpCode::LoadConst => {
                    let constant = self.frames.last_mut().unwrap().read_constant(&self.heap);
                    self.stack.push(constant);
                }
                OpCode::LoadVar => {
                    let name_val = self.frames.last_mut().unwrap().read_constant(&self.heap);
                    if let Value::String(name_idx) = name_val {
                        let name = self.heap.get_string(name_idx).clone();
                        let val = self.globals.get(&name)
                            .cloned()
                            .ok_or_else(|| self.err(format!("Variabel '{}' belum dibuat.", name)))?;
                        self.stack.push(val);
                    }
                }
                OpCode::StoreVar => {
                    let name_val = self.frames.last_mut().unwrap().read_constant(&self.heap);
                    if let Value::String(name_idx) = name_val {
                        let name = self.heap.get_string(name_idx).clone();
                        let val = self.stack.pop().unwrap_or(Value::Kosong);
                        self.globals.insert(name, val);
                    }
                }
                OpCode::Add => {
                    let b = self.stack.pop().unwrap();
                    let a = self.stack.pop().unwrap();
                    match (a, b) {
                        (Value::Angka(a_val), Value::Angka(b_val)) => self.stack.push(Value::Angka(a_val + b_val)),
                        (a, b) => {
                            let is_a_string = matches!(a, Value::String(_));
                            let is_b_string = matches!(b, Value::String(_));
                            if is_a_string || is_b_string {
                                let s1 = a.to_string(&self.heap);
                                let s2 = b.to_string(&self.heap);
                                let new_idx = self.heap.alloc(HeapData::String(format!("{}{}", s1, s2)));
                                self.stack.push(Value::String(new_idx));
                            } else {
                                return Err(self.err("Operan harus angka atau teks untuk dijumlahkan"));
                            }
                        }
                    }
                }
                OpCode::Subtract => {
                    let b = self.stack.pop().unwrap();
                    let a = self.stack.pop().unwrap();
                    if let (Value::Angka(a_val), Value::Angka(b_val)) = (a, b) {
                        self.stack.push(Value::Angka(a_val - b_val));
                    } else {
                        return Err(self.err("Operan harus angka untuk dikurangkan"));
                    }
                }
                OpCode::Multiply => {
                    let b = self.stack.pop().unwrap();
                    let a = self.stack.pop().unwrap();
                    if let (Value::Angka(a_val), Value::Angka(b_val)) = (a, b) {
                        self.stack.push(Value::Angka(a_val * b_val));
                    } else {
                        return Err(self.err("Operan harus angka untuk dikali"));
                    }
                }
                OpCode::Divide => {
                    let b = self.stack.pop().unwrap();
                    let a = self.stack.pop().unwrap();
                    if let (Value::Angka(a_val), Value::Angka(b_val)) = (a, b) {
                        if b_val == 0.0 {
                            return Err(self.err("Pembagian dengan nol"));
                        }
                        self.stack.push(Value::Angka(a_val / b_val));
                    } else {
                        return Err(self.err("Operan harus angka untuk dibagi"));
                    }
                }
                OpCode::Modulus => {
                    let b = self.stack.pop().unwrap();
                    let a = self.stack.pop().unwrap();
                    if let (Value::Angka(a_val), Value::Angka(b_val)) = (a, b) {
                        self.stack.push(Value::Angka(a_val % b_val));
                    } else {
                        return Err(self.err("Operan harus angka untuk modulus"));
                    }
                }
                OpCode::Equal => {
                    let b = self.stack.pop().unwrap();
                    let a = self.stack.pop().unwrap();
                    self.stack.push(Value::Boolean(a == b));
                }
                OpCode::NotEqual => {
                    let b = self.stack.pop().unwrap();
                    let a = self.stack.pop().unwrap();
                    self.stack.push(Value::Boolean(a != b));
                }
                OpCode::Greater => {
                    let b = self.stack.pop().unwrap();
                    let a = self.stack.pop().unwrap();
                    if let (Value::Angka(a_val), Value::Angka(b_val)) = (a, b) {
                        self.stack.push(Value::Boolean(a_val > b_val));
                    }
                }
                OpCode::Less => {
                    let b = self.stack.pop().unwrap();
                    let a = self.stack.pop().unwrap();
                    if let (Value::Angka(a_val), Value::Angka(b_val)) = (a, b) {
                        self.stack.push(Value::Boolean(a_val < b_val));
                    }
                }
                OpCode::GreaterEqual => {
                    let b = self.stack.pop().unwrap();
                    let a = self.stack.pop().unwrap();
                    if let (Value::Angka(a_val), Value::Angka(b_val)) = (a, b) {
                        self.stack.push(Value::Boolean(a_val >= b_val));
                    }
                }
                OpCode::LessEqual => {
                    let b = self.stack.pop().unwrap();
                    let a = self.stack.pop().unwrap();
                    if let (Value::Angka(a_val), Value::Angka(b_val)) = (a, b) {
                        self.stack.push(Value::Boolean(a_val <= b_val));
                    }
                }
                OpCode::And => {
                    let b = self.stack.pop().unwrap();
                    let a = self.stack.pop().unwrap();
                    self.stack.push(Value::Boolean(is_truthy(&a) && is_truthy(&b)));
                }
                OpCode::Or => {
                    let b = self.stack.pop().unwrap();
                    let a = self.stack.pop().unwrap();
                    self.stack.push(Value::Boolean(is_truthy(&a) || is_truthy(&b)));
                }
                OpCode::Not => {
                    let a = self.stack.pop().unwrap();
                    self.stack.push(Value::Boolean(!is_truthy(&a)));
                }
                OpCode::Print => {
                    let a = self.stack.pop().unwrap();
                    println!("{}", a.to_string(&self.heap));
                }
                OpCode::JumpIfFalse => {
                    let offset = self.frames.last_mut().unwrap().read_short(&self.heap) as usize;
                    let peek = self.stack.last().unwrap_or(&Value::Kosong);
                    if !is_truthy(peek) {
                        self.frames.last_mut().unwrap().ip = offset;
                    }
                }
                OpCode::Jump => {
                    let offset = self.frames.last_mut().unwrap().read_short(&self.heap) as usize;
                    self.frames.last_mut().unwrap().ip = offset;
                }
                OpCode::Call => {
                    let arg_count = self.frames.last_mut().unwrap().read_byte(&self.heap) as usize;
                    let fungsi_val = self.stack[self.stack.len() - arg_count - 1];
                    
                    match fungsi_val {
                        Value::Fungsi(fungsi_idx) => {
                            let (p_len, params) = {
                                let f = self.heap.get_fungsi(fungsi_idx);
                                (f.parameter.len(), f.parameter.clone())
                            };
                            if arg_count != p_len {
                                let f_nama = self.heap.get_fungsi(fungsi_idx).nama.clone();
                                return Err(self.err(format!("Fungsi '{}' membutuhkan {} argumen, tetapi diberikan {}", f_nama, p_len, arg_count)));
                            }
                            
                            for i in 0..arg_count {
                                let arg_val = self.stack[self.stack.len() - arg_count + i];
                                self.globals.insert(params[i].clone(), arg_val);
                            }
                            
                            let stack_offset = self.stack.len() - arg_count - 1;
                            self.frames.push(CallFrame {
                                fungsi: fungsi_idx,
                                ip: 0,
                                stack_offset,
                            });
                        }
                        Value::FungsiBawaan(fungsi_idx) => {
                            let mut args = Vec::with_capacity(arg_count);
                            for _ in 0..arg_count {
                                args.push(self.stack.pop().unwrap());
                            }
                            args.reverse();
                            
                            self.stack.pop(); // Pop function itself
                            
                            let func_ptr = self.heap.get_fungsi_bawaan(fungsi_idx).func;
                            // Pass heap implicitly
                            let result = func_ptr(self, args).map_err(|e| self.err(e))?;
                            self.stack.push(result);
                        }
                        _ => return Err(self.err(format!("Hanya fungsi yang dapat dipanggil. Ditemukan: {:?}", fungsi_val))),
                    }
                }
                OpCode::GetIndex => {
                    let index = self.stack.pop().unwrap();
                    let target = self.stack.pop().unwrap();
                    
                    match target {
                        Value::Kamus(k_idx) => {
                            if let Value::String(key_idx) = index {
                                let key_str = self.heap.get_string(key_idx).clone();
                                let val = self.heap.get_kamus(k_idx).get(&key_str).cloned().unwrap_or(Value::Kosong);
                                self.stack.push(val);
                            } else {
                                return Err(self.err("Indeks kamus harus berupa teks"));
                            }
                        }
                        Value::Array(a_idx) => {
                            if let Value::Angka(idx) = index {
                                let i = idx as usize;
                                let val = self.heap.get_array(a_idx).get(i).cloned().unwrap_or(Value::Kosong);
                                self.stack.push(val);
                            } else {
                                return Err(self.err("Indeks array harus berupa angka"));
                            }
                        }
                        _ => return Err(self.err("Operasi index tidak didukung untuk tipe ini")),
                    }
                }
                OpCode::MakeArray => {
                    let count = self.frames.last_mut().unwrap().read_short(&self.heap) as usize;
                    let mut elements = Vec::with_capacity(count);
                    for _ in 0..count {
                        elements.push(self.stack.pop().unwrap());
                    }
                    elements.reverse();
                    let new_idx = self.heap.alloc(HeapData::Array(elements));
                    self.stack.push(Value::Array(new_idx));
                }
                OpCode::MakeKamus => {
                    let count = self.frames.last_mut().unwrap().read_short(&self.heap) as usize;
                    let mut map = HashMap::with_capacity(count);
                    for _ in 0..count {
                        let v = self.stack.pop().unwrap();
                        let k = self.stack.pop().unwrap();
                        if let Value::String(key_idx) = k {
                            let key_str = self.heap.get_string(key_idx).clone();
                            map.insert(key_str, v);
                        } else {
                            return Err(self.err("Kunci kamus harus berupa teks"));
                        }
                    }
                    let new_idx = self.heap.alloc(HeapData::Kamus(map));
                    self.stack.push(Value::Kamus(new_idx));
                }
            }
        }
    }
}

fn is_truthy(val: &Value) -> bool {
    match val {
        Value::Kosong => false,
        Value::Boolean(b) => *b,
        Value::Angka(a) => *a != 0.0,
        _ => true,
    }
}

use crate::value::VmContext;

impl VmContext for VM {
    fn get_heap_mut(&mut self) -> &mut Heap {
        &mut self.heap
    }

    fn execute_function(&mut self, func_idx: usize, args: Vec<Value>) -> Result<Value, String> {
        let func = self.heap.get_fungsi(func_idx).clone();
        
        // Push args
        for arg in &args {
            self.stack.push(*arg);
        }
        
        // Insert into globals
        for i in 0..func.parameter.len() {
            if i < args.len() {
                self.globals.insert(func.parameter[i].clone(), args[i]);
            }
        }
        
        let stack_offset = self.stack.len() - args.len();
        self.frames.push(CallFrame {
            fungsi: func_idx,
            ip: 0,
            stack_offset,
        });

        let target_frames = self.frames.len() - 1;
        match self.run(target_frames) {
            Ok(_) => {
                let result = self.stack.pop().unwrap_or(Value::Kosong);
                Ok(result)
            }
            Err((msg, _lokasi)) => Err(msg),
        }
    }

    fn spawn_task(&mut self, func_idx: usize) -> Result<usize, String> {
        let mut vm_clone = self.clone_vm();
        
        let handle = std::thread::spawn(move || {
            let res = vm_clone.execute_function(func_idx, vec![]);
            (res, vm_clone.heap)
        });
        
        let task_id = self.next_task_id;
        self.next_task_id += 1;
        self.tasks.insert(task_id, handle);
        
        Ok(task_id)
    }

    fn join_task(&mut self, task_id: usize) -> Result<Value, String> {
        if let Some(handle) = self.tasks.remove(&task_id) {
            match handle.join() {
                Ok((res, background_heap)) => {
                    match res {
                        Ok(val) => {
                            let copied_val = crate::value::deep_copy_value(&val, &background_heap, &mut self.heap);
                            Ok(copied_val)
                        }
                        Err(e) => Err(e),
                    }
                }
                Err(_) => Err("Gagal menunggu tugas background (Thread Panicked)".to_string()),
            }
        } else {
            Err(format!("Tiket tugas dengan ID {} tidak ditemukan.", task_id))
        }
    }
}
