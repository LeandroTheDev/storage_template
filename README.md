# Storage Website
A simple template for hosting a personal storage system

Ultra light-weight, works on most devices

Includes:
- Web server to manage your files, including:
- Upload files
- View images
- View videos
- Delete files
- Security system for protecting your user files, including:
- Dynamic RSA Authentication

Supports:
- Windows
- Linux
- Web (Broken) (Client RSA encryption and decryption is broken from the plugin side)
- Android
- MacOS
- IOS

# Login
https://github.com/user-attachments/assets/ef624557-97d1-4b19-8504-d8ca989a503c
# Upload
https://github.com/user-attachments/assets/6b17bb13-7a68-4ccc-9191-f6f50eb29207
# Folder Creation
https://github.com/user-attachments/assets/fc0df58b-63dd-490a-96b5-3a885c6e5349
# Image View
https://github.com/user-attachments/assets/af85df0a-366b-45db-aa42-549ff1848e84
# Video View
https://github.com/user-attachments/assets/0f06525c-ba01-4bae-8389-e9357c8354ee

### Observations
- The Server uses the ports 7979
- The Server cannot handle multiple connections on the same user
- Robust DDOS protection is recommended, although the server has a simple implementation
- Drive encrpytion is recommended if you run sensitive data, storage template will not handle files encryption
- Delete old files in temp folder, lost connections will not delete files automatically

### Considerations
- Login passwords is encrypted, all requests is encrypted after user login, all connected users have different RSA keys.
- The project does not handle http redirects, be careful using it in http on production
- The storage folder will be located in /source_server/drive/account/...
- The temporary received files will be in /source_server/drive/temp/...
- The files is not encrypted, the NAS server has entire access to all files stored in the storage

# Backend Starting
## Dependencies
Storage Template requires some dependencies to fully work
- Conversion videos after upload or download from links: [ffmpeg](https://github.com/BtbN/FFmpeg-Builds/releases)
- Download Videos from links: [yt-dlp](https://github.com/yt-dlp/yt-dlp) (On linux by default you need to install from your repository distro, should be installed in /usr/bin/yt-dlp)

If you do not download this dependencies storage template maybe fail during some tasks

All binaries should be placed in ./source_server/libraries/windows-or-linux

``Windows``
```
libraries\windows\ffmpeg.exe
libraries\windows\yt-dlp.exe
```
``Linux``
By default linux will try to use the libraries from your package manager in: /usr/bin/..., if you distro is different you can manually compile the ``video_converter`` and ``video_downloader``

### Good Practices
This project has a simple DDOS system, if you wish to use the project with the ports open, a DDOS protection system is recommended.

When starting the storage, make sure to clean the temporary files in /source_server/drive/temp/

## Requirements
- Storage templates converts all uploaded videos to 720p 30fps (The video will be unavalaible until the conversion is finished, if the storage server is closed after the conversion, you will need to manually convert), if your NAS server cannot handle a video streaming in 720p probably will not handle very well, a good estimate is: ``Intel(R) Core(TM) i3-2367M CPU @ 1.40GHz`` works flawless for 2 users at same time
- At least 1024 MB RAM (depends on how many users at the same time)

## Linux
- Install [git](https://git-scm.com/downloads)
- Run this command in the folder you want to save the storage system: ``git clone https://github.com/LeandroTheDev/storage_template``
- > You also can clone manually the repository in the github
- Install [mariadb](https://mariadb.org/download/) server
- Open the mariadb terminal cli: ``sudo mariadb``
- Run this command (consider changing the password): ``CREATE DATABASE storage; GRANT ALL PRIVILEGES ON storage.* TO 'nas_admin'@'localhost' IDENTIFIED BY 'secretpassword' WITH GRANT OPTION; FLUSH PRIVILEGES;``
- Change the [database.js](https://github.com/LeandroTheDev/storage_template/blob/main/source_server/components/drive/database.js) credentials
```javascript
this.database_connection = new Sequelize('storage', "nas_admin", "secretpassword", {
    host: "localhost",
    dialect: "mariadb",
    logging: false,
    sync: true,
    dialectOptions: {
        connectTimeout: 30000
    }
})
```
- Install [nodejs](https://nodejs.org/en/download/package-manager)
- Check the [README.md](https://github.com/LeandroTheDev/storage_template/blob/main/source_server/README.md) for node dependencies (or use the command ``npm install``)
- Running the web server: ``node init.js``
- (You need to run the web server first before this command) MariaDB cli, Creating admin account: ``USE storage; INSERT INTO accounts (username, password) VALUES ('admin', 'secretpassword');``

## Windows
- Install [git](https://git-scm.com/downloads)
- Run this command in the folder you want to save the storage system: ``git clone https://github.com/LeandroTheDev/storage_template``
- > You also can clone manually the repository in the github
- Install [mariadb](https://mariadb.org/download/) server
- Open the mariadb terminal cli: ``C:\Program Files\MariaDB version\bin\mariadb -uroot -ppass``
- Run this command (consider changing the password): ``CREATE DATABASE storage; GRANT ALL PRIVILEGES ON storage.* TO 'nas_admin'@'localhost' IDENTIFIED BY 'secretpassword' WITH GRANT OPTION; FLUSH PRIVILEGES;``
- Change the [database.js](https://github.com/LeandroTheDev/storage_template/blob/main/source_server/components/drive/database.js) credentials
```javascript
this.database_connection = new Sequelize('storage', "nas_admin", "secretpassword", {
    host: "localhost",
    dialect: "mariadb",
    logging: false,
    sync: true,
    dialectOptions: {
        connectTimeout: 30000
    }
})
```
- Install [nodejs](https://nodejs.org/en/download/package-manager)
- Check the [README.md](https://github.com/LeandroTheDev/storage_template/blob/main/source_server/README.md) for node dependencies (or use the command ``npm install``)
- Running the web server: ``node init.js``
- (You need to run the web server first before this command) MariaDB cli, Creating admin account: ``USE storage; INSERT INTO accounts (username, password) VALUES ('admin', 'secretpassword');``

# Using
You can manually compile the application for you desire OS, or you can download it on releases section.

After installed and configurated the server, you will need to get the ip address from your server, once you started the application choose the select ip option, change it to your desired address, press the reset keys buttons, select server side for better compatibility, put your credentials and start using.

# Build Frontend
First thing you will need to compile the front end is to install the flutter framework on your machine

## Linux Dependencies
- ninja
- mpv
- pkgconf

Build command: ``flutter build linux``

## Windows Dependencies

Build command: ``flutter build windows``

## Android Dependencies
- android sdk

Build command: ``flutter build android``