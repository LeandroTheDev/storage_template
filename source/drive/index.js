function invalidateSession() {
    localStorage.removeItem("token");
    localStorage.removeItem("timestamp");
    window.location.href = "../index.html";
}

// Treatment for unkown address
if (localStorage.getItem("address") == undefined || localStorage.getItem("port") == undefined) invalidateSession();

// Treatment for invalid token and timestamp
if (localStorage.getItem("token") == undefined || localStorage.getItem("timestamp") == undefined) invalidateSession();

let timestampDiff = Date.now() - parseInt(localStorage.getItem("timestamp"));
// 1 Hour valid for timestamp (of course this is validated on server side this is only for user fast)
if (timestampDiff > 3600000) invalidateSession();

console.log("Your token is valid, have fun");