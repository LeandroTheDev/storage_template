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
- RSA Token and Username Encryptions
- RSA Handshakes between client and server for requesting datas

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

### Considerations
- Login passwords is encrypted, all requests is encrypted after user login, all connected users have different RSA keys.
- The project does not have good security against http redirects, be careful using it in http on production
- > When the hacker redirects the server to themselves, they can generate an RSA key and send the public key to the client, as soon as the client receives it, the client will encrypt the password with their public key and send it to the redirected server, and the hackers will obtain the client's password (So far I don't know a viable alternative to get around redirection problems, if you intend to host locally or via static IP address, you don't need to worry about redirection.)
- The storage folder will be located in /source_server/drive/account/...
- The temporary received files will be in /source_server/drive/temp/...
- The files is not encrypted, the NAS server has entire access to all files stored in the storage

# Starting
## Dependencies
Storage Template requires some dependencies to fully work
- Conversion videos after upload or download from links: [ffmpeg](https://github.com/BtbN/FFmpeg-Builds/releases)
- Download Videos from links: [yt-dlp](https://github.com/yt-dlp/yt-dlp)

If you do not download this dependencies storage template maybe fail during some tasks

All binaries should be placed in ./source_server/libraries

``Windows``
```
libraries\ffmpeg.exe
libraries\yt-dlp.exe
```
``Linux``
```
libraries/ffmpeg
libraries/yt-dlp
```

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
- Check the [README.md](https://github.com/LeandroTheDev/storage_template/blob/main/source_server/README.md) for node dependencies
- Running the web server: ``node init.js``
- (You need to run the web server first before this command) MariaDB cli, Creating admin account: ``USE storage; INSERT INTO accounts (username, password) VALUES ('admin', 'secretpassword');``
- Simple http client server: ``python3 -m http.server 80`` inside ``source_web/build/web`` folder, if not builded yet you can build using the command ``flutter build web`` (don't know what is flutter? refer to [flutter download](https://docs.flutter.dev/get-started/install))
- You can now access your storage using the address of the NAS server in your favorite internet explorer

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
- Check the [README.md](https://github.com/LeandroTheDev/storage_template/blob/main/source_server/README.md) for node dependencies
- Running the web server: ``node init.js``
- (You need to run the web server first before this command) MariaDB cli, Creating admin account: ``USE storage; INSERT INTO accounts (username, password) VALUES ('admin', 'secretpassword');``
- For hosting the web client you can use any web client, my honest recommendation is to use the npm package http-server, its very simple for the personal storage, install it using ``npm install -g http-server``
- Running the http server just type: ``http-server`` in the terminal inside the ``source_web/build/web`` folder, if not builded yet you can build using the command ``flutter build web`` (don't know what is flutter? refer to [flutter download](https://docs.flutter.dev/get-started/install))
- You can now access your storage using the address of the NAS server in your favorite internet explorer