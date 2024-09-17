import validateSession from "../libs/validation.js";
if (!validateSession()) window.location.href = "../login.html";

console.log("Your token is valid, have fun");

var directory = "";

var folders = [];
var files = [];
var isUploading = false;

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
        const textNode = document.createElement("span");
        textNode.classList.add("folder-text");
        textNode.textContent = folderName;
        childElement.appendChild(textNode);

        // Instanciating the click event
        childElement.onclick = () => folderClicked(folderName);

        // Adding the remove to the element
        const removeElement = document.createElement("span");
        removeElement.classList.add("remove-icon");
        removeElement.onclick = function (event) {
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
        const textNode = document.createElement("span");
        textNode.classList.add("file-text");
        textNode.textContent = fileName;
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

/// Remove the folder
function folderRemoved(folderName) {
    if (confirm(`Do you wish to remove ${folderName}?`)) {
        // Creating the xml request
        const xhr = new XMLHttpRequest();
        const address = `http://${localStorage.getItem("address")}:${localStorage.getItem("port")}/drive/delete?item=${directory}/${folderName}`;

        // Configuring the requisition
        xhr.timeout = 5000;
        xhr.open('DELETE', address, true);
        xhr.setRequestHeader('token', localStorage.getItem("token"));
        xhr.setRequestHeader('username', localStorage.getItem("username"));

        // Definition of the result
        xhr.onload = function () {
            // Checking success state
            if (xhr.status == 200) {
                // Resetting variables
                files = [];
                folders = [];
                document.getElementById("folders-list").innerHTML = "";
                document.getElementById("files-list").innerHTML = "";

                requestFolders();
            }
            else
                alert(`Cannot proceed the process, reason: ${xhr.statusText}, code: ${xhr.status}`);

        };
        // Error treatment
        xhr.onerror = function () { alert(xhr.statusText); }

        console.log("Removing folder: " + `${directory}/${folderName}`);

        // Sending request
        xhr.send(null);
    }
}

/// Remove the file
function fileRemoved(fileName) {
    if (confirm(`Do you wish to remove ${fileName}?`)) {
        // Creating the xml request
        const xhr = new XMLHttpRequest();
        const address = `http://${localStorage.getItem("address")}:${localStorage.getItem("port")}/drive/delete?item=${directory}/${fileName}`;

        // Configuring the requisition
        xhr.timeout = 5000;
        xhr.open('DELETE', address, true);
        xhr.setRequestHeader('token', localStorage.getItem("token"));
        xhr.setRequestHeader('username', localStorage.getItem("username"));

        // Definition of the result
        xhr.onload = function () {
            // Checking success state
            if (xhr.status == 200) {
                // Resetting variables
                files = [];
                folders = [];
                document.getElementById("folders-list").innerHTML = "";
                document.getElementById("files-list").innerHTML = "";

                requestFolders();
            }
            else
                alert(`Cannot proceed the process, reason: ${xhr.statusText}, code: ${xhr.status}`);

        };
        // Error treatment
        xhr.onerror = function () { alert(xhr.statusText); }

        console.log("Removing file: " + `${directory}/${fileName}`);

        // Sending request
        xhr.send(null);
    }
}

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
    if (isUploading) {
        alert("Wait until the files finish uploading, or open a new page for it");
        return;
    }
    console.log("User requested upload file");
    isUploading = true;
    const input = document.getElementById('media-picker');
    const uploadFiles = input.files;

    if (uploadFiles.length === 0) {
        isUploading = false;
        return
    };

    let uploadIndex = 0;
    let uploaded = 0;
    let filesElement = document.getElementById("files-list");
    Array.from(uploadFiles).forEach(async file => {
        const actualIndex = uploadIndex;
        uploadIndex++;

        const formData = new FormData();
        formData.append('saveDirectory', directory);
        formData.append('files[]', file, file.name);

        console.log("Sending file: " + file.name);

        try {
            /// Check if this file already exists
            function checkIfFileExists() {
                return files.some(fileName => {
                    console.log(`${fileName} --> ${file.name}`);
                    return fileName === file.name;
                });
            }
            // Wait for user response
            if (checkIfFileExists())
                if (!confirm(`The ${file.name} already exists, do you want to overwrite?`)) return;
            /// Add a new section to the top list, with the upload progress bar
            function addFileToTopList(fileName) {
                // Creating new section to the list
                const childElement = document.createElement("li");
                childElement.classList.add("file-section");

                // Adding the icon to the element
                const iconElement = document.createElement("span");
                iconElement.classList.add("file-icon");
                childElement.appendChild(iconElement);

                // Adding the text
                const textNode = document.createElement("span");
                textNode.classList.add("file-text");
                textNode.textContent = fileName;
                childElement.appendChild(textNode);

                // Instanciating the click event
                childElement.onclick = () => fileClicked(fileName);

                // Adding the remove to the element
                const loadingElement = document.createElement("progress");
                loadingElement.classList.add("upload-icon");
                loadingElement.value = 0;
                loadingElement.max = 100;
                loadingElement.id = "progress-" + actualIndex;
                childElement.appendChild(loadingElement);


                // Add it to the file element
                if (filesElement.firstChild) filesElement.insertBefore(childElement, filesElement.firstChild);
                else filesElement.appendChild(childElement);
            }
            addFileToTopList(file.name);

            const xhr = new XMLHttpRequest();
            const url = `http://${localStorage.getItem("address")}:${localStorage.getItem("port")}/drive/uploadfile`;

            xhr.open('POST', url, true);

            // Authentication
            xhr.setRequestHeader("token", localStorage.getItem("token"));
            xhr.setRequestHeader("username", localStorage.getItem("username"));

            // Progress updater
            xhr.upload.onprogress = function (event) {
                if (event.lengthComputable) {
                    const percentComplete = Math.round((event.loaded / event.total) * 100);
                    const progressBar = document.getElementById("progress-" + actualIndex);
                    progressBar.value = percentComplete;
                }
            };

            // Conclusion event
            xhr.onload = function () {
                if (xhr.status == 200) {
                    // Getting the progress bar
                    const progressBar = document.getElementById("progress-" + actualIndex);

                    // Creating the remove element
                    const removeElement = document.createElement("span");
                    removeElement.classList.add("remove-icon");
                    removeElement.onclick = function (event) {
                        event.stopPropagation();
                        fileRemoved(file.name);
                    };

                    // Replacing the load element with the remove
                    progressBar.replaceWith(removeElement);

                    // If all upload has been finished, refresh the screen
                    if (uploaded == uploadIndex - 1) {
                        isUploading = false;

                        // Resetting variables
                        files = [];
                        folders = [];
                        document.getElementById("folders-list").innerHTML = "";
                        document.getElementById("files-list").innerHTML = "";

                        requestFolders();
                    }
                } else {
                    // Removing the element
                    document.getElementById("progress-" + actualIndex).parentElement.remove();
                    // Sending the message
                    alert('Cannot send the file, reason: ' + xhr.statusText);
                }
            };

            // Error event
            xhr.onerror = function () {
                alert("No connection");
            };

            // Enviando o FormData
            xhr.send(formData);
        } catch (error) {
            alert('Cannot upload the file: ' + error);
        }
    });

    // Resseting the value, so sending the same file again will try to upload again
    event.target.value = '';
});

