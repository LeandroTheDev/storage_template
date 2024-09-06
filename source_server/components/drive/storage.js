const fs = require("fs");
const path = require('path');
const multer = require('multer');

const imageDefaultExpiration = 5;
const videoDefaultExpiration = 100;
class DriveStorage {

    // Stores authentication videos
    static videoRequests = {};
    // Stores authentication images
    static imageRequests = {};
    // Simple check for bad intentions from clients
    static directoryTreatment(directory) {
        const slashTest = !(directory.indexOf("../") !== -1 || directory.indexOf("//") !== -1 || directory.indexOf("./") !== -1);
        const dotsQuantity = (directory.match(/\./g) || []).length;
        const letterNumbersTest = /^[a-zA-Z0-9_ -]+$/.test(directory.replace(/[\/.]/g, '')) && dotsQuantity <= 1;
        return slashTest && letterNumbersTest;
    }

    async getFolders(req, res) {
        const directory = req.query.directory;
        const headers = req.headers;

        //Dependencies
        const database = require('./database');
        const {
            stringsTreatment,
            tokenCheckTreatment,
        } = require('./utils');

        //Errors Treatments
        if (stringsTreatment(typeof headers.username, res, "Invalid Username, why you are sending any invalid username?", 401)) return;
        if (tokenCheckTreatment(headers.token, await database.getUserToken(headers.username), res)) return;
        if (stringsTreatment(typeof directory, res, "Invalid Directory, what are you trying to do my friend?", 401)) return;
        if (directory.length != 0 && !DriveStorage.directoryTreatment(directory)) {
            res.status(401).send({ error: true, message: "Invalid Directory, you cannot do this alright?" });
            return;
        }
        delete require("./init").ipTimeout[req.ip];

        //Getting the program path
        const drivePath = path.resolve(__dirname, '../', '../', 'drive', headers.username);
        //Creating the folder if not exist
        fs.mkdirSync(drivePath, { recursive: true });
        //Reading folders and files
        fs.readdir(drivePath + directory, { withFileTypes: true }, (err, folder) => {
            if (err != null) {
                err = err.toString();
                if (err.includes("no such file or directory")) {
                    res.status(500).send({ error: true, message: "No such file or directory in: " + directory });
                } else {
                    res.status(500).send({ error: true, message: err });
                }
                return;
            }
            // Filter out directories
            const folders = folder.filter(item => item.isDirectory()).map(folder => folder.name);
            const files = folder.filter(item => item.isFile()).map(file => file.name);
            res.status(200).send({
                error: false, message: {
                    "folders": folders,
                    "files": files
                }
            });
        });
    }

    async getFile(req, res) {
        const directory = req.query.directory;
        const headers = req.headers;

        //Dependencies
        const database = require('./database');
        const {
            stringsTreatment,
            tokenCheckTreatment,
        } = require('./utils');

        //Errors Treatments
        if (stringsTreatment(typeof headers.username, res, "Invalid Username, why you are sending any invalid username?", 401)) return;
        if (tokenCheckTreatment(headers.token, await database.getUserToken(headers.username), res)) return;
        if (stringsTreatment(typeof directory, res, "Invalid Directory, what are you trying to do my friend?", 401)) return;
        if (!DriveStorage.directoryTreatment(directory)) {
            res.status(401).send({ error: true, message: "Invalid Directory, you cannot do this alright?" });
            return;
        }
        delete require("./init").ipTimeout[req.ip];

        //Getting the image path
        let filePath = path.resolve(__dirname, '../', '../', 'drive', headers.username) + directory;

        // Getting the file stream
        const stream = fs.createReadStream(filePath);

        // Error treatment
        stream.on('error', (err) => {
            console.error('[Drive] Error reading the file ' + filePath + ' caused by: ' + headers.username + " reason: " + err);
            res.status(500).send('File read error');
        });

        // Send file
        stream.pipe(res);
    }

