import 'package:drive/components/dialogs.dart';
import 'package:drive/components/drive.dart';
import 'package:drive/pages/video_view/video.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ToolBar extends StatelessWidget implements PreferredSizeWidget {
  const ToolBar({super.key});

  @override
  Widget build(BuildContext context) {
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
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () => {Dialogs.alert(context, title: "To do")},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  getLeadingButton(BuildContext context) {
    final driveProvider = Provider.of<DriveProvider>(context);
    final videoProvider = Provider.of<VideoProvider>(context);

    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        driveProvider.changeViewingItem("");
        videoProvider.decompose();

        Navigator.pop(context);
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
