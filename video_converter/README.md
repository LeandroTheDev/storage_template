# Video Converter
This binary will convert all video from the directory to 720p 30fps H.265codec, if the parameter is a file will only convert that file instead

usage:
- ``video_converter /home/admin/server/videos``

OR

- ``video_converter /home/admin/server/videos/myvideo.mp4``

cleanup:
- To delete all incosistence files you can use: ``video_converter /home/admin/server/videos --deleteinvalid``

Requirements:
- ffmpeg (in same folder from binary)