    async requestImage(req, res) {
        const directory = req.query.directory;
        const headers = req.headers;

        // Authentication
        {
            //Dependencies
            const database = require('./database');
            const {
                stringsTreatment,
                tokenCheckTreatment,
            } = require('./utils');

            //Errors Treatments
            if (stringsTreatment(typeof headers.username, res, "Invalid Username, why you are sending any invalid username?", 401)) return;
            if (tokenCheckTreatment(headers.token, await database.getUserToken(headers.username), res)) return;
            if (stringsTreatment(typeof directory, res, "Invalid Directory, what are you trying to do my friend?", 401)) return;
            if (!DriveStorage.directoryTreatment(directory)) {
                res.status(401).send({ error: true, message: "Invalid Directory, you cannot do this alright?" });
                return;
            }
            delete require("./init").ipTimeout[req.ip];
        }

        // Undefined check
        if (DriveStorage.imageRequests[req.ip] == undefined) DriveStorage.imageRequests[req.ip] = {};

        console.log("[Drive] " + headers.username + " request a image from: " + directory);
        // If already exists just increase the expiration from requests
        if (DriveStorage.imageRequests[req.ip][directory] != undefined) {
            DriveStorage.imageRequests[req.ip][directory]["expirationIn"] = imageDefaultExpiration;
            res.status(200).send({ error: false, message: "The image has been requested, you can now access it" });
            return;
        }
        // Creates a request for the ip address
        else DriveStorage.imageRequests[req.ip][directory] = {
            expirationIn: imageDefaultExpiration,
            username: headers.username
        };

        // Reduce expiration every 2 seconds
        let id = setInterval(function () {
            // If request if empty just clear this interval
            if (DriveStorage.imageRequests[req.ip] == undefined || DriveStorage.imageRequests[req.ip][directory] == undefined) {
                clearInterval(id);
                return;
            }
            // Reduce expiration
            DriveStorage.imageRequests[req.ip][directory]["expirationIn"] -= 1;
            //  Remove if empty
            if (DriveStorage.imageRequests[req.ip][directory]["expirationIn"] <= 0) delete DriveStorage.imageRequests[req.ip][directory];
            if (Object.keys(DriveStorage.imageRequests[req.ip]) == 0) delete DriveStorage.imageRequests[req.ip];
        }, 2000);

        res.status(200).send({ error: false, message: "The Image has been requested, you can now access it" });
    }

    async getImage(req, res) {
        const directory = req.query.directory;

        // No video requests
        if (DriveStorage.imageRequests[req.ip] == undefined || DriveStorage.imageRequests[req.ip][directory] == undefined) {
            console.log("[Drive] Ilegal image request from: " + req.ip);
            res.status(401).send({ error: true, message: "You don't have any image requests" });
            return;
        }

        //Getting the video path
        let filePath = path.resolve(__dirname, '../', '../', 'drive', DriveStorage.imageRequests[req.ip][directory]["username"]) + directory;

        if (!fs.existsSync(filePath)) {
            res.status(404).send({ error: true, message: "This image no longers exists" });
            return;
        }

        // Change content type from header
        res.setHeader('content-type', 'image/' + filePath.substring(filePath.lastIndexOf('.') + 1));

        // Creates a stream based on file
        const stream = fs.createReadStream(filePath);

        // Error treatment
        stream.on('error', (error) => {
            console.log("[Drive] Error reading the file: " + directory + " from: " + DriveStorage.imageRequests[req.ip][directory]["username"] + " reason: " + error);
            res.status(500).send({ error: true, message: "Cannot read the file, contact LeandroTheDev" });
        });

        // Send the data for user
        stream.pipe(res);
    }

    async requestVideo(req, res) {
        const directory = req.query.directory;
        const headers = req.headers;

        // Authentication
        {
            //Dependencies
            const database = require('./database');
            const {
                stringsTreatment,
                tokenCheckTreatment,
            } = require('./utils');

            //Errors Treatments
            if (stringsTreatment(typeof headers.username, res, "Invalid Username, why you are sending any invalid username?", 401)) return;
            if (tokenCheckTreatment(headers.token, await database.getUserToken(headers.username), res)) return;
            if (stringsTreatment(typeof directory, res, "Invalid Directory, what are you trying to do my friend?", 401)) return;
            if (!DriveStorage.directoryTreatment(directory)) {
                res.status(401).send({ error: true, message: "Invalid Directory, you cannot do this alright?" });
                return;
            }
            delete require("./init").ipTimeout[req.ip];
        }

        // Undefined check
        if (DriveStorage.videoRequests[req.ip] == undefined) DriveStorage.videoRequests[req.ip] = {};

        console.log("[Drive] " + headers.username + " request a video from: " + directory);
        // If already exists just increase the expiration from requests
        if (DriveStorage.videoRequests[req.ip][directory] != undefined) {
            DriveStorage.videoRequests[req.ip][directory]["expirationIn"] = videoDefaultExpiration;
            res.status(200).send({ error: false, message: "The video has been requested, you can now access it" });
            return;
        }
        // Creates a request for the ip address
        else DriveStorage.videoRequests[req.ip][directory] = {
            expirationIn: videoDefaultExpiration,
            username: headers.username
        };

        // Reduce expiration every 2 seconds
        let id = setInterval(function () {
            // If request if empty just clear this interval
            if (DriveStorage.videoRequests[req.ip] == undefined || DriveStorage.videoRequests[req.ip][directory] == undefined) {
                clearInterval(id);
                return;
            }
            // Reduce expiration
            DriveStorage.videoRequests[req.ip][directory]["expirationIn"] -= 1;
            //  Remove if empty
            if (DriveStorage.videoRequests[req.ip][directory]["expirationIn"] <= 0) delete DriveStorage.videoRequests[req.ip][directory];
            if (Object.keys(DriveStorage.videoRequests[req.ip]) == 0) delete DriveStorage.videoRequests[req.ip];
        }, 2000);

        res.status(200).send({ error: false, message: "The video has been requested, you can now access it" });
    }

