use std::path::Path;
use std::process::{exit, Command};
use std::{env, fs};

fn main() {
    // Getting arguments
    let args: Vec<String> = env::args().collect();

    // Check if argument exist
    if args.len() < 2 {
        println!("Please provide the directory, example: 'video_converter /home/user/files'");
        exit(2);
    }

    let convert_directory: &String = &args[1];

    // Valid argument check
    let path = Path::new(convert_directory);
    if !path.is_dir() {
        println!("Path '{}' is not a valid directory.", convert_directory);
        exit(2);
    }

    // Start the recursive conversion process
    if let Err(e) = process_directory(convert_directory) {
        eprintln!("Error: {}", e);
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
                                    "Ignoring the direcry: {}, because its already converted",
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
                                    // File path
                                    let input_path = path.to_str().unwrap();
                                    // Creating the output path
                                    let output_path = format!(
                                        "{}$720p.{}",
                                        input_path
                                            .strip_suffix(&format!(
                                                ".{}",
                                                extension.to_str().unwrap()
                                            ))
                                            .unwrap_or(input_path),
                                        extension.to_str().unwrap()
                                    );

                                    // Converting to 720
                                    println!("Converting: {} to {}", input_path, output_path);
                                    let status = Command::new("ffmpeg")
                                        .arg("-i")
                                        .arg(input_path)
                                        .arg("-vf")
                                        .arg("scale=-1:720")
                                        .arg("-r")
                                        .arg("30")
                                        .arg("-c:a")
                                        .arg("copy")
                                        .arg(&output_path)
                                        .status();

                                    match status {
                                        Ok(_) => {
                                            println!("Successfully converted: {}", output_path);
                                        }
                                        Err(e) => {
                                            eprintln!("Cannot convert {}: {}", input_path, e);
                                        }
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
