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

    // Configuring the requisition
    xhr.timeout = 5000;
    xhr.open('GET', address, true);
    xhr.setRequestHeader('token', localStorage.getItem("token"));
    xhr.setRequestHeader('username', localStorage.getItem("username"));

    // Definition of the result
    xhr.onload = function () {
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

        // Adding the remove to the element
        const removeElement = document.createElement("span");
        removeElement.classList.add("remove-icon");
        removeElement.onclick = () => function (event) {
            event.stopPropagation();
            folderRemoved(folderName);
        };;
        childElement.appendChild(removeElement);

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

        // Adding the remove to the element
        const removeElement = document.createElement("span");
        removeElement.classList.add("remove-icon");
        removeElement.onclick = function (event) {
            event.stopPropagation();
            fileRemoved(fileName);
        };
        childElement.appendChild(removeElement);


        // Add it to the file element
        filesElement.appendChild(childElement);
    });
}

/// Event when any folder is clicked
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

/// Event when any file is clicked
function fileClicked(fileName) {
    localStorage.setItem("file-view-directory", directory);
    localStorage.setItem("file-view-name", fileName);
    window.location.href = "file-view.html";
}

function folderRemoved(folderName) { }

function fileRemoved(fileName) { }

/// Back button clicked
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

// Upload System
document.getElementById("upload-button").addEventListener("click", () => document.getElementById('media-picker').click());
document.getElementById('media-picker').addEventListener('change', function (event) {
    const input = document.getElementById('media-picker');
    const files = input.files;

    if (files.length === 0) return;

    Array.from(files).forEach(async file => {
        const formData = new FormData();
        formData.append('saveDirectory', directory);
        formData.append('files[]', file, file.name);

        try {
            const response = await fetch(`http://${localStorage.getItem("address")}:${localStorage.getItem("port")}/drive/uploadfile`, {
                method: 'POST',
                body: formData,
                headers: {
                    "token": localStorage.getItem("token"),
                    "username": localStorage.getItem("username")
                }
            });

            if (!response.ok) {
                alert('Cannot upload the file: ' + response.statusText + ", code: " + response.status);
            }
        } catch (error) {
            alert('Cannot upload the file: ' + error);
        }
    });
});

// Request the home folders
requestFolders();