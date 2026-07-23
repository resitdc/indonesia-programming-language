use crate::heap::HeapData;
use crate::machine::VM;
use crate::value::{FungsiBawaanVM, Value, VmContext};
use std::collections::HashMap;

fn extract_text_from_html(html: &str) -> Vec<String> {
    let mut paragraphs = Vec::new();
    let mut clean = String::new();
    let mut in_tag = false;

    let replaced = html
        .replace("<br>", "\n")
        .replace("<br/>", "\n")
        .replace("</p>", "\n")
        .replace("</h1>", "\n")
        .replace("</h2>", "\n")
        .replace("</h3>", "\n")
        .replace("</div>", "\n")
        .replace("</li>", "\n");

    for c in replaced.chars() {
        if c == '<' {
            in_tag = true;
        } else if c == '>' {
            in_tag = false;
        } else if !in_tag {
            clean.push(c);
        }
    }

    for line in clean.lines() {
        let trimmed = line.trim();
        if !trimmed.is_empty() {
            paragraphs.push(trimmed.to_string());
        }
    }

    paragraphs
}

pub fn register(vm: &mut VM) {
    let mut dokumen_module = HashMap::new();

    let buat_func = FungsiBawaanVM {
        nama: "buat".to_string(),
        func: std::sync::Arc::new(
            move |ctx: &mut dyn VmContext, args: Vec<Value>| -> Result<Value, String> {
                if args.len() != 3 {
                    return Err(
                        "Fungsi 'dokumen.buat' membutuhkan 3 argumen: sumber, nama_file, jenis"
                            .to_string(),
                    );
                }

                let sumber = match &args[0] {
                    Value::String(idx) => ctx.get_heap_mut().get_string(*idx).clone(),
                    _ => return Err("Argumen 'sumber' harus berupa teks".to_string()),
                };

                let nama_file = match &args[1] {
                    Value::String(idx) => ctx.get_heap_mut().get_string(*idx).clone(),
                    _ => return Err("Argumen 'nama_file' harus berupa teks".to_string()),
                };

                let jenis = match &args[2] {
                    Value::String(idx) => {
                        ctx.get_heap_mut().get_string(*idx).clone().to_lowercase()
                    }
                    _ => {
                        return Err(
                            "Argumen 'jenis' harus berupa teks ('docx' atau 'pdf')".to_string()
                        )
                    }
                };

                let html_content =
                    if sumber.ends_with(".html") && std::path::Path::new(&sumber).exists() {
                        std::fs::read_to_string(&sumber).unwrap_or(sumber.clone())
                    } else {
                        sumber.clone()
                    };

                let paragraphs = extract_text_from_html(&html_content);
                let final_filename = if nama_file.ends_with(&format!(".{}", jenis)) {
                    nama_file.clone()
                } else {
                    format!("{}.{}", nama_file, jenis)
                };

                if jenis == "docx" {
                    use docx_rs::*;
                    let mut doc = Docx::new();
                    for p in paragraphs {
                        doc = doc.add_paragraph(Paragraph::new().add_run(Run::new().add_text(p)));
                    }
                    let file = std::fs::File::create(&final_filename).map_err(|e| e.to_string())?;
                    doc.build().pack(file).map_err(|e| e.to_string())?;
                } else if jenis == "pdf" {
                    use turbo_html2pdf_core::{
                        build_cascade, compile, emit_pdf, render_pages, style::TokenSet,
                        CompileOptions, Diagnostics, EmitOptions, FontRegistry, RenderInputs, NoImages
                    };
                    
                    let (program, _diags) = compile(&html_content, &CompileOptions::default())
                        .map_err(|e| format!("Gagal kompilasi HTML: {:?}", e.code))?;
                        
                    let data = serde_json::Value::Null;
                    
                    let mut author_css = String::new();
                    if let Some(start) = html_content.find("<style>") {
                        if let Some(end) = html_content.find("</style>") {
                            if start < end {
                                author_css = html_content[start + 7..end].to_string();
                            }
                        }
                    }
                    
                    let cascade = build_cascade(&author_css, "", TokenSet::default());
                    let fonts = FontRegistry::new();
                    let rules = turbo_html2pdf_core::style::parse_stylesheet(&author_css).at_rules;
                    
                    let inputs = RenderInputs {
                        program: &program,
                        data: &data,
                        cascade: &cascade,
                        at_rules: &rules,
                        fonts: &fonts,
                        images: &NoImages,
                        now: Some(0),
                    };
                    
                    let mut diags = Diagnostics::default();
                    let pages = render_pages(&inputs, &mut diags)
                        .map_err(|e| format!("Gagal render PDF: {:?}", e.code))?;
                        
                    let pdf_bytes = emit_pdf(&pages, &EmitOptions::default());
                    
                    std::fs::write(&final_filename, pdf_bytes).map_err(|e| e.to_string())?;
                } else {
                    return Err(
                        "Jenis laporan tidak didukung. Gunakan 'docx' atau 'pdf'.".to_string()
                    );
                }

                Ok(Value::Kosong)
            },
        ),
    };

    let buat_idx = vm.heap.alloc(HeapData::FungsiBawaan(buat_func));
    dokumen_module.insert("buat".to_string(), Value::FungsiBawaan(buat_idx));

    let dokumen_idx = vm.heap.alloc(HeapData::Kamus(dokumen_module));
    vm.environments[0].insert("dokumen".to_string(), Value::Kamus(dokumen_idx));
}
