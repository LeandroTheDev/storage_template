const fs = require("fs");
const path = require('path');
const multer = require('multer');
const decryptText = require("../crypto/decrypto");

const administrators = ["admin"];

const imageDefaultExpiration = 5;
const fileDefaultExpiration = 1;
const videoDefaultExpiration = 100;
class DriveStorage {

    // Stores authentication videos
    static videoRequests = {};
    // Stores authentication images
    static imageRequests = {};
    // Stores authentication files
    static fileRequests = {};
    // Simple check for bad intentions from clients
    static directoryTreatment(directory) {
        const slashTest = !(directory.indexOf("../") !== -1 || directory.indexOf("//") !== -1 || directory.indexOf("./") !== -1);
        const dotsQuantity = (directory.match(/\./g) || []).length;
        const letterNumbersTest = /^[a-zA-Z0-9_ -]+$/.test(directory.replace(/[\/.]/g, '')) && dotsQuantity <= 1;
        return slashTest && letterNumbersTest;
    }
    static getDateTime() {
        const now = new Date();
        const hour = now.getHours();
        const day = now.getDate();
        const month = now.getMonth() + 1;
        const year = now.getFullYear();
        return `${hour}h/${day}d/${month}m/${year}y`;
    }
    // Returns false if the actual user is on administrator list
    static falseConditionIfAdministrator(username) {
        for (let i = 0; i < administrators.length; i++) {
            if (administrators[i] == username) return false
        }
        return true;
    }

