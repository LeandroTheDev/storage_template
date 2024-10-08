# Wiki

Headers are not necessary for logins.

All request you do to the server that needs any authentication needs this header:
```
'token': '123...',
'username': 'user',
'handshake': '421...'
```
The wrong token or username will return the 401 error

The wrong handhsake will return a funny message with 401, because the only reason for the handshake to be wrong is if you are trying to do something "illegal"

All contents in the headers needs to be encrypted and needs to be decrypted by the server, if a content is not encrypted in the header it will just return a internal server error.

### Pointers
- /drive/login (post) - log into the drive returns the token, example: { username: "flinstons", password: "123" }
- /drive/requestfile (get) - request the file to enable downloading, example: address/requestfile?directory=/flinstons.mp4
- /drive/getfile (get) - download the file, example: address/getfile?directory=/flinstons.mp4
- /drive/getfolders (get) - returns "folder": [], "files": [], example: address/getfolders?directory=/myfolder
- /drive/requestImage (get) - request the image to enable in your ip address (returns a success code, use getImage after), example: address/requestImage?directory=/image/flinstons.png
- /drive/getImage (get) - returns the image array bytes via stream, if avaiable to your ip address, address/getImage?directory=/image/flinstons.png
- /drive/requestVideo (get) - request the video to enable in your ip address (returns a success code, use getVideo after), example: address/requestVideo?directory=/movies/dereguejhonsons.mp4
- /drive/getVideo (get) - stream the requested video, if avaiable to your ip address, example: address/getVideo?directory=/movies/
- /drive/createfolder (post) - create a folder in selected location, example: { directory: "/myfolder" }
- /drive/uploadfile (post) - upload a file in selected folder, example: formData Body: { saveDirectory: "/movies/jhonsons.mp4 }, you need to send the files as the form data default
- /drive/delete (delete) - delete a folder or file selected, example: address/delete?item=/movies/jhonsons.mp4 OR address/delete?item=/movies

Success pointers will reset the DDOS protection, this is a ddos failure? yes!