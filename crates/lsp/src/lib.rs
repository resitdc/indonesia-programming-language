//! RPL Language Server Protocol (LSP) implementation.
//!
//! Provides diagnostics (errors from lexer, parser, and type checker),
//! autocompletion for keywords and built-in functions,
//! and hover documentation — for VS Code and other LSP-compatible editors.

use std::collections::HashMap;

use lsp_server::{Connection, Message, Notification, Response};
use lsp_types::{
    CompletionItem, CompletionItemKind, CompletionOptions, CompletionParams,
    Diagnostic, DiagnosticSeverity, Hover, HoverContents, HoverParams,
    MarkupContent, MarkupKind, OneOf, Position, Range,
    ServerCapabilities, TextDocumentSyncCapability, TextDocumentSyncKind,
    TextDocumentSyncOptions, Url,
};

use lexer::Lexer;
use parser::Parser;
use typechecker::TypeChecker;

pub fn run_lsp() -> anyhow::Result<()> {
    eprintln!("[RPL LSP] Memulai Language Server...");

    let (connection, io_threads) = Connection::stdio();

    let capabilities = ServerCapabilities {
        text_document_sync: Some(TextDocumentSyncCapability::Options(
            TextDocumentSyncOptions {
                open_close: Some(true),
                change: Some(TextDocumentSyncKind::FULL),
                will_save: None,
                will_save_wait_until: None,
                save: Some(lsp_types::TextDocumentSyncSaveOptions::Supported(true)),
            },
        )),
        completion_provider: Some(CompletionOptions {
            trigger_characters: Some(vec![".".to_string()]),
            ..Default::default()
        }),
        hover_provider: Some(lsp_types::HoverProviderCapability::Simple(true)),
        definition_provider: Some(OneOf::Left(true)),
        ..Default::default()
    };

    let server_capabilities = serde_json::to_value(&capabilities).unwrap();
    let _ = connection.initialize(server_capabilities)?;
    main_loop(&connection)?;

    io_threads.join()?;
    eprintln!("[RPL LSP] Server dimatikan.");
    Ok(())
}

struct DocumentStore {
    docs: HashMap<String, String>,
}

impl DocumentStore {
    fn new() -> Self { Self { docs: HashMap::new() } }
    fn set(&mut self, uri: &str, content: String) {
        self.docs.insert(uri.to_string(), content);
    }
    fn get(&self, uri: &str) -> Option<&str> {
        self.docs.get(uri).map(|s| s.as_str())
    }
}

fn main_loop(connection: &Connection) -> anyhow::Result<()> {
    let mut store = DocumentStore::new();

    for msg in &connection.receiver {
        match msg {
            Message::Request(req) => {
                if connection.handle_shutdown(&req)? {
                    return Ok(());
                }
                let resp = handle_request(&mut store, &req);
                connection.sender.send(Message::Response(resp))?;
            }
            Message::Notification(not) => {
                handle_notification(connection, &mut store, not)?;
            }
            Message::Response(_) => {}
        }
    }

    Ok(())
}

fn handle_request(store: &mut DocumentStore, req: &lsp_server::Request) -> Response {
    let id = req.id.clone();

    match req.method.as_str() {
        "textDocument/completion" => {
            if let Ok(params) = serde_json::from_value::<CompletionParams>(req.params.clone()) {
                let _uri = params.text_document_position.text_document.uri.to_string();
                Response {
                    id,
                    result: Some(serde_json::to_value(get_completions()).unwrap()),
                    error: None,
                }
            } else {
                Response {
                    id,
                    result: None,
                    error: Some(lsp_server::ResponseError {
                        code: -32602,
                        message: "Invalid params".to_string(),
                        data: None,
                    }),
                }
            }
        }
        "textDocument/hover" => {
            if let Ok(params) = serde_json::from_value::<HoverParams>(req.params.clone()) {
                let uri = params.text_document_position_params.text_document.uri.to_string();
                let content = store.get(&uri).unwrap_or("");
                let pos = params.text_document_position_params.position;
                let hover = get_hover(content, &pos);
                Response {
                    id,
                    result: Some(serde_json::to_value(hover).unwrap()),
                    error: None,
                }
            } else {
                Response { id, result: None, error: Some(lsp_server::ResponseError { code: -32602, message: "Invalid params".to_string(), data: None }) }
            }
        }
        "textDocument/definition" => {
            Response {
                id,
                result: Some(serde_json::to_value(None::<()>).unwrap()),
                error: None,
            }
        }
        _ => Response {
            id,
            result: None,
            error: Some(lsp_server::ResponseError {
                code: lsp_server::ErrorCode::MethodNotFound as i32,
                message: format!("Method not supported: {}", req.method),
                data: None,
            }),
        },
    }
}

fn handle_notification(
    connection: &Connection,
    store: &mut DocumentStore,
    not: Notification,
) -> anyhow::Result<()> {
    if let "textDocument/didOpen" | "textDocument/didChange" = not.method.as_str() {
        if let Ok(params) = serde_json::from_value::<lsp_types::DidChangeTextDocumentParams>(not.params) {
            let uri = params.text_document.uri.to_string();
            if let Some(change) = params.content_changes.into_iter().next() {
                store.set(&uri, change.text);
            }
            send_diagnostics(connection, store, &params.text_document.uri)?;
        }
    }
    Ok(())
}

