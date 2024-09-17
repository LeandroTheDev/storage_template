# Storage Web Server
The backend server for Storage Template, contains everthing you need to storage system to work, this exclusivily needs to be runned in the NAS Server

### Building
For building you will need any sql server, mariadb the recomendation from LeandroTheDev, after that consider creating a database for the server the following API's: 
- ``CREATE DATABASE drive``

Also dont forget to add the permission:
- ``GRANT ALL PRIVILEGES ON drive.* TO 'admin'@'DatabaseIP' IDENTIFIED BY 'secret-password' WITH GRANT OPTION; FLUSH PRIVILEGES``

### Dependencies
- npm install cors
- npm install express
- npm install mariadb (change that to your database if not mariadb)
- npm install sequelize
- npm install multer