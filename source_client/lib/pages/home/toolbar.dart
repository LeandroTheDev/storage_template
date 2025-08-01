import 'package:drive/components/dialogs.dart';
import 'package:drive/components/web_server.dart';
import 'package:drive/components/drive.dart';
import 'package:drive/pages/home/main.dart' as Home;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ToolBar extends StatelessWidget implements PreferredSizeWidget {
  const ToolBar({super.key});

  @override
  Widget build(BuildContext context) {
    final driveProvider = Provider.of<DriveProvider>(context);

    return AppBar(
      title: const Text("Drive"),
      backgroundColor: Theme.of(context).colorScheme.secondary,
      titleTextStyle: Theme.of(context).textTheme.titleLarge,
      iconTheme: Theme.of(context).iconTheme,
      leading: getLeadingButton(context),
      actions: [
        Builder(
          builder: (context) => Row(
            children: [
              // Media Downloader
              IconButton(
                icon: const Icon(Icons.add_link),
                onPressed: () async {
                  final String? videoLink = await Dialogs.typeInput(context, title: "Type video link");
                  if (videoLink == null) return;
                  final String? videoName = await Dialogs.typeInput(context, title: "Video name");
                  if (videoName == null) return;

                  Dialogs.loading(context);
                  bool responseReceived = false;

                  WebServer.sendMessage(
                    context,
                    address: "/drive/downloadVideo",
                    api: "drive",
                    body: {"link": videoLink, "name": videoName, "directory": driveProvider.directory},
                    requestType: "post",
                  ).then((response) {
                    if (!responseReceived) {
                      Dialogs.closeLoading(context);
                      responseReceived = true;
                    }

                    if (WebServer.errorTreatment(context, "drive", response)) {
                      Dialogs.alert(context, title: "Download Success", message: "$videoName has been successfully downloaded");
                    }
                  });

                  await Future.delayed(const Duration(seconds: 3));
                  if (!responseReceived) {
                    Dialogs.closeLoading(context);
                    responseReceived = true;
                    Dialogs.alert(context, title: "Downloading", message: "Server is downloading your video now, soon will be available to you in the storage");
                  }
                },
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              ),
              // Upload Icon
              IconButton(
                icon: driveProvider.getUploadIcon(),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              ),
            ],
          ),
        ),
      ],
    );
  }

  getLeadingButton(BuildContext context) {
    final driveProvider = Provider.of<DriveProvider>(context);

    if (driveProvider.directory.isEmpty)
      return IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () {
          driveProvider.shouldRefreshDirectory = true;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => const Home.Main(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
      );
    else if (driveProvider.viewingItem.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          driveProvider.shouldRefreshDirectory = true;
          driveProvider.changeViewingItem("");

          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => const Home.Main(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
      );
    } else if (driveProvider.directory.isNotEmpty)
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          driveProvider.shouldRefreshDirectory = true;
          driveProvider.previousDirectory(context);

          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => const Home.Main(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
      );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