fn send_diagnostics(
    connection: &Connection,
    store: &DocumentStore,
    uri: &Url,
) -> anyhow::Result<()> {
    let content = store.get(uri.as_str()).unwrap_or("");
    let diagnostics = compute_diagnostics(content);

    let params = lsp_types::PublishDiagnosticsParams {
        uri: uri.clone(),
        diagnostics,
        version: None,
    };

    let not = Notification {
        method: "textDocument/publishDiagnostics".to_string(),
        params: serde_json::to_value(params).unwrap(),
    };

    connection.sender.send(Message::Notification(not))?;
    Ok(())
}

fn compute_diagnostics(source: &str) -> Vec<Diagnostic> {
    let mut diags = Vec::new();

    // --- Lexer ---
    let mut lexer = Lexer::new(source);
    let tokens = match lexer.tokenize() {
        Ok(t) => t,
        Err(e) => {
            // RplError implements Display; extract message & location via Display
            let msg = e.to_string();
            let (line, col) = extract_error_location(&e);
            diags.push(Diagnostic {
                range: Range {
                    start: Position { line, character: col },
                    end: Position { line, character: col + 5 },
                },
                severity: Some(DiagnosticSeverity::ERROR),
                source: Some("rpl-lsp".to_string()),
                message: msg,
                ..Default::default()
            });
            return diags;
        }
    };

    // --- Parser ---
    let mut parser = Parser::new(tokens);
    let program = parser.parse_program();

    for err in &program.errors {
        let msg = err.to_string();
        let (line, col) = extract_error_location(err);
        diags.push(Diagnostic {
            range: Range {
                start: Position { line, character: col },
                end: Position { line, character: col + 10 },
            },
            severity: Some(DiagnosticSeverity::ERROR),
            source: Some("rpl-lsp".to_string()),
            message: msg,
            ..Default::default()
        });
    }

    // --- Type checker ---
    let mut checker = TypeChecker::new();
    let result = checker.check(&program);

    for type_err in &result.errors {
        let line = (type_err.lokasi.baris.saturating_sub(1)) as u32;
        let col = (type_err.lokasi.kolom.saturating_sub(1)) as u32;
        let msg = if let Some(ref saran) = type_err.saran {
            format!("{} 💡 {}", type_err.pesan, saran)
        } else {
            type_err.pesan.clone()
        };
        diags.push(Diagnostic {
            range: Range {
                start: Position { line, character: col },
                end: Position { line, character: col + 10 },
            },
            severity: Some(DiagnosticSeverity::WARNING),
            source: Some("rpl-lsp".to_string()),
            message: msg,
            ..Default::default()
        });
    }

    diags
}

/// Extract line and column from RplError via Display.
fn extract_error_location(err: &errors::RplError) -> (u32, u32) {
    let msg = err.to_string();
    // Try to extract baris:kolom from format_error style messages
    // Fallback to (0, 0)
    for line in msg.lines() {
        if let Some(pos) = line.find("-->") {
            let rest = &line[pos + 3..].trim();
            if let Some(colon) = rest.find(':') {
                let line_str = &rest[..colon];
                let col_rest = &rest[colon + 1..];
                if let Some(colon2) = col_rest.find(':') {
                    let col_str = &col_rest[..colon2];
                    if let (Ok(l), Ok(c)) = (line_str.parse::<usize>(), col_str.parse::<usize>()) {
                        return (l.saturating_sub(1) as u32, c.saturating_sub(1) as u32);
                    }
                }
            }
        }
    }
    // Default position
    (0, 0)
}

