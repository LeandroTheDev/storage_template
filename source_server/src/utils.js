const TIMESTAMP_LIMIAR_FOR_AUTH = 10;

const { generateKeyPairSync, publicEncrypt, privateDecrypt, constants } = require('crypto');

/**
* Stores all temporary tokens and timeout intervals
* {
*   "username": {
*       "created": 123... Date.now()
*       "auth": 123... Random Generated Number
*       "ip": 127.0.0.1 Connection ip
*       "timeoutId": 123... Timeout id that will delete this key from the object after certain time
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

        // Timestamp bypass check
        if (!typeof timestamp === 'number' && isNaN(timestamp)) {
            delete tokens[username];
            console.log("[Drive Auth Check] Corrupted timestamp: " + username + ", " + timestamp);
            resCallBack.status(401).send({ error: true, message: "Invalid Token, you will need to login again." });
            return true;
        }

        // Calculating the received timestamp with a limiar
        const timestampDifference = (Date.now() - parseInt(timestamp)) / 1000;
        if (timestampDifference > TIMESTAMP_LIMIAR_FOR_AUTH || timestampDifference < -TIMESTAMP_LIMIAR_FOR_AUTH) {
            delete tokens[username];
            console.log("[Drive Auth Check] Wrong timestamp: " + username + " timestamp difference: " + timestampDifference);
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
    if (privateKey == undefined) {
        if (tokens[username] == undefined) {
            console.error("[Drive Utils] user " + username + " requested something without keys");
            return "Decrypt Exception"
        };
        privateKey = tokens[username]["privatekey"];
    };

    try {
        const decrypted = privateDecrypt(
            {
                key: privateKey,
                format: 'pem',
                type: 'pkcs1',
                padding: constants.RSA_PKCS1_OAEP_PADDING,
                oaepHash: 'sha256',
            },
            Buffer.from(text, 'base64')
        );

        return decrypted.toString('utf8');
    } catch (error) {
        console.error("[Drive Utils] user " + username + " exception in decrypt " + error);
        return "Decrypt Exception";
    }
};

/**
* Encrypt a text by the public key provided
* @param {String} text - "my future encrypted text"
* @param {String} username - "test"
* @param {String} publicKey - "---BEGIN..."
* @returns {String} Returns the text encrypted, will return "Encrypt Error", if the public key is wrong
*/
function encryptText(text, username, publicKey) {
    if (publicKey == undefined) publicKey = tokens[username]["publickey"];

    try {
        const encryptedText = publicEncrypt(
            {
                key: publicKey,
                format: 'pem',
                type: 'pkcs1',
                padding: constants.RSA_PKCS1_OAEP_PADDING,
                oaepHash: 'sha256',
            },
            Buffer.from(text.toString())
        );

        return encryptedText.toString('base64');
    } catch (error) {
        console.log("[Drive Utils] user " + username + " exception in encrypt " + error);
        return "Encrypt Exception";
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
            type: 'pkcs1',
            format: 'pem'
        },
        privateKeyEncoding: {
            type: 'pkcs1',
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