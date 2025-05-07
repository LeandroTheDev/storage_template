use std::env;
use std::path::Path;
use std::process::{exit, Command, Output};

/// Will use yt-dlp from the OS in /usr/bin/yt-dlp instead of local ./yt-dlp
const USE_OS_YT_DLP: bool = true;

fn main() {
    // Getting arguments
    let args: Vec<String> = env::args().collect();

    // Check if argument exist
    if args.len() < 2 {
        println!(
            "Please provide the link, example: 'video_downloader https://videolink.com /home/admin/server/videos/videoname.mp4'"
        );
        exit(2);
    } else if args.len() < 3 {
        println!(
            "Please provide the path, example: 'video_downloader https://videolink.com /home/admin/server/videos/videoname.mp4'"
        );
        exit(2);
    }

    let input_link: &String = &args[1];
    let input_path: &String = &args[2];

    // Valid argument check for directory
    let path = Path::new(input_path);
    if path.is_dir() {
        println!(
            "Please provide a file path, with the file name included, this is just a directory..."
        );
        exit(2);
    }

    if let Err(e) = download_file(input_link, input_path) {
        eprintln!("Error: {}", e);
        exit(2);
    }
}

fn get_ytpdl_directory() -> &'static str {
    let yt_dlp_binary: &str = if cfg!(target_os = "windows") {
        "./yt-dlp.exe"
    } else if USE_OS_YT_DLP {
        "/usr/bin/yt-dlp"
    } else {
        "./yt-dlp"
    };

    yt_dlp_binary
}

fn get_available_formats(input_link: &str) -> Result<String, String> {
    let output: Output = Command::new(get_ytpdl_directory())
        .args(["-F", input_link])
        .output()
        .map_err(|e| format!("Failed to run yt-dlp: {}", e))?;

    if output.status.success() {
        let formats: String = String::from_utf8_lossy(&output.stdout).to_string();
        Ok(formats)
    } else {
        Err(format!(
            "yt-dlp failed with error: {}",
            String::from_utf8_lossy(&output.stderr)
        ))
    }
}

fn get_best_720p(format_list: &str) -> Option<String> {
    let mut best_format = None;
    let mut best_tbr = 0;

    for line in format_list.lines() {
        if line.contains("1280x720") {
            let parts: Vec<&str> = line.split_whitespace().collect();

            if let (Some(id), Some(tbr_str)) =
                (parts.get(0), parts.iter().find(|s| s.ends_with('k')))
            {
                if let Ok(tbr) = tbr_str.trim_end_matches('k').parse::<i32>() {
                    if tbr > best_tbr {
                        best_tbr = tbr;
                        best_format = Some(id.to_string());
                    }
                }
            }
        }
    }

    best_format
}

fn download_file(input_link: &str, input_path: &str) -> Result<(), String> {
    let formats: String = get_available_formats(input_link)?;

    if let Some(best_720p) = get_best_720p(&formats) {
        if let Some(extension) = Path::new(input_path).extension() {
            if extension == "mkv" || extension == "mp4" {
                println!("Downloading: {} to {}", input_link, input_path);

                let status = Command::new(get_ytpdl_directory())
                    .arg("-f")
                    .arg(best_720p)
                    .arg("-o")
                    .arg(input_path)
                    .arg("--merge-output-format")
                    .arg("mp4")
                    .arg(input_link)
                    .status();

                match status {
                    Ok(_) => {
                        println!("Successfully downloaded: {}", input_link);
                        Ok(())
                    }
                    Err(e) => Err(format!("Cannot download {}: {}", input_link, e)),
                }
            } else {
                Err(format!("Unsupported file format: {}", input_link))
            }
        } else {
            Err(format!(
                "Unable to determine the extension of the file: {}",
                input_path
            ))
        }
    } else {
        println!("Cannot find a 720p format");
        exit(3);
    }
}
