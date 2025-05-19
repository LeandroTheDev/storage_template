# Video Downloader
This binary will download a video link in 720p from provided address to the provided path,
if the video link does not provide a 720p version, it will not be downloaded

usage:
- ``video_downloader "https://videolink.com" /home/admin/server/videos/videoname.mp4``

Windows Requirements:
- yt-dlp (in same folder from binary)

Linux Requirements:
- yt-dlp (from your package manager)
- or
- yt-dlp (in same folder from binary, must change the USE_OS_YT_DLP to true inside ./src/main.rs)

Build Requirements:
- Rust and Cargo installed on your machine
- Build command: ``cargo build --release``