    async getVideo(req, res) {
        const directory = req.query.directory;

        // No video requests
        if (DriveStorage.videoRequests[req.ip] == undefined || DriveStorage.videoRequests[req.ip][directory] == undefined) {
            console.log("[Drive] Ilegal video request from: " + req.ip);
            res.status(401).send({ error: true, message: "You don't have any video requests" });
            return;
        }

        //Getting the video path
        let filePath = path.resolve(__dirname, '../', '../', 'drive', DriveStorage.videoRequests[req.ip][directory]["username"]) + directory;

        if (!fs.existsSync(filePath)) {
            res.status(404).send({ error: true, message: "This video no longs exists" });
            return;
        }

        // Change content type from header
        res.setHeader('content-type', 'video/mp4');

        // Creates a stream based on file
        const stream = fs.createReadStream(filePath);

        // Error treatment
        stream.on('error', (error) => {
            console.log("[Drive] Error reading the file: " + directory + " from: " + DriveStorage.videoRequests[req.ip][directory]["username"] + " reason: " + error);
            res.status(500).send({ error: true, message: "Cannot read the file, contact LeandroTheDev" });
        });

        // Send the data for user
        stream.pipe(res);
    }

    async createFolder(req, res) {
        function getDateTime() {
            const now = new Date();
            const hora = now.getHours();
            const dia = now.getDate();
            const mes = now.getMonth() + 1;
            const ano = now.getFullYear();
            return `${hora}h/${dia}d/${mes}m/${ano}y`;
        }
        const directory = req.body.directory;
        const headers = req.headers;

        //Dependencies
        const database = require('./database');
        const {
            stringsTreatment,
            tokenCheckTreatment,
        } = require('./utils');

        //Errors Treatments
        if (stringsTreatment(typeof headers.username, res, "Invalid Username, why you are sending any invalid username?", 401)) return;
        if (tokenCheckTreatment(headers.token, await database.getUserToken(headers.username), res)) return;
        if (stringsTreatment(typeof directory, res, "Invalid Directory, what are you trying to do my friend?", 401)) return;
        if (!DriveStorage.directoryTreatment(directory)) {
            res.status(403).send({ error: true, message: "Invalid Directory, the directory must contain only letter and numbers" });
            return;
        }
        delete require("./init").ipTimeout[req.ip];

        //Getting the program path
        const drivePath = path.resolve(__dirname, '../', '../', 'drive', headers.username);
        //Create folder
        fs.mkdirSync(drivePath + directory, { recursive: true });
        console.log("[Drive Storage] " + getDateTime() + " " + headers.username + " Folder created in " + directory)
        res.status(200).send({
            error: false, message: "success"
        });
    }

    async delete(req, res) {
        function getDateTime() {
            const now = new Date();
            const hora = now.getHours();
            const dia = now.getDate();
            const mes = now.getMonth() + 1;
            const ano = now.getFullYear();
            return `${hora}h/${dia}d/${mes}m/${ano}y`;
        }
        const item = req.body.item;
        const headers = req.headers;
        //Dependencies
        const database = require('./database');
        const {
            stringsTreatment,
            tokenCheckTreatment,
        } = require('./utils');

        //Errors Treatments
        if (stringsTreatment(typeof headers.username, res, "Invalid Username, why you are sending any invalid username?", 403)) return;
        if (tokenCheckTreatment(headers.token, await database.getUserToken(headers.username), res)) return;
        if (stringsTreatment(typeof item, res, "Invalid Directory, what are you trying to do my friend?", 403)) return;
        if (!DriveStorage.directoryTreatment(item)) {
            res.status(401).send({ error: true, message: "Invalid Directory, you cannot do this alright?" });
            return;
        }
        delete require("./init").ipTimeout[req.ip];
        const drivePath = path.resolve(__dirname, '../', '../', 'drive', headers.username);

        let error = false;
        //If is Folder, remove it
        fs.rm(drivePath + item, { recursive: true }, (err) => {
            if (err != null) {
                err = err.toString();
                if (!err.includes("no such file or directory")) {
                    if (!error) {
                        error = true;
                        console.log("[Drive Storage] " + getDateTime() + " " + headers.username + " " + err);
                        res.status(500).send({ error: true, message: err });
                        return;
                    } else error = true;
                }
            }
            //If is File, remove it
            fs.unlink(drivePath + item, (err) => {
                if (err != null) {
                    err = err.toString();
                    if (!err.includes("no such file or directory") && !err.includes("illegal operation on a directory, unlink")) {
                        if (!error) {
                            error = true;
                            console.log("[Drive Storage] " + getDateTime() + " " + headers.username + " " + err);
                            res.status(500).send({ error: true, message: err });
                            return;
                        }
                    }
                }
                //Finish
                if (!error) {
                    console.log("[Drive Storage] " + getDateTime() + " " + headers.username + " deleted: " + item);
                    res.status(200).send({
                        error: false, message: "success"
                    });
                }
            });
        });
    }

