import 'dart:async';

import 'package:drive/components/cryptography.dart';
import 'package:drive/pages/configs.dart';
import 'package:drive/pages/datas.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:drive/components/dialogs.dart';
import 'package:drive/components/web_server.dart';

class DriveProvider extends ChangeNotifier {
  int apiPorts = 7979;

  String _username = "anonymous";
  String get username => _username;
  void changeUsername(value) => _username = value;

  String _auth = "";
  String get auth => _auth;
  void changeAuth(value) => _auth = value;
  String getAuthWithTimetamp() => "$auth-${DateTime.now().millisecondsSinceEpoch}";

  List _folders = [];
  List get folders => _folders;
  void changeFolders(value) => _folders = value.map((e) => e.toString()).toList();

  List _files = [];
  List get files => _files;
  void changeFiles(value) => _files = value;

  String _directory = "";
  String get directory => _directory;
  void changeDirectory(value) => _directory = value;

  final List<String> _cacheImages = [];
  List<String> get cacheImages => _cacheImages;

  Future addFileToCache(String key, List<int> value) => DriveDatas.saveSingleImageOnCache(key, value);

  final List<String> _cacheVideos = [];
  List<String> get cacheVideos => _cacheVideos;

  Map<String, double> _uploadStatus = {};
  Map<String, double> get uploadStatus => _uploadStatus;
  void changeUploadStatus(value) => _uploadStatus = value;
  void updateKeyUploadStatus(String key, double value) => {_uploadStatus[key] = value, notifyListeners()};

  int _itemViewerPosition = 0;
  int get itemViewerPosition => _itemViewerPosition;
  void changeItemViewerPosition(BuildContext context, int value) {
    // 0 treatment
    if (value < 0) return;
    int previousPosition = _itemViewerPosition;
    _itemViewerPosition = value;
    // Reach max
    if (showFolders().isEmpty && showFiles().isEmpty) {
      _itemViewerPosition = previousPosition;
      return;
    } else if (showFiles().isNotEmpty) {
      // Clean internal strorage
      DriveDatas.clearData();
      // Download images
      downloadImagesCache(context);
    }

    notifyListeners();
  }

  void resetItemViewPositions() {
    _itemViewerPosition = 0;
    notifyListeners();
  }

  int _itemViewerQuantity = 0;
  int get itemViewerQuantity => _itemViewerQuantity;
  void changeItemViewerQuantity(int value) => _itemViewerQuantity = value;

  //
  //#region Directory Managment
  //
  /// Ask for the server the new contents from the actual directory
  Future refreshDirectory(BuildContext context, {bool ignoreImageDownload = false}) {
    DriveUtils.log("---Refreshing directory---");
    return WebServer.sendMessage(context, api: 'drive', address: "/drive/getfolders", body: {"directory": directory}, requestType: "get").then(
      (response) {
        DriveUtils.log("Finished with code: ${response.statusCode}");
        // Check errors
        if (WebServer.errorTreatment(context, "drive", response, isFatal: false)) {
          DriveUtils.log("No errors occurs, proceeding to the data, and resseting view positioning...");
          resetItemViewPositions();

          // Load folders and files
          final data = response.data["message"];

          DriveUtils.log("Folders quantity: ${data["folders"].length}");
          DriveUtils.log("Files quantity: ${data["files"].length}");

          changeFolders(data["folders"]);
          changeFiles(data["files"]);

          if (ignoreImageDownload)
            DriveUtils.log("Ignoring image download");
          else
            downloadImagesCache(context);

          notifyListeners();
        } else
          DriveUtils.log("Error while refreshing directory, will not update screen state...");
      },
    );
  }

  List showFolders() {
    int startNumber = _itemViewerQuantity * _itemViewerPosition;
    List foldersView = [];
    for (startNumber; startNumber < _folders.length; startNumber++) {
      if (foldersView.length >= _itemViewerQuantity) break;
      foldersView.add(_folders[startNumber]);
    }
    return foldersView;
  }

