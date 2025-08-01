import 'package:drive/components/dialogs.dart';
import 'package:drive/components/web_server.dart';
import 'package:drive/components/drive.dart';
import 'package:drive/pages/home/main.dart' as Home;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
