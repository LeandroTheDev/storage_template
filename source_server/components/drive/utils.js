/**
* Stores all temporary tokens and timeout intervals
* {
*   "username": {
*       "token": 678...
*       "handshake": 123...
*       "timeoutId": 987...
*       "usedHandshakes": {
*           "123...": true
*           "345...": true
*       }
*   }
* }
*/
const tokens = {};

/**
* Check if the variable in parameter is a type of string, if not uses the
* res to send a error with the message parameter and status code
* @param {object} variable
* @param {Response} resCallBack
* @param {String} message - "Invalid..."
* @param {int} statusCode - 401
* @returns {boolean} Returns a boolean, true for errors, false for success.
*/
function stringsTreatment(variable, resCallBack, message = "Invalid Argument", statusCode = 401) {
    if (variable !== "string") {
        resCallBack.status(statusCode).send({ error: true, message: message });
        return true;
    }
    return false
}

/**
* Check if the variable in parameter is a type of string, if not uses the
* res to send a error with the message parameter and status code
* also will check for invalid https or http protocol
* @param {object} variable
* @param {Response} resCallBack
* @param {String} message - "Invalid..."
* @param {int} statusCode - 401
* @returns {boolean} Returns a boolean, true for errors, false for success.
*/
function urlTreatment(variable, resCallBack, message = "Invalid Argument", statusCode = 401) {
    if (typeof variable !== "string") {
        resCallBack.status(statusCode).send({ error: true, message });
        return true;
    }

    // Regex for strings starting in http:// ou https://
    const urlPattern = /^(https?:\/\/)[^\s]+$/;

    // Check if is a valid string and does not contains "./" ou "../"
    if (!urlPattern.test(variable) || variable.includes("./")) {
        resCallBack.status(statusCode).send({ error: true, message });
        return true;
    }

    return false;
}

/**
* Check if the auth is valid for the client
* @param {String} username - "123..."
* @param {String} auth - "123..."
* @param {Response} resCallBack
* @param {int} statusCode - 401
* @returns {boolean} Returns a boolean, true for errors, false for success.
*/
function authCheckTreatment(username, auth, resCallBack) {
    try {
        const [randomNumber, timestamp] = auth.split("-");

        // Checking if the token exists
        if (tokens[username] == undefined) {
            delete tokens[username];
            console.log("[Drive Auth Check] Invalid token: " + username);
            resCallBack.status(401).send({ error: true, message: "Invalid Token, you will need to login again." });
            return true;
        }

        // Checking if the auth is the same
        if (randomNumber != tokens[username]["auth"]) {
            delete tokens[username];
            console.log("[Drive Auth Check] Wrong auth: " + username);
            resCallBack.status(401).send({ error: true, message: "Invalid Token, you will need to login again." });
            return true;
        }

        // Calculating the receved timestamp with a limiar of 10 seconds
        if (!Math.abs(Math.floor(Date.now() / 1000) - parseInt(timestamp, 10)) <= 10) {
            delete tokens[username];
            console.log("[Drive Auth Check] Wrong timestamp: " + username);
            resCallBack.status(401).send({ error: true, message: "Invalid Token, you will need to login again." });
            return true;
        }
    } catch (e) {
        delete tokens[username];
        console.log("[Drive Auth Check] Exception: " + username + ", " + e);
        resCallBack.status(401).send({ error: true, message: "Invalid Token, you will need to login again." });
        return true;
    }
    return false
};

/**
* Decrypt any encrypted text by the private key provided, if no private key is provided
* the function will try to get one from tokens
* @param {String} text - "FHADGUAISDFJASKDLAX" --> encrypted text"
* @param {String} username - "test"
* @param {String} privateKey - "---BEGIN..."
* @returns {String} Returns the text decrypted, will return "Decrypt Error", if the private key is wrong
*/
function decryptText(text, username, privateKey) {
    if (privateKey == undefined) privateKey = tokens[username]["privatekey"];

    try {
        const decryptor = new JSEncrypt();
        decryptor.setPrivateKey(privateKey);

        return decryptor.decrypt(text);
    } catch (error) {
        return "Decrypt Error";
    }
};

/**
* Encrypt a text by the public key provided
* @param {String} text - "my future encrypted text" --> encrypted text"
* @param {String} publicKey - "---BEGIN..."
* @returns {String} Returns the text encrypted, will return "Encrypt Error", if the public key is wrong
*/
function encryptText(text, publicKey) {
    try {
        const encryptor = new JSEncrypt();
        encryptor.setPublicKey(publicKey);

        return encryptor.encrypt(text);
    } catch (error) {
        return "Encrypt Error";
    }
}

/**
* Returns the new width and height based on targetResolution
* @param {int} width - "640"
* @param {int} height - "480"
* @param {String} targetResolution - "720p"
* @returns {json} Returns a json with the values: width, height
*/
function resizeToResolution(width, height, targetResolution) {
    const aspectRatio = width / height;

    let newWidth, newHeight;

    switch (targetResolution) {
        case '720p':
            newHeight = 720;
            newWidth = Math.round(newHeight * aspectRatio);
            break;
        case '1080p':
            newHeight = 1080;
            newWidth = Math.round(newHeight * aspectRatio);
            break;
        default:
            newHeight = 480;
            newWidth = Math.round(newHeight * aspectRatio);
            break;
    }

    return { width: newWidth, height: newHeight };
}

/**
* Generates a private and public key
* @returns {json} Returns a json with the values: privatekey, publickey
*/
function generateKeyPair() {
    const { publicKey, privateKey } = generateKeyPairSync('rsa', {
        modulusLength: 2048,
        publicKeyEncoding: {
            type: 'spki',
            format: 'pem'
        },
        privateKeyEncoding: {
            type: 'pkcs8',
            format: 'pem'
        }
    });
    return {
        "privatekey": privateKey,
        "publickey": publicKey
    }
}

module.exports = {
    stringsTreatment,
    authCheckTreatment,
    urlTreatment,
    resizeToResolution,
    decryptText,
    encryptText,
    generateKeyPair,
    tokens
}