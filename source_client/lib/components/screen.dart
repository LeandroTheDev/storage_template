import 'dart:ui';

class Screen {
  static bool isPortrait(Size screenSize) {
    if (screenSize.height <= 500 && screenSize.width < 700) return true;
    // Width is smaller than height, and if not a square
    if (screenSize.width < screenSize.height && !(screenSize.height - screenSize.width < 50)) return true;

    // Checking if the screen is not a square
    if (screenSize.width > screenSize.height && screenSize.width - screenSize.height < 50)
      return true;
    else if (screenSize.width - screenSize.height < 50) return true;

    return false;
  }
}
