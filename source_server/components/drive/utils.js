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
* Check if the parameters userToken and serverToken is the same,
* also checks for the username and handshakes, uses
* resCallBack to send a error with the message parameter and status code
* @param {String} userToken - "123..."
* @param {String} serverToken - "123..."
* @param {Response} resCallBack
* @param {int} statusCode - 401
* @returns {boolean} Returns a boolean, true for errors, false for success.
*/
function tokenCheckTreatment(username, handshake, decryptedHandshake, userToken, serverToken, resCallBack) {
    if (userToken != serverToken) {
        delete tokens[username];
        resCallBack.status(401).send({ error: true, message: "Invalid Token, you will need to login again." });
        return true;
    }
    else if (tokens[username] == undefined) {
        delete tokens[username];
        resCallBack.status(401).send({ error: true, message: "Invalid Token, you will need to login again." });
        return true;
    }
    else if (tokens[username]["handshake"] != decryptedHandshake) {
        delete tokens[username];
        resCallBack.status(401).send({ error: true, message: "Invalid Token, nice try but your handshake its not the same." });
        return true
    }
    else if (tokens[username]["usedHandshakes"][handshake] != undefined) {
        delete tokens[username];
        resCallBack.status(401).send({ error: true, message: "Invalid Token, well done but you can't use a handshake that was already used before" });
        return true
    }
    tokens[username]["usedHandshakes"][handshake] = true;
    return false
};

/**
* Check if the parameters userToken and serverToken is the same,
* also checks for the username and handshakes, uses
* resCallBack to send a error with the message parameter and status code
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

module.exports = {
    stringsTreatment,
    tokenCheckTreatment,
    resizeToResolution,
    tokens
}