fn get_completions() -> Vec<CompletionItem> {
    let mut items = Vec::new();

    for (label, detail, kind) in &[
        ("buat", "Deklarasi variabel", CompletionItemKind::KEYWORD),
        ("fungsi", "Deklarasi fungsi", CompletionItemKind::KEYWORD),
        ("kembalikan", "Nilai kembali", CompletionItemKind::KEYWORD),
        ("jika", "Percabangan", CompletionItemKind::KEYWORD),
        ("maka", "Blok kondisi", CompletionItemKind::KEYWORD),
        ("selesai", "Akhir blok", CompletionItemKind::KEYWORD),
        ("selama", "Perulangan", CompletionItemKind::KEYWORD),
        ("tampilkan", "Cetak ke layar", CompletionItemKind::KEYWORD),
        ("cetak", "Cetak tanpa newline", CompletionItemKind::KEYWORD),
        ("coba", "Blok try", CompletionItemKind::KEYWORD),
        ("tangkap", "Blok catch", CompletionItemKind::KEYWORD),
        ("lempar", "Lempar error", CompletionItemKind::KEYWORD),
        ("impor", "Impor modul", CompletionItemKind::KEYWORD),
        ("gabung", "Impor modul", CompletionItemKind::KEYWORD),
        ("pakai", "Impor modul", CompletionItemKind::KEYWORD),
        ("benar", "Boolean true", CompletionItemKind::CONSTANT),
        ("salah", "Boolean false", CompletionItemKind::CONSTANT),
        ("kosong", "Null", CompletionItemKind::CONSTANT),
        ("panjang", "Panjang", CompletionItemKind::FUNCTION),
        ("db.kueri", "Query SQL", CompletionItemKind::FUNCTION),
        ("db.hubungkan", "Koneksi DB", CompletionItemKind::FUNCTION),
        ("web.get", "Rute GET", CompletionItemKind::FUNCTION),
        ("web.post", "Rute POST", CompletionItemKind::FUNCTION),
        ("web.put", "Rute PUT", CompletionItemKind::FUNCTION),
        ("web.delete", "Rute DELETE", CompletionItemKind::FUNCTION),
        ("web.render", "Render template", CompletionItemKind::FUNCTION),
        ("web.jalankan", "Jalankan server", CompletionItemKind::FUNCTION),
        ("json.parse", "Parse JSON", CompletionItemKind::FUNCTION),
        ("json.buat", "Buat JSON", CompletionItemKind::FUNCTION),
        ("string.dari", "Ke string", CompletionItemKind::FUNCTION),
        ("kripto.sha256", "SHA-256", CompletionItemKind::FUNCTION),
        ("waktu.sekarang", "Waktu sekarang", CompletionItemKind::FUNCTION),
        ("list.tambah", "Tambah ke list", CompletionItemKind::FUNCTION),
    ] {
        items.push(CompletionItem {
            label: label.to_string(),
            detail: Some(detail.to_string()),
            kind: Some(*kind),
            insert_text: Some(label.to_string()),
            ..Default::default()
        });
    }

    items
}

fn get_hover(source: &str, position: &Position) -> Option<Hover> {
    let line_idx = position.line as usize;
    let col = position.character as usize;

    let lines: Vec<&str> = source.lines().collect();
    if line_idx >= lines.len() {
        return None;
    }
    let current_line = lines[line_idx];
    if col >= current_line.len() {
        return None;
    }

    let word = extract_word_at(current_line, col)?;

    let text = match word.as_str() {
        "buat" => "# buat\nMembuat variabel baru.\n\n**Contoh:** `buat x = 10`",
        "fungsi" => "# fungsi\nMendeklarasikan fungsi.\n\n**Contoh:** `fungsi tambah(a, b)`",
        "kembalikan" => "# kembalikan\nMengembalikan nilai dari fungsi.\n\n**Contoh:** `kembalikan x + y`",
        "jika" => "# jika\nPercabangan kondisi.\n\n**Contoh:** `jika x > 5 maka ... selesai`",
        "selama" => "# selama\nPerulangan.\n\n**Contoh:** `selama i < 10 maka ... selesai`",
        "tampilkan" => "# tampilkan\nCetak ke layar (dengan newline).",
        "cetak" => "# cetak\nCetak tanpa newline.",
        "coba" => "# coba\nBlok try-catch.\n\n**Contoh:** `coba ... tangkap (e) ... selesai`",
        "benar" => "# benar\nNilai boolean `true`.",
        "salah" => "# salah\nNilai boolean `false`.",
        "kosong" => "# kosong\nNilai null/kosong.",
        "panjang" => "# panjang()\nMengembalikan panjang array, string, atau kamus.",
        "db" => "# db\nModul database.\n\n- `db.kueri(sql)`\n- `db.hubungkan(url)`",
        "web" => "# web\nModul web server.\n\n- `web.get()`, `web.post()`, `web.put()`, `web.delete()`\n- `web.render(file, data)`\n- `web.jalankan(port)`",
        "json" => "# json\nModul JSON.\n\n- `json.parse(teks)`\n- `json.buat(nilai)`",
        "string" => "# string\nModul teks.\n\n- `string.dari(nilai)`\n- `string.ke_base64(teks)`",
        "kripto" => "# kripto\nModul kriptografi.\n\n- `kripto.sha256(teks)`",
        "waktu" => "# waktu\nModul tanggal & waktu.\n\n- `waktu.sekarang()`",
        "list" => "# list\nModul array/list.\n\n- `list.tambah(list, item)`",
        _ => return None,
    };

    Some(Hover {
        contents: HoverContents::Markup(MarkupContent {
            kind: MarkupKind::Markdown,
            value: text.to_string(),
        }),
        range: Some(Range {
            start: Position { line: position.line, character: (col.saturating_sub(word.len())) as u32 },
            end: Position { line: position.line, character: (col + 1) as u32 },
        }),
    })
}

fn extract_word_at(line: &str, col: usize) -> Option<String> {
    let bytes = line.as_bytes();
    if col >= bytes.len() { return None; }

    let mut start = col;
    while start > 0 && is_word_char(bytes[start - 1]) { start -= 1; }

    let mut end = col;
    while end < bytes.len() && is_word_char(bytes[end]) { end += 1; }

    if start < end {
        Some(line[start..end].to_string())
    } else {
        None
    }
}

fn is_word_char(c: u8) -> bool {
    c.is_ascii_alphanumeric() || c == b'_' || c == b'.'
}