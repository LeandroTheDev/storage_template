import 'dart:async';

import 'package:drive/components/cryptography.dart';
import 'package:drive/pages/configs.dart';
import 'package:drive/pages/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drive/components/dialogs.dart';
import 'package:drive/components/web_server.dart';
import 'package:drive/main.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

class DriveItemViewer extends StatefulWidget {
  final String type;
  final String fileName;
  const DriveItemViewer({
    super.key,
    required this.type,
    required this.fileName,
  });

  @override
  State<DriveItemViewer> createState() => _DriveItemViewerState();
}

class _DriveItemViewerState extends State<DriveItemViewer> {
  bool loaded = false; // Used to check if the page is instanciated
  bool disposed = false; // Simple dispose check
  bool fullyLoaded = false; // Used to check if everthing that needs to be initialized has been propertly initialized

  /// Video
  late final Player videoPlayer = Player();
  late final VideoController videoController = VideoController(videoPlayer);
  double playerAspectRatio = 16 / 9;
  String playerPositionText = "00:00";
  double playerPositionSlider = 0;
  bool playerSliderInUse = false;
  Duration? playerSliderToPosition;
  double playerVolume = 0;
  bool showPlayerVolume = false;
  bool isFullScreenVideo = false;
  bool fullScreenHideBars = false;
  int timeUntilHideBars = 0;
  double playerPlayBackSpeed = 1.0;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    DriveProvider driveProvider = Provider.of<DriveProvider>(context, listen: false);

    void openVideo(String videoDirectory) async {
      // Listening to the server
      videoPlayer
          .open(Media("http://${WebServer.serverAddress}:${driveProvider.apiPorts}/drive/getVideo?directory=$videoDirectory", httpHeaders: {
        "username": driveProvider.username,
        "auth": await Cryptography.encryptText(driveProvider.getAuthWithTimetamp()),
      }))
          .then((_) {
        Timer.periodic(Durations.long1, (timerInstance) {
          if (videoPlayer.state.width == null || videoPlayer.state.height == null) {
            return;
          }

          playerAspectRatio = videoPlayer.state.width! / videoPlayer.state.height!;

          timerInstance.cancel();
        });

        if (disposed) return;

        setState(() => DriveUtils.log("Video Player initialized"));

        if (!fullyLoaded) {
          fullyLoaded = true;
          // Yes, you need to reopen the video to prevent black screens
          Future.delayed(Durations.short4, () => openVideo(videoDirectory));
        } else {
          // Listener for the slider and text minutes
          videoPlayer.stream.position.listen((duration) {
            if (disposed) {
              videoPlayer.dispose();
              return;
            }

            if (!playerSliderInUse && videoPlayer.state.duration.inMilliseconds > 0) {
              playerPositionSlider = (duration.inMilliseconds / videoPlayer.state.duration.inMilliseconds) * 100;
              if (playerPositionSlider < 0) playerPositionSlider = 0;
            }
            final minutes = duration.inMinutes.remainder(60);
            final seconds = duration.inSeconds.remainder(60);

            setState(() => playerPositionText = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}");
          });

          // Restart video on completion
          videoPlayer.stream.completed.listen((completed) {
            if (completed) {
              videoPlayer.seek(const Duration(milliseconds: 0));
            }
          });
        }
      }).catchError((error) {
        DriveUtils.log("Video failed: $error");
        if (isDebug)
          Dialogs.alert(context, title: "No Connection", message: error.toString());
        else
          Dialogs.alert(context, title: "No Connection", message: "Cannot play the video at the moment...");
      });
    }

