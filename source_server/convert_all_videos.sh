#!/bin/sh

# Base directory
BASE_DIR="."

# Function to get video height
get_height() {
    ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$1"
}

# Loop through all MP4 files
find "$BASE_DIR" -type f -name '*.mp4' | while read -r file; do
    echo "Checking: $file"

    height=$(get_height "$file")

    if [ "$height" != "720" ]; then
        echo "Converting to 720p (30fps)..."

        temp_file="${file%.mp4}_temp720p.mp4"

        ffmpeg -i "$file" \
            -vf "scale=-1:720:force_original_aspect_ratio=decrease" \
            -r 30 \
            -c:v libx264 -crf 23 -preset medium \
            -c:a copy \
            "$temp_file" -y

        if [ $? -eq 0 ]; then
            mv -f "$temp_file" "$file"
            echo "Replaced: $file"
        else
            echo "Error converting file: $file"
            rm -f "$temp_file"
        fi
    else
        echo "Already 720p — skipping."
    fi

    echo
done

echo "Conversion completed!"
