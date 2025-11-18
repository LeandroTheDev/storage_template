const fs = require("fs");
const path = require('path');
const multer = require('multer');
const { spawn } = require('child_process');
const { rm } = require('fs/promises');
const sharp = require('sharp');

const administrators = ["admin", "test"];
const drivePath = path.resolve(__dirname, '../', 'drive');
const tempPath = path.resolve(__dirname, '../', 'temp');

/// Libraries paths
var mediaConverterPath;
var mediaDownloaderPath;
var librariesPath;
if (process.platform === 'win32') {
    mediaConverterPath = path.resolve(__dirname, '../', 'libraries', 'windows', 'media_converter.exe');
    mediaDownloaderPath = path.resolve(__dirname, '../', 'libraries', 'windows', 'media_downloader.exe');
    librariesPath = path.resolve(__dirname, '../', 'libraries', 'windows', 'libraries');
} else {
    mediaConverterPath = path.resolve(__dirname, '../', 'libraries', 'linux', 'media_converter');
    mediaDownloaderPath = path.resolve(__dirname, '../', 'libraries', 'linux', 'media_downloader');
    librariesPath = path.resolve('/usr');
}

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
    // Stores pending video conversions
    static mediaConversions = {}
    // Stores pending video downloads
    static mediaDownloads = {}
    // Simple check for bad intentions from clients
    static directoryTreatment(directory) {
        if (typeof directory !== "string") return null;

        directory = directory
            .replace(/\.\.\//g, "_")  // "../"
            .replace(/\.\/+/g, "_")   // "./"
            .replace(/\/{2,}/g, "/"); // "//"

        // Replace multiple dots in one
        directory = directory.replace(/\.{2,}/g, ".");

        // Invaldi characters to "_"
        // Available: letters, numbers, spaces, "-", "_", "/", "."
        directory = directory.replace(/[^a-zA-Z0-9_\- /.]/g, "_");

        // Remove duplicated"/"
        directory = directory.replace(/\/{2,}/g, "/");

        return directory;
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
    // Converts the video if not yet converted
    static convertVideo(videoDirectory) {
        return new Promise(async (resolve, reject) => {
            if (DriveStorage.mediaConversions[videoDirectory] != undefined) {
                reject("Video is already been converted");
                return;
            }

            DriveStorage.mediaConversions[videoDirectory] = true;

            await new Promise((resolve_queue) => {
                const timer = setInterval(() => {
                    const keys = Object.keys(DriveStorage.mediaConversions);
                    const index = keys.indexOf(videoDirectory);

                    if (index === 0) {
                        clearInterval(timer);
                        resolve_queue();
                    } else if (index === -1) {
                        clearInterval(timer);
                        resolve_queue();
                    }
                }, 5000);
            });

            console.log(`Converting: "${videoDirectory}", total in queue: ${Object.keys(DriveStorage.mediaConversions).length}`);

            const tempFolder = path.resolve(path.dirname(videoDirectory), ".temp_convert");
            try {
                const process = spawn(
                    `${mediaConverterPath} --tempFolder "${tempFolder}" --resultFolder "${path.dirname(videoDirectory)}" --extension mp4 "${videoDirectory}"`,
                    {
                        cwd: librariesPath,
                        shell: true
                    }
                );

                process.stdout.on('data', (data) => {
                    console.log(`[Video Converter] ${data.toString()}`);
                });

                process.stderr.on('data', (data) => {
                    console.error(`[Video Converter] ${data.toString()}`);
                });

                process.on('close', (code) => {
                    if (code === 0) {
                        fs.rmSync(tempFolder, { recursive: true, force: true });

                        console.log(`[Video Converter] Conversion completed successfully: ${videoDirectory}`);
                        delete DriveStorage.mediaConversions[videoDirectory];
                        resolve(videoDirectory);
                    } else {
                        fs.rmSync(tempFolder, { recursive: true, force: true });

                        const error = new Error(`Process exited with code ${code}`);
                        console.error(`[Video Converter] Conversion failed: ${error.message}, caused by: ${videoDirectory}`);
                        delete DriveStorage.mediaConversions[videoDirectory];
                        reject(error);
                    }
                });

                process.on('error', (error) => {
                    fs.rmSync(tempFolder, { recursive: true, force: true });

                    console.error(`[Video Converter] Failed to start process: ${error.message}`);
                    delete DriveStorage.mediaConversions[videoDirectory];
                    reject(error);
                });
            } catch (error) {
                fs.rmSync(tempFolder, { recursive: true, force: true });

                console.error(`[Video Converter] Unexpected error: ${error.message}`);
                delete DriveStorage.mediaConversions[videoDirectory];
                reject(error);
            }
        });
    }
    // Download a video by the link
    static downloadVideo(actualFolder, videoLink) {
        //Dependencies
        const {
            urlFixer
        } = require('./utils');
        videoLink = urlFixer(videoLink);

        if (DriveStorage.mediaConversions[videoLink] != undefined)
            throw "Video is already been downloaded";

        return new Promise(async (resolve, reject) => {
            try {
                DriveStorage.mediaDownloads[videoLink] = true;

                await new Promise((resolve_queue) => {
                    const timer = setInterval(() => {
                        const keys = Object.keys(DriveStorage.mediaDownloads);
                        const index = keys.indexOf(videoLink);

                        if (index === 0) {
                            clearInterval(timer);
                            resolve_queue();
                        } else if (index === -1) {
                            clearInterval(timer);
                            resolve_queue();
                        }
                    }, 5000);
                });

                let downloadedFileName = "";

                const resultFolder = path.resolve(actualFolder, ".temp_download");

                const process = spawn(
                    `${mediaDownloaderPath} --resultFolder "${resultFolder}" --extension mp4 --ignorePlaylist "${videoLink}"`,
                    {
                        cwd: librariesPath,
                        shell: true
                    }
                );

                process.stdout.on('data', (data) => {
                    console.log(`[Media Downloader] ${data.toString()}`);

                    const output = data.toString();
                    const match = output.match(/Destination:\s(.+)/);
                    if (match) {
                        downloadedFileName = match[1].trim();
                    }

                    const finalMatch = output.match(/Merging formats into "(.+?)"/);
                    if (finalMatch) {
                        downloadedFileName = finalMatch[1].trim();
                    }
                });

                process.stderr.on('data', (data) => {
                    console.error(`[Media Downloader] ${data.toString()}`);

                    const output = data.toString();
                    const match = output.match(/Destination:\s(.+)/);
                    if (match) {
                        downloadedFileName = match[1].trim();
                    }

                    const finalMatch = output.match(/Merging formats into "(.+?)"/);
                    if (finalMatch) {
                        downloadedFileName = finalMatch[1].trim();
                    }
                });

                process.on('close', async (code) => {
                    if (downloadedFileName == "") {
                        reject("Failed to download Video");
                    } else {
                        downloadedFileName = path.basename(downloadedFileName);
                    }

                    function sanitization() {
                        const before = path.resolve(resultFolder, downloadedFileName);
                        const after = DriveStorage.directoryTreatment(before);
                        return new Promise((resolve, reject) => {
                            fs.rename(before, after, (err) => {
                                if (err) {
                                    console.error(`Failed to rename file '${file}':`, err);
                                    reject(err);
                                } else {
                                    resolve();
                                }
                            });
                        });
                    }

                    await sanitization().catch(reject);
                    downloadedFileName = DriveStorage.directoryTreatment(downloadedFileName);

                    if (code === 0 && downloadedFileName.length > 0) {
                        const videoDirectory = path.resolve(resultFolder, downloadedFileName);

                        DriveStorage.convertVideo(videoDirectory)
                            .catch((error) => {
                                delete DriveStorage.mediaDownloads[videoLink];
                                delete DriveStorage.mediaConversions[videoDirectory];
                                fs.rmSync(videoDirectory, { recursive: true, force: true });
                                reject(error);
                            })
                            .then(() => {
                                delete DriveStorage.mediaDownloads[videoLink];
                                delete DriveStorage.mediaConversions[videoDirectory];
                                console.log(`[Drive Download] ${downloadedFileName} downloaded and converted to ${actualFolder}`);
                                const videoResult = path.resolve(actualFolder, downloadedFileName);
                                fs.renameSync(videoDirectory, videoResult);
                                resolve(videoResult);
                            });
                    } else {
                        if (downloadedFileName.length > 0) {
                            const videoDirectory = path.resolve(resultFolder, downloadedFileName);
                            fs.rmSync(videoDirectory, { recursive: true, force: true });

                            const error = new Error(`Download process exited with code ${code}`);
                            console.error(`[Media Downloader] Download failed: ${error.message}, caused by: ${videoLink}`);
                            delete DriveStorage.mediaDownloads[videoLink];
                            delete DriveStorage.mediaConversions[videoDirectory];
                            reject(error);
                        } else {
                            const videoDirectory = path.resolve(resultFolder, downloadedFileName);
                            fs.rmSync(videoDirectory, { recursive: true, force: true });

                            const error = new Error(`Download process exited with code ${code}`);
                            console.error(`[Media Downloader] Download failed: ${error.message}, caused by: ${videoLink}`);
                            delete DriveStorage.mediaDownloads[videoLink];
                            delete DriveStorage.mediaConversions[videoDirectory];
                            reject(error);
                        }
                    }
                });

                process.on('error', (error) => {
                    const videoDirectory = path.resolve(resultFolder, downloadedFileName);
                    console.error(`[Media Downloader] Failed to start download process: ${error.message}`);
                    delete DriveStorage.mediaDownloads[videoLink];
                    delete DriveStorage.mediaConversions[videoDirectory];
                    reject(error);
                });
            } catch (error) {
                console.error(`[Media Downloader] Unexpected error downloading the video: ${error.message}, caused by: ${videoDirectory}`);
                delete DriveStorage.mediaDownloads[videoLink];
                delete DriveStorage.mediaConversions[videoDirectory];
                reject(error);
            }
        });
    }

    async getFolders(req, res) {
        const directory = DriveStorage.directoryTreatment(req.query.directory);
        const headers = req.headers;
        const username = headers.username;

        //Dependencies
        const {
            stringsTreatment,
            authCheckTreatment,
            decryptText,
        } = require('./utils');

        const auth = decryptText(headers.auth, username);

        //Errors Treatments
        if (stringsTreatment(typeof username, res, "Invalid Username", 401)) return;
        if (authCheckTreatment(username, auth, res)) return;
        if (stringsTreatment(typeof directory, res, "Invalid Directory", 401)) return;
        delete require("./init").ipTimeout[req.ip];

        //Getting the program path
        const userPath = path.resolve(drivePath, username);
        //Creating the folder if not exist
        fs.mkdirSync(userPath, { recursive: true });
        //Reading folders and files
        fs.readdir(userPath + directory, { withFileTypes: true }, (err, folder) => {
            if (err != null) {
                err = err.toString();
                if (err.includes("no such file or directory")) {
                    res.status(500).send({ error: true, message: "No such file or directory in: " + directory });
                } else {
                    res.status(500).send({ error: true, message: err });
                }
                return;
            }

            // Auxiliar function to help get creation time from files
            const getCreationTime = (filePath) => {
                return new Promise((resolve, reject) => {
                    fs.stat(filePath, (err, stats) => {
                        if (err) {
                            reject(err);
                        } else {
                            resolve(stats.birthtime); // Returns the creation time
                        }
                    });
                });
            };

            // Getting the path and name for each folder
            const folders = folder.filter(item => item.isDirectory()).map(folder => {
                return { name: folder.name, path: path.join(userPath + directory, folder.name) };
            });

            // Getting the path and name for each file
            const files = folder
                .filter(item => item.isFile())
                .map(file => ({ name: file.name, path: path.join(userPath + directory, file.name) }));

            const sortByCreationTime = async (items) => {
                const itemsWithTime = await Promise.all(items.map(async (item) => {
                    const creationTime = await getCreationTime(item.path);
                    const singleItem = { ...item, creationTime };
                    delete singleItem.path;
                    return singleItem;
                }));

                // Sort by creation time in descending order (newest first)
                return itemsWithTime.sort((a, b) => b.creationTime - a.creationTime);
            };

            // Sorting files and folders by creation time
            Promise.all([
                sortByCreationTime(folders),
                sortByCreationTime(files)
            ]).then(([sortedFolders, sortedFiles]) => {
                res.status(200).send({
                    error: false,
                    message: {
                        "folders": sortedFolders.map(folder => folder.name),
                        "files": sortedFiles.map(file => file.name)
                    }
                });
            }).catch((error) => {
                console.log("[Drive] " + username + " crashed the getFolders function, reason: " + error);
                res.status(500).send({ error: true, message: "Cannot sort items contact the drive manufactory" });
            });
        });
    }

    async requestFile(req, res) {
        const directory = DriveStorage.directoryTreatment(req.query.directory);
        const headers = req.headers;
        const username = headers.username;

        // Authentication
        {
            //Dependencies
            const {
                stringsTreatment,
                authCheckTreatment,
                decryptText
            } = require('./utils');

            const auth = decryptText(headers.auth, username);

            //Errors Treatments
            if (stringsTreatment(typeof username, res, "Invalid Username", 401)) return;
            if (authCheckTreatment(username, auth, res)) return;
            if (stringsTreatment(typeof directory, res, "Invalid Directory", 401)) return;
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
        return; // Disabled for now
        const directory = req.query.directory;

        // No video requests
        if (DriveStorage.fileRequests[req.ip] == undefined || DriveStorage.fileRequests[req.ip][directory] == undefined) {
            console.log("[Drive] Ilegal file request from: " + req.ip);
            res.status(401).send({ error: true, message: "You don't have any file requests" });
            return;
        }

        //Getting the video path
        let filePath = path.resolve(__dirname, '../', 'drive', DriveStorage.fileRequests[req.ip][directory]["username"]) + directory;

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
        const directory = DriveStorage.directoryTreatment(req.query.directory);
        const headers = req.headers;
        const username = headers.username;

        // Authentication
        {
            //Dependencies
            const {
                stringsTreatment,
                authCheckTreatment,
                decryptText
            } = require('./utils');

            const auth = decryptText(headers.auth, username);

            //Errors Treatments
            if (stringsTreatment(typeof username, res, "Invalid Username", 401)) return;
            if (authCheckTreatment(username, auth, res)) return;
            if (stringsTreatment(typeof directory, res, "Invalid Directory", 401)) return;
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
        const directory = DriveStorage.directoryTreatment(req.query.directory);
        const headers = req.headers;
        const username = headers.username;

        //Dependencies
        const {
            stringsTreatment,
            authCheckTreatment,
            decryptText
        } = require('./utils');

        const auth = decryptText(headers.auth, username);

        //Errors Treatments
        if (stringsTreatment(typeof username, res, "Invalid Username", 401)) return;
        if (authCheckTreatment(username, auth, res)) return;
        if (stringsTreatment(typeof directory, res, "Invalid Directory", 401)) return;
        delete require("./init").ipTimeout[req.ip];

        // No image requests
        if (DriveStorage.imageRequests[req.ip] == undefined || DriveStorage.imageRequests[req.ip][directory] == undefined) {
            console.log("[Drive] Ilegal image request from: " + req.ip);
            res.status(401).send({ error: true, message: "You don't have any image requests" });
            return;
        }

        //Getting the video path
        let filePath = path.resolve(__dirname, '../', 'drive', DriveStorage.imageRequests[req.ip][directory]["username"]) + directory;

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

    async getImageThumbnail(req, res) {
        const directory = DriveStorage.directoryTreatment(req.query.directory);
        const headers = req.headers;
        const username = headers.username;

        //Dependencies
        const {
            stringsTreatment,
            authCheckTreatment,
            decryptText
        } = require('./utils');

        const auth = decryptText(headers.auth, username);

        //Errors Treatments
        if (stringsTreatment(typeof username, res, "Invalid Username", 401)) return;
        if (authCheckTreatment(username, auth, res)) return;
        if (stringsTreatment(typeof directory, res, "Invalid Directory", 401)) return;
        delete require("./init").ipTimeout[req.ip];

        // No thumb requests
        if (DriveStorage.imageRequests[req.ip] == undefined || DriveStorage.imageRequests[req.ip][directory] == undefined) {
            console.log("[Drive] Ilegal image request from: " + req.ip);
            res.status(401).send({ error: true, message: "You don't have any image requests" });
            return;
        }

        //Getting the video path
        let filePath = path.resolve(__dirname, '../', 'drive', DriveStorage.imageRequests[req.ip][directory]["username"]) + directory;

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

        const targetWidth = 426;
        const targetHeight = 240;

        // Send the data for user
        stream.pipe(sharp()
            .resize(targetWidth, targetHeight, { fit: 'inside' })
            .pipe(res));
    }

    async requestVideo(req, res) {
        const directory = DriveStorage.directoryTreatment(req.query.directory);
        const headers = req.headers;
        const username = headers.username;

        // Authentication
        {
            //Dependencies
            const {
                stringsTreatment,
                authCheckTreatment,
                decryptText
            } = require('./utils');

            const auth = decryptText(headers.auth, username);

            //Errors Treatments
            if (stringsTreatment(typeof username, res, "Invalid Username", 401)) return;
            if (authCheckTreatment(username, auth, res)) return;
            if (stringsTreatment(typeof directory, res, "Invalid Directory", 401)) return;
            delete require("./init").ipTimeout[req.ip];
        }

        // Undefined check
        if (DriveStorage.videoRequests[req.ip] == undefined) DriveStorage.videoRequests[req.ip] = {};

        console.log("[Drive Storage] " + username + " request a video from: " + directory);
        // If already exists increase the expiration from requests
        if (DriveStorage.videoRequests[req.ip][directory] != undefined) {
            DriveStorage.videoRequests[req.ip][directory]["expirationIn"] = videoDefaultExpiration;
            DriveStorage.videoRequests[req.ip][directory]["username"] = username;
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
            // If request is empty just clear this interval
            if (DriveStorage.videoRequests[req.ip] == undefined || DriveStorage.videoRequests[req.ip][directory] == undefined) {
                clearInterval(id);
                return;
            }
            // Reduce expiration
            DriveStorage.videoRequests[req.ip][directory]["expirationIn"] -= 1;
            // Remove if empty
            if (DriveStorage.videoRequests[req.ip][directory]["expirationIn"] <= 0) delete DriveStorage.videoRequests[req.ip][directory];
            if (Object.keys(DriveStorage.videoRequests[req.ip]) == 0) delete DriveStorage.videoRequests[req.ip];
        }, 2000);

        res.status(200).send({ error: false, message: "The video has been requested, you can now access it" });
    }

    async getVideo(req, res) {
        const userDirectory = DriveStorage.directoryTreatment(req.query.directory);
        const headers = req.headers;
        const username = headers.username;

        //Dependencies
        const {
            stringsTreatment,
            authCheckTreatment,
            decryptText
        } = require('./utils');

        const auth = decryptText(headers.auth, username);

        //Errors Treatments
        if (stringsTreatment(typeof username, res, "Invalid Username", 401)) return;
        if (authCheckTreatment(username, auth, res)) return;
        if (stringsTreatment(typeof userDirectory, res, "Invalid Directory", 401)) return;
        delete require("./init").ipTimeout[req.ip];

        const directory = userDirectory.substring(0, userDirectory.lastIndexOf('.')) + userDirectory.substring(userDirectory.lastIndexOf('.'));

        // No video requests
        if (DriveStorage.videoRequests[req.ip] == undefined || DriveStorage.videoRequests[req.ip][userDirectory] == undefined) {
            console.warn("[Drive Storage] Ilegal video request from: " + req.ip);
            res.status(401).send({ error: true, message: "You don't have any video requests" });
            return;
        }

        //Getting the video path
        let filePath = path.resolve(__dirname, '../', 'drive', DriveStorage.videoRequests[req.ip][userDirectory]["username"]) + directory;

        if (!fs.existsSync(filePath)) {
            console.log("[Drive Storage] " + DriveStorage.getDateTime() + " " + req.ip + " Illegal getVideo called, video is still processing probably in: " + directory);
            res.status(404).send({ error: true, message: "The video is not processed yet, return later, if the error persists contact the Administrator" });
            return;
        }

        const stat = fs.statSync(filePath);
        const fileSize = stat.size;
        const range = req.headers.range;

        // Complex Stream
        if (range) {
            const parts = range.replace(/bytes=/, "").split("-");
            const start = parseInt(parts[0], 10);
            const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
            const chunkSize = (end - start) + 1;

            if (start < 0 || end < 0) {
                res.status(400).send({ error: true, message: "Invalid range between" });
                return;
            }

            const fileStream = fs.createReadStream(filePath, { start, end });

            res.writeHead(206, {
                'Content-Range': `bytes ${start}-${end}/${fileSize}`,
                'Accept-Ranges': 'bytes',
                'Content-Length': chunkSize,
                'Content-Type': `video/${path.extname(directory)}`,
            });

            fileStream.pipe(res);
        }
        // Simple Stream
        else {
            res.writeHead(200, {
                'Content-Length': fileSize,
                'Content-Type': `video/${path.extname(directory)}`,
            });

            fs.createReadStream(filePath).pipe(res);
        }
    }

    async createFolder(req, res) {
        const directory = DriveStorage.directoryTreatment(req.query.directory);
        const headers = req.headers;
        const username = headers.username;

        //Dependencies
        const {
            stringsTreatment,
            authCheckTreatment,
            decryptText
        } = require('./utils');

        const auth = decryptText(headers.auth, username);

        //Errors Treatments
        if (stringsTreatment(typeof username, res, "Invalid Username", 401)) return;
        if (authCheckTreatment(username, auth, res)) return;
        if (stringsTreatment(typeof directory, res, "Invalid Directory", 403)) return;
        if (path.basename(directory) == ".temp_convert") {
            res.status(403).send({ error: true, message: "Invalid Directory, directory cannot be '.temp_convert'" });
            return;
        }
        if (path.basename(directory) == ".temp_download") {
            res.status(403).send({ error: true, message: "Invalid Directory, directory cannot be '.temp_download'" });
            return;
        }
        delete require("./init").ipTimeout[req.ip];

        //Getting the program path
        const userPath = path.resolve(drivePath, username);
        //Create folder
        fs.mkdirSync(userPath + directory, { recursive: true });
        console.log("[Drive Storage] " + DriveStorage.getDateTime() + " " + username + " Folder created in " + directory)
        res.status(200).send({
            error: false, message: "success"
        });
    }

    async delete(req, res) {
        const item = DriveStorage.directoryTreatment(req.body.item);
        const headers = req.headers;
        const username = headers.username;
        //Dependencies        
        const {
            stringsTreatment,
            authCheckTreatment,
            decryptText
        } = require('./utils');

        const auth = decryptText(headers.auth, username);

        //Errors Treatments
        if (stringsTreatment(typeof username, res, "Invalid Username", 403)) return;
        if (authCheckTreatment(username, auth, res)) return;
        if (stringsTreatment(typeof item, res, "Invalid Directory", 403)) return;
        delete require("./init").ipTimeout[req.ip];
        const userPath = path.resolve(drivePath, username);

        let error = false;
        //If is Folder, remove it
        fs.rm(userPath + item, { recursive: true }, (err) => {
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
            fs.unlink(userPath + item, (err) => {
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
                        error: false, message: "Success"
                    });
                }
            });
        });
    }

    async upload(req, res) {
        //Dependencies            
        const {
            stringsTreatment,
            authCheckTreatment,
            decryptText
        } = require('./utils');

        const headers = req.headers;
        const username = headers.username;

        const auth = decryptText(headers.auth, username);
        if (authCheckTreatment(username, auth, res)) return;

        // Prepare function to receive any file
        const uploader = multer({
            dest: path.resolve(__dirname, '../', 'temp'),
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

            //Errors Treatments
            if (stringsTreatment(typeof username, res, "Invalid Username", 401)) return;

            // Get save directory
            const directory = DriveStorage.directoryTreatment(req.body.saveDirectory);
            if (stringsTreatment(typeof directory, res, "Invalid Directory", 401)) return;

            // Swipe all files
            for (let fileIndex = 0; fileIndex < req.files.length; fileIndex++) {
                const fileName = DriveStorage.directoryTreatment(req.files[fileIndex]["originalname"]);

                //Errors check
                if (stringsTreatment(typeof fileName, res, "Invalid File Name", 401)) return;

                //Getting the save path
                const fileSavePath = path.resolve(__dirname, '../', 'drive', username) + directory;
                try {
                    const originalPath = path.join(fileSavePath, fileName);

                    //Removing from temporary folder and adding to the user folder
                    fs.renameSync(req.files[fileIndex]["path"], originalPath);

                    delete require("./init").ipTimeout[req.ip];
                    console.log("[Drive Storage] " + DriveStorage.getDateTime() + " " + directory + "/" + fileName + " received from: " + username)

                    // Converts the video if exists
                    const fileExtension = path.extname(originalPath);
                    if (fileExtension == ".mp4" || fileExtension == ".mkv") {
                        console.log("[Drive Storage] " + DriveStorage.getDateTime() + " " + directory + "/" + fileName + " conversion started, requested by: " + username);
                        DriveStorage.convertVideo(originalPath).then(function () {
                            console.log("[Drive Storage] " + DriveStorage.getDateTime() + " " + directory + "/" + fileName + " converted, requested by: " + username);
                        }).catch(function () {
                            console.log("[Drive Storage] " + DriveStorage.getDateTime() + " " + directory + "/" + fileName + " conversion failed, by: " + username);
                        });
                    }

                    res.status(200).send({
                        error: false, message: "Success"
                    });
                } catch (error) {
                    res.status(400).send({
                        error: true, message: error
                    });
                }
            }
        });
    }

    async downloadVideo(req, res) {
        const videoLink = req.body.link;
        const directory = DriveStorage.directoryTreatment(req.body.directory);
        const headers = req.headers;
        const username = headers.username;

        //Dependencies
        const {
            stringsTreatment,
            authCheckTreatment,
            urlTreatment,
            decryptText
        } = require('./utils');

        const auth = decryptText(headers.auth, username);

        //Errors Treatments
        if (stringsTreatment(typeof username, res, "Invalid Username", 401)) return;
        if (authCheckTreatment(username, auth, res)) return;
        if (urlTreatment(videoLink, res, "Invalid video link, please recheck the link provided.", 401)) return;
        delete require("./init").ipTimeout[req.ip];

        //Getting the program path
        const userPath = path.resolve(drivePath, username);

        console.log("[Drive Download] Video been downloaded by " + username + ", link: " + videoLink + ", saving on: " + userPath + ", directory: " + directory);

        DriveStorage.downloadVideo(path.resolve(userPath, directory.replace(/^\/+/, "")), videoLink)
            .then(async function (videoDirectory) {
                console.log("[Drive] video fully downloaded to " + videoDirectory + " by " + username);

                res.status(200).send({
                    error: false, message: "success"
                });
            }).catch(function (error) {
                console.log("[Drive] video failed to downloaded by " + username);
                console.error(error);

                res.status(500).send({
                    error: false, message: "Unable to download video"
                });
            });
    }

    instanciateDrive(http, timeoutFunction) {
        this.resetIpTimeout = timeoutFunction;

        console.log("[Drive] Routes will be avaialable after Temp Folders be deleted!");

        function generateRoutes(instance) {
            //Get
            http.get('/drive/getfolders', instance.getFolders);
            http.get('/drive/requestfile', instance.requestFile);
            http.get('/drive/getfile', instance.getFile);
            http.get('/drive/requestImage', instance.requestImage);
            http.get('/drive/getImage', instance.getImage);
            http.get('/drive/getImageThumbnail', instance.getImageThumbnail);
            http.get('/drive/requestVideo', instance.requestVideo);
            http.get('/drive/getvideo', instance.getVideo);

            //Post
            http.post('/drive/createfolder', instance.createFolder);
            http.post('/drive/uploadfile', instance.upload);
            http.post('/drive/downloadvideo', instance.downloadVideo);

            //Delete
            http.delete('/drive/delete', instance.delete);

            console.log("[Drive] Storage routes Instanciated");
        }

        console.log("[Drive] Deleting temp files...");
        rm(tempPath, { recursive: true, force: true }).then((_) => console.log("[Drive] Download temp files deleted!"));
        const { cleanTempFolders } = require("./utils");
        cleanTempFolders(drivePath).then((_) => {
            console.log("[Drive] Temp folders deleted!");

            generateRoutes(this);
        });
    }
}

module.exports = new DriveStorage;