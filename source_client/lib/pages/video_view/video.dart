import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoProvider extends ChangeNotifier {
  Player? _player;
  Player? get player => _player;
  void changePlayer(Player player) => _player = player;

  VideoController? _controller;
  VideoController? get controller => _controller;
  void changeController(VideoController controller) => _controller = controller;

  double _aspectRatio = 16 / 9;
  double get aspectRatio => _aspectRatio;
  void changeAspectRatio(double aspectRatio) => _aspectRatio = aspectRatio;

  String _positionText = "00:00";
  String get positionText => _positionText;
  void changePositionText(String positionText) => _positionText = positionText;

  double _positionSlider = 0;
  double get positionSlider => _positionSlider;
  void changePositionSlider(double positionSlider) => _positionSlider = positionSlider;

  bool _sliderInUse = false;
  bool get sliderInUse => _sliderInUse;
  void changeSliderInUse(bool sliderInUse) => _sliderInUse = sliderInUse;

  Duration? _sliderDuration;
  Duration? get sliderDuration => _sliderDuration;
  void changeSliderDuration(Duration sliderDuration) => _sliderDuration = sliderDuration;

  double _volume = 0;
  double get volume => _volume;
  void changeVolume(double volume) => _volume = volume;

  bool _showPlayerVolume = false;
  bool get showPlayerVolume => _showPlayerVolume;
  void changeShowPlayerVolume(bool showPlayerVolume) => _showPlayerVolume = showPlayerVolume;

  double _playBackSpeed = 1.0;
  double get playBackSpeed => _playBackSpeed;
  void changePlaybackSpeed(double playBackSpeed) => _playBackSpeed = playBackSpeed;
}