  List showFiles() {
    List foldersView = showFolders();
    int startNumber = _itemViewerQuantity * _itemViewerPosition;
    List filesView = [];
    for (startNumber; startNumber < _files.length; startNumber++) {
      if ((filesView.length + foldersView.length) >= _itemViewerQuantity) break;
      filesView.add(_files[startNumber]);
    }
    return filesView;
  }

  /// Change the actual directory and refresh the directories
  nextDirectory(BuildContext context, int folderIndex) {
    String? folderName = folders[folderIndex];
    // ignore: unnecessary_null_comparison
    if (folderName == null) {
      // Wtf flutter compiler? how this cannot be null?
      Navigator.pushNamedAndRemoveUntil(context, "home", (route) => false);
      Dialogs.alert(context, title: "Ops", message: "Something goes wrong when you try to change the directory, if the error persist please contact Administrator");
    }
    _directory += "/$folderName";
    cacheImages.clear();
    cacheVideos.clear();
    DriveDatas.clearData().then((value) => refreshDirectory(context));
  }

  /// Go to previous directory and refresh the directories
  previousDirectory(BuildContext context) {
    try {
      int barrierIndex = _directory.lastIndexOf('/');
      //Remove the last folder in directory variable
      _directory = _directory.substring(0, barrierIndex);
    } catch (error) {
      return;
    }
    cacheImages.clear();
    cacheVideos.clear();
    DriveDatas.clearData().then((value) => refreshDirectory(context));
  }

  /// Returns the final part of the directory
  getDirectoryName() {
    int slashIndex = _directory.lastIndexOf('/');
    if (slashIndex != -1) {
      return _directory.substring(slashIndex + 1);
    } else {
      return _directory;
    }
  }

  /// Creates a new folder on the actual directory
  createFolder(BuildContext context) {
    Dialogs.typeInput(context, title: "Create a folder").then(
      (folderName) => {
        WebServer.sendMessage(context, api: "drive", address: '/drive/createfolder', body: {"directory": "$_directory/$folderName"}).then(
          (response) => {
            //Check errors
            if (WebServer.errorTreatment(context, "drive", response)) refreshDirectory(context, ignoreImageDownload: true),
          },
        )
      },
    );
  }

  /// Delete a folder or file from the actual directory
  delete(BuildContext context, String itemName) {
    Dialogs.showQuestion(context, title: "Are you sure?", content: "Do you want to delete $itemName?").then(
      (value) => {
        if (value)
          WebServer.sendMessage(context, api: "drive", address: '/drive/delete', body: {"item": "$_directory/$itemName"}, requestType: "delete").then(
            (response) => {
              //Check errors
              if (WebServer.errorTreatment(context, "drive", response)) refreshDirectory(context, ignoreImageDownload: true),
            },
          ),
      },
    );
  }
  //
  //#endregion Directory Managment
  //

  //
  //#region Directory Data
  //
  /// Get the image thumbnail widget by the file name,
  /// if not exist yet will return a progress indicator widget
  Future<Image> getImageThumbnail(String fileName, Size screenSize) async {
    if (!DriveUtils.checkIfIsImage(fileName)) {
      if (DriveUtils.checkIfIsVideo(fileName))
        return Future.error("Is a video");
      else
        return Future.error("Not any image");
    }

    final imageDirectory = "$directory/$fileName";
    if (!cacheImages.contains(imageDirectory)) return Future.error("File doesn't contains any image");
    return Image.network(
      "http://${WebServer.serverAddress}:$apiPorts/drive/getImageThumbnail?directory=$imageDirectory",
      height: DriveConfigs.getWidgetSize(widget: "itemicon", type: "height", screenSize: screenSize),
      width: DriveConfigs.getWidgetSize(widget: "itemicon", type: "height", screenSize: screenSize),
      headers: {
        "username": username,
        "auth": await Cryptography.encryptText(getAuthWithTimetamp()),
      },
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
    );
  }

