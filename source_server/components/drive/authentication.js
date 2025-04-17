const loginKeys = {};
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
        const password = decryptText(req.body.password, username, loginKeys[username]);

        if (password == "Decrypt Error") {
            delete loginKeys[username];
            res.status(401).send({ error: true, message: 'Wrong Key, try again' });
            return;
        }

        console.log("[Drive Auth] " + req.ip + " is authenticating in: " + username);

        //Validations
        if (stringsTreatment(typeof username, res, "Invalid Username, use a valid username to login.", 400)) { delete loginKeys[username]; return; }
        if (stringsTreatment(typeof password, res, "Invalid Password, use a valid password to login.", 400)) { delete loginKeys[username]; return; }

        //Credentials for login
        let credentialsPass = await database.login(username, password);
        if (credentialsPass == null) {
            loginKeys[username];
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
            token["publickey"] = req.body.publickey
            token["timeoutId"] = setTimeout(function () {
                delete tokens[username];
            }, 3600000); // Can be logged in max 1 hour

            // Success, send the token to the user
            res.status(200).send({
                error: false, message: encryptText(JSON.stringify({
                    "auth": token["auth"],
                    "publickey": token["publickey"],
                    "created": token["created"]
                }), req.body.publickey)
            });
        }
        //Wrong Credentials
        else {
            console.log("[Drive Auth] " + req.ip + " authentication refused, wrong credentials for " + username);
            res.status(401).send({ error: true, message: 'Invalid Credentials' });
            return;
        }
    }

    async requestKey(req, res) {
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

    instanciateAuthentication(http) {
        //Post
        http.post('/drive/login', this.login);

        //Get
        http.get('/drive/requestkey', this.requestKey);
    }
}

module.exports = new DriveAuthentication;