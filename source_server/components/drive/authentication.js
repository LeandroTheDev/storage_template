const loginKeys = {};

const MAX_REQUESTS_FOR_GENERATE_KEYS = 5;
const INVALIDATION_TIME_AFTER_LOGIN = 3600000;

class DriveAuthentication {
    async login(req, res) {
        const database = require('./database');
        const {
            stringsTreatment,
            generateKeyPair,
            decryptText,
            encryptText,
            tokens
        } = require('./utils');

        //Getting data
        const username = req.body.username;
        const userPublickey = req.body.publickey;

        if (loginKeys[username] == undefined) {
            res.status(401).send({ error: true, message: 'Your login request has expired' });
            return;
        }

        const password = decryptText(req.body.password, username, loginKeys[username]["privatekey"]);

        if (password == "Decrypt Error") {
            delete loginKeys[username];
            res.status(401).send({ error: true, message: 'Wrong Key, try again' });
            return;
        }

        console.log("[Drive Auth] " + req.ip + " is authenticating in: " + username);

        //Validations
        if (stringsTreatment(typeof username, res, "Invalid Username, use a valid username to login.", 400)) { delete loginKeys[username]; return; }
        if (stringsTreatment(typeof password, res, "Invalid Password, use a valid password to login.", 400)) { delete loginKeys[username]; return; }
        if (stringsTreatment(typeof userPublickey, res, "Invalid Password, use a valid password to login.", 400)) { delete loginKeys[username]; return; }

        //Credentials for login
        let credentialsPass = await database.login(username, password);
        if (credentialsPass == null) {
            delete loginKeys[username];
            res.status(500).send({ "message": "Internal Error" });
            return;
        };

        // Check if credentials is correct
        if (credentialsPass) {
            delete require("./init").ipTimeout[req.ip];
            console.log("[Drive Auth] user " + username + " authenticated in ip: " + req.ip);

            let randomPassword = "";
            // Generating the Random Password
            for (let i = 0; i < 20; i++) {
                randomPassword += Math.floor(Math.random() * 10);
            }

            // Clear timeouts to the user if exist
            if (tokens[username] != undefined)
                clearTimeout(tokens[username]["timeoutId"]);

            const token = generateKeyPair();
            token["created"] = Date.now();
            token["auth"] = randomPassword;
            token["ip"] = req.ip;
            token["timeoutId"] = setTimeout(function () {
                delete tokens[username];
            }, INVALIDATION_TIME_AFTER_LOGIN);

            tokens[username] = token;

            // Success, send the token to the user
            res.status(200).send({
                error: false,
                message: {
                    "auth": encryptText(token["auth"], username, userPublickey),
                    "publickey": token["publickey"],
                    "created": encryptText(token["created"], username, userPublickey)
                }
            });
        }
        //Wrong Credentials
        else {
            console.log("[Drive Auth] " + req.ip + " authentication refused, wrong credentials for " + username);
            res.status(401).send({ error: true, message: 'Invalid Credentials' });
            return;
        }
    }

    async requestLoginKey(req, res) {
        console.log("[Drive Auth] " + req.ip + " requested a login key");
        const username = req.headers.username;

        const {
            stringsTreatment,
            generateKeyPair,
        } = require('./utils');

        //Validations
        if (stringsTreatment(typeof username, res, "Invalid Username, use a valid username to login.", 400)) return;

        const keys = generateKeyPair();

        const now = Date.now();
        keys["created"] = now;
        loginKeys[username] = keys;

        // After 10 seconds clear the login keys
        setTimeout(function () {
            if (loginKeys[username] != undefined)
                if (loginKeys[username]["created"] == now)
                    delete loginKeys[username];
        }, 10000);

        res.status(200).send({ error: false, message: keys["publickey"] });
    }

    static requests = 0;
    async requestKeys(req, res) {
        DriveAuthentication.requests++;
        if (DriveAuthentication.requests > MAX_REQUESTS_FOR_GENERATE_KEYS) {
            res.status(401).send({ error: true, message: "The server is busy at moment, wait a while..." });
            return;
        }

        setTimeout(function () {
            DriveAuthentication.requests--;
        }, 5000);

        const {
            generateKeyPair,
        } = require('./utils');

        const keys = generateKeyPair();

        const now = Date.now();
        keys["created"] = now;

        console.log("[Drive Auth] Keys generated for " + req.ip);

        res.status(200).send({ error: false, message: keys });
    }

    instanciateAuthentication(http) {
        //Post
        http.post('/drive/login', this.login);

        //Get
        http.get('/drive/requestloginkey', this.requestLoginKey);
        http.get('/drive/requestkeys', this.requestKeys);
    }
}

module.exports = new DriveAuthentication;