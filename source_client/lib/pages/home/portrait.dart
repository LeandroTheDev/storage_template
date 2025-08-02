import 'package:drive/components/drive.dart';
import 'package:drive/components/system.dart';
import 'package:drive/pages/home/main.dart' as Home;
import 'package:drive/pages/video_view/main.dart' as VideoView;
import 'package:drive/pages/image_view/main.dart' as ImageView;
import 'package:drive/pages/generic_view/main.dart' as GenericView;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Portrait extends StatelessWidget {
  const Portrait({super.key});

  @override
  Widget build(BuildContext context) {
    final driveProvider = Provider.of<DriveProvider>(context, listen: false);
    final screenSize = MediaQuery.of(context).size;

    double statusBarHeight = MediaQuery.of(context).padding.top;
    if(System.isAndroid()) statusBarHeight += 44;
    final availableHeight = screenSize.height - kToolbarHeight - statusBarHeight;

    return Column(
      children: [
        FutureBuilder(
          future: driveProvider.refreshDirectory(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return SizedBox(
                height: availableHeight - 50,
                child: const Center(child: CircularProgressIndicator()),
              );
            else if (snapshot.hasError) return Text('Failed to retrieve data: ${snapshot.error}');

            return Column(
              children: [
                // Folders and Files
                SizedBox(
                  height: availableHeight - 100,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        getFolders(context),
                        getFiles(context),
                      ],
                    ),
                  ),
                ),

                // Upload and Create Folder
                SizedBox(
                  height: 100,
                  width: screenSize.width,
                  child: Column(
                    children: [
                      // Next and back buttons
                      SizedBox(
                        height: 50,
                        child: FittedBox(
                          child: Row(
                            mainAxisAlignment: screenSize.width > screenSize.height ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () {
                                  driveProvider.changeItemViewerPosition(context, driveProvider.itemViewerPosition - 1);
                                  Navigator.pushReplacement(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation1, animation2) => const Home.Main(),
                                      transitionDuration: Duration.zero,
                                      reverseTransitionDuration: Duration.zero,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_back),
                              ),
                              const SizedBox(width: 15),
                              IconButton(
                                onPressed: () {
                                  driveProvider.changeItemViewerPosition(context, driveProvider.itemViewerPosition + 1);
                                  Navigator.pushReplacement(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation1, animation2) => const Home.Main(),
                                      transitionDuration: Duration.zero,
                                      reverseTransitionDuration: Duration.zero,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget getFiles(BuildContext context) {
    final driveProvider = Provider.of<DriveProvider>(context);
    final screenSize = MediaQuery.of(context).size;

    return ListView.builder(
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
                  builder: (context) {
                    if (DriveUtils.checkIfIsVideo(driveProvider.showFiles()[index])) return VideoView.Main(fileName: driveProvider.showFiles()[index]);
                    if (DriveUtils.checkIfIsImage(driveProvider.showFiles()[index]))
                      return ImageView.Main(fileName: driveProvider.showFiles()[index]);
                    else
                      return GenericView.Main(fileName: driveProvider.showFiles()[index]);
                  },
                ),
              ),
              child: SizedBox(
                width: screenSize.width - 100,
                child: Row(children: [
                  //Icon
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: FittedBox(
                      child: FutureBuilder(
                        future: driveProvider.getImageThumbnail(context, driveProvider.showFiles()[index]),
                        builder: (context, future) {
                          if (future.hasData) {
                            return future.data!;
                          } else if (future.error == "Is a video")
                            return const Icon(Icons.video_file_outlined);
                          else if (future.error == "Not any image")
                            return const Icon(Icons.file_present);
                          else
                            return const CircularProgressIndicator();
                        },
                      ),
                    ),
                  ),

                  //Name
                  Expanded(
                    child: Text(
                      driveProvider.showFiles()[index],
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ]),
              ),
            ),
            // Trash icon
            SizedBox(
              width: 50,
              height: 50,
              child: IconButton(
                onPressed: () => driveProvider.delete(context, driveProvider.showFolders()[index]),
                icon: const FittedBox(child: Icon(Icons.delete, color: Colors.redAccent)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getFolders(BuildContext context) {
    final driveProvider = Provider.of<DriveProvider>(context);
    final screenSize = MediaQuery.of(context).size;

    return ListView.builder(
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
              child: SizedBox(
                width: screenSize.width - 100,
                child: Row(children: [
                  //Icon
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: FittedBox(
                      child: Icon(
                        Icons.folder,
                        color: Theme.of(context).secondaryHeaderColor,
                      ),
                    ),
                  ),

                  //Name
                  Expanded(
                    child: Text(
                      driveProvider.showFolders()[index],
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ]),
              ),
            ),
            // Trash icon
            SizedBox(
              width: 50,
              height: 50,
              child: IconButton(
                onPressed: () => driveProvider.delete(context, driveProvider.showFolders()[index]),
                icon: const FittedBox(child: Icon(Icons.delete, color: Colors.redAccent)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