// Create Folder
document.getElementById("create-folder-button").addEventListener("click", () => document.getElementById("folder-create-dialog").showModal());
document.getElementById("folder-create-confirm").addEventListener("click", (event) => {
    const input = document.getElementById("folder-input");

    if (input.value.length < 1) {
        alert("Cannot create a empty folder");
        event.preventDefault();
        return;
    }

    // Creating the xml request
    const xhr = new XMLHttpRequest();
    const address = `http://${localStorage.getItem("address")}:${localStorage.getItem("port")}/drive/createfolder`;

    // Configuring the requisition
    xhr.timeout = 5000;
    xhr.open('POST', address, true);
    xhr.setRequestHeader('token', localStorage.getItem("token"));
    xhr.setRequestHeader('username', localStorage.getItem("username"));
    xhr.setRequestHeader('Content-Type', 'application/json');

    // Definition of the result
    xhr.onload = function () {
        // Checking success state
        if (xhr.status == 200) {
            // Resetting variables
            files = [];
            folders = [];
            document.getElementById("folders-list").innerHTML = "";
            document.getElementById("files-list").innerHTML = "";

            requestFolders();

            input.value = "";

            // Closing dialog manually
            document.getElementById("folder-create-dialog").close();
        }
        else alert(`Cannot proceed the process, reason: ${xhr.statusText}, code: ${xhr.status}`);
    };
    // Error treatment
    xhr.onerror = function () { alert(xhr.statusText); }

    // Sending request
    xhr.send(JSON.stringify({ directory: `${directory}/${input.value}` }));

    event.preventDefault();
});

// Request the home folders
requestFolders();