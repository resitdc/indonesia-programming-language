# RPL — Rakoda Programming Language

**RPL** is a modern programming language designed specifically for Indonesian education. Its syntax uses **Bahasa Indonesia** keywords, making it immediately accessible to Indonesian students from elementary school to university.

RPL is not just a language — it is a complete ecosystem comprising a compiler, virtual machine, web engine, package manager, IDE tooling, and classroom systems.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Philosophy](#philosophy)
- [Project Structure](#project-structure)
- [Architecture Overview](#architecture-overview)
- [Crate Dependency Graph](#crate-dependency-graph)
- [Execution Pipeline](#execution-pipeline)
- [CLI Commands](#cli-commands)
- [Language Features](#language-features)
- [Standard Library](#standard-library)
- [Development Guide](#development-guide)
  - [Prerequisites](#prerequisites)
  - [Building](#building)
  - [Running Tests](#running-tests)
  - [Code Quality](#code-quality)
  - [Project Conventions](#project-conventions)
- [How to Add a New Feature](#how-to-add-a-new-feature)
  - [Adding a New Language Keyword](#adding-a-new-language-keyword)
  - [Adding a New Standard Library Function](#adding-a-new-standard-library-function)
  - [Adding a New CLI Command](#adding-a-new-cli-command)
  - [Adding a New VM Opcode](#adding-a-new-vm-opcode)
  - [Adding a New Crate](#adding-a-new-crate)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Quick Start

```bash
# Clone the repository
git clone git@github.com:resitdc/indonesia-programming-language.git
cd indonesia-programming-language

# Build the project
cargo build --release

# Run a RPL program
./target/release/rpl run examples/test.rpl

# Check syntax without executing
./target/release/rpl cek main.rpl

# Check version
./target/release/rpl --version
```

**Hello World in RPL:**

```rpl
tampilkan("Halo Dunia!")
```

---

## Philosophy

RPL is built on five core principles:

1. **Made for humans, not just computers** — Syntax should read like natural Indonesian sentences.
2. **Educational error messages** — Every error explains the cause and suggests a fix.
3. **Every feature has educational value** — No feature exists without a learning purpose.
4. **Prefer clarity over cleverness** — If two solutions are equally good, pick the one easier for students to understand.
5. **Show the process** — Avoid "magic" that hides how the system works; expose the process if it aids learning.

Target audiences: **SD** (elementary), **SMP** (middle school), **SMK** (vocational), **University students**, and **absolute beginners**.

---

## Project Structure

```
rakoda-programming-language/
├── Cargo.toml                  # Workspace root
├── Cargo.lock
├── README.md                   # ← You are here
├── LICENSE
├── rpl.json                    # Example project manifest
├── main.rpl                    # Example entry point
│
├── crates/                     # All Rust crates (libraries + binary)
│   ├── errors/                 # Error type definitions (leaf crate)
│   ├── ast/                    # Abstract Syntax Tree + optimizer
│   ├── lexer/                  # Tokenizer (source → tokens)
│   ├── parser/                 # Recursive descent + Pratt parser
│   ├── typechecker/            # Static type checker
│   ├── stdlib/                 # Shared standard library (Phase 4)
│   ├── interpreter/            # Tree-walking interpreter (engine A)
│   ├── vm/                     # Stack-based bytecode VM (engine B)
│   ├── runtime/                # Orchestrator (unifies engines + CLI)
│   ├── web/                    # Standalone web server (simple)
│   └── cli/                    # CLI binary entry point
│
├── examples/                   # Example .rpl programs (50+ files)
│   ├── test.rpl                # Basic test
│   ├── matematika.rpl          # Math functions
│   ├── string.rpl              # String manipulation
│   ├── list.rpl                # List/array operations
│   ├── json.rpl                # JSON parsing
│   ├── http.rpl                # HTTP client
│   ├── web_server.rpl          # Web server example
│   ├── file.rpl                # File I/O
│   ├── error_pintar.rpl         # Smart error handling
│   ├── cookie_session.rpl      # Cookies & sessions
│   ├── vm_test.rpl             # VM-specific tests
│   └── proyek_toko/            # Full-stack demo app (MVC)
│
├── editors/vscode/             # VS Code extension
│   ├── package.json            # Extension manifest
│   ├── syntaxes/               # TextMate grammars
│   │   ├── rpl.tmLanguage.json
│   │   └── rpl-html.tmLanguage.json
│   └── rpl-vscode-1.0.0.vsix   # Pre-packaged extension
│
├── installer/                  # Cross-platform installers
│   ├── inno/                   # Windows (Inno Setup)
│   ├── nsis/                   # Windows (NSIS)
│   ├── macos/                  # macOS DMG
│   └── linux/                  # Linux AppImage
│
├── rpl_modules/                # Local package cache
├── .github/workflows/          # CI/CD pipelines
└── documentation/              # Generated HTML docs
    ├── index.html
    └── styles.css
```

---

## Architecture Overview

RPL has **two execution engines** running side-by-side:

| Engine | Type | Location | Status |
|--------|------|----------|--------|
| **Interpreter** | Tree-walking AST interpreter | `crates/interpreter/` | ✅ Mature |
| **VM** | Stack-based bytecode virtual machine | `crates/vm/` | ✅ Mature |

Both engines share the same **frontend** (lexer → parser → AST → optimizer) and a **unified standard library** (`crates/stdlib/`). The `runtime` crate acts as the orchestrator, selecting the engine at runtime.

### Why Two Engines?

- **Interpreter**: Simpler to understand, better for learning and debugging. Direct AST evaluation.
- **VM**: Faster execution, suitable for web servers and production use. Compiles AST to bytecode, executes on a stack machine with garbage collection.

Students learn with the interpreter first; advanced users deploy with the VM.

---

## Crate Dependency Graph

```
errors ← ast ← parser ← interpreter ← runtime ← cli
                ↑        ↑
                │        ├── web (simple axum server)
                │        │
                ├── vm ──┘
                │   ↑
                │   └── stdlib (shared stdlib)
                │
                ├── typechecker
                │
                └── lexer ← runtime
```

### Crate Descriptions

| # | Crate | Type | Purpose |
|---|-------|------|---------|
| 1 | `errors` | Library | `RplError` enum, `Lokasi` (source position), error formatting |
| 2 | `ast` | Library | AST node types (`Statement`, `Expr`), optimizer (constant folding, dead code elimination) |
| 3 | `lexer` | Library | Tokenizer: source code string → `Vec<Token>` (40+ token types) |
| 4 | `parser` | Library | Error-tolerant recursive descent parser: tokens → `Program` (AST) |
| 5 | `typechecker` | Library | Static type checker: detects type mismatches, undefined variables |
| 6 | `stdlib` | Library | Shared standard library implementation (10 core modules) |
| 7 | `interpreter` | Library | Tree-walking interpreter: walks AST directly, manages lexical scopes |
| 8 | `vm` | Library | Stack-based VM: compiler (AST→bytecode), machine (execution loop), GC, 17 stdlib modules |
| 9 | `runtime` | Library | Orchestrator: `run_file()`, `run_source()`, engine selection |
| 10 | `web` | Library | Simple standalone web server (axum-based, single route) |
| 11 | `cli` | Binary | Command-line interface (`rpl` binary) using clap |

---

## Execution Pipeline

```
Source Code (.rpl)
    │
    ▼
[Preprocess]          ← Only for .rpl.html: template {{ var }} → RPL code
    │
    ▼
[Lexer]               ← characters → Vec<Token> (crates/lexer/)
    │
    ▼
[Parser]              ← Vec<Token> → Program (AST) (crates/parser/)
    │
    ▼
[Optimizer]           ← AST constant folding, dead code elimination (crates/ast/optimizer.rs)
    │
    ▼
[TypeChecker]         ← Optional: static type analysis (crates/typechecker/)
    │
    ├─ Interpreter path ──▶ [Interpreter] ──▶ output to stdout / capture buffer
    │
    └─ VM path ───────────▶ [VM Compiler] ──▶ [VM Execute] ──▶ output
```

### Template Pipeline (.rpl.html)

```
File .rpl.html
    │
    ▼
[Preprocess]          ← {{ variabel }} → RPL string concatenation
    │
    ▼
[Continue to main pipeline as RPL source code]
```

### Web Engine Pipeline (VM-based)

```
HTTP Request
    │
    ▼
[Clone VM]            ← vm.clone_vm() — per-request isolation
    │
    ▼
[Route Matching]      ← exact match → :param pattern match
    │
    ▼
[Execute Handler]     ← VM::execute_function(func_val, req_args)
    │
    ▼
[Response Build]      ← Value → JSON/HTML response
```

---

## CLI Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `rpl run <file>` | — | Execute a `.rpl` file |
| `rpl run --watch <file>` | — | Execute with auto-reload on file changes |
| `rpl repl` | — | Start interactive REPL session |
| `rpl serve <file>` | — | Start development server with live reload |
| `rpl cek <file>` | `rpl check` | Syntax check without execution (lexer + parser + typechecker) |
| `rpl fmt <file>` | — | Format source code |
| `rpl init` | `rpl inisialisasi` | Initialize a new RPL project (creates `rpl.json`) |
| `rpl instal [paket]` | — | Install packages (specific package or all from `rpl.json`) |
| `rpl hapus <paket>` | — | Remove a package |
| `rpl kill <port>` | — | Kill process running on a specific port |
| `rpl --version` | `rpl -v` | Display version information |

---

## Language Features

### Keywords (Bahasa Indonesia)

```
buat          (let/var)       kembali      (return)
adalah        (is/assignment)  benar        (true)
jika          (if)            salah        (false)
atau_jika     (else if)       kosong       (null)
lainnya       (else)          tampilkan    (print with newline)
selama        (while)         cetak        (print without newline)
fungsi        (function)      pakai        (import/use)
kembalikan    (return)        coba         (try)
tangkap       (catch)         lempar       (throw)
berhenti      (break)         lanjutkan    (continue)
dan           (and)           atau         (or)
bukan         (not)           untuk_setiap (for each)
dari          (from/in)
```

### Data Types

| Type | Example |
|------|---------|
| Number (float) | `42`, `3.14` |
| String | `"Halo Dunia"` |
| Boolean | `benar`, `salah` |
| Null | `kosong` |
| Array | `[1, 2, 3]` |
| Dictionary | `{ nama: "Budi", umur: 15 }` |
| Function | `fungsi(a, b) { kembali a + b }` |

### Example Program

```rpl
fungsi sapa(nama)
    jika nama isinya "" maka
        kembalikan "Halo, Dunia!"
    jika tidak
        kembalikan "Halo, " + nama + "!"
    selesai
selesai

buat hasil = sapa("Budi")
tampilkan hasil
```

---

## Standard Library

The standard library (`crates/stdlib/`) provides 10 core modules shared across both interpreter and VM:

| Module | File | Functions |
|--------|------|-----------|
| `core` | `core.rs` | `tampilkan()`, `cetak()`, `masukan()`, `tipe()`, `panjang()`, `jangkauan()` |
| `matematika` | `matematika.rs` | `abs()`, `akar()`, `pangkat()`, `bulatkan()`, `acak()`, `PI` |
| `string` | `string.rs` | `ke_besar()`, `ke_kecil()`, `potong()`, `ganti()`, `pisah()`, `gabung()` |
| `list` | `list.rs` | `tambah()`, `hapus()`, `sisip()`, `urutkan()`, `balik()` |
| `waktu` | `waktu.rs` | `sekarang()`, `format_waktu()`, `tidur()` |
| `json` | `json.rs` | `jsonkan()`, `jsonParse()` |
| `http` | `http.rs` | `httpMinta()`, `httpDapatkan()`, `httpKirim()` |
| `env` | `env.rs` | `env()`, `setEnv()` |
| `file` | `file.rs` | `bacaFile()`, `tulisFile()`, `hapusFile()`, `adaFile()` |
| `kripto` | `kripto.rs` | `hashPassword()`, `cekPassword()`, `sha256()` |

**VM-only modules** (in `crates/vm/src/stdlib/`):

| Module | Purpose |
|--------|---------|
| `web` | Full HTTP server (axum-based), routing, middleware, WebSocket |
| `db` | SQLite database (via rusqlite) |
| `session` | Session management |
| `cookie` | Cookie parsing and generation |
| `tugas` | Async task/job system |
| `log` | Structured logging |
| `dev_dashboard` | Development dashboard (HTML UI) |

---

## Development Guide

### Prerequisites

- **Rust** 1.75+ (install via [rustup](https://rustup.rs))
- **Cargo** (comes with Rust)
- **Git**

### Building

```bash
# Debug build (fast compile, slow runtime)
cargo build

# Release build (slow compile, fast runtime)
cargo build --release

# Build all workspace crates
cargo build --workspace

# Build specific crate
cargo build -p rpl-cli
```

The binary will be at:
- Debug: `./target/debug/rpl`
- Release: `./target/release/rpl`

### Running

```bash
# Run directly with cargo
cargo run -- run examples/test.rpl

# Or use the built binary
./target/release/rpl run examples/test.rpl

# Check syntax
cargo run -- cek examples/test.rpl

# Run with watch mode
cargo run -- run --watch examples/test.rpl
```

### Running Tests

```bash
# Run all tests across workspace
cargo test --workspace

# Run tests for a specific crate
cargo test -p rpl-parser
cargo test -p rpl-vm
cargo test -p rpl-cli

# Run tests with output
cargo test --workspace -- --nocapture

# Run a specific test
cargo test -p rpl-parser test_parse_function
```

### Code Quality

```bash
# Format all code
cargo fmt --all

# Check formatting (CI)
cargo fmt --check --all

# Run linter
cargo clippy --workspace

# Strict linting (treat warnings as errors)
cargo clippy --workspace -- -D warnings

# Check compilation without building
cargo check --workspace
```

### Project Conventions

- **Language**: All identifiers, error messages, and documentation use **Bahasa Indonesia** (e.g., `Lokasi` not `Location`, `kesalahan` not `error`). Code comments may use either language.
- **Module naming**: Files are named in Bahasa Indonesia (e.g., `lingkungan.rs` = environment, `objek.rs` = object).
- **Error handling**: Use `Result<T, RplError>` for recoverable errors. Avoid `.unwrap()` and `panic!` in production code.
- **Testing**: Every public function should have unit tests. CLI commands have parsing tests.
- **Idiomatic Rust**: Follow Rust idioms. No `unsafe` unless absolutely necessary and documented.
- **No unnecessary dependencies**: Each dependency must be justified.

---

## How to Add a New Feature

This section is a step-by-step guide for contributors. Each feature type lists every file you need to touch.

### Adding a New Language Keyword

Example: adding a `ulangi` (repeat/loop) keyword.

**Files to modify:**

| # | File | What to do |
|---|------|------------|
| 1 | `crates/lexer/src/token.rs` | Add new token variant: `Ulangi` to the `Token` enum |
| 2 | `crates/lexer/src/lib.rs` | Add keyword mapping: `"ulangi" => Token::Ulangi` in the keyword lookup |
| 3 | `crates/ast/src/lib.rs` | Add AST node: `Ulangi { kondisi: Expr, tubuh: Vec<Statement> }` to the `Statement` enum |
| 4 | `crates/parser/src/lib.rs` | Add parsing logic: `parse_ulangi_statement()` method |
| 5 | `crates/interpreter/src/lib.rs` | Add evaluation: handle `Statement::Ulangi` in `eval_statement()` |
| 6 | `crates/vm/src/compiler.rs` | Add bytecode compilation for the new loop |
| 7 | `crates/vm/src/opcodes.rs` | Add new opcodes if needed (e.g., `LoopStart`, `LoopEnd`) |
| 8 | `crates/vm/src/machine.rs` | Add opcode execution in the VM loop |
| 9 | `crates/typechecker/src/lib.rs` | Add type checking rules for `Ulangi` |
| 10 | `editors/vscode/syntaxes/rpl.tmLanguage.json` | Add `ulangi` to the keyword list |
| 11 | `examples/` | Add test files: `examples/ulangi.rpl` |

### Adding a New Standard Library Function

Example: adding `statistik.median()` to the math module.

**Files to modify:**

| # | File | What to do |
|---|------|------------|
| 1 | `crates/stdlib/src/matematika.rs` | Implement the function logic |
| 2 | `crates/stdlib/src/lib.rs` | Export/register the function if needed |
| 3 | `crates/interpreter/src/stdlib/matematika.rs` | Add interpreter binding (if interpreter has its own wrapper) |
| 4 | `crates/vm/src/stdlib/matematika.rs` | Add VM binding |
| 5 | `examples/matematika.rpl` | Add usage example |

### Adding a New CLI Command

Example: adding `rpl info <file>` to display file metadata.

**Files to modify:**

| # | File | What to do |
|---|------|------------|
| 1 | `crates/cli/src/main.rs` | Add variant to `Commands` enum: `Info { file: PathBuf }` |
| 2 | `crates/cli/src/commands.rs` | Implement `handle_info()` function |
| 3 | `crates/cli/src/commands.rs` | Add CLI parsing test in the `tests` module |

### Adding a New VM Opcode

Example: adding a `DuplicateStackTop` opcode.

**Files to modify:**

| # | File | What to do |
|---|------|------------|
| 1 | `crates/vm/src/opcodes.rs` | Add variant to `OpCode` enum |
| 2 | `crates/vm/src/compiler.rs` | Emit the opcode during compilation |
| 3 | `crates/vm/src/machine.rs` | Implement execution logic in the VM dispatch loop |

### Adding a New Crate

Example: adding a `crates/lsp/` for the Language Server.

**Files to modify:**

| # | File | What to do |
|---|------|------------|
| 1 | `crates/lsp/Cargo.toml` | Create new crate manifest with dependencies |
| 2 | `crates/lsp/src/lib.rs` | Create library entry point |
| 3 | Root `Cargo.toml` | Add `"crates/lsp"` to `[workspace] members` |
| 4 | (If binary) `crates/cli/Cargo.toml` | Add dependency on new crate |
| 5 | (If binary) `crates/cli/src/main.rs` | Add CLI subcommand that uses the crate |

### General Checklist for Any Change

- [ ] Write or update unit tests
- [ ] Add an example file in `examples/`
- [ ] Run `cargo fmt --all`
- [ ] Run `cargo clippy --workspace -- -D warnings`
- [ ] Run `cargo test --workspace`
- [ ] Update this README if the change affects project structure or commands

---

## Outline Roadmap

| No | Focus | Status |
|-------|-------|--------|
| 1 | Build Programming Language with Indonesia syntax | Done |
| 2 | Build Web Server | Done |
| 3 | Build Package Manager | Done |
| 4 | Add Stdlib | Done |
| 5 | Add Language Server | Planned |
| 6 | Add VSCode Extention for RPL language | Done |
| 7 | Build RPL Studio for Cross Platform using Flutter ( Desktop, Android, IOS ) | Planned |
| 8 | Later when RPL Studio is done, We can separate Desktop app using Tauri | Planned |
| 9 | Create Logo for Rakoda | Done |
| 10 | Create Documentation with Docusaurus | Planned |
| 11 | Create Rakoda Website | Planned |
| 12 | Create community | Planned |
| 13 | Build Server SDK | Planned |
| 14 | Introducing Rakoda to the public | Planned |

---

## Contributing

RPL is an open-source project. Contributions are welcome!

1. Ensure all tests pass: `cargo test --workspace`
2. Format your code: `cargo fmt --all`
3. Run clippy: `cargo clippy --workspace -- -D warnings`
4. Submit a pull request with a clear description.

### CI/CD

GitHub Actions runs on every push:
- **Build**: `cargo build --workspace` (all crates)
- **Lint**: `cargo clippy --workspace -- -D warnings`
- **Format**: `cargo fmt --check --all`
- **Test**: `cargo test --workspace`

Configuration: [.github/workflows/ci.yml](.github/workflows/ci.yml)

---

## License

This project is licensed under the terms in the [LICENSE](LICENSE) file.

---

**RAKODA PROGRAMMING LANGUAGE** 🇮🇩