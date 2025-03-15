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
- Consider changing the [RSA keys](https://cryptotools.net/rsagen) if you are hosting this template.
- By default, the website tries to connect into the server as the same address for the url, for example if you are hosting the website in address 127.0.0.1, the website will try to connect to the ``source_server`` in 127.0.0.1:7979
- You need to change the database address to your desired database, my personal recommendation is the NAS server hosts the database, and only the NAS server has access to it.
- The server is not mean to be used by a lot of users, because of handshake authentications and security systems.

### Considerations
- Local token and handshake is not encrypted, tecnically is not safe to use in ``http`` on production because hackers can redirect your website address and steal your token and handshakes keys to bypass, be careful hosting this in http on production
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
Some features maybe not work on windows!

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

### Changing RSA Keys
- Generate your keys, [the simple way on websites](https://cryptotools.net/rsagen)
- Go to ./source_server/components/crypto/decrypto.js
- Change the variable ``const PRIVATE_KEY``
```js
const PRIVATE_KEY = `
-----BEGIN RSA PRIVATE KEY-----
your private key here
-----END RSA PRIVATE KEY-----
`;
```
- Go to ./source_web/lib/components/crypto.dart
- Change the variable ``static final RSAAsymmetricKey _publicKey =``
```dart
RSAKeyParser().parse('''-----BEGIN PUBLIC KEY-----
your public key here
-----END PUBLIC KEY-----''');
```