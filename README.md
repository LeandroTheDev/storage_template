# Storage Website
A simple template for hosting a personal storage system

Ultra light-weight, works on most devices

Includes:
- Website for managing files/view/download.
- Web server to manage all files.
- Simple DDOS attack protection.
- RSA Keys credentials protection for requests.
- TCP Security Server

### Observations
- Consider changing the [RSA keys](https://cryptotools.net/rsagen) if you are hosting this template.
- You need to change the address the website tries to contact.
- You need to change the database address to your desired database, my personal recommendation is the NAS server hosts the database, and only the NAS server has access to it.

### Considerations
- All credentials are encrypted in the moment of login button, there is no brute credentials (only encrypted) saved in localstorage for redirection hackers to steal, tecnically is safe to use in ``http``, but by the nature of http redirection, they can change the javascript code so the password and username will not be encrypted, be careful hosting this in http on production
- The storage folder will be located in /source_server/drive/account/...
- The temporary received files will be in /source_server/temp/...
- The files is not encrypted, the NAS server has entire access to all files stored in the storage

# Starting
## Linux
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
- Change the address from web client in [validation.js](https://github.com/LeandroTheDev/storage_template/blob/main/source_web/libs/validation.js) to the NAS address
```javascript
function validateSession() {
    // Updating server address
    localStorage.setItem("address", "NAS_ADDRESS");
    localStorage.setItem("port", "7979");
    ....
```
- Simple http client server: ``python3 -m http.server 80`` inside source_web
- You can now access your storage using the address of the NAS server in your favorite internet explorer

## Windows
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
- Change the address from web client in [validation.js](https://github.com/LeandroTheDev/storage_template/blob/main/source_web/libs/validation.js) to the NAS address
```javascript
function validateSession() {
    // Updating server address
    localStorage.setItem("address", "NAS_ADDRESS");
    localStorage.setItem("port", "7979");
    ....
```
- For hosting the web client you can use any web client, my honest recommendation is to use the npm package http-server, its very simple for the personal storage, install it using ``npm install -g http-server``
- Running the http server just type: ``http-server`` in the terminal inside the ``source_web`` folder
- You can now access your storage using the address of the NAS server in your favorite internet explorer