    async upload(req, res) {
        // Prepare function to receive any file
        const uploader = multer({
            dest: path.resolve(__dirname, '../', '../', 'temp'),
            limits: {
                fileSize: 1024 * 1024 * 20000
            }
        }).any();
        // On file receive
        uploader(req, res, async function (errors) {
            // Errors treatment
            if (errors instanceof multer.MulterError) {
                switch (errors.code) {
                    case "LIMIT_FILE_SIZE": res.status(414).send({
                        error: true, message: "Size limit reached"
                    }); break;
                    default: res.status(400).send({
                        error: true, message: "Unkown Error"
                    }); break;
                }
                return;
            }
            // Unkown errors
            else if (errors) {
                console.log("[Drive] Upload has crashed: " + errors)
                res.status(400).send({
                    error: true, message: "Unkown error"
                });
                return;
            }

            function getDateTime() {
                const now = new Date();
                const hour = now.getHours();
                const day = now.getDate();
                const month = now.getMonth() + 1;
                const year = now.getFullYear();
                return `${hour}h/${day}d/${month}m/${year}y`;
            }
            const headers = req.headers;

            //Dependencies
            const database = require('./database');
            const {
                stringsTreatment,
                tokenCheckTreatment,
            } = require('./utils');

            //Errors Treatments
            if (stringsTreatment(typeof headers.username, res, "Invalid Username, why you are sending any invalid username?", 401)) return;
            if (tokenCheckTreatment(headers.token, await database.getUserToken(headers.username), res)) return;

            // Get save directory
            const directory = req.body.saveDirectory;
            if (stringsTreatment(typeof directory, res, "Invalid Directory, why you are sending me a non string directory?", 401)) return;
            if (directory.length != 0 && !DriveStorage.directoryTreatment(directory)) {
                res.status(401).send({ error: true, message: "Invalid Directory, you cannot do this alright?" });
                return;
            }

            // Swipe all files
            for (let fileIndex = 0; fileIndex < req.files.length; fileIndex++) {
                const fileName = req.files[fileIndex]["originalname"];

                if (!DriveStorage.directoryTreatment(fileName)) {
                    res.status(401).send({ error: true, message: "The file name is not acceptable, please change it" });
                    return;
                }

                //Errors check
                if (stringsTreatment(typeof fileName, res, "Invalid File Name, why you are sending me a non string file name?", 401)) return;

                //Getting the save path
                const fileSavePath = path.resolve(__dirname, '../', '../', 'drive', headers.username) + directory;
                try {
                    //Removing from temporary folder and adding to the user folder
                    fs.renameSync(req.files[fileIndex]["path"], path.join(fileSavePath, fileName));

                    delete require("./init").ipTimeout[req.ip];
                    console.log("[Drive Storage] " + getDateTime() + " " + directory + "/" + fileName + " received from: " + headers.username)
                    res.status(200).send({
                        error: false, message: "success"
                    });
                } catch (error) {
                    res.status(400).send({
                        error: true, message: error
                    });
                }
            }
        });
    }

    instanciateDrive(http, timeoutFunction) {
        this.resetIpTimeout = timeoutFunction;

        //Get
        http.get('/drive/getfolders', this.getFolders);
        http.get('/drive/getfile', this.getFile);
        http.get('/drive/requestImage', this.requestImage);
        http.get('/drive/getImage', this.getImage);
        http.get('/drive/requestVideo', this.requestVideo);
        http.get('/drive/getvideo', this.getVideo);

        //Post
        http.post('/drive/createfolder', this.createFolder);
        http.post('/drive/uploadfile', this.upload);

        //Delete
        http.delete('/drive/delete', this.delete);
    }
}

module.exports = new DriveStorage;