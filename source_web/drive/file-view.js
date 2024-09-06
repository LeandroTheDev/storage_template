import validateSession from "../libs/validation.js";
if (!validateSession()) window.location.href = "../login.html";

const fileDirectory = localStorage.getItem("file-view-directory");
const fileName = localStorage.getItem("file-view-name");

const imageView = document.getElementById("image-view");
const videoView = document.getElementById("video-view");

imageView.classList.add("invisible");
videoView.classList.add("invisible");

function requestImage() {
    // Creating the xml request
    const xhr = new XMLHttpRequest();
    const address = `http://${localStorage.getItem("address")}:${localStorage.getItem("port")}/drive/requestImage?directory=${fileDirectory}/${fileName}`;

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
            imageView.classList.remove("invisible");
            imageView.setAttribute("src",
                `http://${localStorage.getItem("address")}:${localStorage.getItem("port")}/drive/getImage?directory=${fileDirectory}/${fileName}`);
        }
        else
            alert(`Cannot proceed the process, reason: ${xhr.statusText}, code: ${xhr.status}`);

    };
    // Error treatment
    xhr.onerror = function () { alert(xhr.statusText); }

    // Sending request
    xhr.send(null);
}

function requestVideo() {
    // Creating the xml request
    const xhr = new XMLHttpRequest();
    const address = `http://${localStorage.getItem("address")}:${localStorage.getItem("port")}/drive/requestVideo?directory=${fileDirectory}/${fileName}`;

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
            videoView.classList.remove("invisible");
            videoView.setAttribute("src",
                `http://${localStorage.getItem("address")}:${localStorage.getItem("port")}/drive/getVideo?directory=${fileDirectory}/${fileName}`);
        }
        else
            alert(`Cannot proceed the process, reason: ${xhr.statusText}, code: ${xhr.status}`);

    };
    // Error treatment
    xhr.onerror = function () { alert(xhr.statusText); }

    // Sending request
    xhr.send(null);
}

// Getting the mimeType
const lastDotIndex = fileName.lastIndexOf('.');
if (lastDotIndex !== -1) {
    switch (fileName.substring(lastDotIndex + 1)) {
        case "mp4": requestVideo();
        case "mkv": requestVideo();
        case "png": requestImage();
        case "jpg": requestImage();
        case "jpeg": requestImage();
        case "gif": requestImage();
    }
}