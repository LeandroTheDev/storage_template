use std::fs::DirEntry;
use std::path::{Path, PathBuf};
use std::process::{exit, Command};
use std::{env, fs};

/// Will use ffmpeg from the OS in /usr/bin/ffmpeg instead of local ./ffmpeg
const USE_OS_FFMPEG: bool = true;

fn main() {
    // Getting arguments
    let args: Vec<String> = env::args().collect();

    // Check if argument exist
    if args.len() < 2 {
        println!(
            "Please provide the directory or file, example: 'video_converter /home/user/files'"
        );
        exit(2);
    }

    let input_path: &String = &args[1];

    // Delete incosistence files
    if args.iter().any(|arg: &String| arg == "--deleteinvalid") {
        delete_inconsistent_files(&input_path);
        return;
    }

    // Converting files
    // Valid argument check for file or directory
    let path = Path::new(input_path);
    if path.is_dir() {
        // Start the recursive conversion process if it's a directory
        if let Err(e) = process_directory(input_path) {
            eprintln!("Error: {}", e);
            exit(2);
        }
    } else if path.is_file() {
        // If it's a file, directly convert it
        if let Err(e) = convert_file(input_path) {
            eprintln!("Error: {}", e);
            exit(2);
        }
    } else {
        println!("Path '{}' is not a valid file or directory.", input_path);
        exit(2);
    }
}

fn process_directory(dir: &str) -> Result<(), String> {
    // Reading content of the directory
    match fs::read_dir(dir) {
        Ok(entries) => {
            for entry in entries {
                match entry {
                    Ok(entry) => {
                        let path = entry.path();

                        if path.is_dir() {
                            if path.to_str().unwrap().contains("$720p") {
                                println!(
                                    "Ignoring the directory: {}, because it's already converted",
                                    path.display()
                                );
                            } else {
                                // If it's a directory, recurse into it
                                println!("Entering directory: {}", path.display());
                                if let Err(e) = process_directory(path.to_str().unwrap()) {
                                    eprintln!(
                                        "Failed to process directory {}: {}",
                                        path.display(),
                                        e
                                    );
                                }
                            }
                        } else if path.is_file() {
                            // Checking file extension compatibility
                            if let Some(extension) = path.extension() {
                                if extension == "mkv" || extension == "mp4" {
                                    // Convert the file if it's .mkv or .mp4
                                    let input_path = path.to_str().unwrap();
                                    if let Err(e) = convert_file(input_path) {
                                        eprintln!("Failed to convert {}: {}", input_path, e);
                                    }
                                }
                            }
                        }
                    }
                    Err(e) => eprintln!("Cannot read directory entry: {}", e),
                }
            }
        }
        Err(e) => return Err(format!("Cannot access directory '{}': {}", dir, e)),
    }

    Ok(())
}

fn get_ffmpeg_directory() -> &'static str {
    let yt_dlp_binary: &str = if cfg!(target_os = "windows") {
        "./ffmpeg.exe"
    } else if USE_OS_FFMPEG {
        "/usr/bin/ffmpeg"
    } else {
        "./ffmpeg"
    };

    yt_dlp_binary
}

fn convert_file(input_path: &str) -> Result<(), String> {
    // Check the extension of the file
    if let Some(extension) = Path::new(input_path).extension() {
        if extension == "mkv" || extension == "mp4" {
            // Creating the output path with $720p suffix
            let output_path = format!(
                "{}$720p.{}",
                input_path
                    .strip_suffix(&format!(".{}", extension.to_str().unwrap()))
                    .unwrap_or(input_path),
                extension.to_str().unwrap()
            );

            // Converting to 720p
            println!("Converting: {} to {}", input_path, output_path);

            let ffmpeg_binary: &str = get_ffmpeg_directory();

            let status = Command::new(ffmpeg_binary)
                .arg("-i")
                .arg(input_path)
                .arg("-vf")
                .arg("scale=-1:720")
                .arg("-r")
                .arg("30")
                .arg("-c:v")
                .arg("libx265")
                .arg("-crf")
                .arg("23")
                .arg("-preset")
                .arg("medium")
                .arg("-c:a")
                .arg("copy")
                .arg(&output_path)
                .status();

            match status {
                Ok(_) => {
                    println!("Successfully converted: {}", output_path);
                    Ok(())
                }
                Err(e) => Err(format!("Cannot convert {}: {}", input_path, e)),
            }
        } else {
            Err(format!("Unsupported file format: {}", input_path))
        }
    } else {
        Err(format!(
            "Unable to determine the extension of the file: {}",
            input_path
        ))
    }
}

fn delete_inconsistent_files(dir: &str) {
    let dir_path = Path::new(dir);

    // Valid directory check
    if !dir_path.is_dir() {
        eprintln!("O caminho fornecido não é um diretório válido.");
        return;
    }

    // Delete files recursively
    if let Err(e) = delete_files_recursively(dir_path) {
        eprintln!("Cannot delete files: {}", e);
    }
}

fn delete_files_recursively(dir: &Path) -> Result<(), std::io::Error> {
    // Reading all files and subdirectories
    for entry in fs::read_dir(dir)? {
        let entry: DirEntry = entry?;
        let entry_path: PathBuf = entry.path();

        // If is a directory call it recursively
        if entry_path.is_dir() {
            delete_files_recursively(&entry_path)?;
        } else if let Some(file_name) = entry_path.file_name() {
            // Incosistence: "$720p$720p"
            if let Some(file_str) = file_name.to_str() {
                if file_str.contains("$720p$720p") {
                    println!(
                        "Removing file: {}, double 720p incosistence",
                        entry_path.display()
                    );
                    fs::remove_file(entry_path)?;
                }
            }
        }
    }

    Ok(())
}
