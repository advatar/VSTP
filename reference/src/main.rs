use clap::{Parser, Subcommand};
use std::{fs, path::PathBuf, process::ExitCode};
use vstp_reference::{model::Bundle, verify};

#[derive(Parser)]
#[command(name = "vstp", about = "VSTP Example Profile 00 reference verifier")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    /// Verify a self-contained bundle and print its assurance report as JSON.
    Verify { bundle: PathBuf },
    /// Print the transition identifier recomputed from canonical bytes.
    Id { bundle: PathBuf },
}

fn load(path: &PathBuf) -> Result<Bundle, String> {
    let bytes = fs::read(path).map_err(|e| format!("{}: {e}", path.display()))?;
    serde_json::from_slice(&bytes).map_err(|e| format!("{}: {e}", path.display()))
}

fn run() -> Result<bool, String> {
    match Cli::parse().command {
        Command::Verify { bundle } => {
            let report = verify::verify(&load(&bundle)?);
            println!("{}", serde_json::to_string_pretty(&report).unwrap());
            Ok(report.valid)
        }
        Command::Id { bundle } => {
            println!("{}", verify::transition_id(&load(&bundle)?)?);
            Ok(true)
        }
    }
}

fn main() -> ExitCode {
    match run() {
        Ok(true) => ExitCode::SUCCESS,
        Ok(false) => ExitCode::from(1),
        Err(error) => {
            eprintln!("error: {error}");
            ExitCode::from(2)
        }
    }
}
