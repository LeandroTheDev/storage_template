/// Invalidate the session the user will not longer can connect to the servers
function invalidateSession() {
    localStorage.removeItem("token");
    localStorage.removeItem("timestamp");
}

/// Returns true if is a valid session, false if not
function validateSession() {
    // Updating server address
    localStorage.setItem("address", "localhost");
    localStorage.setItem("port", "7979");

    // Checking for token existance
    if (localStorage.getItem("token") == undefined || localStorage.getItem("timestamp") == undefined) {
        invalidateSession();
        return false;
    }

    // Checking the timestamp for token, 1 hour max by default in both sides
    let timestampDiff = Date.now() - parseInt(localStorage.getItem("timestamp"));
    if (timestampDiff > 3600000) {
        invalidateSession();
        return false;
    }

    return true;
}

export default validateSession;