  /// Upload a file to the actual directory
  uploadFile(BuildContext context) {
    try {
      Dialogs.loading(context);
      FilePicker.platform.pickFiles(allowMultiple: true, withReadStream: true).then(
        (result) {
          if (result != null) {
            DriveUtils.log("Total files to be send: ${result.files.length}");
            Dialogs.closeLoading(context);

            int filesCompleted = 0;
            for (int i = 0; i < result.files.length; i++) {
              try {
                if (result.files[i].readStream == null) throw "File not found";

                // Update upload status for the file
                _uploadStatus[result.files[i].name] = 0;
                notifyListeners();

                // Send selected image to the server
                WebServer.sendFile(
                  context,
                  api: "drive",
                  address: '/drive/uploadfile',
                  fileStream: result.files[i].readStream!,
                  fileSize: result.files[i].size,
                  configs: {"fileName": result.files[i].name, "saveDirectory": directory},
                ).then(
                  (response) {
                    filesCompleted++;

                    // Update upload status for the file
                    if (response.statusCode != 200)
                      updateKeyUploadStatus(result.files[i].name, -1);
                    else
                      _uploadStatus[result.files[i].name] = 100;

                    DriveUtils.log("File send finished with code: ${response.statusCode}, remaining: $filesCompleted/${result.files.length}");

                    response.data["message"] = "Cannot send ${result.files[i].name}, reason: ${response.data["message"]}";
                    // Check for errors
                    if (WebServer.errorTreatment(context, "drive", response)) {
                      // If the total files finished, refresh the directory
                      if (filesCompleted == result.files.length) refreshDirectory(context);
                    }
                  },
                );
              } catch (error) {
                _uploadStatus[result.files[i].name] = -1;
                Dialogs.alert(context, title: "Error", message: "Cannot send the file: ${result.files[i].name} reason: $error");
              }
            }
          } else
            Navigator.pop(context);
        },
      );
    } catch (error) {
      Dialogs.alert(context, message: "Cannot upload files, reason: $error");
    }
  }

  /// Download images from showFiles function and save to cache image
  /// listeners is refreshed every download and save
  void downloadImagesCache(BuildContext context) {
    List filesView = showFiles();
    // Image Loader
    for (int i = 0; i < filesView.length; i++) {
      if (DriveUtils.checkIfIsImage(filesView[i])) {
        DriveUtils.log("Image in file $i detected, downloading thumbnail...");
        // Request image read
        WebServer.sendMessage(
          context,
          address: "/drive/requestImage",
          api: "drive",
          body: {
            "directory": "$directory/${filesView[i]}",
          },
          requestType: "get",
        ).then((response) {
          // Check errors
          if (WebServer.errorTreatment(context, "drive", response)) {
            // Add to cache images variable
            _cacheImages.add("$directory/${filesView[i]}");

            // Refresh page
            notifyListeners();

            DriveUtils.log("Image $i request and saved");
          }
        }).onError((error, stackTrace) {
          Dialogs.alert(context, title: "Image Error", message: "Cannot request the image, reason: $error");
        });
      }
    }
  }
  //
  //#endregion
  //
}

class DriveUtils {
  /// Simple check the last string characters for matching files
  static bool checkIfIsImage(String fileName) {
    if (fileName.endsWith(".png")) return true;
    if (fileName.endsWith(".jpg")) return true;
    if (fileName.endsWith(".jpeg")) return true;
    if (fileName.endsWith(".gif")) return true;
    return false;
  }

  /// Simple check the last string characters for matching files
  static bool checkIfIsVideo(String fileName) {
    if (fileName.endsWith(".mp4")) return true;
    if (fileName.endsWith(".mkv")) return true;
    if (fileName.endsWith(".avi")) return true;
    return false;
  }

  static log(String message) {
    // ignore: avoid_print
    print(message);
  }
}