    async getFolders(req, res) {
        const directory = req.query.directory;
        const headers = req.headers;
        const username = decryptText(headers.username);
        const token = decryptText(headers.token);
        const handshake = headers.handshake;
        const decryptedHandshake = decryptText(headers.handshake);

        //Dependencies
        const database = require('./database');
        const {
            stringsTreatment,
            tokenCheckTreatment,
        } = require('./utils');

        //Errors Treatments
        if (stringsTreatment(typeof username, res, "Invalid Username, why you are sending any invalid username?", 401)) return;
        if (stringsTreatment(typeof decryptedHandshake, res, "Invalid Handshake, nope not like that.", 401)) return;
        if (tokenCheckTreatment(username, handshake, decryptedHandshake, token, await database.getUserToken(username), res)) return;
        if (stringsTreatment(typeof directory, res, "Invalid Directory, what are you trying to do my friend?", 401)) return;
        if (directory.length != 0 && !DriveStorage.directoryTreatment(directory) && DriveStorage.falseConditionIfAdministrator(username)) {
            res.status(401).send({ error: true, message: "Invalid Directory, you cannot do this alright?" });
            return;
        }
        delete require("./init").ipTimeout[req.ip];

        //Getting the program path
        const drivePath = path.resolve(__dirname, '../', '../', 'drive', username);
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

    async requestFile(req, res) {
        const directory = req.query.directory;
        const headers = req.headers;
        const username = decryptText(headers.username);
        const token = decryptText(headers.token);
        const handshake = headers.handshake;
        const decryptedHandshake = decryptText(headers.handshake);

        // Authentication
        {
            //Dependencies
            const database = require('./database');
            const {
                stringsTreatment,
                tokenCheckTreatment,
            } = require('./utils');

            //Errors Treatments
            if (stringsTreatment(typeof username, res, "Invalid Username, why you are sending any invalid username?", 401)) return;
            if (stringsTreatment(typeof decryptedHandshake, res, "Invalid Handshake, nope not like that.", 401)) return;
            if (tokenCheckTreatment(username, handshake, decryptedHandshake, token, await database.getUserToken(username), res)) return;
            if (stringsTreatment(typeof directory, res, "Invalid Directory, what are you trying to do my friend?", 401)) return;
            if (!DriveStorage.directoryTreatment(directory) && DriveStorage.falseConditionIfAdministrator(username)) {
                res.status(401).send({ error: true, message: "Invalid Directory, you cannot do this alright?" });
                return;
            }
            delete require("./init").ipTimeout[req.ip];
        }

        // Undefined check
        if (DriveStorage.fileRequests[req.ip] == undefined) DriveStorage.fileRequests[req.ip] = {};

        console.log("[Drive] " + username + " request a file from: " + directory);
        // If already exists just increase the expiration from requests
        if (DriveStorage.fileRequests[req.ip][directory] != undefined) {
            DriveStorage.fileRequests[req.ip][directory]["expirationIn"] = fileDefaultExpiration;
            res.status(200).send({ error: false, message: "The File has been requested, you can now access it" });
            return;
        }
        // Creates a request for the ip address
        else DriveStorage.fileRequests[req.ip][directory] = {
            expirationIn: fileDefaultExpiration,
            username: username
        };

        // Reduce expiration every 2 seconds
        let id = setInterval(function () {
            // If request if empty just clear this interval
            if (DriveStorage.fileRequests[req.ip] == undefined || DriveStorage.fileRequests[req.ip][directory] == undefined) {
                clearInterval(id);
                return;
            }
            // Reduce expiration
            DriveStorage.fileRequests[req.ip][directory]["expirationIn"] -= 1;
            //  Remove if empty
            if (DriveStorage.fileRequests[req.ip][directory]["expirationIn"] <= 0) delete DriveStorage.fileRequests[req.ip][directory];
            if (Object.keys(DriveStorage.fileRequests[req.ip]) == 0) delete DriveStorage.fileRequests[req.ip];
        }, 2000);

        res.status(200).send({ error: false, message: "The File has been requested, you can now access it" });
    }

    async getFile(req, res) {
        const directory = req.query.directory;

        // No video requests
        if (DriveStorage.fileRequests[req.ip] == undefined || DriveStorage.fileRequests[req.ip][directory] == undefined) {
            console.log("[Drive] Ilegal file request from: " + req.ip);
            res.status(401).send({ error: true, message: "You don't have any file requests" });
            return;
        }

        //Getting the video path
        let filePath = path.resolve(__dirname, '../', '../', 'drive', DriveStorage.fileRequests[req.ip][directory]["username"]) + directory;

        if (!fs.existsSync(filePath)) {
            res.status(404).send({ error: true, message: "This file no longers exists" });
            return;
        }

        const stats = fs.statSync(filePath);
        const fileSize = stats.size;

        // Change content type from header
        res.setHeader('content-type', 'file/' + filePath.substring(filePath.lastIndexOf('.') + 1));
        res.setHeader('content-length', fileSize);
        res.setHeader('content-disposition', `attachment; filename="${path.basename(filePath)}"`);


        // Creates a stream based on file
        const stream = fs.createReadStream(filePath);

        // Error treatment
        stream.on('error', (error) => {
            console.log("[Drive] Error reading the file: " + directory + " from: " + DriveStorage.fileRequests[req.ip][directory]["username"] + " reason: " + error);
            res.status(500).send({ error: true, message: "Cannot read the file" });
        });

        // Send the data for user
        stream.pipe(res);
    }

    async requestImage(req, res) {
        const directory = req.query.directory;
        const headers = req.headers;
        const username = decryptText(headers.username);
        const token = decryptText(headers.token);
        const handshake = headers.handshake;
        const decryptedHandshake = decryptText(headers.handshake);

        // Authentication
        {
            //Dependencies
            const database = require('./database');
            const {
                stringsTreatment,
                tokenCheckTreatment,
            } = require('./utils');

            //Errors Treatments
            if (stringsTreatment(typeof username, res, "Invalid Username, why you are sending any invalid username?", 401)) return;
            if (stringsTreatment(typeof decryptedHandshake, res, "Invalid Handshake, nope not like that.", 401)) return;
            if (tokenCheckTreatment(username, handshake, decryptedHandshake, token, await database.getUserToken(username), res)) return;
            if (stringsTreatment(typeof directory, res, "Invalid Directory, what are you trying to do my friend?", 401)) return;
            if (!DriveStorage.directoryTreatment(directory) && DriveStorage.falseConditionIfAdministrator(username)) {
                res.status(401).send({ error: true, message: "Invalid Directory, you cannot do this alright?" });
                return;
            }
            delete require("./init").ipTimeout[req.ip];
        }

        // Undefined check
        if (DriveStorage.imageRequests[req.ip] == undefined) DriveStorage.imageRequests[req.ip] = {};

        console.log("[Drive] " + username + " request a image from: " + directory);
        // If already exists just increase the expiration from requests
        if (DriveStorage.imageRequests[req.ip][directory] != undefined) {
            DriveStorage.imageRequests[req.ip][directory]["expirationIn"] = imageDefaultExpiration;
            res.status(200).send({ error: false, message: "The image has been requested, you can now access it" });
            return;
        }
        // Creates a request for the ip address
        else DriveStorage.imageRequests[req.ip][directory] = {
            expirationIn: imageDefaultExpiration,
            username: username
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

        const stats = fs.statSync(filePath);
        const fileSize = stats.size;

        // Change content type from header
        res.setHeader('content-type', 'image/' + filePath.substring(filePath.lastIndexOf('.') + 1));
        res.setHeader('content-length', fileSize);

        // Creates a stream based on file
        const stream = fs.createReadStream(filePath);

        // Error treatment
        stream.on('error', (error) => {
            console.log("[Drive] Error reading the file: " + directory + " from: " + DriveStorage.imageRequests[req.ip][directory]["username"] + " reason: " + error);
            res.status(500).send({ error: true, message: "Cannot read the file" });
        });

        // Send the data for user
        stream.pipe(res);
    }

    async requestVideo(req, res) {
        const directory = req.query.directory;
        const headers = req.headers;
        const username = decryptText(headers.username);
        const token = decryptText(headers.token);
        const handshake = headers.handshake;
        const decryptedHandshake = decryptText(headers.handshake);

        // Authentication
        {
            //Dependencies
            const database = require('./database');
            const {
                stringsTreatment,
                tokenCheckTreatment,
            } = require('./utils');

            //Errors Treatments
            if (stringsTreatment(typeof username, res, "Invalid Username, why you are sending any invalid username?", 401)) return;
            if (stringsTreatment(typeof decryptedHandshake, res, "Invalid Handshake, nope not like that.", 401)) return;
            if (tokenCheckTreatment(username, handshake, decryptedHandshake, token, await database.getUserToken(username), res)) return;
            if (stringsTreatment(typeof directory, res, "Invalid Directory, what are you trying to do my friend?", 401)) return;
            if (!DriveStorage.directoryTreatment(directory) && DriveStorage.falseConditionIfAdministrator(username)) {
                res.status(401).send({ error: true, message: "Invalid Directory, you cannot do this alright?" });
                return;
            }
            delete require("./init").ipTimeout[req.ip];
        }

        // Undefined check
        if (DriveStorage.videoRequests[req.ip] == undefined) DriveStorage.videoRequests[req.ip] = {};

        console.log("[Drive Storage] " + username + " request a video from: " + directory);
        // If already exists just increase the expiration from requests
        if (DriveStorage.videoRequests[req.ip][directory] != undefined) {
            DriveStorage.videoRequests[req.ip][directory]["expirationIn"] = videoDefaultExpiration;
            res.status(200).send({ error: false, message: "The video has been requested, you can now access it" });
            return;
        }
        // Creates a request for the ip address
        else DriveStorage.videoRequests[req.ip][directory] = {
            expirationIn: videoDefaultExpiration,
            username: username
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

        const stat = fs.statSync(filePath);
        const fileSize = stat.size;
        const range = req.headers.range;

        if (range) {
            const parts = range.replace(/bytes=/, "").split("-");
            const start = parseInt(parts[0], 10);
            const end = Math.min(fileSize - 1, parts[1] ? parseInt(parts[1], 10) : fileSize - 1);

            const chunkSize = (end - start) + 1;
            const file = fs.createReadStream(filePath, { start, end });

            const headers = {
                'Content-Range': `bytes ${start}-${end}/${fileSize}`,
                'Accept-Ranges': 'bytes',
                'Content-Length': chunkSize,
                'Content-Type': 'video/mp4',
            };

            res.writeHead(206, headers);
            file.pipe(res);
        } else {
            const headers = {
                'Content-Type': 'video/mp4',
                'Content-Length': fileSize,
            };

            res.writeHead(200, headers);
            fs.createReadStream(filePath).pipe(res);
        }
    }

    async createFolder(req, res) {
        const directory = req.body.directory;
        const headers = req.headers;
        const username = decryptText(headers.username);
        const token = decryptText(headers.token);
        const handshake = headers.handshake;
        const decryptedHandshake = decryptText(headers.handshake);

        //Dependencies
        const database = require('./database');
        const {
            stringsTreatment,
            tokenCheckTreatment,
        } = require('./utils');

        //Errors Treatments
        if (stringsTreatment(typeof username, res, "Invalid Username, why you are sending any invalid username?", 401)) return;
        if (stringsTreatment(typeof decryptedHandshake, res, "Invalid Handshake, nope not like that.", 401)) return;
        if (tokenCheckTreatment(username, handshake, decryptedHandshake, token, await database.getUserToken(username), res)) return;
        if (stringsTreatment(typeof directory, res, "Invalid Directory, what are you trying to do my friend?", 403)) return;
        if (!DriveStorage.directoryTreatment(directory) && DriveStorage.falseConditionIfAdministrator(username)) {
            res.status(403).send({ error: true, message: "Invalid Directory, the directory must contain only letter and numbers" });
            return;
        }
        delete require("./init").ipTimeout[req.ip];

        //Getting the program path
        const drivePath = path.resolve(__dirname, '../', '../', 'drive', username);
        //Create folder
        fs.mkdirSync(drivePath + directory, { recursive: true });
        console.log("[Drive Storage] " + DriveStorage.getDateTime() + " " + username + " Folder created in " + directory)
        res.status(200).send({
            error: false, message: "success"
        });
    }

    async delete(req, res) {
        const item = req.body.item;
        const headers = req.headers;
        const username = decryptText(headers.username);
        const token = decryptText(headers.token);
        const handshake = headers.handshake;
        const decryptedHandshake = decryptText(headers.handshake);
        //Dependencies
        const database = require('./database');
        const {
            stringsTreatment,
            tokenCheckTreatment,
        } = require('./utils');

        //Errors Treatments
        if (stringsTreatment(typeof username, res, "Invalid Username, why you are sending any invalid username?", 403)) return;
        if (stringsTreatment(typeof decryptedHandshake, res, "Invalid Handshake, nope not like that.", 401)) return;
        if (tokenCheckTreatment(username, handshake, decryptedHandshake, token, await database.getUserToken(username), res)) return;
        if (stringsTreatment(typeof item, res, "Invalid Directory, what are you trying to do my friend?", 403)) return;
        if (!DriveStorage.directoryTreatment(item) && DriveStorage.falseConditionIfAdministrator(username)) {
            res.status(401).send({ error: true, message: "Invalid Directory, you cannot do this alright?" });
            return;
        }
        delete require("./init").ipTimeout[req.ip];
        const drivePath = path.resolve(__dirname, '../', '../', 'drive', username);

        let error = false;
        //If is Folder, remove it
        fs.rm(drivePath + item, { recursive: true }, (err) => {
            if (err != null) {
                err = err.toString();
                if (!err.includes("no such file or directory")) {
                    if (!error) {
                        error = true;
                        console.log("[Drive Storage] " + DriveStorage.getDateTime() + " " + username + " " + err);
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
                            console.log("[Drive Storage] " + DriveStorage.getDateTime() + " " + username + " " + err);
                            res.status(500).send({ error: true, message: err });
                            return;
                        }
                    }
                }
                //Finish
                if (!error) {
                    console.log("[Drive Storage] " + DriveStorage.getDateTime() + " " + username + " deleted: " + item);
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

            const headers = req.headers;
            const username = decryptText(headers.username);
            const token = decryptText(headers.token);
            const handshake = headers.handshake;
            const decryptedHandshake = decryptText(headers.handshake);

            //Dependencies
            const database = require('./database');
            const {
                stringsTreatment,
                tokenCheckTreatment,
            } = require('./utils');

            //Errors Treatments
            if (stringsTreatment(typeof username, res, "Invalid Username, why you are sending any invalid username?", 401)) return;
            if (stringsTreatment(typeof decryptedHandshake, res, "Invalid Handshake, nope not like that.", 401)) return;
            if (tokenCheckTreatment(username, handshake, decryptedHandshake, token, await database.getUserToken(username), res)) return;

            // Get save directory
            const directory = req.body.saveDirectory;
            if (stringsTreatment(typeof directory, res, "Invalid Directory, why you are sending me a non string directory?", 401)) return;
            if (directory.length != 0 && !DriveStorage.directoryTreatment(directory) && DriveStorage.falseConditionIfAdministrator(username)) {
                res.status(401).send({ error: true, message: "Invalid Directory, you cannot do this alright?" });
                return;
            }

            // Swipe all files
            for (let fileIndex = 0; fileIndex < req.files.length; fileIndex++) {
                const fileName = req.files[fileIndex]["originalname"];

                if (!DriveStorage.directoryTreatment(fileName) && DriveStorage.falseConditionIfAdministrator(username)) {
                    res.status(401).send({ error: true, message: "The file name is not acceptable, please change it" });
                    return;
                }

                //Errors check
                if (stringsTreatment(typeof fileName, res, "Invalid File Name, why you are sending me a non string file name?", 401)) return;

                //Getting the save path
                const fileSavePath = path.resolve(__dirname, '../', '../', 'drive', username) + directory;
                try {
                    //Removing from temporary folder and adding to the user folder
                    fs.renameSync(req.files[fileIndex]["path"], path.join(fileSavePath, fileName));

                    delete require("./init").ipTimeout[req.ip];
                    console.log("[Drive Storage] " + DriveStorage.getDateTime() + " " + directory + "/" + fileName + " received from: " + username)
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
        http.get('/drive/requestfile', this.requestFile);
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