    // First load
    if (!loaded) {
      DriveUtils.log("Initializing Viewer type: ${widget.type}, from item: ${widget.fileName}");
      loaded = true;

      // Video initialization
      if (widget.type == "video") {
        DriveUtils.log("Requesting video stream");
        final String videoDirectory = "${driveProvider.directory}/${widget.fileName}";
        // Request the video streaming for the server
        WebServer.sendMessage(
          context,
          address: "/drive/requestVideo",
          api: "drive",
          body: {
            "directory": videoDirectory,
          },
          requestType: "get",
        ).then((response) async {
          // Error Treatment
          if (WebServer.errorTreatment(context, "drive", response)) {
            DriveUtils.log("Request success, initializing Video Player, in: ${"http://${WebServer.serverAddress}:${driveProvider.apiPorts}/drive/getVideo?directory=$videoDirectory"}");

            // Make the video in loop
            videoPlayer.setPlaylistMode(PlaylistMode.single);
            videoPlayer.setVolume(playerVolume);

            setState(() => DriveUtils.log("Video Player is starting..."));

            openVideo(videoDirectory);
          }
        });
      }
    }

    /// Help functions

    void changeToFullScreenVideo() {
      // Landscape orientations
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      setState(() {
        isFullScreenVideo = true;
        fullScreenHideBars = true;
      });
    }

    void exitToFullScreenVideo() {
      // Reset orientations
      SystemChrome.setPreferredOrientations([]);
      setState(() => isFullScreenVideo = false);
    }

    Future<Map<String, String>> getHeaders() async {
      return {
        "username": driveProvider.username,
        "auth": await Cryptography.encryptText(driveProvider.getAuthWithTimetamp()),
      };
    }

    /// Widgets
    Scaffold getVideoScaffold() => Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(
              DriveConfigs.getWidgetSize(widget: "bar", type: "height", screenSize: screenSize),
            ),
            child: AppBar(
              title: const Text("Drive"),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              titleTextStyle: Theme.of(context).textTheme.titleLarge,
              iconTheme: Theme.of(context).iconTheme,
              actions: [
                // Fullscreen button
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.fullscreen),
                    onPressed: () => changeToFullScreenVideo(),
                  ),
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              // Video Player
              Column(
                children: [
                  // Video Player
                  !fullyLoaded
                      ? const Center(child: SizedBox(height: 50, width: 50, child: CircularProgressIndicator()))
                      : Expanded(
                          child: AspectRatio(
                            aspectRatio: playerAspectRatio,
                            child: Video(controller: videoController),
                          ),
                        ),
                  // Buttons
                  SizedBox(
                    height: DriveConfigs.getWidgetSize(widget: "bar", type: "height", screenSize: screenSize),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // Video Position
                          Text(
                            playerPositionText,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          // Video Position change
                          Expanded(
                            child: Slider(
                              value: playerPositionSlider,
                              min: 0,
                              max: 100,
                              onChanged: (newValue) {
                                if (!fullyLoaded || disposed) return;

                                showPlayerVolume = false;
                                if (playerSliderInUse) return;
                                videoPlayer.pause();
                                playerSliderInUse = true;
                                playerSliderToPosition = Duration(milliseconds: (videoPlayer.state.duration.inMilliseconds * (newValue / 100)).toInt());
                                videoPlayer.seek(playerSliderToPosition!);
                                setState(() => playerPositionSlider = newValue);
                              },
                              onChangeEnd: (_) {
                                if (!fullyLoaded || disposed) return;

                                playerSliderInUse = false;
                                playerSliderToPosition = null;
                                videoPlayer.play();
                              },
                            ),
                          ),
                          // Backward playback
                          IconButton(
                            onPressed: () {
                              if (playerPlayBackSpeed <= 0.25) return;
                              playerPlayBackSpeed -= 0.25;
                              videoPlayer.setRate(playerPlayBackSpeed);
                            },
                            icon: const Icon(Icons.arrow_back),
                          ),
                          // Forward plaback
                          IconButton(
                            onPressed: () {
                              if (playerPlayBackSpeed >= 10.0) return;
                              playerPlayBackSpeed += 0.25;
                              videoPlayer.setRate(playerPlayBackSpeed);
                            },
                            icon: const Icon(Icons.arrow_forward),
                          ),
                          // Sound button
                          IconButton(
                            onPressed: () => setState(() => showPlayerVolume = true),
                            icon: Icon(
                              playerVolume == 0
                                  ? Icons.volume_off
                                  : playerVolume <= 0.3
                                      ? Icons.volume_mute
                                      : playerVolume <= 0.6
                                          ? Icons.volume_down
                                          : Icons.volume_up,
                            ),
                          ),
                          // Play/Pause button
                          IconButton(
                            onPressed: () => setState(() {
                              showPlayerVolume = false;
                              videoPlayer.playOrPause();
                            }),
                            icon: Icon(
                              videoPlayer.state.playing ? Icons.pause : Icons.play_arrow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Gestures
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (showPlayerVolume) {
                          showPlayerVolume = false;
                          return;
                        }
                        showPlayerVolume = false;

                        if (!fullyLoaded) return;
                        videoPlayer.playOrPause();
                      });
                    },
                    child: Container(
                      color: Colors.transparent,
                      width: screenSize.width,
                      height: DriveConfigs.getScreenSize(widgets: ["bar", "bar"], type: "height", screenSize: screenSize) - 200,
                    ),
                  ),
                ],
              ),
              // Volume Changer
              Column(
                children: [
                  // Height Spacer
                  SizedBox(
                    height: DriveConfigs.getScreenSize(widgets: ["bar", "bar"], type: "height", screenSize: screenSize) - 300,
                  ),
                  // Volume changer row
                  SizedBox(
                    height: DriveConfigs.getWidgetSize(widget: "videosound", type: "height", screenSize: screenSize),
                    child: Row(
                      children: [
                        // Spacer
                        const Spacer(),
                        // Volume Changer
                        showPlayerVolume
                            ? Padding(
                                padding: const EdgeInsets.only(right: 4, bottom: 30),
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: Slider(
                                    value: playerVolume,
                                    min: 0.0,
                                    max: 1.0,
                                    onChanged: (newValue) {
                                      setState(() {
                                        playerVolume = newValue;
                                        videoPlayer.setVolume(playerVolume);
                                      });
                                    },
                                    onChangeEnd: (_) => showPlayerVolume = false,
                                  ),
                                ),
                              )
                            : const SizedBox(),
                        // Spacer button
                        const IconButton(
                          onPressed: null,
                          icon: Icon(
                            Icons.volume_up, // Você pode escolher qualquer ícone
                            color: Colors.transparent, // Torna o ícone invisível
                            size: 24.0, // Define o tamanho do ícone conforme necessário
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

    Widget getImageScaffold() => FutureBuilder<Map<String, String>>(
          future: getHeaders(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final headers = snapshot.data!;
            final screenSize = MediaQuery.of(context).size;

            return Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(
                  DriveConfigs.getWidgetSize(widget: "bar", type: "height", screenSize: screenSize),
                ),
                child: AppBar(
                  title: const Text("Drive"),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  titleTextStyle: Theme.of(context).textTheme.titleLarge,
                  iconTheme: Theme.of(context).iconTheme,
                ),
              ),
              body: Center(
                child: PhotoView(
                  imageProvider: NetworkImage(
                    "http://${WebServer.serverAddress}:${driveProvider.apiPorts}/drive/getImage?directory=${driveProvider.directory}/${widget.fileName}",
                    headers: headers,
                  ),
                  backgroundDecoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ),
            );
          },
        );

    Scaffold getFileScaffold() => Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(DriveConfigs.getWidgetSize(widget: "bar", type: "height", screenSize: screenSize)),
            child: AppBar(
              title: const Text("Drive"),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              titleTextStyle: Theme.of(context).textTheme.titleLarge,
              iconTheme: Theme.of(context).iconTheme,
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.fileName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Icon(Icons.file_present),
              ],
            ),
          ),
        );

    Scaffold getVideoFullScreenScaffold() => Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.black,
          appBar: PreferredSize(
            preferredSize: fullScreenHideBars ? const Size.fromHeight(0) : Size.fromHeight(DriveConfigs.getWidgetSize(widget: "bar", type: "height", screenSize: screenSize)),
            child: AppBar(
              title: const Text("Drive"),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              titleTextStyle: Theme.of(context).textTheme.titleLarge,
              iconTheme: Theme.of(context).iconTheme,
              actions: [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.fullscreen_exit),
                    onPressed: () => exitToFullScreenVideo(),
                  ),
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              // Video Player
              Column(
                children: [
                  // Video Player
                  SizedBox(
                    height: screenSize.height,
                    width: screenSize.width,
                    child: videoPlayer.state.duration <= Duration.zero
                        ? const Center(child: SizedBox(height: 50, width: 50, child: CircularProgressIndicator()))
                        : AspectRatio(
                            aspectRatio: playerAspectRatio,
                            child: Video(controller: videoController),
                          ),
                  ),
                ],
              ),
              // Gestures
              Column(
                children: [
                  // Detect video player click
                  GestureDetector(
                    onTap: () {
                      showPlayerVolume = false;
                      if (fullScreenHideBars) {
                        setState(() {
                          fullScreenHideBars = false;
                          timeUntilHideBars = 3;
                        });
                        Timer.periodic(Durations.extralong4, (timer) {
                          if (disposed) return;

                          timeUntilHideBars -= 1;
                          if (timeUntilHideBars <= 0) {
                            setState(() {
                              fullScreenHideBars = true;
                              showPlayerVolume = false;
                            });
                            timer.cancel();
                          }
                        });
                      } else
                        setState(() {
                          timeUntilHideBars = 0;
                          fullScreenHideBars = true;
                        });
                    },
                    child: Container(
                      color: Colors.transparent,
                      width: screenSize.width,
                      height: screenSize.height,
                    ),
                  ),
                ],
              ),
              // Buttons
              Column(
                children: [
                  // Video Player Spacer
                  SizedBox(height: DriveConfigs.getScreenSize(widgets: ["bar", "bar", "bar"], type: "height", screenSize: screenSize) - 200),
                  // Buttons
                  fullScreenHideBars
                      ? const SizedBox()
                      : SizedBox(
                          height: DriveConfigs.getWidgetSize(widget: "bar", type: "height", screenSize: screenSize),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // Video Position
                                Text(
                                  playerPositionText,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                // Video Position change
                                Expanded(
                                  child: Slider(
                                    value: playerPositionSlider,
                                    min: 0,
                                    max: 100,
                                    onChanged: (newValue) {
                                      showPlayerVolume = false;
                                      if (playerSliderInUse) return;
                                      videoPlayer.pause();
                                      playerSliderInUse = true;
                                      playerSliderToPosition = Duration(milliseconds: (videoPlayer.state.duration.inMilliseconds * (newValue / 100)).toInt());
                                      videoPlayer.seek(playerSliderToPosition!);
                                      setState(() => playerPositionSlider = newValue);
                                    },
                                    onChangeEnd: (_) {
                                      playerSliderInUse = false;
                                      playerSliderToPosition = null;
                                      videoPlayer.play();
                                    },
                                  ),
                                ),
                                // Sound button
                                IconButton(
                                  onPressed: () => setState(() {
                                    showPlayerVolume = true;
                                    timeUntilHideBars = 3;
                                  }),
                                  icon: Icon(
                                    playerVolume == 0
                                        ? Icons.volume_off
                                        : playerVolume <= 0.3
                                            ? Icons.volume_mute
                                            : playerVolume <= 0.6
                                                ? Icons.volume_down
                                                : Icons.volume_up,
                                  ),
                                ),
                                // Play/Pause button
                                IconButton(
                                  onPressed: () => setState(() {
                                    showPlayerVolume = false;
                                    videoPlayer.playOrPause();
                                  }),
                                  icon: Icon(
                                    videoPlayer.state.playing ? Icons.pause : Icons.play_arrow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
              // Volume Changer
              Column(
                children: [
                  // Video player spacer
                  SizedBox(
                    height: DriveConfigs.getScreenSize(widgets: ["bar", "bar", "bar"], type: "height", screenSize: screenSize) - 300,
                  ),
                  // Volume changer row
                  SizedBox(
                    height: DriveConfigs.getWidgetSize(widget: "videosound", type: "height", screenSize: screenSize),
                    child: Row(
                      children: [
                        // Spacer
                        const Spacer(),
                        // Volume Changer
                        showPlayerVolume
                            ? Padding(
                                padding: const EdgeInsets.only(right: 4, bottom: 30),
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: Slider(
                                    value: playerVolume,
                                    min: 0.0,
                                    max: 1.0,
                                    onChanged: (newValue) {
                                      timeUntilHideBars = 3;
                                      setState(() {
                                        playerVolume = newValue;
                                        videoPlayer.setVolume(playerVolume);
                                      });
                                    },
                                    onChangeEnd: (_) => showPlayerVolume = false,
                                  ),
                                ),
                              )
                            : const SizedBox(),
                        // Spacer button
                        const IconButton(
                          onPressed: null,
                          icon: Icon(
                            Icons.volume_up, // Você pode escolher qualquer ícone
                            color: Colors.transparent, // Torna o ícone invisível
                            size: 24.0, // Define o tamanho do ícone conforme necessário
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

    return widget.type == "video" && !isFullScreenVideo
        ? getVideoScaffold()
        : widget.type == "image"
            ? getImageScaffold()
            : isFullScreenVideo
                ? getVideoFullScreenScaffold()
                : getFileScaffold();
  }
}
