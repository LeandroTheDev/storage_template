import 'package:drive/components/auth.dart';
import 'package:drive/components/dialogs.dart';
import 'package:drive/components/drive.dart';
import 'package:drive/components/screen.dart';
import 'package:drive/pages/home/toolbar.dart';
import 'package:drive/pages/home/landscape.dart';
import 'package:drive/pages/home/portrait.dart';
import 'package:drive/pages/upload_drawer/main.dart' as UploadDrawer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = Screen.isPortrait(size);

    final authProvider = Provider.of<AuthProvider>(context);
    final driveProvider = Provider.of<DriveProvider>(context);    

    if (authProvider.auth.isEmpty) {
      Dialogs.driveCredentials(context).then((response) {
        if (response == null) return;

        // Close loading
        Dialogs.closeLoading(context);
        // Close drive credentials
        Dialogs.closeDriveCredentials(context);

        // Reload it
        driveProvider.shouldRefreshDirectory = true;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) => this,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      });
      driveProvider.shouldRefreshDirectory = false;
    }

    return Scaffold(
      appBar: const ToolBar(),
      endDrawer: const UploadDrawer.Main(),
      body: isPortrait ? const Portrait() : const Landscape(),
    );
  }
}
