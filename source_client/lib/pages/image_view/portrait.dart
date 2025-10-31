import 'package:drive/components/auth.dart';
import 'package:drive/components/cryptography.dart';
import 'package:drive/components/drive.dart';
import 'package:drive/components/web_server.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

class Portrait extends StatelessWidget {
  final String fileName;
  const Portrait({super.key, required this.fileName});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final driveProvider = Provider.of<DriveProvider>(context);

    Future<Map<String, String>> getHeaders() async {
      await WebServer.sendMessage(context, api: 'drive', address: "/drive/requestImage", body: {"directory": "${driveProvider.directory}/$fileName"}, requestType: "get");

      return {
        "username": authProvider.username,
        "auth": await Cryptography.encryptText(authProvider.getAuthWithTimetamp()),
      };
    }

    return FutureBuilder<Map<String, String>>(
      future: getHeaders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Failed to get image'));
        }

        final headers = snapshot.data!;

        return Center(
          child: PhotoView(
            imageProvider: NetworkImage(
              "http://${WebServer.serverAddress}/drive/getImage?directory=${driveProvider.directory}/$fileName",
              headers: headers,
            ),
            backgroundDecoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
        );
      },
    );
  }
}
