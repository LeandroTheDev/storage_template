import validateSession from "../libs/validation.js";
if (!validateSession()) window.location.href = "../login.html";

console.log("Your token is valid, have fun");

var directory = "";

var folders = [];
var files = [];

/// Request the folders based on the actual directory from the script
function requestFolders() {
    // Creating the xml request
    const xhr = new XMLHttpRequest();
    const address = `http://${localStorage.getItem("address")}:${localStorage.getItem("port")}/drive/getfolders?directory=${directory}`;

    console.log("Requesting folders to: " + address);

    // Configuring the requisition
    xhr.timeout = 5000;
    xhr.open('GET', address, true);
    console.log(localStorage.getItem("token"));
    xhr.setRequestHeader('token', localStorage.getItem("token"));
    xhr.setRequestHeader('username', localStorage.getItem("username"));

    // Definition of the result
    xhr.onload = function () {
        console.log("REQUEST OBJECT: ");
        console.log(xhr);
        // Checking success state
        if (xhr.status == 200) {
            // Collecting the data
            let body = JSON.parse(xhr.responseText)["message"];
            folders = body["folders"];
            files = body["files"];

            updateScreen();
        }
        else
            alert(`Cannot proceed the process, reason: ${xhr.statusText}, code: ${xhr.status}`);

    };
    // Error treatment
    xhr.onerror = function () { alert(xhr.statusText); }

    // Sending request
    xhr.send(null);
}

/// Updates the screen based on the variables that store files and folders
function updateScreen() {
    let foldersElement = document.getElementById("folders-list");
    let filesElement = document.getElementById("files-list");

    // Adding folders
    folders.forEach(folderName => {
        // Creating new section to the list
        const childElement = document.createElement("li");
        childElement.classList.add("folder-section");

        // Adding the icon to the element
        const iconElement = document.createElement("span");
        iconElement.classList.add("folder-icon");
        childElement.appendChild(iconElement);

        // Adding the text
        const textNode = document.createTextNode(folderName);
        childElement.appendChild(textNode);

        // Instanciating the click event
        childElement.onclick = () => folderClicked(folderName);

        // Add it to the folder element
        foldersElement.appendChild(childElement);
    });

    files.forEach(fileName => {
        // Creating new section to the list
        const childElement = document.createElement("li");
        childElement.classList.add("file-section");

        // Adding the icon to the element
        const iconElement = document.createElement("span");
        iconElement.classList.add("file-icon");
        childElement.appendChild(iconElement);

        // Adding the text
        const textNode = document.createTextNode(fileName);
        childElement.appendChild(textNode);

        // Instanciating the click event
        childElement.onclick = () => fileClicked(fileName);

        // Add it to the file element
        filesElement.appendChild(childElement);
    });
}

function folderClicked(folderName) {
    // Resetting variables
    files = [];
    folders = [];
    document.getElementById("folders-list").innerHTML = "";
    document.getElementById("files-list").innerHTML = "";

    // Increment directory
    directory += `/${folderName}`;

    // Request new folder
    requestFolders();
}

function fileClicked(fileName) {
    alert(fileName);
}

function backButtonClicked() {
    // Getting last position from directory /
    const lastSlashIndex = directory.lastIndexOf('/');

    // Check if exist
    if (lastSlashIndex !== -1) {
        // Remove the last directory
        directory = directory.substring(0, lastSlashIndex);
    }

    // Resetting variables
    files = [];
    folders = [];
    document.getElementById("folders-list").innerHTML = "";
    document.getElementById("files-list").innerHTML = "";

    requestFolders();
}
document.getElementById("back-button").addEventListener("click", backButtonClicked);

// Request the home folders
requestFolders();