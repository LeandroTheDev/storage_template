import 'dart:ui';

class DriveConfigs {
  static const Map<String, double> sizes = {
    "buttonheight": 20,
    "buttonwidth": 100,
    "barheight": 50,
    "barwidth": 100,
    "nextheight": 50,
    "nextwidth": 0,
    "itemiconheight": 50,
    "itemiconwidth": 50,
    "itemprogressheight": 25,
    "itemprogresswidth": 25,
    "itemtextheight": 50,
    "itemtextwidth": 0,
    "videoplayerheight": 0,
    "videoplayerwidth": 0,
    "videosoundheight": 150,
    "videosoundwidth": 20,
  };

  static double getWidgetSize({required String widget, required String type, required Size screenSize}) {
    if (sizes["$widget$type"] == null) return 1;
    if (sizes["$widget$type"] == 0)
      switch (type) {
        case "height":
          return screenSize.height;
        case "width":
          return screenSize.width;
        default:
          return 1;
      }

    return sizes["$widget$type"]!;
  }

  static double getScreenSize({required List<String> widgets, required String type, required Size screenSize}) {
    double reducedSize = 0;
    for (int i = 0; i < widgets.length; i++) {
      if (sizes["${widgets[i]}$type"] == null)
        reducedSize -= 1;
      else
        reducedSize -= sizes["${widgets[i]}$type"]!;
    }
    switch (type) {
      case "height":
        return screenSize.height - reducedSize;
      case "width":
        return screenSize.width - reducedSize;
      default:
        return 1;
    }
  }

  static bool isPortrait(Size screenSize) {
    if (screenSize.height <= 500 && screenSize.width < 700) return true;
    // Width is smaller than height, and if not a square
    if (screenSize.width < screenSize.height && !(screenSize.height - screenSize.width < 50)) return true;

    // Checking if the screen is not a square
    if (screenSize.width > screenSize.height && screenSize.width - screenSize.height < 50)
      return true;
    else if ( screenSize.width - screenSize.height < 50) return true;

    return false;
  }
}
