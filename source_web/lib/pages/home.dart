import 'package:drive/main.dart';
import 'package:drive/pages/configs.dart';
import 'package:drive/pages/itemviewer.dart';
import 'package:drive/pages/provider.dart';
import 'package:drive/pages/storage.dart';
import 'package:flutter/material.dart';

import 'package:drive/components/dialogs.dart';
import 'package:drive/components/web_server.dart';
import 'package:provider/provider.dart';

class DriveHome extends StatefulWidget {
  const DriveHome({super.key});

  @override
  State<DriveHome> createState() => _DriveHomeState();
}

class _DriveHomeState extends State<DriveHome> {
  bool loaded = false;

  @override
  Widget build(BuildContext context) {
    final driveProvider = Provider.of<DriveProvider>(context, listen: true);
    final screenSize = MediaQuery.of(context).size;

    driveProvider.changeItemViewerQuantity(
      (DriveConfigs.getScreenSize(
                widgets: ["bar", "bar", "bar", "next"],
                type: "height",
                screenSize: screenSize,
              ) -
              431) ~/
          (DriveConfigs.getWidgetSize(widget: "itemicon", type: "height", screenSize: screenSize) + 18),
    );

    // Page Loader
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //Check if credentials is needed
      if (!loaded && driveProvider.token == "") {
        loaded = true;
        Storage.getData("username").then(
          (username) => Storage.getData("handshake").then(
            (handshake) => Storage.getData("token").then(
              (token) => Storage.getData("token_timestamp").then((tokenTimestamp) {
                tokenTimestamp ??= 0;
                Duration difference = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(tokenTimestamp as int));
                // check for 1 hour token expiration
                if (difference.inHours < 1) {
                  // Token not expired updating provider...
                  DriveUtils.log("Token is not expired, refreshing directory...");
                  driveProvider.changeToken(token);
                  driveProvider.changeUsername(username);
                  driveProvider.changeHandshake(handshake);
                  driveProvider.refreshDirectory(context);
                  return;
                }
                //Ask for credentials
                Dialogs.driveCredentials(context).then(
                  (response) {
                    if (WebServer.errorTreatment(context, "drive", response, isFatal: true)) {
                      DriveUtils.log("No errors in credentials, updating token and refreshing directory");
                      driveProvider.changeToken(response.data["message"]);
                      Storage.saveData("token", response.data["message"]);
                      Storage.saveData("token_timestamp", DateTime.timestamp().millisecondsSinceEpoch);
                      driveProvider.refreshDirectory(context);
                    }
                  },
                );
              }),
            ),
          ),
        );
      } else if (!loaded) {
        loaded = true;
        driveProvider.refreshDirectory(context);
      }
    });

    Icon getUploadIcon() {
      String situation = "none";
      driveProvider.uploadStatus.forEach((key, value) {
        if (value < 100 && value != -1)
          situation = "downloading";
        else if (value == -1) {
          situation = "error";
          return;
        }
      });
      switch (situation) {
        case "none":
          return const Icon(Icons.cloud_upload);
        case "downloading":
          return const Icon(Icons.file_upload);
        case "error":
          return const Icon(Icons.file_upload_off);
        default:
          return const Icon(Icons.error);
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // If theres is no more directory return to home screen
        if (driveProvider.directory == "") {
          Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
          driveProvider.resetItemViewPositions();
        }
        // In others case go to previous directory
        else {
          driveProvider.previousDirectory(context);
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(DriveConfigs.getWidgetSize(widget: "bar", type: "height", screenSize: screenSize)),
          child: AppBar(
            title: const Text("Drive"),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            titleTextStyle: Theme.of(context).textTheme.titleLarge,
            iconTheme: Theme.of(context).iconTheme,
            leading: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => loaded = false),
            ),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: getUploadIcon(),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                  tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                ),
              ),
            ],
          ),
        ),
        endDrawer: const UploadDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            // Title Bar
            SizedBox(
              height: DriveConfigs.getWidgetSize(widget: "bar", type: "height", screenSize: screenSize),
              child: Row(
                children: [
                  // Back button
                  SizedBox(
                    height: 46,
                    width: 46,
                    child: driveProvider.directory == ""
                        ? const SizedBox(height: 10, width: 25)
                        : IconButton(
                            onPressed: () => {
                              driveProvider.previousDirectory(context),
                            },
                            icon: const Icon(Icons.arrow_back_ios),
                          ),
                  ),
                  const SizedBox(width: 5),
                  // Actual Directory
                  SizedBox(
                    height: 24,
                    child: Text(
                      driveProvider.directory == "" ? "Home" : driveProvider.directory,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            // Spacer
            const SizedBox(height: 15),
            // Files and folders
            SizedBox(
              height: DriveConfigs.getScreenSize(widgets: ["bar", "bar", "bar", "next"], type: "height", screenSize: screenSize) - 431,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    //Folders
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: driveProvider.showFolders().length,
                      itemBuilder: (context, index) => Container(
                        padding: const EdgeInsets.all(8),
                        width: screenSize.width - 16,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).secondaryHeaderColor,
                              width: 2.0,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icon and Name
                            TextButton(
                              onPressed: () => driveProvider.nextDirectory(context, index),
                              child: Row(children: [
                                //Icon
                                SizedBox(
                                  width: DriveConfigs.getWidgetSize(widget: "itemicon", type: "width", screenSize: screenSize),
                                  height: DriveConfigs.getWidgetSize(widget: "itemicon", type: "height", screenSize: screenSize),
                                  child: FittedBox(
                                      child: Icon(
                                    Icons.folder,
                                    color: Theme.of(context).secondaryHeaderColor,
                                  )),
                                ),
                                //Spacer
                                const SizedBox(width: 15),
                                //Name
                                SizedBox(
                                  width: DriveConfigs.getScreenSize(widgets: ["itemicon"], type: "width", screenSize: screenSize) - 236,
                                  height: DriveConfigs.getWidgetSize(widget: "itemtext", type: "height", screenSize: screenSize),
                                  child: FittedBox(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      driveProvider.showFolders()[index],
                                      textAlign: TextAlign.start,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                            const SizedBox(width: 15),
                            // Trash icon
                            SizedBox(
                              width: DriveConfigs.getWidgetSize(widget: "itemicon", type: "width", screenSize: screenSize),
                              height: DriveConfigs.getWidgetSize(widget: "itemicon", type: "height", screenSize: screenSize),
                              child: IconButton(
                                onPressed: () => driveProvider.delete(context, driveProvider.showFolders()[index]),
                                icon: const FittedBox(child: Icon(Icons.delete, color: Colors.redAccent)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Files
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: driveProvider.showFiles().length,
                      itemBuilder: (context, index) => Container(
                        padding: const EdgeInsets.all(8),
                        width: screenSize.width - 16,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).secondaryHeaderColor,
                              width: 2.0,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icon and Name
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DriveItemViewer(
                                    type: DriveUtils.checkIfIsImage(driveProvider.showFiles()[index])
                                        ? "image"
                                        : DriveUtils.checkIfIsVideo(driveProvider.showFiles()[index])
                                            ? "video"
                                            : "file",
                                    fileName: driveProvider.showFiles()[index],
                                  ),
                                ),
                              ),
                              child: Row(children: [
                                //Icon
                                SizedBox(
                                  width: DriveConfigs.getWidgetSize(widget: "itemicon", type: "width", screenSize: screenSize),
                                  height: DriveConfigs.getWidgetSize(widget: "itemicon", type: "height", screenSize: screenSize),
                                  child: FittedBox(
                                    child: FutureBuilder(
                                      future: driveProvider.getImageThumbnail(driveProvider.showFiles()[index], screenSize),
                                      builder: (context, future) {
                                        if (future.hasData)
                                          return future.data!;
                                        else if (future.error == "Is a video")
                                          return const Icon(Icons.video_file_outlined);
                                        else if (future.error == "Not any image")
                                          return const Icon(Icons.file_present);
                                        else
                                          return const CircularProgressIndicator();
                                      },
                                    ),
                                  ),
                                ),
                                //Spacer
                                const SizedBox(width: 15),
                                //Name
                                SizedBox(
                                  width: DriveConfigs.getScreenSize(widgets: ["itemicon"], type: "width", screenSize: screenSize) - 236,
                                  height: DriveConfigs.getWidgetSize(widget: "itemtext", type: "height", screenSize: screenSize),
                                  child: FittedBox(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      driveProvider.showFiles()[index],
                                      textAlign: TextAlign.start,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                            const SizedBox(width: 15),
                            // Trash icon
                            SizedBox(
                              width: DriveConfigs.getWidgetSize(widget: "itemicon", type: "width", screenSize: screenSize),
                              height: DriveConfigs.getWidgetSize(widget: "itemicon", type: "height", screenSize: screenSize),
                              child: IconButton(
                                onPressed: () => driveProvider.delete(context, driveProvider.showFiles()[index]),
                                icon: const FittedBox(child: Icon(Icons.delete, color: Colors.redAccent)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Next and back buttons
            SizedBox(
              height: DriveConfigs.getWidgetSize(widget: "next", type: "height", screenSize: screenSize),
              child: FittedBox(
                child: Row(
                  mainAxisAlignment: screenSize.width > screenSize.height ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => driveProvider.changeItemViewerPosition(context, driveProvider.itemViewerPosition - 1),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 15),
                    IconButton(
                      onPressed: () => driveProvider.changeItemViewerPosition(context, driveProvider.itemViewerPosition + 1),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),
            ),
            // Upload and Create folder buttons
            SizedBox(
              height: DriveConfigs.getWidgetSize(widget: "bar", type: "height", screenSize: screenSize),
              width: DriveConfigs.isPortrait(screenSize) ? screenSize.width : screenSize.width / 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Espaçamento entre os botões
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => driveProvider.uploadFile(context),
                      child: const Text("Upload File"),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => driveProvider.createFolder(context),
                      child: const Text("Create Folder"),
                    ),
                  ),
                ],
              ),
            )
          ]),
        ),
      ),
    );
  }
}

class UploadDrawer extends StatefulWidget {
  const UploadDrawer({super.key});

  @override
  State<UploadDrawer> createState() => _UploadDrawerState();
}

class _UploadDrawerState extends State<UploadDrawer> {
  @override
  Widget build(BuildContext context) {
    final driveProvider = Provider.of<DriveProvider>(context, listen: true);
    final screenSize = MediaQuery.of(context).size;

    return Drawer(
      width: DriveConfigs.isPortrait(screenSize) ? screenSize.width * 0.5 : screenSize.width * 0.3,
      child: Container(
        color: Drive.colors["primary"],
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                "Uploads",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: driveProvider.uploadStatus.length,
                  itemBuilder: (context, index) => SizedBox(
                      height: DriveConfigs.getWidgetSize(widget: "bar", type: "height", screenSize: screenSize),
                      width: screenSize.width * 0.3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // File name
                          SizedBox(
                            width: screenSize.width * 0.2,
                            child: Text(
                              driveProvider.uploadStatus.keys.toList()[index],
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          // Upload Progress indicator
                          driveProvider.uploadStatus.values.toList()[index] >= 100
                              // Success Upload
                              ? Icon(Icons.check, color: Drive.colors["seedColor"])
                              : driveProvider.uploadStatus.values.toList()[index] == -1
                                  // Error upload
                                  ? const Icon(Icons.close, color: Colors.red)
                                  // Uploading
                                  : SizedBox(
                                      height: DriveConfigs.getWidgetSize(widget: "itemprogress", type: "height", screenSize: screenSize),
                                      width: DriveConfigs.getWidgetSize(widget: "itemprogress", type: "width", screenSize: screenSize),
                                      child: CircularProgressIndicator(
                                        value: driveProvider.uploadStatus.values.toList()[index] / 100,
                                        color: Drive.colors["seedColor"],
                                        strokeWidth: 5,
                                        backgroundColor: Drive.colors["background"],
                                      ),
                                    ),
                        ],
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
