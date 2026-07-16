use anyhow::Result;
use clap::{Parser, Subcommand};
use std::path::PathBuf;

mod commands;
mod pkg;

#[derive(Parser)]
#[command(name = "rpl")]
#[command(about = "Interpreter Rakoda Programming Language (RPL)", long_about = None)]
#[command(disable_version_flag = true)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,

    #[arg(short = 'v', long = "version", action = clap::ArgAction::SetTrue)]
    version: bool,
}

#[derive(Subcommand)]
enum Commands {
    Run {
        file: PathBuf,
        #[arg(short, long)]
        watch: bool,
    },
    Repl,
    Serve {
        file: PathBuf,
    },
    Fmt {
        file: PathBuf,
    },
    #[command(alias = "inisialisasi")]
    Init,
    Instal {
        paket: Option<String>,
    },
    Hapus {
        paket: String,
    },
    Kill {
        port: u16,
    },
    #[command(alias = "check")]
    /// Cek error sintaks tanpa menjalankan program
    Cek {
        file: PathBuf,
    },
    /// Language Server Protocol (LSP) untuk editor
    Lsp,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    if cli.version {
        println!("Rakoda Programming Language\nV{}", runtime::version());
        return Ok(());
    }

    match &cli.command {
        Some(Commands::Run { file, watch }) => {
            commands::handle_run(file, *watch)?;
        }
        Some(Commands::Repl) => {
            commands::handle_repl()?;
        }
        Some(Commands::Serve { file }) => {
            commands::handle_serve(file)?;
        }
        Some(Commands::Fmt { file }) => {
            commands::handle_fmt(file)?;
        }
        Some(Commands::Init) => {
            commands::handle_init()?;
        }
        Some(Commands::Instal { paket }) => {
            let rt = tokio::runtime::Runtime::new()?;
            rt.block_on(async {
                commands::handle_instal(paket.clone()).await
            })?;
        }
        Some(Commands::Hapus { paket }) => {
            commands::handle_hapus(paket)?;
        }
        Some(Commands::Kill { port }) => {
            commands::handle_kill(*port)?;
        }
        Some(Commands::Cek { file }) => {
            commands::handle_cek(file)?;
        }
        Some(Commands::Lsp) => {
            commands::handle_lsp()?;
        }
        None => {
            use clap::CommandFactory;
            let mut cmd = Cli::command();
            cmd.print_help()?;
        }
    }

    Ok(())
}