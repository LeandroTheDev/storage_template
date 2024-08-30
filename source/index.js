console.log("Initializing the Homepage\nThis website is made by Lean's\nFTM License");

// Configs
localStorage.setItem("address", "192.168.15.151");
localStorage.setItem("port", "7979");

// Check if the user has a valid token
if (localStorage.getItem("token") == undefined) {
    window.location.href = 'login.html';
} else
    window.location.href = 'drive/index.html';
