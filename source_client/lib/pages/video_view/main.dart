import 'dart:async';

import 'package:drive/components/auth.dart';
import 'package:drive/components/cryptography.dart';
import 'package:drive/components/dialogs.dart';
import 'package:drive/components/drive.dart';
import 'package:drive/components/screen.dart';
import 'package:drive/components/web_server.dart';
import 'package:drive/main.dart';
import 'package:drive/pages/video_view/toolbar.dart';
// import 'package:drive/pages/video_view/landscape.dart';
import 'package:drive/pages/video_view/portrait.dart';
import 'package:drive/pages/video_view/video.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

class Main extends StatelessWidget {
  final String fileName;
  const Main({super.key, required this.fileName});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = Screen.isPortrait(size);

    final driveProvider = Provider.of<DriveProvider>(context);
    final videoProvider = Provider.of<VideoProvider>(context);

    driveProvider.changeViewingItem(fileName);

    if (videoProvider.player == null) initVideoPlayer(context);

    return Scaffold(
      appBar: const ToolBar(),
      body: videoProvider.player == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : isPortrait
              ? const Portrait()
              : const Portrait(),
    );
  }

  initVideoPlayer(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context);
    final driveProvider = Provider.of<DriveProvider>(context);
    final videoProvider = Provider.of<VideoProvider>(context);

    final String videoDirectory = "${driveProvider.directory}/$fileName";

    DriveUtils.log("Requesting video stream: $videoDirectory");

    // Request the video streaming for the server
    final response = await WebServer.sendMessage(
      context,
      address: "/drive/requestVideo",
      api: "drive",
      body: {
        "directory": videoDirectory,
      },
      requestType: "get",
    );

    // Error Treatment
    if (!WebServer.errorTreatment(context, "drive", response)) {
      return;
    }

    DriveUtils.log("Request success, initializing Video Player, in: ${"http://${WebServer.serverAddress}/drive/getVideo?directory=$videoDirectory"}");

    videoProvider.changePlayer(Player());
    videoProvider.player!.setPlaylistMode(PlaylistMode.single);
    videoProvider.player!.setVolume(videoProvider.volume);
    videoProvider.changeController(VideoController(videoProvider.player!));

    // Listening to the server
    try {
      await videoProvider.player!.open(
        Media("http://${WebServer.serverAddress}/drive/getVideo?directory=$videoDirectory", httpHeaders: {
          "username": authProvider.username,
          "auth": await Cryptography.encryptText(authProvider.getAuthWithTimetamp()),
        }),
      );
    } catch (error) {
      DriveUtils.log("Video failed: $error");
      if (isDebug)
        Dialogs.alert(context, title: "No Connection", message: error.toString());
      else
        Dialogs.alert(context, title: "No Connection", message: "Cannot play the video at the moment...");
      return;
    }

    Timer.periodic(Durations.long1, (timerInstance) {
      if (videoProvider.player!.state.width == null || videoProvider.player!.state.height == null) {
        return;
      }

      videoProvider.changeAspectRatio(videoProvider.player!.state.width! / videoProvider.player!.state.height!);

      timerInstance.cancel();
    });

    DriveUtils.log("Video Player initialized");

    // Listener for the slider and text minutes
    videoProvider.player!.stream.position.listen((duration) {
      if (!videoProvider.sliderInUse && videoProvider.player!.state.duration.inMilliseconds > 0) {
        videoProvider.changePositionSlider((duration.inMilliseconds / videoProvider.player!.state.duration.inMilliseconds) * 100);
        if (videoProvider.positionSlider < 0) videoProvider.changePositionSlider(0);
      }
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);

      videoProvider.changePositionText("${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}");
    });

    // Restart video on completion
    videoProvider.player!.stream.completed.listen((completed) {
      if (completed) {
        videoProvider.player!.seek(const Duration(milliseconds: 0));
      }
    });
  }
}
