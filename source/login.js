import validateSession from "./libs/validation.js";
validateSession();

document.addEventListener('DOMContentLoaded', function () {
    // Selecting the formulary
    const loginForm = document.getElementById('login-form');

    // Add a listener for the submition
    loginForm.addEventListener('submit', function (event) {
        event.preventDefault(); // Impede o envio padrão do formulário

        // Getting the data
        const username = document.getElementById('username').value;
        const password = document.getElementById('password').value;

        // Creating the xml request
        const xhr = new XMLHttpRequest();
        const address = `http://${localStorage.getItem("address")}:${localStorage.getItem("port")}/drive/login`;

        console.log("Requesting login to: " + address);

        // Configuring the requisition
        xhr.timeout = 5000;
        xhr.open('POST', address, true);
        xhr.setRequestHeader('Content-Type', 'application/json');

        // Definition of the result
        xhr.onload = function () {
            // Checking success state
            if (xhr.status == 200) {
                // Collecting the token
                let body = JSON.parse(xhr.responseText);                
                localStorage.setItem("token", body["message"]);
                localStorage.setItem("timestamp", Date.now());
                localStorage.setItem("username", username);
                // Changing the page
                window.location.href = "drive/index.html";
            }
            else if (xhr.status == 401)
                alert("Invalid credentials");
            else
                alert(`Cannot proceed the authentication, reason: ${xhr.statusText}, code: ${xhr.status}`);

        };
        // Error treatment
        xhr.onerror = function () { alert(xhr.statusText); }

        // Sending request
        xhr.send(JSON.stringify({
            "username": username,
            "password": password
        }));
    });
});
