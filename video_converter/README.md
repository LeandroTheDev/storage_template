# Video Converter
This binary will convert all video from the directory to 720p 30fps H.265codec, if the parameter is a file will only convert that file instead

usage:
- ``video_converter /home/admin/server/videos``
- > For converting all videos

OR

- ``video_converter /home/admin/server/videos/myvideo.mp4``
- > For converting a single video

cleanup:
- To delete all incosistence files you can use: ``video_converter /home/admin/server/videos --deleteinvalid``

Windows Requirements:
- ffmpeg (in same folder from binary)

Linux Requirements:
- ffmpeg (from your package manager)
- or
- ffmpeg (in same folder from binary, must change the USE_OS_FFMPEG to true inside ./src/main.rs)

Build Requirements:
- Rust and Cargo installed on your machine
- Build command: ``cargo build --release``