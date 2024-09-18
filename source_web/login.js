import validateSession from "./libs/validation.js";
import encryptText from "./libs/crypto.js";
validateSession();

localStorage.removeItem("previous-directory");

// Add a listener for the submition
document.getElementById('login-form').addEventListener('submit', async function (event) {
    event.preventDefault(); // Impede o envio padrão do formulário

    // Getting the data
    const username = await encryptText(document.getElementById('username').value);
    const password = await encryptText(document.getElementById('password').value);

    // Creating the xml request
    const xhr = new XMLHttpRequest();
    const address = `http://${localStorage.getItem("address")}:${localStorage.getItem("port")}/drive/login`;

    console.log("Requesting login to: " + address);

    // Configuring the requisition
    xhr.timeout = 5000;
    xhr.open('POST', address, true);
    xhr.setRequestHeader('Content-Type', 'application/json');

    // Definition of the result
    xhr.onload = async function () {
        // Checking success state
        if (xhr.status == 200) {
            // Collecting the token
            let body = JSON.parse(xhr.responseText);
            localStorage.setItem("token", await encryptText(body["message"]));
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

