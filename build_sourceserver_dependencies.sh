#!/bin/bash

# REGION Modules Check

git submodule update --init --recursive

if [[ ! -d "./media_converter" ]]; then
    git clone https://github.com/LeandroTheDev/media_converter.git
fi

if [[ ! -d "./media_downloader" ]]; then
    git clone https://github.com/LeandroTheDev/media_downloader.git
fi

if [[ ! -d "./media_converter" ]]; then
    echo "Error: 'media_converter' module not found in current directory."
    exit 1
fi

if [[ ! -d "./media_downloader" ]]; then
    echo "Error: 'media_downloader' module not found in current directory."
    exit 1
fi

# ENDREGION: Modules Check

# REGION: media_downloader COMPILATION

if ! command -v cargo &> /dev/null; then
    echo "Error: 'cargo' from Rust does not exist. Please install it before building."
    exit 1
fi

cd ./media_downloader || {
    echo "Error: Folder './media_downloader' does not exist."
    exit 1
}

cargo build --release

if [ $? -eq 0 ]; then
    echo "Build completed successfully."
else
    echo "Build failed."
    exit 1
fi

OS="$(uname -s)"
case "$OS" in
    Linux*)
        echo "Detected OS: Linux"
        cp -r ./target/release/media_downloader ../source_server/libraries/linux/
        ;;
    Darwin*)
        echo "Detected OS: macOS"
        cp -r ./target/release/media_downloader ../source_server/libraries/macos/
        ;;
    MINGW* | MSYS* | CYGWIN*)
        echo "Detected OS: Windows"
        cp -r ./target/release/media_downloader.exe ../source_server/libraries/windows/
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

echo "Media Downloader Compiled!"
cd ..

# ENDREGION: media_downloader COMPILATION

# REGION: media_converter COMPILATION

if ! command -v cargo &> /dev/null; then
    echo "Error: 'cargo' from Rust does not exist. Please install it before building."
    exit 1
fi

cd ./media_converter || {
    echo "Error: Folder './media_converter' does not exist."
    exit 1
}

cargo build --release

if [ $? -eq 0 ]; then
    echo "Build completed successfully."
else
    echo "Build failed."
    exit 1
fi

OS="$(uname -s)"
case "$OS" in
    Linux*)
        echo "Detected OS: Linux"
        cp -r ./target/release/media_converter ../source_server/libraries/linux/
        ;;
    Darwin*)
        echo "Detected OS: macOS"
        cp -r ./target/release/media_converter ../source_server/libraries/macos/
        ;;
    MINGW* | MSYS* | CYGWIN*)
        echo "Detected OS: Windows"
        cp -r ./target/release/media_converter.exe ../source_server/libraries/windows/
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

echo "Media Compiler Compiled!"
cd ..

# ENDREGION: media_converter COMPILATION

# REGION: Libraries Check

OS="$(uname -s)"
case "$OS" in
    Linux*)
        echo "Detected OS: Linux"

        if ! command -v ffmpeg >/dev/null 2>&1; then
            echo "WARNING: 'ffmpeg' not found in PATH"            
        fi

        if ! command -v yt-dlp >/dev/null 2>&1; then
            echo "WARNING: 'yt-dlp' not found in PATH"
        fi        
        ;;

    Darwin*)
        echo "Detected OS: macOS"

        if ! command -v ffmpeg >/dev/null 2>&1; then
            echo "WARNING: 'ffmpeg' not found in PATH"
            exit 1
        fi

        if ! command -v yt-dlp >/dev/null 2>&1; then
            echo "WARNING: 'yt-dlp' not found in PATH"
        fi        
        ;;

    MINGW* | MSYS* | CYGWIN*)
        echo "Detected OS: Windows"

        FFMPEG_PATH="./source_server/libraries/windows/libraries/ffmpeg.exe"
        YTDLP_PATH="./source_server/libraries/windows/libraries/yt-dlp.exe"

        if [[ ! -f "$FFMPEG_PATH" ]]; then
            echo "WARNING: ffmpeg not found at $FFMPEG_PATH"            
        fi

        if [[ ! -f "$YTDLP_PATH" ]]; then
            echo "WARNING: yt-dlp not found at $YTDLP_PATH"
        fi
        ;;

    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

# ENDREGION

echo "Source Server dependencies builded successfully!"