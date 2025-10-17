import 'package:drive/components/system.dart';
import 'package:drive/pages/video_view/video.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

class Portrait extends StatelessWidget {
  const Portrait({super.key});
  
  static const double BOTTOMBAR_SIZE = 50;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final videoProvider = Provider.of<VideoProvider>(context);    

    return Stack(
      children: [
        // Video Player
        Column(
          children: [
            // Video Player
            videoProvider.player == null
                ? const Center(child: SizedBox(height: 50, width: 50, child: CircularProgressIndicator()))
                : Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: videoProvider.aspectRatio,
                        child: Video(controller: videoProvider.controller!),
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
                videoProvider.changeShowPlayerVolume(false);

                videoProvider.player!.playOrPause();
              },
              child: Container(
                color: Colors.transparent,
                width: screenSize.width,
                height: screenSize.height - MediaQuery.of(context).padding.top - kToolbarHeight - BOTTOMBAR_SIZE,
              ),
            ),
          ],
        ),

        // Low Buttons
        getLowButtons(context),
      ],
    );
  }

  Widget getLowButtons(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final videoProvider = Provider.of<VideoProvider>(context);

    double statusBarHeight = MediaQuery.of(context).padding.top;
    if (System.isAndroid()) statusBarHeight += 15;
    if (System.isWindows()) statusBarHeight -= 24;
    double availableHeight = screenSize.height - kToolbarHeight - statusBarHeight;
    availableHeight -= 44;

    return Column(
      children: [
        // Volume Changer
        Column(
          children: [
            // Height Spacer
            SizedBox(
              height: availableHeight - 230,
            ),
            // Volume changer row
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // Spacer
                  const Spacer(),
                  // Volume Changer
                  videoProvider.showPlayerVolume
                      ? Padding(
                          padding: const EdgeInsets.only(right: 4, top: 30),
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Slider(
                              value: videoProvider.volume,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (newValue) {
                                videoProvider.changeVolume(newValue);
                                videoProvider.player!.setVolume(videoProvider.volume);
                              },
                              onChangeEnd: (_) => videoProvider.changeShowPlayerVolume(false),
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
        // Bottom Bar
        SizedBox(
          height: BOTTOMBAR_SIZE,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Video Position
                Text(
                  videoProvider.positionText,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                // Video Position change
                Expanded(
                  child: Slider(
                    value: videoProvider.positionSlider,
                    min: 0,
                    max: 100,
                    onChanged: (newValue) {
                      videoProvider.changeShowPlayerVolume(false);
                      if (videoProvider.sliderInUse) return;
                      videoProvider.player!.pause();
                      videoProvider.changeSliderInUse(true);
                      videoProvider.changeSliderDuration(Duration(milliseconds: (videoProvider.player!.state.duration.inMilliseconds * (newValue / 100)).toInt()));
                      videoProvider.player!.seek(videoProvider.sliderDuration!);
                      videoProvider.changePositionSlider(newValue);
                    },
                    onChangeEnd: (_) {
                      videoProvider.changeSliderInUse(false);
                      videoProvider.player!.play();
                    },
                  ),
                ),
                // Backward playback
                IconButton(
                  onPressed: () {
                    if (videoProvider.playBackSpeed <= 0.25) return;
                    videoProvider.changePlaybackSpeed(videoProvider.playBackSpeed - 0.25);
                    videoProvider.player!.setRate(videoProvider.playBackSpeed);
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                // Forward plaback
                IconButton(
                  onPressed: () {
                    if (videoProvider.playBackSpeed >= 10.0) return;
                    videoProvider.changePlaybackSpeed(videoProvider.playBackSpeed + 0.25);
                    videoProvider.player!.setRate(videoProvider.playBackSpeed);
                  },
                  icon: const Icon(Icons.arrow_forward),
                ),
                // Sound button
                IconButton(
                  onPressed: () {
                    if (videoProvider.showPlayerVolume)
                      videoProvider.changeShowPlayerVolume(false);
                    else
                      videoProvider.changeShowPlayerVolume(true);
                  },
                  icon: Icon(
                    videoProvider.volume == 0
                        ? Icons.volume_off
                        : videoProvider.volume <= 0.3
                            ? Icons.volume_mute
                            : videoProvider.volume <= 0.6
                                ? Icons.volume_down
                                : Icons.volume_up,
                  ),
                ),
                // Play/Pause button
                IconButton(
                  onPressed: () {
                    videoProvider.changeShowPlayerVolume(false);
                    videoProvider.player!.playOrPause();
                  },
                  icon: Icon(
                    videoProvider.player!.state.playing ? Icons.pause : Icons.play_arrow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
