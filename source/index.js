console.log("Initializing the Homepage\nThis website is made by Lean's\nFTM License");

// Configs
import validateSession from "./libs/validation.js";
validateSession();

// Check if the user has a valid token
if (localStorage.getItem("token") == undefined) {
    window.location.href = 'login.html';
} else
    window.location.href = 'drive/index.html';
