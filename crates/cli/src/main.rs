use clap::{Parser, Subcommand};
use std::path::PathBuf;
use std::fs;
use anyhow::{Context, Result};
use lexer::Lexer;
use parser::Parser as IplParser;
use interpreter::Interpreter;

#[derive(Parser)]
#[command(name = "ipl")]
#[command(about = "Interpreter Indonesia Programming Language (IPL)", long_about = None)]
#[command(version = "0.1.0")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Run {
        file: PathBuf,
    },
    Repl,
    Serve {
        #[arg(short, long, default_value_t = 4000)]
        port: u16,
    },
    Fmt {
        file: PathBuf,
    },
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match &cli.command {
        Commands::Run { file } => {
            let kode_sumber = fs::read_to_string(file)
                .with_context(|| format!("Gagal membaca file: {}", file.display()))?;

            let mut lexer = Lexer::new(&kode_sumber);
            let tokens = lexer.tokenize().unwrap_or_else(|e| {
                eprintln!("{}", e.tampilkan(&kode_sumber));
                std::process::exit(1);
            });

            let mut parser = IplParser::new(tokens);
            let program = parser.parse_program().unwrap_or_else(|e| {
                eprintln!("{}", e.tampilkan(&kode_sumber));
                std::process::exit(1);
            });

            let mut interpreter = Interpreter::baru();
            match interpreter.eval_program(program) {
                Ok(hasil) => {
                    if hasil != interpreter::objek::Objek::Kosong {
                        println!("{}", hasil);
                    }
                }
                Err(e) => {
                    eprintln!("{}", e.tampilkan(&kode_sumber));
                    std::process::exit(1);
                }
            }
        }
        Commands::Repl => {
            println!("Memulai sesi REPL IPL. Ketik 'berhenti' untuk keluar.");
        }
        Commands::Serve { port } => {
            println!("Menjalankan server web IPL pada http://localhost:{}", port);
        }
        Commands::Fmt { file } => {
            println!("Memformat file: {}", file.display());
        }
    }

    Ok(())
}
