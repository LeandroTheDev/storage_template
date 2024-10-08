const decryptText = require("../crypto/decrypto");
const { tokens } = require("./utils");
class DriveAuthentication {
    async login(req, res) {
        function internalError() {
            res.status(500).send({ "message": "Internal Error" });
        }
        const database = require('./database');
        const {
            stringsTreatment,
        } = require('./utils');
        //Getting data
        const username = decryptText(req.body.username);
        const password = decryptText(req.body.password);
        const handshake = decryptText(req.body.handshake);

        console.log("[Drive Auth] " + req.ip + " is authenticating");

        //Validations
        if (stringsTreatment(typeof username, res, "Invalid Username, use a valid username to login.", 400)) return;
        if (stringsTreatment(typeof password, res, "Invalid Password, use a valid password to login.", 400)) return;
        if (stringsTreatment(typeof handshake, res, "Invalid Handshake, nope not like that.", 401)) return;

        //Credentials for login
        let credentialsPass = await database.login(username, password);
        if (credentialsPass == null) { internalError(); return; };

        // Check if credentials is correct
        if (credentialsPass) {
            let token = "";
            // Generating the token
            for (let i = 0; i < 100; i++) {
                token += Math.floor(Math.random() * 10);
            }

            // Clear timeouts to the user if exist
            if (tokens[username] != undefined)
                clearTimeout(tokens[username]["timeoutId"]);

            // Resseting the token for that user if exist
            tokens[username] = {
                "token": token,
                "handshake": handshake,
                "timeoutId": setTimeout(function () {
                    delete tokens[username];
                }, 3600000), // 1 hour timeout
                "usedHandshakes": {},
            }

            // Updating the token in database
            if (await database.updateUserToken(token, username)) { internalError(); return };
            delete require("./init").ipTimeout[req.ip];
            console.log("[Drive Auth] user " + username + " authenticated in ip: " + req.ip);
            // Success, send the token to the user
            res.status(200).send({ error: false, message: token });
        }
        //Wrong Credentials
        else {
            console.log("[Drive Auth] " + req.ip + " authentication refused, wrong credentials for " + username);
            res.status(401).send({ error: true, message: 'Invalid Credentials' });
            return;
        }
    }

    instanciateAuthentication(http) {
        //Post
        http.post('/drive/login', this.login);
    }
}

module.exports = new DriveAuthentication;