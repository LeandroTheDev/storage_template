const cors = require('cors');

//Declare HTTP
const http = require('express')();

//DDOS Protection
var ipTimeout = {};
http.use((req, res, next) => {
    //Ip blocked
    if (ipTimeout[req.ip] == 99) {
        console.log("[Drive DDOS] blocked connection from: " + req.ip);
        res.status(413).send({ error: true, message: 'Too Many Attempts' });
        return;
    }

    //Add a limiter for ips
    if (ipTimeout[req.ip] == undefined) {
        ipTimeout[req.ip] = 0
        //Reset Timer
        setTimeout(function () {
            delete ipTimeout[req.ip];
        }, 100000);
    }
    else ipTimeout[req.ip] += 1;

    //If the ip try to communicate 5 times to fast then block it
    if (ipTimeout[req.ip] > 50) ipTimeout[req.ip] = 99;

    next();
});

//Enable json suport
http.use(require('express').json());
//Enable cors for web
http.use(cors());
//Ports for the server
http.listen(7979, function () {
    console.log("[Drive] Listening in 7979");

    //Declaring Authentication
    const authentication = require('./authentication');
    authentication.instanciateAuthentication(http)
    console.log("[Drive] Authentication Instanciated")

    //Declaring Storage
    const storage = require("./storage");
    storage.instanciateDrive(http);
    console.log("[Drive] Storage Instanciated");

});
module.exports = {
    ipTimeout,
};