// Treatment for unkown address
if (localStorage.getItem("address") == undefined || localStorage.getItem("port") == undefined) window.location.href = "index.html";

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
        const addres = `http://${localStorage.getItem("address")}:${localStorage.getItem("port")}/drive/login`;

        console.log("Requesting login to: " + addres);

        // Configuring the requisition
        xhr.timeout = 100;
        xhr.open('POST', addres, true);
        xhr.setRequestHeader('Content-Type', 'application/json');

        // Definition of the result
        xhr.onload = function () {
            // Checking success state
            if (xhr.status >= 200) {
                // Collecting the token
                let body = JSON.parse(xhr.responseText);
                localStorage.setItem("token", body["MESSAGE"]);
                localStorage.setItem("timestamp", Date.now());
                // Changing the page
                window.location.href = "drive/index.html";
            }
            else
                alert(xhr.statusText);

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
