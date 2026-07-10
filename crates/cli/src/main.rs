use clap::{Parser, Subcommand};
use std::path::PathBuf;
use anyhow::Result;

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
            println!("Menjalankan file: {}", file.display());
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
