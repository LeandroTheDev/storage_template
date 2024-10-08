import 'dart:async';

import 'package:drive/pages/configs.dart';
import 'package:drive/pages/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drive/components/dialogs.dart';
import 'package:drive/components/web_server.dart';
import 'package:drive/main.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

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
  bool loaded = false;
  bool disposed = false;

  // Video
  VideoPlayerController? videoPlayer;
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
    super.dispose();
    disposed = true;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    DriveProvider driveProvider = Provider.of<DriveProvider>(context, listen: false);

    //  First load
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
        ).then((response) {
          // Error Treatment
          if (WebServer.errorTreatment(context, "drive", response)) {
            DriveUtils.log("Request success, initializing Video Player");
            // Listening to the server
            videoPlayer = VideoPlayerController.networkUrl(
              Uri.parse("http://${WebServer.serverAddress}:${driveProvider.apiPorts}/drive/getVideo?directory=$videoDirectory"),
              httpHeaders: {
                "username": driveProvider.username,
                "token": driveProvider.token,
              },
            );
            // Initialize the video player
            videoPlayer!.initialize().then((_) {
              // Video always looping
              videoPlayer!.setLooping(true);
              // Update player volume
              videoPlayer!.setVolume(playerVolume);
              // Automatic start the video
              videoPlayer!.play();

              // Refresh video thumbnail
              setState(() => DriveUtils.log("Video Player initialized"));

              // Constantly refresh video position
              Future.doWhile(() {
                return videoPlayer!.position.then((position) async {
                  // Refresh every 200 ms
                  await Future.delayed(Durations.short1);
                  // Update position string
                  if (position != null) {
                    // Simple check if widget has been disposed
                    if (disposed) return false;
                    setState(() {
                      // Slider
                      if (!playerSliderInUse) playerPositionSlider = (position.inMilliseconds / videoPlayer!.value.duration.inMilliseconds) * 100;
                      // Text
                      playerPositionText = "${position.inMinutes.toString().padLeft(2, '0')}:${position.inSeconds.toString().padLeft(2, '0')}";
                    });
                  }
                  return true;
                });
              });
              // ignore: invalid_return_type_for_catch_error
            }).catchError((error) => Dialogs.alert(context, title: "No Connection", message: isDebug ? error.toString() : "Cannot receive the video from the server"));
          }
        });
      }
    }

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

    Scaffold getVideoScaffold() => Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(DriveConfigs.getWidgetSize(widget: "bar", type: "height", screenSize: screenSize)),
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
                  SizedBox(
                    height: DriveConfigs.getScreenSize(widgets: ["bar", "bar"], type: "height", screenSize: screenSize) - 200,
                    child: videoPlayer == null
                        ? const Center(child: SizedBox(height: 50, width: 50, child: CircularProgressIndicator()))
                        : videoPlayer!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: videoPlayer!.value.aspectRatio,
                                child: VideoPlayer(videoPlayer!),
                              )
                            : const Center(child: SizedBox(height: 50, width: 50, child: CircularProgressIndicator())),
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
                                showPlayerVolume = false;
                                if (videoPlayer == null || playerSliderInUse) return;
                                videoPlayer!.pause();
                                playerSliderInUse = true;
                                playerSliderToPosition = Duration(milliseconds: (videoPlayer!.value.duration.inMilliseconds * (newValue / 100)).toInt());
                                videoPlayer!.seekTo(playerSliderToPosition!);
                                setState(() => playerPositionSlider = newValue);
                              },
                              onChangeEnd: (_) {
                                if (videoPlayer == null) return;
                                final int lastSecond = videoPlayer!.value.position.inMilliseconds;
                                // We need to wait sometime to not break the video player
                                Timer.periodic(Durations.long1, (timer) {
                                  if (lastSecond == videoPlayer!.value.position.inMilliseconds) return;
                                  timer.cancel();
                                  playerSliderInUse = false;
                                });
                                playerSliderToPosition = null;
                                videoPlayer!.play();
                              },
                            ),
                          ),
                          // Backward playback
                          IconButton(
                            onPressed: () {
                              if (playerPlayBackSpeed <= 0.25) return;
                              playerPlayBackSpeed -= 0.25;
                              videoPlayer!.setPlaybackSpeed(playerPlayBackSpeed);
                            },
                            icon: const Icon(Icons.arrow_back),
                          ),
                          // Forward plaback
                          IconButton(
                            onPressed: () {
                              if (playerPlayBackSpeed >= 10.0) return;
                              playerPlayBackSpeed += 0.25;
                              videoPlayer!.setPlaybackSpeed(playerPlayBackSpeed);
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
                              if (videoPlayer != null) {
                                videoPlayer!.value.isPlaying ? videoPlayer!.pause() : videoPlayer!.play();
                              }
                            }),
                            icon: Icon(
                              videoPlayer == null
                                  ? Icons.pause
                                  : videoPlayer!.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
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
                      if (videoPlayer == null) return;
                      setState(() {
                        if (showPlayerVolume) {
                          showPlayerVolume = false;
                          return;
                        }
                        showPlayerVolume = false;
                        if (videoPlayer!.value.isPlaying)
                          videoPlayer!.pause();
                        else
                          videoPlayer!.play();
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
                                        videoPlayer?.setVolume(playerVolume);
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

    Scaffold getImageScaffold() => Scaffold(
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
            child: PhotoView(
              imageProvider: NetworkImage(
                "http://${WebServer.serverAddress}:${driveProvider.apiPorts}/drive/getImage?directory=${driveProvider.directory}/${widget.fileName}",
                headers: {
                  "username": driveProvider.username,
                  "token": driveProvider.token,
                },
              ),
              backgroundDecoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
            ),
          ),
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
                    child: videoPlayer == null
                        ? const Center(child: SizedBox(height: 50, width: 50, child: CircularProgressIndicator()))
                        : videoPlayer!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: videoPlayer!.value.aspectRatio,
                                child: VideoPlayer(videoPlayer!),
                              )
                            : const Center(child: SizedBox(height: 50, width: 50, child: CircularProgressIndicator())),
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
                                      timeUntilHideBars = 3;
                                      if (videoPlayer == null) return;
                                      playerSliderInUse = true;
                                      Duration nextPosition = Duration(milliseconds: (videoPlayer!.value.duration.inMilliseconds * (newValue / 100)).toInt());
                                      // Calculates the desired position
                                      videoPlayer!.seekTo(nextPosition);
                                      setState(() => playerPositionSlider = newValue);
                                    },
                                    onChangeEnd: (_) => playerSliderInUse = false,
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
                                    timeUntilHideBars = 3;
                                    if (videoPlayer != null) {
                                      videoPlayer!.value.isPlaying ? videoPlayer!.pause() : videoPlayer!.play();
                                    }
                                  }),
                                  icon: Icon(
                                    videoPlayer == null
                                        ? Icons.pause
                                        : videoPlayer!.value.isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
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
                                        videoPlayer?.setVolume(playerVolume);
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
