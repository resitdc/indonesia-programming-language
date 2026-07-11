use clap::{Parser, Subcommand};
use std::path::PathBuf;
use anyhow::Result;

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
        #[arg(long)]
        interpreter: bool,
    },
    Repl,
    Serve {
        file: PathBuf,
        #[arg(short, long, default_value_t = 4000)]
        port: u16,
    },
    Fmt {
        file: PathBuf,
    },
    #[command(alias = "inisialisasi")]
    Init,
    Instal {
        paket: Option<String>,
    },
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    if cli.version {
        println!("Rakoda Programming Language\nV{}", runtime::version());
        return Ok(());
    }

    match &cli.command {
        Some(Commands::Run { file, watch, interpreter }) => {
            let use_vm = !*interpreter;
            if !*watch {
                match runtime::run_file(file, use_vm) {
                    Ok(success) => {
                        if !success {
                            std::process::exit(1);
                        }
                    }
                    Err(e) => {
                        eprintln!("{}", e);
                        std::process::exit(1);
                    }
                }
            } else {
                use notify::{Watcher, RecursiveMode};
                use std::sync::mpsc::channel;
                use std::time::Duration;

                print!("{}[2J{}[1;1H", 27 as char, 27 as char); // Clear screen
                println!("\x1b[32m⏳ Memulai watch mode untuk {}...\x1b[0m", file.display());
                if let Err(e) = runtime::run_file(file, use_vm) {
                    eprintln!("{}", e);
                }
                println!("\n\x1b[32m👀 Menunggu perubahan file...\x1b[0m");

                let (tx, rx) = channel();
                let mut watcher = notify::recommended_watcher(tx)?;
                watcher.watch(file, RecursiveMode::NonRecursive)?;

                let mut last_run = std::time::Instant::now();

                for res in rx {
                    match res {
                        Ok(event) => {
                            if event.kind.is_modify() {
                                if last_run.elapsed() > Duration::from_millis(500) {
                                    last_run = std::time::Instant::now();
                                    print!("{}[2J{}[1;1H", 27 as char, 27 as char); // Clear screen
                                    println!("\x1b[32m🔄 File berubah, menjalankan ulang...\x1b[0m\n");
                                    if let Err(e) = runtime::run_file(file, use_vm) {
                                        eprintln!("{}", e);
                                    }
                                    println!("\n\x1b[32m👀 Menunggu perubahan file...\x1b[0m");
                                }
                            }
                        }
                        Err(e) => eprintln!("Watch error: {:?}", e),
                    }
                }
            }
        }
        Some(Commands::Repl) => {
            println!("Memulai sesi REPL RPL. Ketik 'berhenti' untuk keluar.");
        }
        Some(Commands::Serve { file, port }) => {
            if let Err(e) = runtime::serve(file.clone(), *port).await {
                let msg = e.to_string();
                if msg.contains("Address already in use") || msg.contains("os error 48") {
                    eprintln!("\x1b[33mError: Port sudah digunakan oleh program lain.\x1b[0m");
                } else {
                    eprintln!("\x1b[33mError: {}\x1b[0m", msg);
                }
                std::process::exit(1);
            }
        }
        Some(Commands::Fmt { file }) => {
            println!("Memformat file: {}", file.display());
            println!("Format selesai (fitur masih dalam pengembangan).");
        }
        Some(Commands::Init) => {
            let cwd = std::env::current_dir()?;
            pkg::inisialisasi(&cwd)?;
        }
        Some(Commands::Instal { paket }) => {
            pkg::instal(paket.clone()).await?;
        }
        None => {
            use clap::CommandFactory;
            let mut cmd = Cli::command();
            cmd.print_help()?;
        }
    }

    Ok(())
}
